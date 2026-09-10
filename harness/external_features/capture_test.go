package main

import (
	"bytes"
	"crypto/sha256"
	"errors"
	"flag"
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"syscall"
	"testing"
	"time"

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
		if len(c.Spans) != 1 || len(c.SpanStreams) != 1 || len(c.Resources) != 2 || len(events(c)) != 1 {
			t.Fatalf("bad decoding: %+v", c)
		}
		if attributeValue(c.Resources[0], "service.name") != "probe" || attributeValue(c.Resources[1], "service.name") != "" || maxAttributes(c.Spans) != 1 || maxLength(c.Spans) != 4 {
			t.Fatalf("nested attributes leaked or string lost: %+v", c)
		}
	}
}

func TestDecodePreservesSpanStreamContext(t *testing.T) {
	data := []byte(`[{
		"signal":"traces","payload":{"resourceSpans":[
			{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"one"}}]},"scopeSpans":[{"scope":{"name":"scope.one"},"spans":[{"traceId":"00000000000000000000000000000001","name":"GET /api/tags","kind":2,"attributes":[{"key":"http.route","value":{"stringValue":"/api/tags"}}]}]}]},
			{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"two"}}]},"scopeSpans":[{"scope":{"name":"scope.two"},"spans":[{"traceId":"00000000000000000000000000000001","name":"GET /api/tags","kind":2,"attributes":[{"key":"http.route","value":{"stringValue":"/api/tags"}}]}]}]}
		]}}]`)
	c, err := decodeCapture(data)
	if err != nil {
		t.Fatal(err)
	}
	if len(c.Spans) != 2 || len(c.SpanStreams) != 2 || spanContextID(c.SpanStreams[0], nil) == spanContextID(c.SpanStreams[1], nil) {
		t.Fatalf("span stream context was flattened: %+v", c.SpanStreams)
	}
	duplicated := capture{Spans: []object{c.Spans[0], c.Spans[0]}, SpanStreams: []spanStream{c.SpanStreams[0], c.SpanStreams[0]}}
	if expected, present := matchingWorkloadSpans(c, duplicated); expected != 2 || present != 1 {
		t.Fatalf("one contextual span stream stood in for another: %d/%d", present, expected)
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

func TestDecodePreservesLogStreamContext(t *testing.T) {
	data := []byte(`[{"signal":"logs","payload":{"resourceLogs":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"one"}}]},"scopeLogs":[{"scope":{"name":"scope.one"},"logRecords":[{"body":{"stringValue":"shared log"}}]}]},{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"two"}}]},"scopeLogs":[{"scope":{"name":"scope.two"},"logRecords":[{"body":{"stringValue":"shared log"}}]}]}]}}]`)
	c, err := decodeCapture(data)
	if err != nil {
		t.Fatal(err)
	}
	if len(c.Logs) != 2 || len(c.LogStreams) != 2 || logStreamID(c.LogStreams[0], nil) == logStreamID(c.LogStreams[1], nil) {
		t.Fatalf("log stream context was flattened: %+v", c.LogStreams)
	}
	duplicated := capture{Logs: []object{c.Logs[0], c.Logs[0]}, LogStreams: []logStream{c.LogStreams[0], c.LogStreams[0]}}
	if expected, present := matchingLogStreams(c, duplicated, nil); expected != 2 || present != 1 {
		t.Fatalf("one contextual log stream stood in for another: %d/%d", present, expected)
	}
}

func TestLogIdentityIncludesStableRecordFields(t *testing.T) {
	record := func(source string) object {
		return object{
			"body": object{"stringValue": "shared log"}, "severityText": "WARN", "severityNumber": float64(13),
			"attributes": []any{attr("source", source)}, "timeUnixNano": "123", "traceId": "volatile",
		}
	}
	one, two := record("one"), record("two")
	baseline := capture{Logs: []object{one, two}, LogStreams: []logStream{{Record: one}, {Record: two}}}
	duplicate := record("one")
	changed := capture{Logs: []object{one, duplicate}, LogStreams: []logStream{{Record: one}, {Record: duplicate}}}
	if expected, present := matchingLogStreams(baseline, changed, nil); expected != 2 || present != 1 {
		t.Fatalf("one stable log record stood in for another: %d/%d", present, expected)
	}
	timestampOnly := record("one")
	timestampOnly["timeUnixNano"] = "456"
	timestampOnly["traceId"] = "other"
	timestampOnly["flags"] = float64(0)
	if logStreamID(logStream{Record: one}, nil) != logStreamID(logStream{Record: timestampOnly}, nil) {
		t.Fatal("volatile log correlation fields split one record across captures")
	}
}

func TestLogLimitsPreserveStreamContext(t *testing.T) {
	baselineRecord := func() object {
		return object{"body": object{"stringValue": "shared log"}, "attributes": []any{attr("first", "long baseline attribute"), attr("second", "another long attribute")}}
	}
	cappedCount := func() object {
		return object{"body": object{"stringValue": "shared log"}, "attributes": []any{attr("first", "long baseline attribute")}, "droppedAttributesCount": float64(1)}
	}
	cappedLength := func() object {
		return object{"body": object{"stringValue": "shared log"}, "attributes": []any{attr("first", "long bas"), attr("second", "another ")}}
	}
	baseOne, baseTwo := baselineRecord(), baselineRecord()
	baseline := capture{Logs: []object{baseOne, baseTwo}, LogStreams: []logStream{
		{Record: baseOne, Scope: object{"name": "scope.one"}},
		{Record: baseTwo, Scope: object{"name": "scope.two"}},
	}}
	countOne, countDuplicate := cappedCount(), cappedCount()
	countChanged := capture{Logs: []object{countOne, countDuplicate}, LogStreams: []logStream{
		{Record: countOne, Scope: object{"name": "scope.one"}},
		{Record: countDuplicate, Scope: object{"name": "scope.one"}},
	}}
	if got := evaluate(experiment{Name: "log-count"}, baseline, countChanged); got.Status == "pass" {
		t.Fatal("one log stream stood in for another in the count-limit check")
	}
	lengthOne, lengthDuplicate := cappedLength(), cappedLength()
	lengthChanged := capture{Logs: []object{lengthOne, lengthDuplicate}, LogStreams: []logStream{
		{Record: lengthOne, Scope: object{"name": "scope.one"}},
		{Record: lengthDuplicate, Scope: object{"name": "scope.one"}},
	}}
	if got := evaluate(experiment{Name: "log-length"}, baseline, lengthChanged); got.Status == "pass" {
		t.Fatal("one log stream stood in for another in the length-limit check")
	}
}

func TestLogLengthPreservesIndividualRecordContext(t *testing.T) {
	record := func(timestamp string, values ...string) object {
		attributes := make([]any, len(values))
		for i, value := range values {
			attributes[i] = attr("payload", value)
		}
		return object{"body": object{"stringValue": "shared log"}, "timeUnixNano": timestamp, "attributes": attributes}
	}
	baseline := capture{Logs: []object{record("1", "long payload"), record("2", "long payload")}}
	changed := capture{Logs: []object{record("3", "long pay", "long pay"), record("4")}}
	if expected, present, _ := preservedLongLogAttributes(baseline, changed, 8); expected != 2 || present != 1 {
		t.Fatalf("one log record supplied another record's capped attribute: %d/%d", present, expected)
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
			case "default-service", "resource":
				base.Spans = syntheticProbeSpans()
				base.Logs[0]["body"] = object{"stringValue": "workload log"}
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
			case "request-headers":
				base.Spans = syntheticProbeSpans()
			case "propagation-none":
				base.Spans = syntheticProbeSpans()
				base.Logs[0]["body"] = object{"stringValue": "workload log"}
			case "span-length", "attribute-length":
				base.Spans = syntheticProbeSpans()
			case "attribute-count":
				base.Spans = syntheticProbeSpans()
				for _, span := range base.Spans {
					span["attributes"] = append(span["attributes"].([]any), attr("second", "value"), attr("third", "value"))
				}
			case "exemplars":
				base.Spans = syntheticProbeSpans()
				base.Logs[0]["body"] = object{"stringValue": "workload log"}
			case "log-length":
				base.Logs[0]["body"] = object{"stringValue": "workload log"}
			case "log-count":
				base.Logs[0]["body"] = object{"stringValue": "workload log"}
			case "event-attributes":
				base.Spans[0]["name"] = "INSERT"
				objects(base.Spans[0], "events")[0]["name"] = "exception"
			case "sampler", "sampler-arg":
				base.Logs[0]["body"] = object{"stringValue": "workload log"}
			}
			if got := evaluate(e, base, base); got.Status != "gap" {
				t.Fatalf("ignored setting passed: %+v", got)
			}
			changed := baselineCapture()
			switch e.Name {
			case "default-service":
				changed.Spans = syntheticProbeSpans()
				changed.Resources = []object{{"attributes": []any{attr("service.name", "unknown_service:probe")}}}
				changed.Logs[0]["body"] = object{"stringValue": "workload log"}
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
				changed.Logs[0]["body"] = object{"stringValue": "workload log"}
			case "resource":
				changed.Spans = syntheticProbeSpans()
				changed.Resources = []object{{"attributes": []any{attr("probe.external", "visible"), attr("service.name", "external-probe")}}}
				changed.Logs[0]["body"] = object{"stringValue": "workload log"}
			case "disabled":
				changed = capture{}
			case "sampler", "sampler-arg":
				changed.Spans = nil
				changed.Logs[0]["body"] = object{"stringValue": "workload log"}
			case "span-length", "attribute-length":
				changed.Spans = syntheticProbeSpans()
				for _, span := range changed.Spans {
					span["attributes"] = []any{attr("http.route", "api/tags"), attr("http.user_agent", "external")}
				}
			case "log-length":
				changed.Logs = []object{{
					"body": object{"stringValue": "workload log"},
					"attributes": []any{
						attr("first", "long bas"), attr("second", "another "), attr("third", "third at"),
					},
				}}
			case "attribute-count":
				changed.Spans = syntheticProbeSpans()
				for _, span := range changed.Spans {
					span["attributes"] = []any{attr("first", "value"), attr("second", "value")}
					span["dropped_attributes_count"] = float64(1)
				}
			case "events":
				changed.Spans = []object{{"dropped_events_count": float64(1)}}
			case "event-attributes":
				parent := item()
				parent["name"] = "INSERT"
				parent["events"] = []any{object{"name": "exception", "attributes": []any{attr("first", "long baseline attribute")}, "droppedAttributesCount": float64(2)}}
				changed.Spans = []object{parent}
			case "log-count":
				changed.Logs = []object{{"body": object{"stringValue": "workload log"}, "attributes": []any{attr("first", "long baseline attribute")}, "dropped_attributes_count": float64(2)}}
			case "exemplars":
				changed.Metrics = []object{{"name": "probe.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}}
				changed.Spans = syntheticProbeSpans()
				changed.Logs[0]["body"] = object{"stringValue": "workload log"}
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
		baseline := baselineCapture()
		c := baselineCapture()
		if name == "log-count" {
			baseline.Logs[0]["body"] = object{"stringValue": "workload log"}
			c.Logs[0]["body"] = object{"stringValue": "workload log"}
		} else if name == "event-attributes" {
			baseline.Spans[0]["name"] = "INSERT"
			objects(baseline.Spans[0], "events")[0]["name"] = "exception"
			c.Spans[0]["name"] = "INSERT"
			objects(c.Spans[0], "events")[0]["name"] = "exception"
		} else if name == "attribute-count" {
			baseline.Spans = syntheticProbeSpans()
			for _, span := range baseline.Spans {
				span["attributes"] = append(span["attributes"].([]any), attr("second", "value"), attr("third", "value"))
			}
			c.Spans = append(syntheticProbeSpans(), object{"attributes": []any{attr("first", "value"), attr("second", "value")}, "dropped_attributes_count": float64(20)})
		} else {
			c.Spans = append([]object{{"attributes": []any{attr("short", "12345678")}, "dropped_attributes_count": float64(20)}}, c.Spans...)
		}
		if got := evaluate(e, baseline, c); got.Status != "gap" {
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
	wrongExecutable := capture{Resources: []object{{"attributes": []any{attr("service.name", "unknown_service:wrong-binary"), attr("process.executable.name", "probe")}}}}
	if got := evaluate(experiment{Name: "default-service"}, capture{Resources: []object{{}}}, wrongExecutable); got.Status == "pass" {
		t.Fatal("incorrect executable suffix was accepted as a default service name")
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
	pointA := object{"attributes": []any{attr("route", "a")}, "count": "1", "exemplars": []any{object{"timeUnixNano": "1"}}}
	pointB := object{"attributes": []any{attr("route", "b")}, "count": "1"}
	multiPoint := object{"name": "multi.metric", "histogram": object{"dataPoints": []any{pointA, pointB}}}
	baseline = capture{Metrics: []object{multiPoint}, MetricStreams: []metricStream{{Metric: multiPoint, Scope: object{"name": "scope.one"}}}}
	onlyB := object{"name": "multi.metric", "histogram": object{"dataPoints": []any{pointB}}}
	changed = capture{Metrics: []object{onlyB}, MetricStreams: []metricStream{{Metric: onlyB, Scope: object{"name": "scope.one"}}}}
	if got := evaluate(experiment{Name: "exemplars"}, baseline, changed); got.Status == "pass" {
		t.Fatal("a different data point stood in for the exemplar-bearing series")
	}
	convertedA := object{"name": "multi.metric", "exponentialHistogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "a")}, "count": "1"}}}}
	changed = capture{Metrics: []object{convertedA}, MetricStreams: []metricStream{{Metric: convertedA, Scope: object{"name": "scope.one"}}}}
	if got := evaluate(experiment{Name: "histogram"}, baseline, changed); got.Status == "pass" {
		t.Fatal("one converted data point stood in for a missing histogram series")
	}
}

func TestControlMetricsPreserveDataPointIdentities(t *testing.T) {
	point := func(route string) object { return object{"attributes": []any{attr("route", route)}} }
	metric := func(name string, points ...object) object {
		values := make([]any, len(points))
		for i, point := range points {
			values[i] = point
		}
		return object{"name": name, "sum": object{"dataPoints": values}}
	}
	baselineMetric := metric("request.count", point("a"), point("b"))
	changedMetric := metric("request.count", point("a"))
	baseline := capture{Metrics: []object{baselineMetric}, MetricStreams: []metricStream{{Metric: baselineMetric}}}
	changed := capture{Metrics: []object{changedMetric}, MetricStreams: []metricStream{{Metric: changedMetric}}}
	if expected, present := matchingMetricStreams(baseline, changed); expected != 2 || present != 1 {
		t.Fatalf("metric data-point loss was not detected: %d/%d", present, expected)
	}
	beforeConnections := metric("system.network.connections", point("SYN_SENT"))
	afterConnections := metric("system.network.connections", point("ESTABLISHED"))
	before := capture{Metrics: []object{beforeConnections}, MetricStreams: []metricStream{{Metric: beforeConnections}}}
	after := capture{Metrics: []object{afterConnections}, MetricStreams: []metricStream{{Metric: afterConnections}}}
	if expected, present := matchingMetricStreams(before, after); expected != 1 || present != 1 {
		t.Fatalf("transient connection states split one observer stream: %d/%d", present, expected)
	}
	if expected, present, exemplars := unsampledExemplars(before, after); expected != 0 || present != 0 || exemplars != 0 {
		t.Fatalf("transient connection points supplied exemplar evidence: eligible=%d preserved=%d exemplars=%d", expected, present, exemplars)
	}
}

func TestResourceChecksPreserveRegistrationSpans(t *testing.T) {
	server := func(traceID string, status int) object {
		return object{
			"name": "POST /api/users", "kind": float64(2), "traceId": traceID,
			"attributes": []any{attr("http.route", "/api/users"), attr("http.method", "POST"), object{"key": "http.status_code", "value": object{"intValue": float64(status)}}},
		}
	}
	database := func(traceID string) object {
		return object{"name": "INSERT", "kind": float64(3), "traceId": traceID, "attributes": []any{attr("db.system", "sqlite")}}
	}
	baseline := capture{Spans: []object{server("baseline-one", 201), database("baseline-one"), server("baseline-two", 409), database("baseline-two")}}
	changed := capture{Spans: []object{server("changed-one", 201), database("changed-one"), database("changed-one")}}
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("lost registration span was not detected: %d/%d", present, expected)
	}
	probes := syntheticProbeSpans()
	batchBaseline := capture{Spans: append(append([]object{}, probes...), baseline.Spans...)}
	batchBaseline.Records = []object{batchRecord("traces", "spans", batchBaseline.Spans)}
	batchChanged := capture{Spans: syntheticProbeSpans()}
	for _, span := range batchChanged.Spans {
		batchChanged.Records = append(batchChanged.Records, batchRecord("traces", "spans", []object{span}))
	}
	if got := evaluate(experiment{Name: "span-batch"}, batchBaseline, batchChanged); got.Status == "pass" {
		t.Fatal("singleton probe batches hid lost registration spans")
	}
	defaultBaseline := batchBaseline
	defaultBaseline.Resources = []object{{}}
	defaultPreserved := batchBaseline
	defaultPreserved.Resources = []object{{}}
	defaultMissing := batchChanged
	defaultMissing.Resources = []object{{}}
	if preserved, missing := evaluate(experiment{Name: "default-service"}, defaultBaseline, defaultPreserved).signature(), evaluate(experiment{Name: "default-service"}, defaultBaseline, defaultMissing).signature(); preserved == missing {
		t.Fatalf("default-service gap hid workload span loss: %q", missing)
	}
}

func TestEventLimitsPreserveParentOccurrences(t *testing.T) {
	event := func() object {
		return object{"name": "exception", "attributes": []any{attr("type", "conflict"), attr("message", "duplicate")}}
	}
	parent := func(start string, events ...object) object {
		values := make([]any, len(events))
		for i, event := range events {
			values[i] = event
		}
		return object{"name": "INSERT", "kind": float64(3), "startTimeUnixNano": start, "attributes": []any{attr("db.system", "sqlite")}, "events": values}
	}
	baseline := capture{Spans: []object{parent("1", event()), parent("2", event())}}
	capped := func() object {
		return object{"name": "exception", "attributes": []any{attr("type", "conflict")}, "droppedAttributesCount": float64(1)}
	}
	changed := capture{Spans: []object{parent("3", capped(), capped()), parent("4")}}
	if expected, present := limitedEventRecords(baseline, changed, 1); expected != 2 || present != 1 {
		t.Fatalf("one event parent stood in for another: %d/%d", present, expected)
	}
}

func TestLengthLimitsPreserveBaselineRecords(t *testing.T) {
	spanBaseline := baselineCapture()
	spanBaseline.Spans = syntheticProbeSpans()
	unrelatedSpan := capture{Spans: []object{{"kind": float64(2), "attributes": []any{attr("unrelated", "12345678")}}}}
	if got := evaluate(experiment{Name: "span-length"}, spanBaseline, unrelatedSpan); got.Status == "pass" {
		t.Fatal("unrelated span stood in for missing workload requests")
	}
	missingAttribute := capture{Spans: syntheticProbeSpans()}
	for _, span := range missingAttribute.Spans {
		span["attributes"] = []any{attr("unrelated", "12345678")}
	}
	if got := evaluate(experiment{Name: "span-length"}, spanBaseline, missingAttribute); got.Status == "pass" {
		t.Fatal("unrelated capped attributes stood in for dropped long baseline attributes")
	}

	logBaseline := capture{Logs: []object{{"body": object{"stringValue": "workload log"}, "attributes": []any{attr("request", "long workload attribute")}}}}
	unrelatedLog := capture{Logs: []object{{"body": object{"stringValue": "unrelated log"}, "attributes": []any{attr("request", "12345678")}}}}
	if got := evaluate(experiment{Name: "log-length"}, logBaseline, unrelatedLog); got.Status == "pass" {
		t.Fatal("unrelated log stood in for the baseline log record")
	}
	twoLogs := capture{Logs: []object{
		{"body": object{"stringValue": "first"}, "attributes": []any{attr("request", "long workload attribute")}},
		{"body": object{"stringValue": "second"}, "attributes": []any{attr("request", "long workload attribute")}},
	}}
	oneLog := capture{Logs: []object{{"body": object{"stringValue": "first"}, "attributes": []any{attr("request", "12345678")}}}}
	if preserved, missing := evaluate(experiment{Name: "log-length"}, logBaseline, unrelatedLog).signature(), evaluate(experiment{Name: "log-length"}, twoLogs, oneLog).signature(); preserved == missing {
		t.Fatalf("missing log identity kept the reviewed gap signature: %q", missing)
	}
	mixedLogs := capture{Logs: []object{
		{"body": object{"stringValue": "limited"}, "attributes": []any{attr("request", "long workload attribute")}},
		{"body": object{"stringValue": "ordinary"}, "attributes": []any{attr("request", "short")}},
	}}
	onlyLimited := capture{Logs: []object{
		{"body": object{"stringValue": "limited"}, "attributes": []any{attr("request", "long wor")}},
	}}
	if got := evaluate(experiment{Name: "log-length"}, mixedLogs, onlyLimited); got.Status == "pass" {
		t.Fatal("correctly capped log masked the loss of an unaffected log")
	}
	arrayValue := object{"arrayValue": object{"values": []any{object{"stringValue": "long array member"}}}}
	arraySpan := capture{Spans: []object{{"attributes": []any{attr("scalar", "12345678"), object{"key": "array", "value": arrayValue}}}}}
	if got := evaluate(experiment{Name: "span-length"}, baselineCapture(), arraySpan); got.Status == "pass" {
		t.Fatal("oversized string array member was ignored")
	}
	arrayBaseline := capture{Spans: syntheticProbeSpans()}
	arrayChanged := capture{Spans: syntheticProbeSpans()}
	for i := range arrayBaseline.Spans {
		arrayBaseline.Spans[i]["attributes"] = append(arrayBaseline.Spans[i]["attributes"].([]any), object{"key": "array", "value": object{"arrayValue": object{"values": []any{object{"stringValue": "long array member"}, object{"stringValue": "second long member"}}}}})
		arrayChanged.Spans[i]["attributes"] = []any{attr("http.route", "api/tags"), attr("http.user_agent", "external"), object{"key": "array", "value": object{"arrayValue": object{"values": []any{object{"stringValue": "long arr"}, object{"stringValue": "second l"}}}}}}
	}
	if got := evaluate(experiment{Name: "span-length"}, arrayBaseline, arrayChanged); got.Status != "pass" {
		t.Fatalf("correctly truncated string arrays were not preserved: %+v", got)
	}
	for _, span := range arrayChanged.Spans {
		span["attributes"] = []any{attr("http.route", "api/tags"), attr("http.user_agent", "external"), object{"key": "array", "value": object{"arrayValue": object{"values": []any{object{"stringValue": "long arr"}}}}}}
	}
	if got := evaluate(experiment{Name: "span-length"}, arrayBaseline, arrayChanged); got.Status == "pass" {
		t.Fatal("a dropped long array member was credited as preserved")
	}
}

func TestLengthLimitsPreserveIndividualSpanContext(t *testing.T) {
	span := func(name, value string) object {
		return object{
			"name": name, "kind": float64(3), "traceId": fmt.Sprintf("%032x", 1),
			"attributes": []any{attr("payload", value)},
		}
	}
	baseline := capture{Spans: []object{span("SELECT", "long payload"), span("INSERT", "long payload")}}
	changed := capture{Spans: []object{span("SELECT", "long pay"), span("SELECT", "long pay")}}
	if expected, present, _ := preservedLongSpanAttributes(baseline, changed, 8); expected != 2 || present != 1 {
		t.Fatalf("one span supplied another span's capped attribute: %d/%d", present, expected)
	}
}

func TestCountLimitsPreserveBaselineRecords(t *testing.T) {
	spanBaseline := baselineCapture()
	spanBaseline.Spans = syntheticProbeSpans()
	unrelatedSpan := capture{Spans: []object{{"kind": float64(2), "attributes": []any{attr("first", "value"), attr("second", "value")}, "droppedAttributesCount": float64(1)}}}
	if got := evaluate(experiment{Name: "attribute-count"}, spanBaseline, unrelatedSpan); got.Status == "pass" {
		t.Fatal("unrelated span stood in for missing count-limited requests")
	}
	for _, span := range spanBaseline.Spans {
		span["attributes"] = append(span["attributes"].([]any), attr("second", "value"), attr("third", "value"))
	}
	uncappedProbes := capture{Spans: syntheticProbeSpans()}
	uncappedProbes.Spans = append(uncappedProbes.Spans, object{"kind": float64(2), "attributes": []any{attr("first", "value"), attr("second", "value")}, "droppedAttributesCount": float64(1)})
	if got := evaluate(experiment{Name: "attribute-count"}, spanBaseline, uncappedProbes); got.Status == "pass" {
		t.Fatal("an unrelated capped span stood in for uncapped probe requests")
	}
	registration := object{"name": "POST /api/users", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("first", "value"), attr("second", "value"), attr("third", "value")}}
	withRegistration := spanBaseline
	withRegistration.Spans = append(append([]object{}, spanBaseline.Spans...), registration)
	cappedProbes := capture{Spans: syntheticProbeSpans()}
	for _, span := range cappedProbes.Spans {
		span["attributes"] = []any{attr("first", "value"), attr("second", "value")}
		span["dropped_attributes_count"] = float64(1)
	}
	if got := evaluate(experiment{Name: "attribute-count"}, withRegistration, cappedProbes); got.Status == "pass" {
		t.Fatal("capped probe spans masked a missing registration span")
	}
	noProbeBaseline := capture{Spans: []object{{"kind": float64(2), "attributes": []any{attr("first", "value"), attr("second", "value"), attr("third", "value")}}}}
	cappedUnrelated := capture{Spans: []object{{"kind": float64(2), "attributes": []any{attr("first", "value"), attr("second", "value")}, "droppedAttributesCount": float64(1)}}}
	if got := evaluate(experiment{Name: "attribute-count"}, noProbeBaseline, cappedUnrelated); got.Status != "not_exercised" {
		t.Fatalf("attribute-count without baseline probe evidence was %s", got.Status)
	}
	unnamedLogBaseline := capture{Logs: []object{{"attributes": []any{attr("first", "value"), attr("second", "value")}}}}
	cappedUnrelatedLog := capture{Logs: []object{{"body": object{"stringValue": "unrelated"}, "attributes": []any{attr("first", "value")}, "droppedAttributesCount": float64(1)}}}
	if got := evaluate(experiment{Name: "log-count"}, unnamedLogBaseline, cappedUnrelatedLog); got.Status != "not_exercised" {
		t.Fatalf("log-count without identifiable baseline logs was %s", got.Status)
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

func TestSamplerPreservesMetricAndLogIdentities(t *testing.T) {
	metric := object{"name": "workload.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	baseline := capture{
		Spans:   syntheticProbeSpans(),
		Metrics: []object{metric},
		Logs:    []object{{"body": object{"stringValue": "workload log"}}},
	}
	preserved := capture{Metrics: []object{metric}, Logs: []object{{"body": object{"stringValue": "workload log"}}}}
	if got := evaluate(experiment{Name: "sampler"}, baseline, preserved); got.Status != "pass" {
		t.Fatalf("sampler rejected preserved metric and log identities: %+v", got)
	}
	unrelatedMetric := object{"name": "unrelated.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	unrelated := capture{Metrics: []object{unrelatedMetric}, Logs: []object{{"body": object{"stringValue": "unrelated log"}}}}
	if got := evaluate(experiment{Name: "sampler"}, baseline, unrelated); got.Status == "pass" {
		t.Fatal("unrelated metrics and logs stood in for sampler control signals")
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
	metric := object{"name": "workload.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	baseline = capture{
		Spans:     syntheticProbeSpans(),
		Metrics:   []object{metric},
		Logs:      []object{{"body": object{"stringValue": "workload log"}}},
		Resources: []object{{}},
	}
	unrelatedMetric := object{"name": "unrelated.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	changed = capture{
		Spans:     syntheticProbeSpans(),
		Metrics:   []object{unrelatedMetric},
		Logs:      []object{{"body": object{"stringValue": "unrelated log"}}},
		Resources: []object{{"attributes": []any{attr("probe.external", "visible"), attr("service.name", "external-probe")}}},
	}
	if got := evaluate(experiment{Name: "resource"}, baseline, changed); got.Status == "pass" {
		t.Fatal("unrelated metrics and logs stood in for resource-run baseline signals")
	}
}

func TestLogBatchBurstMonitorsOwnership(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		time.Sleep(250 * time.Millisecond)
		w.WriteHeader(http.StatusConflict)
	}))
	defer server.Close()
	var checks atomic.Int32
	verify := func() error {
		if checks.Add(1) >= 10 {
			return errPortInUse
		}
		return nil
	}
	if err := logBatchBurst(server.URL, []byte(`{}`), verify); !errors.Is(err, errPortInUse) {
		t.Fatalf("in-flight ownership loss was not detected: %v", err)
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
		out = append(out, object{"name": "GET api/tags", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", i), "parent_span_id": "00f067aa0ba902b7", "attributes": []any{attr("http.route", "api/tags"), attr("http.user_agent", "external-feature-probe-long-user-agent")}})
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

func TestPropagationPreservesTheRestOfTheWorkload(t *testing.T) {
	registration := object{
		"name": "POST /api/users", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", 20),
		"attributes": []any{attr("http.route", "/api/users"), attr("http.method", "POST")},
	}
	base := capture{
		Spans:   append(syntheticProbeSpans(), registration),
		Metrics: baselineCapture().Metrics,
		Logs:    []object{{"body": object{"stringValue": "workload log"}}},
	}
	changed := capture{
		Spans:   syntheticProbeSpans(),
		Metrics: base.Metrics,
		Logs:    base.Logs,
	}
	for i, span := range changed.Spans {
		span["trace_id"] = fmt.Sprintf("%032x", i+10)
		span["parent_span_id"] = ""
	}
	e := experiment{Name: "propagation-none"}
	for _, drop := range []string{"registration spans", "metrics", "logs"} {
		candidate := changed
		switch drop {
		case "registration spans":
		case "metrics":
			candidate.Spans = append(candidate.Spans, registration)
			candidate.Metrics = nil
		case "logs":
			candidate.Spans = append(candidate.Spans, registration)
			candidate.Logs = nil
		}
		if got := evaluate(e, base, candidate); got.Status == "pass" {
			t.Fatalf("propagation-none passed after dropping %s", drop)
		}
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
	owned, shared, err := processTCPPortOwnership(os.Getpid(), port)
	if err != nil || !owned || shared {
		t.Fatalf("current process listener not recognized: owned=%t shared=%t err=%v", owned, shared, err)
	}
	owned, shared = socketOwnership(map[string]bool{"child": true, "foreign": true}, map[string]bool{"child": true})
	if owned || !shared {
		t.Fatalf("shared SO_REUSEPORT listeners were misclassified: owned=%t shared=%t", owned, shared)
	}
	owned, shared = socketOwnership(map[string]bool{"foreign": true}, map[string]bool{"child": true})
	if owned || shared {
		t.Fatalf("a foreign-only listener was misclassified: owned=%t shared=%t", owned, shared)
	}
	for _, test := range []struct {
		network, address string
		want             bool
	}{
		{"tcp", "0100007F", true},
		{"tcp", "00000000", true},
		{"tcp", "0200007F", false},
		{"tcp6", "00000000000000000000000000000000", false},
		{"tcp6", "0000000000000000FFFF00000100007F", true},
		{"tcp6", "00000000000000000000000001000000", false},
	} {
		if got := conflictsWithProbeAddress(test.network, test.address); got != test.want {
			t.Fatalf("conflict classification for %s/%s: got %t, want %t", test.network, test.address, got, test.want)
		}
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
	if n, preserved, exemplars := unsampledExemplars(base, base); n != 1 || preserved != 0 || exemplars != 0 {
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

func TestExemplarSuppressionPreservesUnaffectedSignals(t *testing.T) {
	affected := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}, "exemplars": []any{object{"timeUnixNano": "1"}}}}}}
	unaffected := object{"name": "requests", "sum": object{"dataPoints": []any{object{"attributes": []any{attr("route", "users")}}}}}
	suppressed := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}
	base := capture{
		Spans:   syntheticProbeSpans(),
		Metrics: []object{affected, unaffected},
		Logs:    []object{{"body": object{"stringValue": "workload log"}}},
	}
	complete := capture{Spans: syntheticProbeSpans(), Metrics: []object{suppressed, unaffected}, Logs: base.Logs}
	if got := evaluate(experiment{Name: "exemplars"}, base, complete); got.Status != "pass" {
		t.Fatalf("complete exemplar suppression did not pass: %+v", got)
	}
	for _, candidate := range []capture{
		{Spans: complete.Spans, Metrics: []object{suppressed}, Logs: complete.Logs},
		{Metrics: complete.Metrics, Logs: complete.Logs},
		{Spans: complete.Spans, Metrics: complete.Metrics},
	} {
		if got := evaluate(experiment{Name: "exemplars"}, base, candidate); got.Status == "pass" {
			t.Fatal("exemplar suppression passed after dropping an unaffected signal")
		}
	}
}

func TestBatchAndHeaderExperimentsPreserveOtherSignals(t *testing.T) {
	complete := func() capture {
		return capture{
			Spans:   syntheticProbeSpans(),
			Metrics: []object{{"name": "requests", "sum": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}},
			Logs:    []object{{"body": object{"stringValue": "workload log"}}},
		}
	}
	spanBase := complete()
	spanBase.Records = []object{batchRecord("traces", "spans", spanBase.Spans)}
	spanChanged := complete()
	for _, span := range spanChanged.Spans {
		spanChanged.Records = append(spanChanged.Records, batchRecord("traces", "spans", []object{span}))
	}
	if got := evaluate(experiment{Name: "span-batch"}, spanBase, spanChanged); got.Status != "pass" {
		t.Fatalf("complete span-batch capture did not pass: %+v", got)
	}
	for _, candidate := range []capture{
		{Records: spanChanged.Records, Spans: spanChanged.Spans, Metrics: spanChanged.Metrics},
		{Records: spanChanged.Records, Spans: spanChanged.Spans, Logs: spanChanged.Logs},
	} {
		if got := evaluate(experiment{Name: "span-batch"}, spanBase, candidate); got.Status == "pass" {
			t.Fatal("span-batch passed after dropping an unaffected signal")
		}
	}

	logBase := complete()
	logBase.Logs = append(logBase.Logs, object{"body": object{"stringValue": "second workload log"}})
	logBase.Records = []object{batchRecord("logs", "log_records", logBase.Logs)}
	logChanged := complete()
	logChanged.Logs = append(logChanged.Logs, object{"body": object{"stringValue": "second workload log"}})
	for _, record := range logChanged.Logs {
		logChanged.Records = append(logChanged.Records, batchRecord("logs", "log_records", []object{record}))
	}
	for _, candidate := range []capture{
		{Records: logChanged.Records, Logs: logChanged.Logs, Metrics: logChanged.Metrics},
		{Records: logChanged.Records, Logs: logChanged.Logs, Spans: logChanged.Spans},
	} {
		if got := evaluate(experiment{Name: "log-batch"}, logBase, candidate); got.Status == "pass" {
			t.Fatal("log-batch passed after dropping an unaffected signal")
		}
	}

	headerBase := complete()
	registration := object{"name": "POST /api/users", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("http.route", "/api/users")}}
	headerBase.Spans = append(headerBase.Spans, registration)
	headerChanged := complete()
	headerChanged.Spans = append(headerChanged.Spans, registration)
	for _, span := range probeSpans(headerChanged) {
		span["attributes"] = append(span["attributes"].([]any), object{"key": "http.request.header.x_probe_feature", "value": object{"arrayValue": object{"values": []any{object{"stringValue": "visible"}}}}})
	}
	if got := evaluate(experiment{Name: "request-headers"}, headerBase, headerChanged); got.Status != "pass" {
		t.Fatalf("complete header capture did not pass: %+v", got)
	}
	for _, candidate := range []capture{
		{Spans: headerChanged.Spans[:4], Metrics: headerChanged.Metrics, Logs: headerChanged.Logs},
		{Spans: headerChanged.Spans, Logs: headerChanged.Logs},
		{Spans: headerChanged.Spans, Metrics: headerChanged.Metrics},
	} {
		if got := evaluate(experiment{Name: "request-headers"}, headerBase, candidate); got.Status == "pass" {
			t.Fatal("header capture passed after dropping unaffected workload telemetry")
		}
	}
}

func TestAlwaysOnPreservesAllControlMetricsAndLogs(t *testing.T) {
	eligible := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}
	excluded := object{"name": "active", "sum": object{"dataPoints": []any{object{"attributes": []any{attr("route", "users")}, "exemplars": []any{object{"timeUnixNano": "1"}}}}}}
	withExemplar := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}, "exemplars": []any{object{"timeUnixNano": "2"}}}}}}
	base := capture{Metrics: []object{eligible, excluded}, Logs: []object{{"body": object{"stringValue": "workload log"}}}}
	complete := capture{Metrics: []object{withExemplar, excluded}, Logs: base.Logs}
	if got := evaluate(experiment{Name: "exemplars-always-on"}, base, complete); got.Status != "pass" {
		t.Fatalf("complete AlwaysOn capture did not pass: %+v", got)
	}
	for _, candidate := range []capture{{Metrics: []object{withExemplar}, Logs: complete.Logs}, {Metrics: complete.Metrics}} {
		if got := evaluate(experiment{Name: "exemplars-always-on"}, base, candidate); got.Status == "pass" {
			t.Fatal("AlwaysOn passed after dropping control telemetry")
		}
	}
}

func TestCountEventAndHistogramExperimentsPreserveOtherSignals(t *testing.T) {
	metric := object{"name": "requests", "sum": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}
	logRecord := object{"body": object{"stringValue": "workload log"}}

	logBase := capture{Spans: syntheticProbeSpans(), Metrics: []object{metric}, Logs: []object{
		{"body": object{"stringValue": "limited"}, "attributes": []any{attr("first", "one"), attr("second", "two")}},
		{"body": object{"stringValue": "ordinary"}, "attributes": []any{attr("first", "one")}},
	}}
	logChanged := capture{Spans: syntheticProbeSpans(), Metrics: []object{metric}, Logs: []object{
		{"body": object{"stringValue": "limited"}, "attributes": []any{attr("first", "one")}, "dropped_attributes_count": float64(1)},
		{"body": object{"stringValue": "ordinary"}, "attributes": []any{attr("first", "one")}},
	}}
	if got := evaluate(experiment{Name: "log-count"}, logBase, logChanged); got.Status != "pass" {
		t.Fatalf("complete log-count capture did not pass: %+v", got)
	}
	droppedOrdinary := logChanged
	droppedOrdinary.Logs = droppedOrdinary.Logs[:1]
	if got := evaluate(experiment{Name: "log-count"}, logBase, droppedOrdinary); got.Status == "pass" {
		t.Fatal("log-count passed after dropping an unaffected log")
	}

	server := object{"name": "POST /api/users", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("http.route", "/api/users")}}
	parent := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("db.system", "sqlite")}}
	event := object{"name": "exception", "attributes": []any{attr("first", "one"), attr("second", "two")}}
	parent["events"] = []any{event}
	eventBase := capture{Spans: []object{server, parent}, Metrics: []object{metric}, Logs: []object{logRecord}}
	cappedParent := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("db.system", "sqlite")}, "events": []any{object{"name": "exception", "attributes": []any{attr("first", "one")}, "dropped_attributes_count": float64(1)}}}
	eventChanged := capture{Spans: []object{server, cappedParent}, Metrics: []object{metric}, Logs: []object{logRecord}}
	if got := evaluate(experiment{Name: "event-attributes"}, eventBase, eventChanged); got.Status != "pass" {
		t.Fatalf("complete event-attribute capture did not pass: %+v", got)
	}
	if got := evaluate(experiment{Name: "event-attributes"}, eventBase, capture{Spans: []object{cappedParent}}); got.Status == "pass" {
		t.Fatal("event-attribute limit passed after dropping unaffected telemetry")
	}
	suppressedParent := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("db.system", "sqlite")}, "dropped_events_count": float64(1)}
	if got := evaluate(experiment{Name: "events"}, eventBase, capture{Spans: []object{suppressedParent}}); got.Status == "pass" {
		t.Fatal("event suppression passed after dropping eventless workload telemetry")
	}

	histogram := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}
	exponential := object{"name": "duration", "exponentialHistogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}
	histogramBase := capture{Spans: syntheticProbeSpans(), Metrics: []object{histogram, metric}, Logs: []object{logRecord}}
	histogramChanged := capture{Spans: syntheticProbeSpans(), Metrics: []object{exponential, metric}, Logs: []object{logRecord}}
	if got := evaluate(experiment{Name: "histogram"}, histogramBase, histogramChanged); got.Status != "pass" {
		t.Fatalf("complete histogram conversion did not pass: %+v", got)
	}
	if got := evaluate(experiment{Name: "histogram"}, histogramBase, capture{Metrics: []object{exponential}}); got.Status == "pass" {
		t.Fatal("histogram conversion passed after dropping unaffected telemetry")
	}
}

func TestMetricIdentityIncludesStableStreamAttributes(t *testing.T) {
	metric := object{"name": "shared.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	base := metricStream{
		Metric:   metric,
		Scope:    object{"name": "scope", "attributes": []any{attr("scope.key", "one")}},
		Resource: object{"attributes": []any{attr("deployment.environment", "prod"), attr("process.pid", "1")}},
	}
	changedScope := base
	changedScope.Scope = object{"name": "scope", "attributes": []any{attr("scope.key", "two")}}
	if metricID(base) == metricID(changedScope) {
		t.Fatal("scope attributes were omitted from metric identity")
	}
	changedResource := base
	changedResource.Resource = object{"attributes": []any{attr("deployment.environment", "staging"), attr("process.pid", "1")}}
	if metricID(base) == metricID(changedResource) {
		t.Fatal("stable resource attributes were omitted from metric identity")
	}
	volatileResource := base
	volatileResource.Resource = object{"attributes": []any{attr("deployment.environment", "prod"), attr("process.pid", "2")}}
	if metricID(base) != metricID(volatileResource) {
		t.Fatal("volatile process ID split one metric stream across captures")
	}
}

func TestMetricPointIdentityNormalizesRandomizedEndpointPorts(t *testing.T) {
	metric := func(host string) object {
		return object{"name": "http.server.duration", "histogram": object{"dataPoints": []any{object{
			"attributes": []any{attr("http.host", host), attr("net.host.name", host), attr("http.method", "GET")},
		}}}}
	}
	baseline := metricStream{Metric: metric("127.0.0.1:12345")}
	changed := metricStream{Metric: metric("127.0.0.1:54321")}
	if metricPointID(baseline, objects(baseline.Metric, "data_points")[0], nil) != metricPointID(changed, objects(changed.Metric, "data_points")[0], nil) {
		t.Fatal("randomized endpoint port split one metric point across captures")
	}
	otherHost := metricStream{Metric: metric("localhost:54321")}
	if metricPointID(baseline, objects(baseline.Metric, "data_points")[0], nil) == metricPointID(otherHost, objects(otherHost.Metric, "data_points")[0], nil) {
		t.Fatal("endpoint host was omitted from metric point identity")
	}
	if got := normalizeEndpointPort("::1"); got != "::1" {
		t.Fatalf("bare IPv6 address was treated as a host-port pair: %q", got)
	}
}
