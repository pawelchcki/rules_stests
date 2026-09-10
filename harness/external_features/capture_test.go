package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
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
	single := capture{Logs: []object{one}}
	duplicatedCapture := capture{Logs: []object{one, one}}
	if expected, present := matchingLogStreams(single, duplicatedCapture, nil); expected != 1 || present != 2 {
		t.Fatalf("duplicate log occurrence was not rejected: %d/%d", present, expected)
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
		Metrics: []object{{"name": "probe.metric", "histogram": object{"dataPoints": []any{object{"count": "1", "exemplars": []any{object{"timeUnixNano": "1", "value": object{"asInt": "1"}}}}}}}},
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
				if e.Name == "attribute-length" {
					changed.Logs[0]["attributes"] = []any{attr("first", "long bas"), attr("second", "another "), attr("third", "third at")}
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
					span["attributes"] = append([]any(nil), span["attributes"].([]any)[:2]...)
					span["dropped_attributes_count"] = float64(2)
				}
				changed.Logs[0]["attributes"] = []any{attr("first", "long baseline attribute"), attr("second", "another long attribute")}
				changed.Logs[0]["dropped_attributes_count"] = float64(1)
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
				changed.Metrics = []object{{"name": "probe.metric", "data": object{"exponential_histogram": object{"data_points": []any{object{"count": float64(1), "positive": object{"bucket_counts": []any{float64(1)}}}}}}}}
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

func TestGlobalAttributeLimitsCoverLogsAndEvents(t *testing.T) {
	lengthBaseline := capture{Spans: syntheticProbeSpans(), Logs: []object{{
		"body": object{"stringValue": "workload log"}, "attributes": []any{attr("payload", "long log attribute")},
	}}}
	lengthChanged := capture{Spans: syntheticProbeSpans(), Logs: []object{{
		"body": object{"stringValue": "workload log"}, "attributes": []any{attr("payload", "long log attribute")},
	}}}
	for _, span := range lengthChanged.Spans {
		span["attributes"] = []any{attr("http.route", "api/tags"), attr("http.user_agent", "external")}
	}
	if got := evaluate(experiment{Name: "attribute-length"}, lengthBaseline, lengthChanged); got.Status == "pass" {
		t.Fatal("global attribute length passed with an uncapped log attribute")
	}

	countBaseline := capture{Spans: syntheticProbeSpans(), Logs: []object{{
		"body": object{"stringValue": "workload log"}, "attributes": []any{attr("first", "value"), attr("second", "value"), attr("third", "value")},
	}}}
	for _, span := range countBaseline.Spans {
		span["attributes"] = append(span["attributes"].([]any), attr("second", "value"), attr("third", "value"))
	}
	countChanged := capture{Spans: syntheticProbeSpans(), Logs: []object{{
		"body": object{"stringValue": "workload log"}, "attributes": []any{attr("first", "value"), attr("second", "value"), attr("third", "value")},
	}}}
	for _, span := range countChanged.Spans {
		span["attributes"] = []any{attr("first", "value"), attr("second", "value")}
		span["dropped_attributes_count"] = float64(1)
	}
	if got := evaluate(experiment{Name: "attribute-count"}, countBaseline, countChanged); got.Status == "pass" {
		t.Fatal("global attribute count passed with an uncapped log record")
	}

	eventLengthBaseline := capture{Spans: syntheticProbeSpans()}
	eventLengthChanged := capture{Spans: syntheticProbeSpans()}
	eventLengthBaseline.Spans[0]["events"] = []any{object{"name": "exception", "attributes": []any{attr("message", "long event attribute")}}}
	eventLengthChanged.Spans[0]["events"] = []any{object{"name": "exception", "attributes": []any{attr("message", "long event attribute")}}}
	for _, span := range eventLengthChanged.Spans {
		span["attributes"] = []any{attr("http.route", "api/tags"), attr("http.user_agent", "external")}
	}
	if got := evaluate(experiment{Name: "attribute-length"}, eventLengthBaseline, eventLengthChanged); got.Status == "pass" {
		t.Fatal("global attribute length passed with an uncapped event attribute")
	}

	eventCountBaseline := capture{Spans: syntheticProbeSpans()}
	eventCountChanged := capture{Spans: syntheticProbeSpans()}
	for _, span := range eventCountBaseline.Spans {
		span["attributes"] = append(span["attributes"].([]any), attr("second", "value"), attr("third", "value"))
	}
	eventCountBaseline.Spans[0]["events"] = []any{object{"name": "exception", "attributes": []any{attr("first", "value"), attr("second", "value"), attr("third", "value")}}}
	eventCountChanged.Spans[0]["events"] = []any{object{"name": "exception", "attributes": []any{attr("first", "value"), attr("second", "value"), attr("third", "value")}}}
	for _, span := range eventCountChanged.Spans {
		span["attributes"] = []any{attr("first", "value"), attr("second", "value")}
		span["dropped_attributes_count"] = float64(1)
	}
	if got := evaluate(experiment{Name: "attribute-count"}, eventCountBaseline, eventCountChanged); got.Status == "pass" {
		t.Fatal("global attribute count passed with an uncapped event")
	}
}

func TestSpanLengthDoesNotNormalizeEventAttributes(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	baseline.Spans[0]["events"] = []any{object{"name": "exception", "attributes": []any{attr("message", "long event attribute")}}}
	changed.Spans[0]["events"] = []any{object{"name": "exception", "attributes": []any{attr("message", "long eve")}}}
	for _, span := range changed.Spans {
		span["attributes"] = []any{attr("http.route", "api/tags"), attr("http.user_agent", "external")}
	}
	if got := evaluate(experiment{Name: "span-length"}, baseline, changed); got.Status == "pass" {
		t.Fatal("span-only length limit accepted a truncated event attribute")
	}
}

func TestWorkloadSpanIdentityPreservesStatus(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	baseline.Spans[0]["status"] = object{"code": float64(2), "message": "registration rejected"}
	changed.Spans[0]["status"] = object{"code": float64(0), "message": ""}
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("span status corruption was not detected: %d/%d", present, expected)
	}
	if expected, present := matchingLengthLimitedWorkloadSpans(baseline, changed, 8, true); expected != 4 || present != 3 {
		t.Fatalf("length-limit identity omitted span status: %d/%d", present, expected)
	}
	if expected, present := matchingCountLimitedWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("count-limit identity omitted span status: %d/%d", present, expected)
	}
}

func TestWorkloadSpanIdentityRejectsInvalidTraceIDs(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	for _, span := range changed.Spans {
		span["trace_id"] = strings.Repeat("0", 32)
	}
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 0 {
		t.Fatalf("invalid workload trace IDs were preserved: %d/%d", present, expected)
	}
}

func TestWorkloadSpanIdentityRejectsInvalidSpanStructure(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	for name, mutate := range map[string]func(object){
		"zero span id": func(span object) { span["span_id"] = strings.Repeat("0", 16) },
		"duplicate span id": func(span object) {
			span["trace_id"] = field(baseline.Spans[1], "trace_id")
			span["span_id"] = field(baseline.Spans[1], "span_id")
		},
		"zero start": func(span object) { span["start_time_unix_nano"] = "0" },
		"reversed timestamps": func(span object) {
			span["start_time_unix_nano"], span["end_time_unix_nano"] = "200", "100"
		},
	} {
		t.Run(name, func(t *testing.T) {
			changed := capture{Spans: syntheticProbeSpans()}
			mutate(changed.Spans[0])
			if expected, present := matchingWorkloadSpans(baseline, changed); expected == present {
				t.Fatalf("invalid span structure was preserved: %d/%d", present, expected)
			}
		})
	}
}

func TestWorkloadSpanIdentityPreservesTracePartitions(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	changed.Spans[0]["trace_id"] = field(changed.Spans[1], "trace_id")
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 5 {
		t.Fatalf("merged independent request traces were accepted: %d/%d", present, expected)
	}
}

func TestWorkloadSpanIdentityPreservesFlagsAndEvents(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	baseline.Spans[0]["flags"] = float64(1)
	changed.Spans[0]["flags"] = float64(0)
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("span flag corruption was not detected: %d/%d", present, expected)
	}

	baseline = capture{Spans: syntheticProbeSpans()}
	changed = capture{Spans: syntheticProbeSpans()}
	baseline.Spans[0]["events"] = []any{object{"name": "exception", "attributes": []any{attr("type", "conflict")}}}
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("span event loss was not detected: %d/%d", present, expected)
	}
	if expected, present := matchingWorkloadSpansIgnoringEvents(baseline, changed); expected != 4 || present != 4 {
		t.Fatalf("event-specific matching did not ignore its intended transformation: %d/%d", present, expected)
	}
}

func TestWorkloadSpanIdentityPreservesAllStableAttributes(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	baseline.Spans[0]["attributes"] = append(baseline.Spans[0]["attributes"].([]any), attr("network.protocol.version", "1.1"), attr("url.scheme", "http"), attr("server.address", "127.0.0.1:12345"))
	changed.Spans[0]["attributes"] = append(changed.Spans[0]["attributes"].([]any), attr("url.scheme", "http"), attr("server.address", "127.0.0.1:54321"))
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("dropped stable span attribute was not detected: %d/%d", present, expected)
	}
}

func TestWorkloadSpanIdentityPreservesTopologyAndMultiplicity(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	detached := capture{Spans: syntheticProbeSpans()}
	for _, span := range baseline.Spans {
		span["flags"] = float64(257)
	}
	for _, span := range detached.Spans {
		span["parent_span_id"] = ""
		span["flags"] = float64(1)
	}
	if expected, present := matchingWorkloadSpans(baseline, detached); expected != 4 || present != 0 {
		t.Fatalf("detached server spans were not detected: %d/%d", present, expected)
	}
	if expected, present := matchingWorkloadSpansIgnoringParents(baseline, detached); expected != 4 || present != 4 {
		t.Fatalf("propagation-specific matching did not ignore the intended parent change: %d/%d", present, expected)
	}

	propagationBaseline := capture{Spans: syntheticProbeSpans()}
	propagationChanged := capture{Spans: syntheticProbeSpans()}
	for index := range propagationBaseline.Spans {
		baselineParentID := fmt.Sprintf("%016x", index+1)
		changedParentID := fmt.Sprintf("%016x", index+11)
		propagationBaseline.Spans[index]["span_id"] = baselineParentID
		propagationBaseline.Spans[index]["flags"] = float64(257)
		propagationChanged.Spans[index]["span_id"] = changedParentID
		propagationChanged.Spans[index]["parent_span_id"] = ""
		propagationChanged.Spans[index]["flags"] = float64(1)
		traceID := field(propagationBaseline.Spans[index], "trace_id")
		propagationBaseline.Spans = append(propagationBaseline.Spans, object{"name": "SELECT", "kind": float64(3), "trace_id": traceID, "span_id": fmt.Sprintf("%016x", index+101), "parent_span_id": baselineParentID, "start_time_unix_nano": fmt.Sprintf("%d", index*100+1000), "end_time_unix_nano": fmt.Sprintf("%d", index*100+1001), "attributes": []any{attr("db.system", "sqlite")}})
		propagationChanged.Spans = append(propagationChanged.Spans, object{"name": "SELECT", "kind": float64(3), "trace_id": traceID, "span_id": fmt.Sprintf("%016x", index+111), "parent_span_id": changedParentID, "start_time_unix_nano": fmt.Sprintf("%d", index*100+2000), "end_time_unix_nano": fmt.Sprintf("%d", index*100+2001), "attributes": []any{attr("db.system", "sqlite")}})
	}
	if expected, present := matchingWorkloadSpansIgnoringParents(propagationBaseline, propagationChanged); expected != 8 || present != 8 {
		t.Fatalf("valid local topology changed under propagation normalization: %d/%d", present, expected)
	}
	propagationChanged.Spans[4]["parent_span_id"] = ""
	if expected, present := matchingWorkloadSpansIgnoringParents(propagationBaseline, propagationChanged); expected != 8 || present != 7 {
		t.Fatalf("corrupted local parent was not detected under propagation normalization: %d/%d", present, expected)
	}

	duplicated := capture{Spans: syntheticProbeSpans()}
	for _, span := range duplicated.Spans {
		span["flags"] = float64(257)
	}
	duplicated.Spans = append(duplicated.Spans, duplicated.Spans[0])
	if expected, present := matchingWorkloadSpans(baseline, duplicated); expected != 4 || present != 5 {
		t.Fatalf("duplicate workload span was not rejected: %d/%d", present, expected)
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

	metric := object{"name": "requests", "sum": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}
	logBaseline := capture{
		Spans:   syntheticProbeSpans(),
		Metrics: []object{metric},
		Logs:    []object{{"body": object{"stringValue": "workload log"}, "attributes": []any{attr("request", strings.Repeat("r", 32))}}},
	}
	logGap := capture{Spans: syntheticProbeSpans(), Metrics: []object{metric}, Logs: logBaseline.Logs}
	stableLogGap := evaluate(e, logBaseline, logGap).signature()
	logLoss := capture{Logs: logGap.Logs}
	if loss := evaluate(e, logBaseline, logLoss).signature(); loss == stableLogGap {
		t.Fatalf("known log-length gap hid signal loss: %q", loss)
	}

	headerBase := capture{
		Spans:   append(syntheticProbeSpans(), object{"name": "POST /api/users", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("http.route", "/api/users")}}),
		Metrics: []object{metric},
		Logs:    []object{{"body": object{"stringValue": "workload log"}}},
	}
	headerGap := capture{Spans: append([]object{}, headerBase.Spans...), Metrics: headerBase.Metrics, Logs: headerBase.Logs}
	stableHeaderGap := evaluate(experiment{Name: "request-headers"}, headerBase, headerGap).signature()
	headerLoss := headerGap
	headerLoss.Spans = headerLoss.Spans[:4]
	if loss := evaluate(experiment{Name: "request-headers"}, headerBase, headerLoss).signature(); loss == stableHeaderGap {
		t.Fatalf("known header gap hid workload loss: %q", loss)
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
	zeroCount := object{"name": "multi.metric", "exponentialHistogram": object{"dataPoints": []any{
		object{"attributes": []any{attr("route", "a")}, "count": "0"},
		object{"attributes": []any{attr("route", "b")}, "count": "0"},
	}}}
	changed = capture{Metrics: []object{zeroCount}, MetricStreams: []metricStream{{Metric: zeroCount, Scope: object{"name": "scope.one"}}}}
	if got := evaluate(experiment{Name: "histogram"}, baseline, changed); got.Status == "pass" {
		t.Fatal("zero-count exponential histograms supplied conversion evidence")
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
	extraMetric := metric("unrelated.count", point("a"))
	if expected, present := matchingMetricStreams(capture{Metrics: []object{baselineMetric}}, capture{Metrics: []object{baselineMetric, extraMetric}}); expected != 2 || present != 3 {
		t.Fatalf("unexpected metric identity was not rejected: %d/%d", present, expected)
	}
	baselineFlaggedPoint := point("a")
	baselineFlaggedPoint["flags"] = float64(0)
	changedFlaggedPoint := point("a")
	changedFlaggedPoint["flags"] = float64(1)
	baselineFlaggedMetric := metric("flagged.metric", baselineFlaggedPoint)
	changedFlaggedMetric := metric("flagged.metric", changedFlaggedPoint)
	if expected, present := matchingMetricStreams(capture{Metrics: []object{baselineFlaggedMetric}}, capture{Metrics: []object{changedFlaggedMetric}}); expected != 1 || present != 0 {
		t.Fatalf("metric no-recorded-value flag was not detected: %d/%d", present, expected)
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
	baselineOne, baselineTwo := fmt.Sprintf("%032x", 101), fmt.Sprintf("%032x", 102)
	changedOne := fmt.Sprintf("%032x", 201)
	baseline := capture{Spans: []object{server(baselineOne, 201), database(baselineOne), server(baselineTwo, 409), database(baselineTwo)}}
	changed := capture{Spans: []object{server(changedOne, 201), database(changedOne), database(changedOne)}}
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

func TestResourceRejectsDuplicateConfiguredKeys(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans(), Resources: []object{{}}}
	changed := capture{Spans: syntheticProbeSpans(), Resources: []object{{"attributes": []any{
		attr("probe.external", "visible"), attr("probe.external", "conflict"), attr("service.name", "external-probe"),
	}}}}
	if got := evaluate(experiment{Name: "resource"}, baseline, changed); got.Status == "pass" {
		t.Fatal("resource experiment accepted duplicate configured keys")
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
	stableAttributeBaseline := capture{Spans: syntheticProbeSpans()}
	stableAttributeChanged := capture{Spans: syntheticProbeSpans()}
	for index := range stableAttributeBaseline.Spans {
		stableAttributeBaseline.Spans[index]["attributes"] = append(stableAttributeBaseline.Spans[index]["attributes"].([]any), attr("network.protocol.version", "1.1"))
		stableAttributeChanged.Spans[index]["attributes"] = []any{attr("http.route", "api/tags"), attr("http.user_agent", "external")}
	}
	if got := evaluate(experiment{Name: "span-length"}, stableAttributeBaseline, stableAttributeChanged); got.Status == "pass" {
		t.Fatal("span-length passed after dropping a short non-whitelisted attribute")
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
	affectedChildBaseline := capture{Spans: syntheticProbeSpans()}
	for _, span := range affectedChildBaseline.Spans {
		span["attributes"] = append(span["attributes"].([]any), attr("second", "value"), attr("third", "value"))
	}
	affectedChildBaseline.Spans = append(affectedChildBaseline.Spans, object{
		"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 1),
		"attributes": []any{attr("first", "value"), attr("second", "value"), attr("third", "value")},
	})
	affectedChildChanged := capture{Spans: syntheticProbeSpans()}
	for _, span := range affectedChildChanged.Spans {
		span["attributes"] = []any{attr("first", "value"), attr("second", "value")}
		span["dropped_attributes_count"] = float64(1)
	}
	affectedChildChanged.Spans = append(affectedChildChanged.Spans, object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 1)})
	if got := evaluate(experiment{Name: "attribute-count"}, affectedChildBaseline, affectedChildChanged); got.Status == "pass" {
		t.Fatal("capped probes masked an affected child span without cap/drop evidence")
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

func TestSamplerControlRequiresFourProbeRequestTraces(t *testing.T) {
	if !validSamplerControl(capture{Spans: syntheticProbeSpans()}) {
		t.Fatal("complete sampler control was rejected")
	}
	incidental := capture{Spans: []object{{
		"name": "startup", "kind": float64(1), "trace_id": fmt.Sprintf("%032x", 10), "span_id": fmt.Sprintf("%016x", 10),
	}}}
	if validSamplerControl(incidental) {
		t.Fatal("incidental span stood in for sampled probe requests")
	}
	duplicated := capture{Spans: syntheticProbeSpans()}
	duplicated.Spans[0]["trace_id"] = field(duplicated.Spans[1], "trace_id")
	if validSamplerControl(duplicated) {
		t.Fatal("duplicate probe trace stood in for an independent request")
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
	spanValues := make([]any, len(syntheticProbeSpans()))
	for index, span := range syntheticProbeSpans() {
		spanValues[index] = span
	}
	data, err := json.Marshal([]any{object{
		"signal":  "traces",
		"payload": object{"resourceSpans": []any{object{"scopeSpans": []any{object{"spans": spanValues}}}}},
	}})
	if err != nil {
		t.Fatal(err)
	}
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
	invalidControl := []byte(`[{"signal":"traces","payload":{"spans":[{"name":"startup","kind":1,"trace_id":"0000000000000000000000000000000a","span_id":"000000000000000a"}]}}]`)
	controlName := samplerArgumentControl.Name
	if err := os.WriteFile(filepath.Join(dir, controlName+".capture.json"), invalidControl, 0600); err != nil {
		t.Fatal(err)
	}
	r.Captures[controlName] = fmt.Sprintf("%x", sha256.Sum256(invalidControl))
	if err := verifyResult(r, dir); err == nil {
		t.Fatal("invalid replayed sampler control accepted")
	}
	if err := os.WriteFile(filepath.Join(dir, controlName+".capture.json"), data, 0600); err != nil {
		t.Fatal(err)
	}
	r.Captures[controlName] = fmt.Sprintf("%x", sha256.Sum256(data))
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
		out = append(out, object{"name": "GET api/tags", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", i), "span_id": fmt.Sprintf("%016x", i), "parent_span_id": "00f067aa0ba902b7", "start_time_unix_nano": fmt.Sprintf("%d", i*100), "end_time_unix_nano": fmt.Sprintf("%d", i*100+1), "attributes": []any{attr("http.route", "api/tags"), attr("http.user_agent", "external-feature-probe-long-user-agent")}})
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
	invalidMetric := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"count": "1", "exemplars": []any{object{"timeUnixNano": "1"}}}}}}
	invalid := capture{Metrics: []object{invalidMetric}, MetricStreams: []metricStream{{Metric: invalidMetric, Scope: object{"name": "control.scope"}}}}
	if got := evaluate(experiment{Name: "exemplars-always-on"}, control, invalid); got.Status == "pass" {
		t.Fatal("timestamp-only exemplar supplied AlwaysOn measurement evidence")
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
	registration := object{"name": "POST /api/users", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", 20), "span_id": fmt.Sprintf("%016x", 20), "start_time_unix_nano": "2000", "end_time_unix_nano": "2001", "attributes": []any{attr("http.route", "/api/users")}}
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
	excluded := object{"name": "active", "sum": object{"dataPoints": []any{object{"attributes": []any{attr("route", "users")}, "exemplars": []any{object{"timeUnixNano": "1", "value": object{"asInt": "1"}}}}}}}
	withExemplar := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}, "exemplars": []any{object{"timeUnixNano": "2", "value": object{"asDouble": float64(1)}}}}}}}
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

	server := object{"name": "POST /api/users", "kind": float64(2), "trace_id": fmt.Sprintf("%032x", 20), "span_id": fmt.Sprintf("%016x", 20), "start_time_unix_nano": "2000", "end_time_unix_nano": "2001", "attributes": []any{attr("http.route", "/api/users")}}
	parent := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "span_id": fmt.Sprintf("%016x", 21), "start_time_unix_nano": "2100", "end_time_unix_nano": "2101", "attributes": []any{attr("db.system", "sqlite")}}
	event := object{"name": "exception", "attributes": []any{attr("first", "one"), attr("second", "two")}}
	parent["events"] = []any{event}
	eventBase := capture{Spans: []object{server, parent}, Metrics: []object{metric}, Logs: []object{logRecord}}
	cappedParent := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "span_id": fmt.Sprintf("%016x", 21), "start_time_unix_nano": "2100", "end_time_unix_nano": "2101", "attributes": []any{attr("db.system", "sqlite")}, "events": []any{object{"name": "exception", "attributes": []any{attr("first", "one")}, "dropped_attributes_count": float64(1)}}}
	eventChanged := capture{Spans: []object{server, cappedParent}, Metrics: []object{metric}, Logs: []object{logRecord}}
	if got := evaluate(experiment{Name: "event-attributes"}, eventBase, eventChanged); got.Status != "pass" {
		t.Fatalf("complete event-attribute capture did not pass: %+v", got)
	}
	duplicatedEventParent := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "span_id": fmt.Sprintf("%016x", 21), "start_time_unix_nano": "2100", "end_time_unix_nano": "2101", "attributes": []any{attr("db.system", "sqlite")}, "events": []any{
		object{"name": "exception", "attributes": []any{attr("first", "one")}, "dropped_attributes_count": float64(1)},
		object{"name": "exception", "attributes": []any{attr("first", "one")}, "dropped_attributes_count": float64(1)},
	}}
	if got := evaluate(experiment{Name: "event-attributes"}, eventBase, capture{Spans: []object{server, duplicatedEventParent}, Metrics: []object{metric}, Logs: []object{logRecord}}); got.Status == "pass" {
		t.Fatal("event-attribute limit accepted a duplicated configured event")
	}
	if got := evaluate(experiment{Name: "event-attributes"}, eventBase, capture{Spans: []object{cappedParent}}); got.Status == "pass" {
		t.Fatal("event-attribute limit passed after dropping unaffected telemetry")
	}
	suppressedParent := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "attributes": []any{attr("db.system", "sqlite")}, "dropped_events_count": float64(1)}
	if got := evaluate(experiment{Name: "events"}, eventBase, capture{Spans: []object{suppressedParent}}); got.Status == "pass" {
		t.Fatal("event suppression passed after dropping eventless workload telemetry")
	}

	histogram := object{"name": "duration", "histogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}, "count": "1"}}}}
	exponential := object{"name": "duration", "exponentialHistogram": object{"dataPoints": []any{object{"attributes": []any{attr("route", "tags")}, "count": "1", "positive": object{"bucketCounts": []any{"1"}}}}}}
	histogramBase := capture{Spans: syntheticProbeSpans(), Metrics: []object{histogram, metric}, Logs: []object{logRecord}}
	histogramChanged := capture{Spans: syntheticProbeSpans(), Metrics: []object{exponential, metric}, Logs: []object{logRecord}}
	if got := evaluate(experiment{Name: "histogram"}, histogramBase, histogramChanged); got.Status != "pass" {
		t.Fatalf("complete histogram conversion did not pass: %+v", got)
	}
	if got := evaluate(experiment{Name: "histogram"}, histogramBase, capture{Metrics: []object{exponential}}); got.Status == "pass" {
		t.Fatal("histogram conversion passed after dropping unaffected telemetry")
	}
	countEight := object{"name": "counted", "histogram": object{"dataPoints": []any{object{"count": "8"}}}}
	countOne := object{"name": "counted", "exponentialHistogram": object{"dataPoints": []any{object{"count": "1", "positive": object{"bucketCounts": []any{"1"}}}}}}
	if got := evaluate(experiment{Name: "histogram"}, capture{Metrics: []object{countEight}}, capture{Metrics: []object{countOne}}); got.Status == "pass" {
		t.Fatal("partial histogram measurements supplied conversion evidence")
	}
}

func TestMetricIdentityIncludesStableStreamAttributes(t *testing.T) {
	metric := object{"name": "shared.metric", "histogram": object{"dataPoints": []any{object{"count": "1"}}}}
	base := metricStream{
		Metric:   metric,
		Scope:    object{"name": "scope", "attributes": []any{attr("scope.key", "one")}},
		Resource: object{"attributes": []any{attr("deployment.environment", "prod"), object{"key": "process.pid", "value": object{"intValue": "1"}}}},
	}
	changedScope := base
	changedScope.Scope = object{"name": "scope", "attributes": []any{attr("scope.key", "two")}}
	if metricID(base) == metricID(changedScope) {
		t.Fatal("scope attributes were omitted from metric identity")
	}
	changedResource := base
	changedResource.Resource = object{"attributes": []any{attr("deployment.environment", "staging"), object{"key": "process.pid", "value": object{"intValue": "1"}}}}
	if metricID(base) == metricID(changedResource) {
		t.Fatal("stable resource attributes were omitted from metric identity")
	}
	volatileResource := base
	volatileResource.Resource = object{"attributes": []any{attr("deployment.environment", "prod"), object{"key": "process.pid", "value": object{"intValue": "2"}}}}
	if metricID(base) != metricID(volatileResource) {
		t.Fatal("volatile process ID split one metric stream across captures")
	}
	sum := func(temporality float64, monotonic bool) metricStream {
		return metricStream{Metric: object{"name": "requests", "sum": object{"aggregationTemporality": temporality, "isMonotonic": monotonic, "dataPoints": []any{object{"attributes": []any{attr("route", "tags")}}}}}}
	}
	point := object{"attributes": []any{attr("route", "tags")}}
	if controlMetricPointID(sum(1, true), point, nil) == controlMetricPointID(sum(2, true), point, nil) {
		t.Fatal("metric identity omitted aggregation temporality")
	}
	if controlMetricPointID(sum(1, true), point, nil) == controlMetricPointID(sum(1, false), point, nil) {
		t.Fatal("metric identity omitted monotonicity")
	}
}

func TestLogIdentityPreservesCorrelationExceptForSamplers(t *testing.T) {
	traceID, spanID := fmt.Sprintf("%032x", 1), fmt.Sprintf("%016x", 2)
	span := object{"trace_id": traceID, "span_id": spanID, "name": "GET api/tags", "kind": float64(2), "attributes": []any{attr("http.route", "api/tags")}}
	correlated := object{"body": object{"stringValue": "workload log"}, "trace_id": traceID, "span_id": spanID, "flags": float64(1)}
	uncorrelated := object{"body": object{"stringValue": "workload log"}}
	baseline := capture{Spans: []object{span}, Logs: []object{correlated}}
	changed := capture{Spans: []object{span}, Logs: []object{uncorrelated}}
	if expected, present := matchingLogStreams(baseline, changed, nil); expected != 1 || present != 0 {
		t.Fatalf("lost log correlation was preserved: %d/%d", present, expected)
	}
	if expected, present := matchingLogStreamsIgnoringCorrelation(baseline, changed); expected != 1 || present != 1 {
		t.Fatalf("sampler correlation exclusion did not preserve the log: %d/%d", present, expected)
	}
	if expected, present := matchingLogStreamsForSampler(baseline, changed); expected != 1 || present != 0 {
		t.Fatalf("sampler accepted lost correlation validity: %d/%d", present, expected)
	}
	validChanged := object{
		"body":     object{"stringValue": "workload log"},
		"trace_id": fmt.Sprintf("%032x", 10), "span_id": fmt.Sprintf("%016x", 10), "flags": float64(0),
	}
	if expected, present := matchingLogStreamsForSampler(baseline, capture{Logs: []object{validChanged}}); expected != 1 || present != 1 {
		t.Fatalf("sampler did not normalize changed valid correlation: %d/%d", present, expected)
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
	invalidPort := metricStream{Metric: metric("127.0.0.1:99999")}
	if metricPointID(baseline, objects(baseline.Metric, "data_points")[0], nil) == metricPointID(invalidPort, objects(invalidPort.Metric, "data_points")[0], nil) {
		t.Fatal("out-of-range endpoint port was normalized as valid")
	}
	if got := normalizeURLPort("http://127.0.0.1:99999/api/tags"); got != "http://127.0.0.1:99999/api/tags" {
		t.Fatalf("out-of-range URL port was normalized: %q", got)
	}
}

func TestWorkloadIdentityPreservesCountersEventsLinksAndTraceState(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	baseline.Spans[0]["events"] = []any{object{"name": "exception", "droppedAttributesCount": float64(1)}}
	baseline.Spans[0]["links"] = []any{object{
		"traceId": fmt.Sprintf("%032x", 50), "spanId": fmt.Sprintf("%016x", 50),
		"traceState": "vendor=value", "flags": float64(1), "droppedAttributesCount": float64(2),
		"attributes": []any{attr("link.kind", "retry")},
	}}
	baseline.Spans[0]["traceState"] = "vendor=value"
	baseline.Spans[0]["droppedAttributesCount"] = float64(1)
	baseline.Spans[0]["droppedEventsCount"] = float64(2)
	baseline.Spans[0]["droppedLinksCount"] = float64(3)

	for name, mutate := range map[string]func(object){
		"span dropped attributes": func(span object) { span["droppedAttributesCount"] = float64(0) },
		"span dropped events":     func(span object) { span["droppedEventsCount"] = float64(0) },
		"span dropped links":      func(span object) { span["droppedLinksCount"] = float64(0) },
		"event dropped attributes": func(span object) {
			objects(span, "events")[0]["droppedAttributesCount"] = float64(0)
		},
		"links":       func(span object) { span["links"] = []any{} },
		"trace state": func(span object) { span["traceState"] = "vendor=changed" },
	} {
		t.Run(name, func(t *testing.T) {
			changed := capture{Spans: syntheticProbeSpans()}
			changed.Spans[0] = cloneObject(baseline.Spans[0])
			mutate(changed.Spans[0])
			if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
				t.Fatalf("corruption was not detected: %d/%d", present, expected)
			}
		})
	}
}

func TestCountLimitPreservesUnaffectedAndRetainedSpanAttributes(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	changed.Spans[0]["attributes"] = changed.Spans[0]["attributes"].([]any)[:1]
	if expected, present := matchingCountLimitedWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("attributes on an unaffected span were not preserved: %d/%d", present, expected)
	}

	baseline = capture{Spans: syntheticProbeSpans()}
	changed = capture{Spans: syntheticProbeSpans()}
	for i := range baseline.Spans {
		baseline.Spans[i]["attributes"] = append(baseline.Spans[i]["attributes"].([]any), attr("second", "value"), attr("third", "value"))
		changed.Spans[i]["attributes"] = append([]any(nil), changed.Spans[i]["attributes"].([]any)[:2]...)
		changed.Spans[i]["droppedAttributesCount"] = float64(2)
	}
	changed.Spans[0]["attributes"] = []any{attr("fabricated", "one"), attr("fabricated", "two")}
	if expected, present := limitedGlobalCountSpanRecords(baseline, changed, 2); expected != 4 || present != 3 {
		t.Fatalf("fabricated retained attributes were accepted: %d/%d", present, expected)
	}
}

func TestSpanPortNormalizationRejectsMalformedValues(t *testing.T) {
	span := func(port any) object {
		return object{"name": "GET /", "kind": float64(2), "attributes": []any{object{"key": "server.port", "value": port}}}
	}
	first := span(object{"intValue": "12345"})
	second := span(object{"intValue": "54321"})
	if workloadSpanID(first) != workloadSpanID(second) {
		t.Fatal("valid randomized span ports were not normalized")
	}
	malformed := span(object{"stringValue": "54321"})
	if workloadSpanID(first) == workloadSpanID(malformed) {
		t.Fatal("malformed span port was normalized as valid")
	}
}

func TestLogIdentityPreservesStructuredBodiesAndDroppedCounts(t *testing.T) {
	structured := object{"body": object{"arrayValue": object{"values": []any{object{"intValue": "1"}, object{"boolValue": true}}}}}
	ordinary := object{"body": object{"stringValue": "ordinary"}}
	if expected, present := matchingLogStreams(capture{Logs: []object{structured, ordinary}}, capture{Logs: []object{ordinary}}, nil); expected != 2 || present != 1 {
		t.Fatalf("structured log loss was not detected: %d/%d", present, expected)
	}
	changed := cloneObject(ordinary)
	changed["droppedAttributesCount"] = float64(1)
	if expected, present := matchingLogStreams(capture{Logs: []object{ordinary}}, capture{Logs: []object{changed}}, nil); expected != 1 || present != 0 {
		t.Fatalf("log dropped-attribute corruption was not detected: %d/%d", present, expected)
	}
}

func TestMetricIdentityPreservesMeasurementsExemplarsAndPorts(t *testing.T) {
	metric := func(port any, includeSum, includeExemplar bool) object {
		point := object{
			"attributes":   []any{object{"key": "server.port", "value": port}},
			"count":        "2",
			"bucketCounts": []any{"2"},
		}
		if includeSum {
			point["sum"] = float64(1.5)
		}
		if includeExemplar {
			point["exemplars"] = []any{object{
				"timeUnixNano": "10", "asInt": "1",
				"traceId": fmt.Sprintf("%032x", 60), "spanId": fmt.Sprintf("%016x", 60),
				"filteredAttributes": []any{attr("sample.kind", "request")},
			}}
		}
		return object{"name": "request.duration", "histogram": object{"dataPoints": []any{point}}}
	}
	baselineMetric := metric(object{"intValue": "12345"}, true, true)
	baseline := capture{Metrics: []object{baselineMetric}}
	portChanged := metric(object{"intValue": "54321"}, true, true)
	if expected, present := matchingMetricStreams(baseline, capture{Metrics: []object{portChanged}}); expected != 1 || present != 1 {
		t.Fatalf("valid randomized metric port split a point: %d/%d", present, expected)
	}
	for name, candidate := range map[string]object{
		"measurement": metric(object{"intValue": "54321"}, false, true),
		"exemplar":    metric(object{"intValue": "54321"}, true, false),
		"port type":   metric(object{"stringValue": "54321"}, true, true),
	} {
		t.Run(name, func(t *testing.T) {
			if expected, present := matchingMetricStreams(baseline, capture{Metrics: []object{candidate}}); expected != 1 || present != 0 {
				t.Fatalf("metric corruption was not detected: %d/%d", present, expected)
			}
		})
	}
	withoutExemplar := metric(object{"intValue": "54321"}, true, false)
	if expected, present := matchingMetricStreamsIgnoringExemplars(baseline, capture{Metrics: []object{withoutExemplar}}); expected != 1 || present != 1 {
		t.Fatalf("exemplar-specific matching did not ignore the intended change: %d/%d", present, expected)
	}
	nestedGauge := object{"name": "queue.depth", "gauge": object{"dataPoints": []any{object{"value": object{"asInt": "3"}}}}}
	emptyGauge := object{"name": "queue.depth", "gauge": object{"dataPoints": []any{object{}}}}
	if expected, present := matchingMetricStreams(capture{Metrics: []object{nestedGauge}}, capture{Metrics: []object{emptyGauge}}); expected != 1 || present != 0 {
		t.Fatalf("nested numeric measurement loss was not detected: %d/%d", present, expected)
	}
}

func cloneObject(value object) object {
	data, _ := json.Marshal(value)
	var cloned object
	_ = json.Unmarshal(data, &cloned)
	return cloned
}

func TestStreamContextsPreserveResourceAndScopeDropCounters(t *testing.T) {
	span := syntheticProbeSpans()[0]
	baseSpan := spanStream{Span: span, Scope: object{"droppedAttributesCount": float64(0)}, Resource: object{"droppedAttributesCount": float64(0)}}
	changedSpan := baseSpan
	changedSpan.Scope = object{"droppedAttributesCount": float64(1)}
	if spanContextID(baseSpan, nil) == spanContextID(changedSpan, nil) {
		t.Fatal("span scope dropped-attribute count was omitted")
	}
	metric := object{"name": "queue.depth", "gauge": object{"dataPoints": []any{object{"value": object{"asInt": "1"}}}}}
	baseMetric := metricStream{Metric: metric, Resource: object{"droppedAttributesCount": float64(0)}}
	changedMetric := baseMetric
	changedMetric.Resource = object{"droppedAttributesCount": float64(1)}
	if metricID(baseMetric) == metricID(changedMetric) {
		t.Fatal("metric resource dropped-attribute count was omitted")
	}
	baseLog := logStream{Record: object{"body": object{"stringValue": "workload"}}, Scope: object{"droppedAttributesCount": float64(0)}}
	changedLog := baseLog
	changedLog.Scope = object{"droppedAttributesCount": float64(1)}
	if logStreamID(baseLog, nil) == logStreamID(changedLog, nil) {
		t.Fatal("log scope dropped-attribute count was omitted")
	}
	baseSpan.Resource = object{"entityRefs": []any{object{"schemaUrl": "https://example.test/entity", "type": float64(1), "idKeys": []any{float64(2)}}}}
	changedSpan = baseSpan
	changedSpan.Resource = object{}
	if spanContextID(baseSpan, nil) == spanContextID(changedSpan, nil) {
		t.Fatal("resource entity references were omitted")
	}
}

func TestSignalIdentitiesValidateTimestamps(t *testing.T) {
	baselineSpans := capture{Spans: syntheticProbeSpans()}
	changedSpans := capture{Spans: syntheticProbeSpans()}
	baselineSpans.Spans[0]["events"] = []any{object{"name": "exception", "timeUnixNano": "100"}}
	changedSpans.Spans[0]["events"] = []any{object{"name": "exception", "timeUnixNano": "0"}}
	if expected, present := matchingWorkloadSpans(baselineSpans, changedSpans); expected != 4 || present != 3 {
		t.Fatalf("invalid event timestamp was accepted: %d/%d", present, expected)
	}

	baselineLog := object{"body": object{"stringValue": "workload"}, "timeUnixNano": "10", "observedTimeUnixNano": "11"}
	changedLog := object{"body": object{"stringValue": "workload"}, "timeUnixNano": "10", "observedTimeUnixNano": "9"}
	if expected, present := matchingLogStreams(capture{Logs: []object{baselineLog}}, capture{Logs: []object{changedLog}}, nil); expected != 1 || present != 0 {
		t.Fatalf("invalid log timestamp ordering was accepted: %d/%d", present, expected)
	}

	metric := func(start, end string) object {
		return object{"name": "queue.depth", "gauge": object{"dataPoints": []any{object{"value": object{"asInt": "1"}, "startTimeUnixNano": start, "timeUnixNano": end}}}}
	}
	if expected, present := matchingMetricStreams(capture{Metrics: []object{metric("5", "10")}}, capture{Metrics: []object{metric("11", "10")}}); expected != 1 || present != 0 {
		t.Fatalf("invalid metric time window was accepted: %d/%d", present, expected)
	}
}

func TestSignalIdentitiesCompareNanosecondTimestampsExactly(t *testing.T) {
	const earlier = "1700000000000000000"
	const later = "1700000000000000001"
	decoded, err := decodeCapture([]byte(`[{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"name":"workload","startTimeUnixNano":1700000000000000000,"endTimeUnixNano":1700000000000000001}]}]}]}}]`))
	if err != nil {
		t.Fatal(err)
	}
	start, valid := otlpTimestamp(field(decoded.Spans[0], "start_time_unix_nano"))
	if !valid || start.String() != earlier {
		t.Fatalf("numeric JSON timestamp lost precision: %v, %t", start, valid)
	}

	baselineSpans := capture{Spans: syntheticProbeSpans()}
	changedSpans := capture{Spans: syntheticProbeSpans()}
	baselineSpans.Spans[0]["start_time_unix_nano"] = earlier
	baselineSpans.Spans[0]["end_time_unix_nano"] = later
	changedSpans.Spans[0]["start_time_unix_nano"] = later
	changedSpans.Spans[0]["end_time_unix_nano"] = earlier
	if expected, present := matchingWorkloadSpans(baselineSpans, changedSpans); expected != 4 || present != 5 {
		t.Fatalf("one-nanosecond span inversion was accepted: %d/%d", present, expected)
	}

	eventBaseline := capture{Spans: syntheticProbeSpans()}
	eventChanged := capture{Spans: syntheticProbeSpans()}
	for _, candidate := range []capture{eventBaseline, eventChanged} {
		candidate.Spans[0]["start_time_unix_nano"] = earlier
		candidate.Spans[0]["end_time_unix_nano"] = earlier
	}
	eventBaseline.Spans[0]["events"] = []any{object{"name": "exception", "timeUnixNano": earlier}}
	eventChanged.Spans[0]["events"] = []any{object{"name": "exception", "timeUnixNano": later}}
	if expected, present := matchingWorkloadSpans(eventBaseline, eventChanged); expected != 4 || present != 3 {
		t.Fatalf("one-nanosecond event overflow was accepted: %d/%d", present, expected)
	}

	baselineLog := object{"body": object{"stringValue": "workload"}, "timeUnixNano": later, "observedTimeUnixNano": later}
	changedLog := object{"body": object{"stringValue": "workload"}, "timeUnixNano": later, "observedTimeUnixNano": earlier}
	if expected, present := matchingLogStreams(capture{Logs: []object{baselineLog}}, capture{Logs: []object{changedLog}}, nil); expected != 1 || present != 0 {
		t.Fatalf("one-nanosecond log inversion was accepted: %d/%d", present, expected)
	}

	metric := func(start, end string) object {
		return object{"name": "queue.depth", "gauge": object{"dataPoints": []any{object{"value": object{"asInt": "1"}, "startTimeUnixNano": start, "timeUnixNano": end}}}}
	}
	if expected, present := matchingMetricStreams(capture{Metrics: []object{metric(earlier, later)}}, capture{Metrics: []object{metric(later, earlier)}}); expected != 1 || present != 0 {
		t.Fatalf("one-nanosecond metric inversion was accepted: %d/%d", present, expected)
	}
}

func TestMetricIdentityPreservesMetadata(t *testing.T) {
	metric := object{
		"name": "queue.depth", "metadata": []any{attr("prometheus.type", "gauge"), attr("prometheus.help", "Queue depth")},
		"gauge": object{"dataPoints": []any{object{"value": object{"asInt": "1"}}}},
	}
	changed := cloneObject(metric)
	delete(changed, "metadata")
	if expected, present := matchingMetricStreams(capture{Metrics: []object{metric}}, capture{Metrics: []object{changed}}); expected != 1 || present != 0 {
		t.Fatalf("metric metadata loss was accepted: %d/%d", present, expected)
	}
	reordered := cloneObject(metric)
	metadata := reordered["metadata"].([]any)
	metadata[0], metadata[1] = metadata[1], metadata[0]
	if expected, present := matchingMetricStreams(capture{Metrics: []object{metric}}, capture{Metrics: []object{reordered}}); expected != 1 || present != 1 {
		t.Fatalf("metric metadata order was treated as semantic: %d/%d", present, expected)
	}
}

func TestOrdinaryWorkloadIdentityPreservesInjectedRemoteParent(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	changed.Spans[0]["parent_span_id"] = "1111111111111111"
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("wrong injected remote parent was accepted: %d/%d", present, expected)
	}
}

func TestPropagationOnlyNormalizesProbeTraceLogCorrelation(t *testing.T) {
	baselineProbe := syntheticProbeSpans()[0]
	changedProbe := cloneObject(baselineProbe)
	changedProbe["trace_id"] = fmt.Sprintf("%032x", 10)
	changedProbe["span_id"] = fmt.Sprintf("%016x", 10)
	changedProbe["parent_span_id"] = ""
	registration := object{"name": "INSERT", "kind": float64(3), "trace_id": fmt.Sprintf("%032x", 20), "span_id": fmt.Sprintf("%016x", 20), "start_time_unix_nano": "20", "end_time_unix_nano": "21"}
	probeLog := func(span object) object {
		return object{"body": object{"stringValue": "probe"}, "trace_id": field(span, "trace_id"), "span_id": field(span, "span_id")}
	}
	registrationLog := object{"body": object{"stringValue": "registration"}, "trace_id": field(registration, "trace_id"), "span_id": field(registration, "span_id")}
	baseline := capture{Spans: []object{baselineProbe, registration}, Logs: []object{probeLog(baselineProbe), registrationLog}}
	changed := capture{Spans: []object{changedProbe, registration}, Logs: []object{probeLog(changedProbe), object{"body": object{"stringValue": "registration"}}}}
	if expected, present := matchingLogStreamsForPropagation(baseline, changed); expected != 2 || present != 1 {
		t.Fatalf("unaffected registration correlation loss was accepted: %d/%d", present, expected)
	}
}

func TestCountLimitRequiresAccurateDroppedAttributeCounts(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	for i := range baseline.Spans {
		baseline.Spans[i]["attributes"] = append(baseline.Spans[i]["attributes"].([]any), attr("second", "value"), attr("third", "value"))
		changed.Spans[i]["attributes"] = append([]any(nil), changed.Spans[i]["attributes"].([]any)[:2]...)
		changed.Spans[i]["droppedAttributesCount"] = float64(2)
	}
	changed.Spans[0]["droppedAttributesCount"] = float64(99)
	if expected, present := limitedGlobalCountSpanRecords(baseline, changed, 2); expected != 4 || present != 3 {
		t.Fatalf("inaccurate dropped count was accepted: %d/%d", present, expected)
	}
}

func TestPropagationPreservesRegistrationSpanContext(t *testing.T) {
	registration := object{
		"name": "POST /api/users", "kind": float64(2),
		"trace_id": fmt.Sprintf("%032x", 20), "span_id": fmt.Sprintf("%016x", 20),
		"parent_span_id": "00f067aa0ba902b7", "flags": float64(1), "trace_state": "vendor=baseline",
		"attributes": []any{attr("http.route", "/api/users")},
	}
	changedRegistration := cloneObject(registration)
	changedRegistration["flags"] = float64(0)
	changedRegistration["trace_state"] = "vendor=changed"
	baseline := capture{Spans: []object{registration}}
	changed := capture{Spans: []object{changedRegistration}}
	if expected, present := matchingWorkloadSpansIgnoringParents(baseline, changed); expected != 1 || present != 0 {
		t.Fatalf("propagation normalization hid registration context changes: %d/%d", present, expected)
	}
}

func TestPropagationPreservesUntaggedReadinessSpanContext(t *testing.T) {
	readiness := object{
		"name": "GET /api/tags", "kind": float64(2),
		"trace_id": fmt.Sprintf("%032x", 30), "span_id": fmt.Sprintf("%016x", 30),
		"parent_span_id": "", "flags": float64(1), "trace_state": "vendor=baseline",
		"attributes": []any{attr("http.route", "/api/tags"), attr("http.user_agent", "readiness-probe")},
	}
	changedReadiness := cloneObject(readiness)
	changedReadiness["flags"] = float64(0)
	changedReadiness["trace_state"] = "vendor=changed"
	baseline := capture{Spans: []object{readiness}}
	changed := capture{Spans: []object{changedReadiness}}
	if expected, present := matchingWorkloadSpansIgnoringParents(baseline, changed); expected != 1 || present != 0 {
		t.Fatalf("propagation normalization hid readiness context changes: %d/%d", present, expected)
	}
}

func TestExplicitHistogramIdentityPreservesBucketLayout(t *testing.T) {
	point := object{"count": "2", "explicitBounds": []any{float64(1)}, "bucketCounts": []any{"1", "1"}}
	metric := object{"name": "request.duration", "histogram": object{"dataPoints": []any{point}}}
	for name, changedPoint := range map[string]object{
		"bounds":  {"count": "2", "explicitBounds": []any{float64(2)}, "bucketCounts": []any{"1", "1"}},
		"buckets": {"count": "2", "explicitBounds": []any{float64(1)}, "bucketCounts": []any{"2", "0"}},
	} {
		t.Run(name, func(t *testing.T) {
			changed := object{"name": "request.duration", "histogram": object{"dataPoints": []any{changedPoint}}}
			if expected, present := matchingMetricStreams(capture{Metrics: []object{metric}}, capture{Metrics: []object{changed}}); expected != 1 || present != 0 {
				t.Fatalf("histogram layout change was accepted: %d/%d", present, expected)
			}
		})
	}
}

func TestMetricIdentityPreservesExemplarMultiplicity(t *testing.T) {
	exemplar := object{"timeUnixNano": "1", "value": object{"asInt": "1"}}
	point := object{"count": "1", "exemplars": []any{exemplar}}
	metric := object{"name": "queue.latency", "histogram": object{"dataPoints": []any{point}}}
	changedPoint := cloneObject(point)
	changedPoint["exemplars"] = append(changedPoint["exemplars"].([]any), cloneObject(exemplar))
	changed := object{"name": "queue.latency", "histogram": object{"dataPoints": []any{changedPoint}}}
	if expected, present := matchingMetricStreams(capture{Metrics: []object{metric}}, capture{Metrics: []object{changed}}); expected != 1 || present != 0 {
		t.Fatalf("duplicate exemplar was accepted: %d/%d", present, expected)
	}
}

func TestSpanIdentityPreservesEventOrder(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	first := object{"name": "first", "timeUnixNano": "100"}
	second := object{"name": "second", "timeUnixNano": "100"}
	baseline.Spans[0]["events"] = []any{first, second}
	changed.Spans[0]["events"] = []any{cloneObject(second), cloneObject(first)}
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 4 || present != 3 {
		t.Fatalf("event reordering was accepted: %d/%d", present, expected)
	}
}

func TestSpanIdentityPreservesParentIntervalRelationship(t *testing.T) {
	baseline := capture{Spans: syntheticProbeSpans()}
	changed := capture{Spans: syntheticProbeSpans()}
	for _, candidate := range []capture{baseline, changed} {
		candidate.Spans[0]["start_time_unix_nano"] = "100"
		candidate.Spans[0]["end_time_unix_nano"] = "200"
	}
	child := object{
		"name": "SELECT", "kind": float64(3), "trace_id": field(baseline.Spans[0], "trace_id"),
		"span_id": fmt.Sprintf("%016x", 50), "parent_span_id": field(baseline.Spans[0], "span_id"),
		"start_time_unix_nano": "120", "end_time_unix_nano": "130",
	}
	changedChild := cloneObject(child)
	changedChild["start_time_unix_nano"], changedChild["end_time_unix_nano"] = "201", "202"
	baseline.Spans = append(baseline.Spans, child)
	changed.Spans = append(changed.Spans, changedChild)
	if expected, present := matchingWorkloadSpans(baseline, changed); expected != 5 || present != 4 {
		t.Fatalf("child interval corruption was accepted: %d/%d", present, expected)
	}
}

func TestExponentialHistogramRequiresValidMappingParameters(t *testing.T) {
	valid := object{"count": "1", "scale": float64(0), "zeroThreshold": float64(0), "zeroCount": "0", "min": float64(1), "max": float64(1), "positive": object{"bucketCounts": []any{"1"}}}
	if !validExponentialHistogramPoint(valid) {
		t.Fatal("valid exponential histogram rejected")
	}
	for name, mutate := range map[string]func(object){
		"scale":           func(point object) { point["scale"] = float64(21) },
		"threshold":       func(point object) { point["zeroThreshold"] = float64(-1) },
		"extrema":         func(point object) { point["min"], point["max"] = float64(2), float64(1) },
		"fractionalCount": func(point object) { point["count"] = float64(1.5) },
	} {
		t.Run(name, func(t *testing.T) {
			candidate := cloneObject(valid)
			mutate(candidate)
			if validExponentialHistogramPoint(candidate) {
				t.Fatal("malformed exponential histogram accepted")
			}
		})
	}
}

func TestHistogramNotExercisedStillRequiresTelemetryPreservation(t *testing.T) {
	metric := object{"name": "queue.depth", "gauge": object{"dataPoints": []any{object{"value": object{"asInt": "1"}}}}}
	baseline := capture{Spans: syntheticProbeSpans(), Metrics: []object{metric}, Logs: []object{{"body": object{"stringValue": "workload"}}}}
	if got := evaluate(experiment{Name: "histogram"}, baseline, capture{}); got.Status != "gap" {
		t.Fatalf("telemetry loss was masked as not exercised: %+v", got)
	}
}

func TestAlwaysOnRejectsMalformedExemplarContext(t *testing.T) {
	valid := func() object {
		return object{"exemplars": []any{object{
			"timeUnixNano": "1", "value": object{"asInt": "1"},
			"traceId": fmt.Sprintf("%032x", 1), "spanId": fmt.Sprintf("%016x", 1),
		}}}
	}
	if count, ok := validExemplarCount(valid()); !ok || count != 1 {
		t.Fatal("valid exemplar context rejected")
	}
	for name, mutate := range map[string]func(object){
		"missing span": func(exemplar object) { delete(exemplar, "spanId") },
		"zero trace":   func(exemplar object) { exemplar["traceId"] = strings.Repeat("0", 32) },
		"short span":   func(exemplar object) { exemplar["spanId"] = "01" },
	} {
		t.Run(name, func(t *testing.T) {
			candidate := valid()
			exemplar := candidate["exemplars"].([]any)[0].(object)
			mutate(exemplar)
			if _, ok := validExemplarCount(candidate); ok {
				t.Fatal("malformed exemplar context accepted")
			}
		})
	}
}

func TestControlMetricsRejectSiblingMetricDuplicates(t *testing.T) {
	decode := func(data string) capture {
		decoded, err := decodeCapture([]byte(data))
		if err != nil {
			t.Fatal(err)
		}
		return decoded
	}
	metric := `{"name":"queue.depth","gauge":{"dataPoints":[{"value":{"asInt":"1"}}]}}`
	baseline := decode(`[{"signal":"metrics","payload":{"resourceMetrics":[{"scopeMetrics":[{"metrics":[` + metric + `]}]}]}}]`)
	duplicated := decode(`[{"signal":"metrics","payload":{"resourceMetrics":[{"scopeMetrics":[{"metrics":[` + metric + `,` + metric + `]}]}]}}]`)
	if expected, present := matchingMetricStreams(baseline, duplicated); expected != 1 || present != 2 {
		t.Fatalf("duplicate metric objects in one scope were accepted: %d/%d", present, expected)
	}
	repeatedExport := decode(`[
		{"signal":"metrics","payload":{"resourceMetrics":[{"scopeMetrics":[{"metrics":[` + metric + `]}]}]}},
		{"signal":"metrics","payload":{"resourceMetrics":[{"scopeMetrics":[{"metrics":[` + metric + `]}]}]}}
	]`)
	if expected, present := matchingMetricStreams(baseline, repeatedExport); expected != 1 || present != 1 {
		t.Fatalf("ordinary repeated exports were treated as duplicates: %d/%d", present, expected)
	}
}

func TestEventSuppressionRequiresAccurateDroppedCount(t *testing.T) {
	baselineParent := object{
		"name": "INSERT", "kind": float64(3), "attributes": []any{attr("db.system", "sqlite")},
		"events": []any{object{"name": "exception"}}, "dropped_events_count": float64(2),
	}
	changedParent := cloneObject(baselineParent)
	delete(changedParent, "events")
	changedParent["dropped_events_count"] = float64(3)
	if expected, present := suppressedEventRecords(capture{Spans: []object{baselineParent}}, capture{Spans: []object{changedParent}}); expected != 1 || present != 1 {
		t.Fatalf("accurate dropped-event count was rejected: %d/%d", present, expected)
	}
	changedParent["dropped_events_count"] = float64(99)
	if expected, present := suppressedEventRecords(capture{Spans: []object{baselineParent}}, capture{Spans: []object{changedParent}}); expected != 1 || present != 0 {
		t.Fatalf("inaccurate dropped-event count was accepted: %d/%d", present, expected)
	}
}

func TestVolatileResourceAttributesPreservePresenceAndType(t *testing.T) {
	resource := func(pid any, args any, instance any) object {
		return object{"attributes": []any{
			object{"key": "process.pid", "value": pid},
			object{"key": "process.command_args", "value": args},
			object{"key": "service.instance.id", "value": instance},
		}}
	}
	validArgs := func(values ...any) object { return object{"arrayValue": object{"values": values}} }
	baseline := spanStream{Span: syntheticProbeSpans()[0], Resource: resource(
		object{"intValue": "123"}, validArgs(object{"stringValue": "server"}, object{"stringValue": "--port=123"}), object{"stringValue": "instance-one"},
	)}
	changed := baseline
	changed.Resource = resource(
		object{"value": object{"int_value": "456"}}, validArgs(object{"stringValue": "worker"}), object{"value": object{"string_value": "instance-two"}},
	)
	if spanContextID(baseline, nil) != spanContextID(changed, nil) {
		t.Fatal("valid volatile resource values were not normalized")
	}

	malformed := map[string]object{
		"pid":       resource(object{"stringValue": "123"}, validArgs(object{"stringValue": "server"}), object{"stringValue": "instance"}),
		"arguments": resource(object{"intValue": "123"}, validArgs(object{"intValue": "1"}), object{"stringValue": "instance"}),
		"instance":  resource(object{"intValue": "123"}, validArgs(object{"stringValue": "server"}), object{"stringValue": ""}),
		"missing":   object{"attributes": []any{object{"key": "process.pid", "value": object{"intValue": "123"}}}},
	}
	for name, candidate := range malformed {
		t.Run(name, func(t *testing.T) {
			changed := baseline
			changed.Resource = candidate
			if spanContextID(baseline, nil) == spanContextID(changed, nil) {
				t.Fatal("missing or malformed volatile resource attribute was ignored")
			}
		})
	}
}
