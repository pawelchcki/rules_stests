package main

import (
	"bytes"
	"crypto/sha256"
	"errors"
	"flag"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"testing"

	"github.com/pawelchcki/rules_stests/report"
)

func TestAdditionalFeatureCoverage(t *testing.T) {
	args := flag.Args()
	if len(args) == 0 {
		t.Fatal("matrix and proof tables are required")
	}
	data, err := os.ReadFile(resolve(args[0]))
	if err != nil {
		t.Fatal(err)
	}
	features, err := report.ImportMatrix(string(data), report.CatalogSource{Revision: "test", URL: "test", RawURL: "test", SHA256: "test"})
	if err != nil {
		t.Fatal(err)
	}
	known := map[string]bool{}
	for _, f := range features {
		known[f.ID] = true
	}
	var proofs []byte
	for _, path := range args[1:] {
		data, err := os.ReadFile(resolve(path))
		if err != nil {
			t.Fatal(err)
		}
		proofs = append(proofs, data...)
	}
	existing, err := report.ParseProofRuleAssertions(proofs)
	if err != nil {
		t.Fatal(err)
	}
	additional := map[string]bool{}
	for _, e := range experiments {
		for _, f := range e.Features {
			if !known[f] {
				t.Errorf("unknown matrix feature %q", f)
			}
			if existing[f] != "" {
				t.Errorf("already covered by existing proof: %s", f)
			}
			if additional[f] {
				t.Errorf("duplicate feature %s", f)
			}
			additional[f] = true
		}
	}
	if len(additional)*5 < len(existing) {
		t.Errorf("%d additions to %d existing features misses 20%% target", len(additional), len(existing))
	}
	t.Logf("%d existing features + %d external experiments = %.1f%% growth", len(existing), len(additional), 100*float64(len(additional))/float64(len(existing)))
}

func TestDecodeBothWireRepresentations(t *testing.T) {
	for _, data := range []string{
		`[{"signal":"traces","payload":{"resource_spans":[{"resource":{"attributes":[{"key":"service.name","value":{"value":{"string_value":"probe"}}}]},"scope_spans":[{"spans":[{"attributes":[{"key":"name","value":{"value":{"string_value":"span"}}}],"events":[{"attributes":[{"key":"event","value":{"value":{"string_value":"nested"}}}]}]}]}]},{}]}}]`,
		`[{"signal":"traces","payload":{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"probe"}}]},"scopeSpans":[{"spans":[{"attributes":[{"key":"name","value":{"stringValue":"span"}}],"events":[{"attributes":[{"key":"event","value":{"stringValue":"nested"}}]}]}]}]},{}]}}]`,
	} {
		c, err := decodeCapture([]byte(data))
		if err != nil {
			t.Fatal(err)
		}
		if len(c.Spans) != 1 || len(c.Resources) != 2 || len(events(c)) != 1 {
			t.Fatalf("bad decoding: %+v", c)
		}
		if attributeValue(c.Resources[0], "service.name") != "probe" || attributeValue(c.Resources[1], "service.name") != "" || maxAttributes(c.Spans) != 1 || maxLength(c.Spans) != 4 {
			t.Fatalf("nested attributes leaked or string lost: %+v", c)
		}
	}
}

func TestDecodePreservesMetricStreamContext(t *testing.T) {
	data := []byte(`[{"signal":"metrics","payload":{"resourceMetrics":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"probe"}}]},"scopeMetrics":[{"scope":{"name":"scope.one"},"metrics":[{"name":"shared.metric","histogram":{"dataPoints":[{"count":"1"}]}}]},{"scope":{"name":"scope.two"},"metrics":[{"name":"shared.metric","histogram":{"dataPoints":[{"count":"1"}]}}]}]}]}}]`)
	c, err := decodeCapture(data)
	if err != nil {
		t.Fatal(err)
	}
	if len(c.Metrics) != 2 || len(c.MetricStreams) != 2 || metricID(c.MetricStreams[0]) == metricID(c.MetricStreams[1]) {
		t.Fatalf("metric stream context was flattened: %+v", c.MetricStreams)
	}
}

func attr(key, value string) any { return object{"key": key, "value": object{"stringValue": value}} }
func item() object {
	return object{"attributes": []any{attr("first", "long baseline attribute"), attr("second", "another long attribute"), attr("third", "third attribute")}}
}
func baselineCapture() capture {
	s := item()
	s["events"] = []any{item()}
	return capture{
		Records: []object{{"request": object{"content_encoding": "identity"}}},
		Spans:   []object{s}, Logs: []object{item()}, Resources: []object{item()},
		Metrics: []object{{"name": "probe.metric", "histogram": object{"dataPoints": []any{object{"exemplars": []any{object{"timeUnixNano": "1"}}}}}}},
	}
}

func TestExperimentsRequireBaselineAndRejectIgnoredSettings(t *testing.T) {
	for _, e := range experiments {
		t.Run(e.Name, func(t *testing.T) {
			base := baselineCapture()
			switch e.Name {
			case "span-batch":
				base.Spans = syntheticProbeSpans()
				base.Records = []object{batchRecord("traces", "spans", base.Spans)}
			case "log-batch":
				base.Logs = []object{item(), item()}
				base.Logs[0]["body"], base.Logs[1]["body"] = object{"stringValue": "first"}, object{"stringValue": "second"}
				base.Records = []object{batchRecord("logs", "log_records", base.Logs)}
			case "exemplars-always-on":
				base.Spans = nil
				base.Metrics = []object{{"name": "probe.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}}
			case "request-headers", "propagation-none":
				base.Spans = syntheticProbeSpans()
			}
			if got := evaluate(e, base, base); got.Status != "gap" {
				t.Fatalf("ignored setting passed: %+v", got)
			}
			changed := baselineCapture()
			switch e.Name {
			case "default-service":
				changed.Resources = []object{{"attributes": []any{attr("service.name", "unknown_service:probe")}}}
			case "span-batch":
				changed.Spans = syntheticProbeSpans()
				changed.Records = nil
				for _, s := range changed.Spans {
					changed.Records = append(changed.Records, batchRecord("traces", "spans", []object{s}))
				}
			case "log-batch":
				changed.Logs = []object{item(), item()}
				changed.Logs[0]["body"], changed.Logs[1]["body"] = object{"stringValue": "first"}, object{"stringValue": "second"}
				changed.Records = nil
				for _, l := range changed.Logs {
					changed.Records = append(changed.Records, batchRecord("logs", "log_records", []object{l}))
				}
			case "exemplars-always-on":
				changed.Spans = nil
			case "request-headers":
				changed.Spans = syntheticProbeSpans()
				for _, s := range changed.Spans {
					s["attributes"] = append(s["attributes"].([]any), object{"key": "http.request.header.x_probe_feature", "value": object{"arrayValue": object{"values": []any{object{"stringValue": "visible"}}}}})
				}
			case "propagation-none":
				changed.Spans = syntheticProbeSpans()
				for i, s := range changed.Spans {
					s["trace_id"] = fmt.Sprintf("%032x", i+10)
					s["parent_span_id"] = ""
				}
			case "resource":
				changed.Resources = []object{{"attributes": []any{attr("probe.external", "visible"), attr("service.name", "external-probe")}}}
			case "disabled":
				changed = capture{}
			case "sampler", "sampler-arg":
				changed.Spans = nil
			case "span-length", "attribute-length":
				changed.Spans = []object{{"attributes": []any{attr("first", "12345678")}}}
			case "log-length":
				changed.Logs = []object{{"attributes": []any{attr("first", "12345678")}}}
			case "attribute-count":
				changed.Spans = []object{{"attributes": []any{attr("first", "value"), attr("second", "value")}, "dropped_attributes_count": float64(1)}}
			case "events":
				changed.Spans = []object{{"dropped_events_count": float64(1)}}
			case "event-attributes":
				changed.Spans = []object{{"events": []any{object{"attributes": []any{attr("first", "value")}, "droppedAttributesCount": float64(2)}}}}
			case "log-count":
				changed.Logs = []object{{"attributes": []any{attr("first", "value")}, "dropped_attributes_count": float64(2)}}
			case "exemplars":
				changed.Metrics = []object{{"name": "probe.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}}
			case "histogram":
				changed.Metrics = []object{{"name": "probe.metric", "data": object{"exponential_histogram": object{"data_points": []any{object{"count": float64(1)}}}}}}
			default:
				t.Fatal("missing positive fixture")
			}
			if got := evaluate(e, base, changed); got.Status != "pass" {
				t.Fatalf("expected pass: %+v", got)
			}
			if got := evaluate(e, capture{}, changed); got.Status != "not_exercised" {
				t.Fatalf("empty baseline credited: %+v", got)
			}
			if e.Name != "disabled" && e.Name != "sampler" && e.Name != "sampler-arg" {
				if got := evaluate(e, base, capture{}); got.Status == "pass" {
					t.Fatalf("empty capture credited: %+v", got)
				}
			}
		})
	}
}

func TestLimitsCheckEveryRecordAndExactCap(t *testing.T) {
	for _, name := range []string{"span-length", "attribute-count", "log-length", "log-count", "event-attributes"} {
		var e experiment
		for _, candidate := range experiments {
			if candidate.Name == name {
				e = candidate
			}
		}
		c := baselineCapture()
		c.Spans = append([]object{{"attributes": []any{attr("short", "12345678")}, "dropped_attributes_count": float64(20)}}, c.Spans...)
		if got := evaluate(e, baselineCapture(), c); got.Status != "gap" {
			t.Fatalf("one good span masked violations: %+v", got)
		}
	}
}

func TestComparisonSeparatesMissingEvidence(t *testing.T) {
	var out bytes.Buffer
	if err := compareResults(nil, &out); err == nil {
		t.Fatal("accepted empty comparison")
	}
	if strings.Contains(out.String(), "observed discrepancy") {
		t.Fatal("invented discrepancy")
	}
}

func TestConfigurationRejectionIsSpecific(t *testing.T) {
	var e experiment
	for _, candidate := range experiments {
		if candidate.Name == "span-length" {
			e = candidate
		}
	}
	log := "opentelemetry/sdk/trace/span_limits.rb:45:in `initialize': attribute_length_limit must not be less than 32 (ArgumentError)"
	if o, ok := configurationRejection("rails", e, log); !ok || o.Status != "startup_rejected" {
		t.Fatalf("lost observed rejection: %+v", o)
	}
	for _, bad := range []string{"application crashed", "attribute_length_limit must not be less than 32", strings.ReplaceAll(log, "ArgumentError", "LoadError")} {
		if _, ok := configurationRejection("rails", e, bad); ok {
			t.Fatal("arbitrary startup error accepted")
		}
	}
	if _, ok := configurationRejection("gin", e, log); ok {
		t.Fatal("wrong implementation credited")
	}
}

func TestComparisonRequiresRetainedCapture(t *testing.T) {
	r := result{SchemaVersion: 1, Application: "django", Captures: map[string]string{"baseline": "missing"}}
	if err := verifyResult(r, t.TempDir()); err == nil {
		t.Fatal("missing baseline accepted")
	}
}

func TestKnownGapCannotHideAdditionalViolations(t *testing.T) {
	var e experiment
	for _, candidate := range experiments {
		if candidate.Name == "log-length" {
			e = candidate
		}
	}
	changed := baselineCapture()
	changed.Logs = []object{{"attributes": []any{attr("request", strings.Repeat("r", 32))}}}
	if got := evaluate(e, baselineCapture(), changed).signature(); got != "gap:request=32" {
		t.Fatalf("unexpected gap signature: %s", got)
	}
	changed.Logs[0]["attributes"] = append(changed.Logs[0]["attributes"].([]any), attr("code.file.path", "unexpected oversized value"))
	if got := evaluate(e, baselineCapture(), changed).signature(); got == "gap:request=32" {
		t.Fatal("known gap hid a new violation")
	}
}

func TestGapSignaturesPreserveFailureModes(t *testing.T) {
	spanBatch := experiment{Name: "span-batch"}
	baseline := capture{Spans: syntheticProbeSpans()}
	baseline.Records = []object{batchRecord("traces", "spans", baseline.Spans)}
	if ignored, missing := evaluate(spanBatch, baseline, baseline).signature(), evaluate(spanBatch, baseline, capture{}).signature(); ignored == missing {
		t.Fatalf("missing telemetry matched ignored batch limit: %q", ignored)
	}
	jittered := baseline
	jittered.Records = []object{batchRecord("traces", "spans", jittered.Spans[:3])}
	if unchanged, jitter := evaluate(spanBatch, baseline, baseline).signature(), evaluate(spanBatch, baseline, jittered).signature(); unchanged != jitter {
		t.Fatalf("batch-count jitter changed the limit-violation signature: %q != %q", unchanged, jitter)
	}
	logBatch := experiment{Name: "log-batch"}
	controlLogs := []object{{"body": object{"stringValue": "first"}}, {"body": object{"stringValue": "second"}}}
	control := capture{Logs: controlLogs, Records: []object{batchRecord("logs", "log_records", controlLogs)}}
	unrelatedLogs := []object{{"body": object{"stringValue": "third"}}, {"body": object{"stringValue": "fourth"}}}
	configuredLogs := capture{Logs: unrelatedLogs}
	for _, record := range unrelatedLogs {
		configuredLogs.Records = append(configuredLogs.Records, batchRecord("logs", "log_records", []object{record}))
	}
	if got := evaluate(logBatch, control, configuredLogs); got.Status == "pass" {
		t.Fatal("unrelated singleton logs stood in for the control batch")
	}
	volatileControl := []object{
		{"body": object{"stringValue": "Started POST \"/api/users\" for 127.0.0.1 at 2026-09-10 00:00:00 +0000"}},
		{"body": object{"stringValue": "Completed 409 Conflict in 141ms (Views: 0.1ms)"}},
	}
	volatileChanged := []object{
		{"body": object{"stringValue": "Started POST \"/api/users\" for 127.0.0.1 at 2026-09-10 00:00:05 +0000"}},
		{"body": object{"stringValue": "Completed 409 Conflict in 152ms (Views: 0.8ms)"}},
	}
	if expected, present := matchingLogRecords(volatileControl, volatileChanged); expected != 2 || present != 2 {
		t.Fatalf("volatile Rails log fields changed record identity: %d/%d", present, expected)
	}

	headers := experiment{Name: "request-headers"}
	if absent, missing := evaluate(headers, capture{Spans: syntheticProbeSpans()}, capture{Spans: syntheticProbeSpans()}).signature(), evaluate(headers, capture{Spans: syntheticProbeSpans()}, capture{}).signature(); absent == missing {
		t.Fatalf("missing spans matched absent headers: %q", absent)
	}

	defaultBaseline := baselineCapture()
	defaultBaseline.Spans = syntheticProbeSpans()
	configured := baselineCapture()
	configured.Spans = nil
	if preserved, missing := evaluate(experiment{Name: "default-service"}, defaultBaseline, defaultBaseline).signature(), evaluate(experiment{Name: "default-service"}, defaultBaseline, configured).signature(); preserved == missing {
		t.Fatalf("missing default-service telemetry matched preserved signals: %q", preserved)
	}

	malformed := capture{Spans: syntheticProbeSpans()}
	for _, s := range malformed.Spans {
		s["attributes"] = append(s["attributes"].([]any), attr("http.request.header.x_probe_feature", "visible"))
	}
	if absent, invalid := evaluate(headers, capture{Spans: syntheticProbeSpans()}, capture{Spans: syntheticProbeSpans()}).signature(), evaluate(headers, capture{Spans: syntheticProbeSpans()}, malformed).signature(); absent == invalid {
		t.Fatalf("malformed headers matched absent headers: %q", absent)
	}
	duplicated := capture{Spans: syntheticProbeSpans()}
	duplicated.Spans[3]["trace_id"] = field(duplicated.Spans[2], "trace_id")
	if absent, missingRequest := evaluate(headers, capture{Spans: syntheticProbeSpans()}, capture{Spans: syntheticProbeSpans()}).signature(), evaluate(headers, capture{Spans: syntheticProbeSpans()}, duplicated).signature(); absent == missingRequest {
		t.Fatalf("missing request matched absent headers: %q", absent)
	}

	emptyService := capture{Resources: []object{{"attributes": []any{attr("service.name", "")}}}}
	malformedService := capture{Resources: []object{{"attributes": []any{object{"key": "service.name", "value": object{"intValue": float64(1)}}}}}}
	if empty, invalid := evaluate(experiment{Name: "default-service"}, capture{Resources: []object{{}}}, emptyService).signature(), evaluate(experiment{Name: "default-service"}, capture{Resources: []object{{}}}, malformedService).signature(); empty == invalid {
		t.Fatalf("malformed service.name matched an empty string: %q", empty)
	}
	identityBaseline := capture{Resources: []object{{}}, Spans: syntheticProbeSpans()}
	duplicatedDefault := capture{Resources: []object{{}}, Spans: syntheticProbeSpans()}
	duplicatedDefault.Spans[3]["trace_id"] = field(duplicatedDefault.Spans[2], "trace_id")
	if preserved, missingRequest := evaluate(experiment{Name: "default-service"}, identityBaseline, identityBaseline).signature(), evaluate(experiment{Name: "default-service"}, identityBaseline, duplicatedDefault).signature(); preserved == missingRequest {
		t.Fatalf("default-service gap hid a missing request: %q", preserved)
	}
}

func TestMetricChangesPreserveInstrumentIdentity(t *testing.T) {
	baseline := baselineCapture()
	unrelated := capture{Metrics: []object{
		{"name": "unrelated.metric", "data": object{"exponential_histogram": object{"data_points": []any{object{"count": float64(1)}}}}},
	}}
	if got := evaluate(experiment{Name: "exemplars"}, baseline, unrelated); got.Status == "pass" {
		t.Fatal("unrelated metric stood in for the exemplar-bearing instrument")
	}
	if got := evaluate(experiment{Name: "histogram"}, baseline, unrelated); got.Status == "pass" {
		t.Fatal("unrelated exponential histogram stood in for the baseline instrument")
	}

	baseMetric := object{"name": "shared.metric", "histogram": object{"dataPoints": []any{object{"count": "1", "exemplars": []any{object{"timeUnixNano": "1"}}}}}}
	baseline = capture{Metrics: []object{baseMetric, baseMetric}, MetricStreams: []metricStream{
		{Metric: baseMetric, Scope: object{"name": "scope.one"}},
		{Metric: baseMetric, Scope: object{"name": "scope.two"}},
	}}
	suppressed := object{"name": "shared.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	changed := capture{Metrics: []object{suppressed}, MetricStreams: []metricStream{{Metric: suppressed, Scope: object{"name": "scope.one"}}}}
	if got := evaluate(experiment{Name: "exemplars"}, baseline, changed); got.Status == "pass" {
		t.Fatal("one scope stood in for a missing exemplar-bearing metric stream")
	}
	converted := object{"name": "shared.metric", "exponentialHistogram": object{"dataPoints": []any{object{"count": "1"}}}}
	changed = capture{Metrics: []object{converted}, MetricStreams: []metricStream{{Metric: converted, Scope: object{"name": "scope.one"}}}}
	if got := evaluate(experiment{Name: "histogram"}, baseline, changed); got.Status == "pass" {
		t.Fatal("one scope stood in for a missing histogram stream")
	}
	replacement := object{"name": "shared.metric", "sum": object{"dataPoints": []any{object{"asInt": "1"}}}}
	changed = capture{Metrics: []object{replacement}, MetricStreams: []metricStream{{Metric: replacement, Scope: object{"name": "scope.one"}}, {Metric: replacement, Scope: object{"name": "scope.two"}}}}
	if got := evaluate(experiment{Name: "exemplars"}, baseline, changed); got.Status == "pass" {
		t.Fatal("a different metric type stood in for exemplar-bearing histograms")
	}
	preserved := object{"name": "shared.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	newExemplars := object{"name": "new.metric", "histogram": object{"dataPoints": []any{object{"count": "1", "exemplars": []any{object{"timeUnixNano": "1"}}}}}}
	changed = capture{Metrics: []object{preserved, newExemplars}, MetricStreams: []metricStream{
		{Metric: preserved, Scope: object{"name": "scope.one"}},
		{Metric: preserved, Scope: object{"name": "scope.two"}},
		{Metric: newExemplars, Scope: object{"name": "scope.one"}},
	}}
	if got := evaluate(experiment{Name: "exemplars"}, baseline, changed); got.Status == "pass" {
		t.Fatal("new metric stream exported exemplars under the SDK-wide filter")
	}
}

func TestLengthLimitsPreserveBaselineRecords(t *testing.T) {
	spanBaseline := baselineCapture()
	spanBaseline.Spans = syntheticProbeSpans()
	unrelatedSpan := capture{Spans: []object{{"kind": float64(2), "attributes": []any{attr("unrelated", "12345678")}}}}
	if got := evaluate(experiment{Name: "span-length"}, spanBaseline, unrelatedSpan); got.Status == "pass" {
		t.Fatal("unrelated span stood in for missing workload requests")
	}

	logBaseline := capture{Logs: []object{{"body": object{"stringValue": "workload log"}, "attributes": []any{attr("request", "long workload attribute")}}}}
	unrelatedLog := capture{Logs: []object{{"body": object{"stringValue": "unrelated log"}, "attributes": []any{attr("request", "12345678")}}}}
	if got := evaluate(experiment{Name: "log-length"}, logBaseline, unrelatedLog); got.Status == "pass" {
		t.Fatal("unrelated log stood in for the baseline log record")
	}
	arrayValue := object{"arrayValue": object{"values": []any{object{"stringValue": "long array member"}}}}
	arraySpan := capture{Spans: []object{{"attributes": []any{attr("scalar", "12345678"), object{"key": "array", "value": arrayValue}}}}}
	if got := evaluate(experiment{Name: "span-length"}, baselineCapture(), arraySpan); got.Status == "pass" {
		t.Fatal("oversized string array member was ignored")
	}
}

func TestCountLimitsPreserveBaselineRecords(t *testing.T) {
	spanBaseline := baselineCapture()
	spanBaseline.Spans = syntheticProbeSpans()
	unrelatedSpan := capture{Spans: []object{{"kind": float64(2), "attributes": []any{attr("first", "value"), attr("second", "value")}, "droppedAttributesCount": float64(1)}}}
	if got := evaluate(experiment{Name: "attribute-count"}, spanBaseline, unrelatedSpan); got.Status == "pass" {
		t.Fatal("unrelated span stood in for missing count-limited requests")
	}

	logBaseline := capture{Logs: []object{{"body": object{"stringValue": "workload log"}, "attributes": []any{attr("first", "value"), attr("second", "value")}}}}
	unrelatedLog := capture{Logs: []object{{"body": object{"stringValue": "unrelated log"}, "attributes": []any{attr("first", "value")}, "droppedAttributesCount": float64(1)}}}
	if got := evaluate(experiment{Name: "log-count"}, logBaseline, unrelatedLog); got.Status == "pass" {
		t.Fatal("unrelated log stood in for the baseline count-limited record")
	}

	eventBaseline := capture{Spans: []object{{"name": "INSERT", "events": []any{object{"name": "exception", "attributes": []any{attr("first", "value"), attr("second", "value")}}}}}}
	unrelatedEvent := capture{Spans: []object{{"name": "SELECT", "events": []any{object{"name": "exception", "attributes": []any{attr("first", "value")}, "droppedAttributesCount": float64(1)}}}}}
	if got := evaluate(experiment{Name: "event-attributes"}, eventBaseline, unrelatedEvent); got.Status == "pass" {
		t.Fatal("unrelated event stood in for the baseline exception event")
	}
	suppressedEvent := capture{Spans: []object{{"name": "SELECT", "droppedEventsCount": float64(1)}}}
	if got := evaluate(experiment{Name: "events"}, eventBaseline, suppressedEvent); got.Status == "pass" {
		t.Fatal("unrelated span stood in for the baseline event-bearing span")
	}
}

func TestResourceExperimentPreservesWorkload(t *testing.T) {
	baseline := baselineCapture()
	baseline.Spans = syntheticProbeSpans()
	changed := baselineCapture()
	changed.Spans = nil
	changed.Resources = []object{{"attributes": []any{attr("probe.external", "visible"), attr("service.name", "external-probe")}}}
	if got := evaluate(experiment{Name: "resource"}, baseline, changed); got.Status == "pass" {
		t.Fatal("unrelated resource stood in for missing workload telemetry")
	}
}

func TestComparisonRecomputesAndRejectsTamperedEvidence(t *testing.T) {
	dir := t.TempDir()
	data := []byte(`[{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"name":"GET /api/tags"}]}]}]}}]`)
	c, err := decodeCapture(data)
	if err != nil {
		t.Fatal(err)
	}
	r := result{SchemaVersion: 1, Application: "test", Captures: map[string]string{}}
	names := []string{"baseline"}
	for _, control := range experimentControls {
		names = append(names, control.Name)
	}
	for _, e := range experiments {
		names = append(names, e.Name)
		r.Observations = append(r.Observations, evaluate(e, c, c))
	}
	for _, name := range names {
		if err := os.WriteFile(filepath.Join(dir, name+".capture.json"), data, 0600); err != nil {
			t.Fatal(err)
		}
		r.Captures[name] = fmt.Sprintf("%x", sha256.Sum256(data))
	}
	if err := verifyResult(r, dir); err != nil {
		t.Fatal(err)
	}
	original := r.Observations[0].Status
	r.Observations[0].Status = "pass"
	if err := verifyResult(r, dir); err == nil {
		t.Fatal("edited outcome accepted")
	}
	r.Observations[0].Status = original
	if err := os.WriteFile(filepath.Join(dir, "baseline.capture.json"), []byte("[]"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := verifyResult(r, dir); err == nil {
		t.Fatal("edited capture accepted")
	}
}

func syntheticProbeSpans() []object {
	var out []object
	for i := 1; i <= 4; i++ {
		out = append(out, object{"kind": float64(2), "trace_id": fmt.Sprintf("%032x", i), "parent_span_id": "00f067aa0ba902b7", "attributes": []any{attr("http.user_agent", "external-feature-probe-long-user-agent")}})
	}
	return out
}
func batchRecord(signal, key string, items []object) object {
	values := make([]any, len(items))
	for i, item := range items {
		values[i] = item
	}
	return object{"signal": signal, "payload": object{key: values}}
}

func TestPropagationCannotPassWithWrongOrMissingParents(t *testing.T) {
	e := experiment{Name: "propagation-none"}
	base := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	for _, s := range changed.Spans {
		s["parent_span_id"] = ""
	}
	if got := evaluate(e, base, changed); got.Status != "gap" {
		t.Fatal("retained incoming trace IDs credited")
	}
	for i, s := range changed.Spans {
		s["trace_id"] = fmt.Sprintf("%032x", i+10)
	}
	changed.Spans[1]["trace_id"] = changed.Spans[0]["trace_id"]
	if got := evaluate(e, base, changed); got.Status != "gap" {
		t.Fatal("duplicate root trace ID credited as independent traces")
	}
	base.Spans[0]["trace_id"] = field(base.Spans[1], "trace_id")
	if got := evaluate(e, base, changed); got.Status != "not_exercised" {
		t.Fatal("duplicate trace stood in for missing request")
	}
}

func TestAlwaysOnExemplarsRequireUnsampledControl(t *testing.T) {
	e := experiment{Name: "exemplars-always-on"}
	base := baselineCapture()
	changed := baselineCapture()
	changed.Spans = nil
	if got := evaluate(e, base, changed); got.Status != "not_exercised" {
		t.Fatal("sampled control credited")
	}
	base.Spans = nil
	if got := evaluate(e, base, changed); got.Status != "not_exercised" {
		t.Fatal("control with exemplars credited")
	}
}

func TestCapturedHeaderMustBeAnExactArray(t *testing.T) {
	s := object{"attributes": []any{attr("http.request.header.x_probe_feature", "visible")}}
	if headerArray(s) {
		t.Fatal("scalar credited as array")
	}
	for _, values := range [][]any{{}, {object{"stringValue": "wrong"}}, {object{"stringValue": "visible"}, object{"intValue": 1}}} {
		s["attributes"] = []any{object{"key": "http.request.header.x_probe_feature", "value": object{"value": object{"array_value": object{"values": values}}}}}
		if headerArray(s) {
			t.Fatal("empty, mixed or incorrect array accepted")
		}
	}
}

func TestCapturedHeadersRequireDistinctRequests(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	changed.Spans[3]["trace_id"] = field(changed.Spans[2], "trace_id")
	for _, s := range changed.Spans {
		s["attributes"] = append(s["attributes"].([]any), object{"key": "http.request.header.x_probe_feature", "value": object{"arrayValue": object{"values": []any{object{"stringValue": "visible"}}}}})
	}
	if got := evaluate(experiment{Name: "request-headers"}, baseline, changed); got.Status == "pass" {
		t.Fatal("duplicate request stood in for a missing header capture")
	}
}

func TestSpanBatchRequiresDistinctRequests(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	baseline.Records = []object{batchRecord("traces", "spans", baseline.Spans)}
	changed := capture{Spans: syntheticProbeSpans()}
	changed.Spans[3]["trace_id"] = field(changed.Spans[2], "trace_id")
	for _, span := range changed.Spans {
		changed.Records = append(changed.Records, batchRecord("traces", "spans", []object{span}))
	}
	if got := evaluate(experiment{Name: "span-batch"}, baseline, changed); got.Status == "pass" {
		t.Fatal("duplicate request stood in for a missing single-span batch")
	}
}

func TestKillAfterGraceToleratesExitedProcess(t *testing.T) {
	done := make(chan error, 1)
	done <- nil
	if err := killAfterGrace(done, func() error { return syscall.ESRCH }); err != nil {
		t.Fatalf("already-exited process failed shutdown: %v", err)
	}
}

func TestPortConflictsAreRetried(t *testing.T) {
	attempts := 0
	data, err := retryPortConflicts(func() ([]byte, error) {
		attempts++
		if attempts < 3 {
			return nil, errPortInUse
		}
		return []byte("capture"), nil
	})
	if err != nil || string(data) != "capture" || attempts != 3 {
		t.Fatalf("port conflict was not retried: attempts=%d data=%q err=%v", attempts, data, err)
	}
	log, err := os.CreateTemp(t.TempDir(), "bind-log")
	if err != nil {
		t.Fatal(err)
	}
	defer log.Close()
	if _, err := log.WriteString("listen tcp: bind: address already in use"); err != nil {
		t.Fatal(err)
	}
	if err := classifyProcessExit(errors.New("exit status 1"), log); !errors.Is(err, errPortInUse) {
		t.Fatalf("bind conflict was not classified for retry: %v", err)
	}
}

func TestProcessPortOwnership(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	port := listener.Addr().(*net.TCPAddr).Port
	owned, err := processOwnsTCPPort(os.Getpid(), port)
	if err != nil || !owned {
		t.Fatalf("current process listener not recognized: owned=%t err=%v", owned, err)
	}
}

func TestWorkloadRejectionRequiresExactContextFailure(t *testing.T) {
	e := experiment{Name: "propagation-none"}
	log := "opentelemetry/context/__init__.py\nAttributeError: 'NoneType' object has no attribute 'get'"
	if o, ok := configurationRejection("django", e, log); !ok || o.Status != "workload_rejected" {
		t.Fatalf("lost context failure: %+v", o)
	}
	for _, bad := range []string{"HTTP 500", strings.ReplaceAll(log, "opentelemetry/context", "application/context"), strings.ReplaceAll(log, "AttributeError", "ValueError")} {
		if _, ok := configurationRejection("django", e, bad); ok {
			t.Fatal("unrelated HTTP failure accepted")
		}
	}
	if _, ok := configurationRejection("aiohttp", e, log); ok {
		t.Fatal("wrong application accepted")
	}
}

func TestTraceBasedExemplarsCannotProveAlwaysOn(t *testing.T) {
	base := capture{Metrics: []object{
		{"name": "active_requests", "sum": object{"dataPoints": []any{object{"exemplars": []any{object{"timeUnixNano": "1"}}}}}},
		{"name": "duration", "histogram": object{"dataPoints": []any{object{"count": "1"}}}},
	}}
	if n, preserved, exemplars := unsampledExemplars(base, base); n != 1 || preserved != 1 || exemplars != 0 {
		t.Fatalf("remote parent exemplars credited: eligible=%d preserved=%d exemplars=%d", n, preserved, exemplars)
	}
	controlMetric := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	configuredMetric := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"count": "1", "exemplars": []any{object{"timeUnixNano": "1"}}}}}}
	control := capture{Metrics: []object{controlMetric}, MetricStreams: []metricStream{{Metric: controlMetric, Scope: object{"name": "control.scope"}}}}
	configured := capture{Metrics: []object{configuredMetric}, MetricStreams: []metricStream{{Metric: configuredMetric, Scope: object{"name": "other.scope"}}}}
	if got := evaluate(experiment{Name: "exemplars-always-on"}, control, configured); got.Status == "pass" {
		t.Fatal("an unmatched metric stream supplied AlwaysOn exemplar evidence")
	}
}
