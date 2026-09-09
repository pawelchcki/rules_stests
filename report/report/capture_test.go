package report

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func captureFixtureWithEncoding(encoding string, spans ...map[string]any) []byte {
	values := make([]any, len(spans))
	for i, s := range spans {
		values[i] = s
	}
	b, _ := json.Marshal([]any{map[string]any{"signal": "traces", "encoding": encoding, "payload": map[string]any{"resourceSpans": []any{map[string]any{"resource": map[string]any{"attributes": []any{map[string]any{"key": "service.name", "value": map[string]any{"stringValue": "realworld"}}}}, "scopeSpans": []any{map[string]any{"scope": map[string]any{"name": "fixture", "version": "1"}, "spans": values}}}}}}})
	return b
}
func captureFixture(spans ...map[string]any) []byte {
	return captureFixtureWithEncoding("json", spans...)
}
func captureSpan(trace, span, parent int, name string) map[string]any {
	p := ""
	if parent != 0 {
		p = fmt.Sprintf("%016x", parent)
	}
	return map[string]any{"traceId": fmt.Sprintf("%032x", trace), "spanId": fmt.Sprintf("%016x", span), "parentSpanId": p, "name": name, "kind": 2, "startTimeUnixNano": "18446744073709551000", "endTimeUnixNano": "18446744073709551615"}
}
func decodedFixtureWithEncoding(t *testing.T, profile, encoding string, spans ...map[string]any) CaptureDataset {
	t.Helper()
	d := DecodeCapture(ValidationReceipt{Profile: profile, Scenario: "case", Outcome: "verified", Revision: strings.Repeat("a", 40)}, captureFixtureWithEncoding(encoding, spans...))
	if len(d.Diagnostics) > 0 {
		t.Fatal(d.Diagnostics)
	}
	return d
}
func decodedFixture(t *testing.T, profile string, spans ...map[string]any) CaptureDataset {
	return decodedFixtureWithEncoding(t, profile, "json", spans...)
}
func TestCaptureWireFormatsAndPrecision(t *testing.T) {
	otlp := `[{"signal":"traces","encoding":"json","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"GET /tags","kind":2,"status":{"code":1},"attributes":[{"key":"large","value":{"intValue":"09223372036854775807"}},{"key":"bytes","value":{"bytesValue":"AQI="}},{"key":"array","value":{"arrayValue":{"values":[{"boolValue":true},{"stringValue":"9223372036854775807"}]}}}],"startTimeUnixNano":"1","endTimeUnixNano":"2"}]}]}]}}]`
	proto := `[{"signal":"traces","encoding":"protobuf","payload":{"resource_spans":[{"resource":null,"schema_url":"","scope_spans":[{"scope":null,"schema_url":"","spans":[{"trace_id":"00000000000000000000000000000001","span_id":"0000000000000001","parent_span_id":"","name":"GET /tags","kind":2,"status":{"code":1,"message":""},"attributes":[{"key":"array","value":{"value":{"array_value":{"values":[{"value":{"bool_value":true}},{"value":{"string_value":"9223372036854775807"}}]}}}},{"key":"bytes","value":{"value":{"bytes_value":[1,2]}}},{"key":"large","value":{"value":{"int_value":9223372036854775807}}}],"events":[],"links":[],"flags":0,"dropped_attributes_count":0,"dropped_events_count":0,"dropped_links_count":0,"start_time_unix_nano":1,"end_time_unix_nano":2,"trace_state":""}]}]}]}}]`
	a, b := DecodeCapture(ValidationReceipt{}, []byte(otlp)), DecodeCapture(ValidationReceipt{}, []byte(proto))
	if len(a.Diagnostics) > 0 || len(b.Diagnostics) > 0 {
		t.Fatalf("diagnostics %v %v", a.Diagnostics, b.Diagnostics)
	}
	if !reflect.DeepEqual(a, b) {
		t.Fatalf("wire formats differ:\n%s\n%s", canonical(a), canonical(b))
	}
	if !strings.Contains(canonical(a), `"intValue":"9223372036854775807"`) {
		t.Fatal("lost integer precision/type")
	}
}
func TestCaptureNormalizesNullAnyValueVariants(t *testing.T) {
	direct := `[{"signal":"traces","encoding":"json","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"span","startTimeUnixNano":"1","endTimeUnixNano":"2","attributes":[{"key":"unset","value":{"stringValue":null}}]}]}]}]}}]`
	wrapped := `[{"signal":"traces","encoding":"protobuf","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"span","startTimeUnixNano":"1","endTimeUnixNano":"2","attributes":[{"key":"unset","value":{"value":null}}]}]}]}]}}]`
	nullMessage := `[{"signal":"traces","encoding":"json","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"span","startTimeUnixNano":"1","endTimeUnixNano":"2","attributes":[{"key":"unset","value":null}]}]}]}]}}]`
	omitted := `[{"signal":"traces","encoding":"json","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"span","startTimeUnixNano":"1","endTimeUnixNano":"2","attributes":[{"key":"unset"}]}]}]}]}}]`
	a, b := DecodeCapture(ValidationReceipt{}, []byte(direct)), DecodeCapture(ValidationReceipt{}, []byte(wrapped))
	c, d := DecodeCapture(ValidationReceipt{}, []byte(nullMessage)), DecodeCapture(ValidationReceipt{}, []byte(omitted))
	if len(a.Diagnostics) > 0 || len(b.Diagnostics) > 0 || len(c.Diagnostics) > 0 || len(d.Diagnostics) > 0 || !reflect.DeepEqual(a, b) || !reflect.DeepEqual(c, d) {
		t.Fatalf("null AnyValue variants differ:\n%s\n%s\n%s\n%s", canonical(a), canonical(b), canonical(c), canonical(d))
	}
}
func TestCapturePreservesKeyValueAroundWrappedAnyValue(t *testing.T) {
	direct := `[{"signal":"traces","encoding":"json","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"span","startTimeUnixNano":"1","endTimeUnixNano":"2","attributes":[{"value":{"stringValue":"x"}}]}]}]}]}}]`
	wrapped := `[{"signal":"traces","encoding":"protobuf","payload":{"resource_spans":[{"scope_spans":[{"spans":[{"trace_id":"00000000000000000000000000000001","span_id":"0000000000000001","name":"span","start_time_unix_nano":"1","end_time_unix_nano":"2","attributes":[{"key":"","value":{"value":{"string_value":"x"}}}]}]}]}]}}]`
	a, b := DecodeCapture(ValidationReceipt{}, []byte(direct)), DecodeCapture(ValidationReceipt{}, []byte(wrapped))
	if len(a.Diagnostics) > 0 || len(b.Diagnostics) > 0 || !reflect.DeepEqual(a, b) {
		t.Fatalf("KeyValue AnyValue wrappers differ:\n%s\n%s", canonical(a), canonical(b))
	}
}
func TestCaptureCanonicalizesAcceptedBase64Variants(t *testing.T) {
	fixture := func(value any) []byte {
		span := captureSpan(1, 1, 0, "bytes")
		span["attributes"] = []any{map[string]any{"key": "bytes", "value": map[string]any{"bytesValue": value}}}
		return captureFixture(span)
	}
	standard := DecodeCapture(ValidationReceipt{}, fixture("+w=="))
	urlSafe := DecodeCapture(ValidationReceipt{}, fixture("-w"))
	span := captureSpan(1, 1, 0, "bytes")
	span["attributes"] = []any{map[string]any{"key": "bytes", "value": map[string]any{"bytesValue": []any{251}}}}
	protobuf := DecodeCapture(ValidationReceipt{}, captureFixtureWithEncoding("protobuf", span))
	if len(standard.Diagnostics) > 0 || len(urlSafe.Diagnostics) > 0 || len(protobuf.Diagnostics) > 0 ||
		!reflect.DeepEqual(standard, urlSafe) || !reflect.DeepEqual(standard, protobuf) {
		t.Fatalf("base64 variants differ:\n%s\n%s\n%s", canonical(standard), canonical(urlSafe), canonical(protobuf))
	}
}
func TestCaptureRejectsSinkInvalidJSONEncoding(t *testing.T) {
	byteArray := captureSpan(1, 1, 0, "bytes")
	byteArray["attributes"] = []any{map[string]any{"key": "bytes", "value": map[string]any{"bytesValue": []any{1, 2}}}}
	wrapper := captureSpan(1, 1, 0, "wrapper")
	wrapper["attributes"] = []any{map[string]any{"key": "wrapped", "value": map[string]any{"value": map[string]any{"stringValue": "x"}}}}
	symbolicKind := captureSpan(1, 1, 0, "kind")
	symbolicKind["kind"] = "SPAN_KIND_SERVER"
	symbolicStatus := captureSpan(1, 1, 0, "status")
	symbolicStatus["status"] = map[string]any{"code": "STATUS_CODE_OK"}

	duplicate := bytes.Replace(
		captureFixture(captureSpan(1, 1, 0, "valid")),
		[]byte(`"name":"valid"`),
		[]byte(`"name":"first","name":"valid"`),
		1,
	)

	oversized := captureSpan(1, 1, 0, "oversized")
	values := make([]any, maxJSONValueNodes)
	for i := range values {
		values[i] = map[string]any{}
	}
	oversized["attributes"] = []any{map[string]any{"key": "wide", "value": map[string]any{"arrayValue": map[string]any{"values": values}}}}

	for name, test := range map[string]struct {
		raw  []byte
		want string
	}{
		"protobuf byte array":    {captureFixture(byteArray), "unexpected JSON type"},
		"protobuf value wrapper": {captureFixture(wrapper), `invalid OTLP anyValue field "value"`},
		"symbolic span kind":     {captureFixture(symbolicKind), "expected integer enum"},
		"symbolic status code":   {captureFixture(symbolicStatus), "expected integer enum"},
		"duplicate object key":   {duplicate, "duplicate JSON key"},
		"structural node limit":  {captureFixture(oversized), "exceeds structural limit"},
	} {
		t.Run(name, func(t *testing.T) {
			d := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, test.raw)
			if len(d.Diagnostics) != 1 || !strings.Contains(d.Diagnostics[0], test.want) || len(d.Shape.Traces) != 0 {
				t.Fatalf("sink-invalid JSON entered topology: %+v", d)
			}
		})
	}
}
func TestInternIndexesCanonicalMetadata(t *testing.T) {
	items := []map[string]any{}
	indexes := map[string]int{}
	first := map[string]any{"name": "scope", "attributes": []any{map[string]any{"key": "b"}, map[string]any{"key": "a"}}}
	equivalent := map[string]any{"attributes": []any{map[string]any{"key": "b"}, map[string]any{"key": "a"}}, "name": "scope"}
	if got := intern(&items, indexes, first); got != 0 {
		t.Fatalf("first metadata index = %d, want 0", got)
	}
	if got := intern(&items, indexes, equivalent); got != 0 {
		t.Fatalf("equivalent metadata index = %d, want 0", got)
	}
	if got := intern(&items, indexes, map[string]any{"name": "other"}); got != 1 {
		t.Fatalf("distinct metadata index = %d, want 1", got)
	}
	if len(items) != 2 || len(indexes) != 2 {
		t.Fatalf("metadata interning mismatch: %d items, %d indexes", len(items), len(indexes))
	}
}
func TestCaptureGroupingOccurrencesAndReorderedExports(t *testing.T) {
	a, b, c, d := captureSpan(1, 1, 0, "GET /tags"), captureSpan(1, 2, 1, "db"), captureSpan(2, 3, 0, "GET /tags"), captureSpan(2, 4, 3, "db")
	b["attributes"] = []any{map[string]any{"key": "query", "value": map[string]any{"stringValue": "first"}}}
	d["attributes"] = []any{map[string]any{"key": "query", "value": map[string]any{"stringValue": "second"}}}
	left := decodedFixture(t, "left", a, b, c, d)
	right := decodedFixture(t, "right", d, c, b, a)
	if len(left.Shape.Traces) != 1 || left.Shape.Traces[0].Count != 2 || len(left.Shape.Traces[0].Roots[0].Span.Children[0].Span.Occurrences) != 2 {
		t.Fatalf("occurrences lost: %+v", left.Shape)
	}
	alignment := AlignShapes(&left.Shape, &right.Shape)
	if alignment.Summary.Differing != 0 || alignment.Summary.Matched != 2 {
		t.Fatalf("export ordering changed structure: %+v", alignment)
	}
	if len(left.Spans) != 4 || canonical(left.Spans[1].Fields["attributes"]) == canonical(left.Spans[3].Fields["attributes"]) {
		t.Fatal("field variants lost")
	}
}
func TestCapturePartialAndDiagnostics(t *testing.T) {
	partial := decodedFixture(t, "p", captureSpan(1, 2, 99, "partial"))
	if partial.Shape.Traces[0].Coverage != "partial" || !strings.Contains(partial.Spans[0].Parent, "external") {
		t.Fatal("missing parent not partial")
	}
	for name, raw := range map[string][]byte{"duplicate": captureFixture(captureSpan(1, 1, 0, "a"), captureSpan(1, 1, 0, "b")), "cycle": captureFixture(captureSpan(1, 1, 2, "a"), captureSpan(1, 2, 1, "b")), "bad JSON": []byte("broken"), "bad spans": []byte(`[{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":1}]}]}}]`), "trailing": append(captureFixture(captureSpan(1, 1, 0, "a")), []byte(` {}`)...)} {
		t.Run(name, func(t *testing.T) {
			d := DecodeCapture(ValidationReceipt{}, raw)
			if len(d.Diagnostics) == 0 || len(d.Shape.Traces) > 0 {
				t.Fatalf("invented topology: %+v", d)
			}
		})
	}
}
func TestCaptureRejectsSinkInvalidSpanFields(t *testing.T) {
	fixture := func(change func(map[string]any)) []byte {
		span := captureSpan(1, 1, 0, "valid")
		change(span)
		return captureFixture(span)
	}
	for name, raw := range map[string][]byte{
		"missing name":     fixture(func(span map[string]any) { delete(span, "name") }),
		"empty name":       fixture(func(span map[string]any) { span["name"] = "" }),
		"zero start":       fixture(func(span map[string]any) { span["startTimeUnixNano"] = "0" }),
		"reversed":         fixture(func(span map[string]any) { span["endTimeUnixNano"] = "1" }),
		"numeric trace ID": fixture(func(span map[string]any) { span["traceId"] = json.Number("11111111111111111111111111111111") }),
		"numeric span ID":  fixture(func(span map[string]any) { span["spanId"] = json.Number("1111111111111111") }),
		"numeric parent ID": fixture(func(span map[string]any) {
			span["parentSpanId"] = json.Number("1111111111111111")
		}),
		"invalid kind": fixture(func(span map[string]any) { span["kind"] = 99 }),
		"invalid status": fixture(func(span map[string]any) {
			span["status"] = map[string]any{"code": 99}
		}),
		"object events": fixture(func(span map[string]any) { span["events"] = map[string]any{} }),
		"scalar links":  fixture(func(span map[string]any) { span["links"] = true }),
		"object attributes": fixture(func(span map[string]any) {
			span["attributes"] = map[string]any{}
		}),
		"event object attributes": fixture(func(span map[string]any) {
			span["events"] = []any{map[string]any{"attributes": map[string]any{}}}
		}),
		"link scalar attributes": fixture(func(span map[string]any) {
			span["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", 2), "spanId": fmt.Sprintf("%016x", 1), "attributes": false}}
		}),
		"multi-variant AnyValue": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"intValue": "1", "stringValue": "x"}}}
		}),
		"numeric string AnyValue": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"stringValue": 7}}}
		}),
		"invalid base64 AnyValue": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"bytesValue": "%%%"}}}
		}),
		"nonzero base64 padding bits": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"bytesValue": "AB=="}}}
		}),
		"unknown span field": fixture(func(span map[string]any) {
			span["nmae"] = "typo"
		}),
		"repeated underscore alias": fixture(func(span map[string]any) {
			span["trace__id"] = span["traceId"]
			delete(span, "traceId")
		}),
		"trailing underscore alias": fixture(func(span map[string]any) {
			span["span_id_"] = span["spanId"]
			delete(span, "spanId")
		}),
		"numeric status message": fixture(func(span map[string]any) {
			span["status"] = map[string]any{"message": 7}
		}),
		"string flags": fixture(func(span map[string]any) { span["flags"] = "1" }),
		"negative event dropped count": fixture(func(span map[string]any) {
			span["events"] = []any{map[string]any{"droppedAttributesCount": -1}}
		}),
		"overflow link flags": fixture(func(span map[string]any) {
			span["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", 2), "spanId": fmt.Sprintf("%016x", 1), "flags": 4294967296}}
		}),
		"scalar attribute": fixture(func(span map[string]any) {
			span["attributes"] = []any{7}
		}),
		"scalar array AnyValue": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"arrayValue": map[string]any{"values": []any{7}}}}}
		}),
		"lowercase NaN": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"doubleValue": "nan"}}}
		}),
		"short infinity": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"doubleValue": "Inf"}}}
		}),
		"signed infinity": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"doubleValue": "+Inf"}}}
		}),
		"hexadecimal float": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"doubleValue": "0x1p2"}}}
		}),
		"underscored float": fixture(func(span map[string]any) {
			span["attributes"] = []any{map[string]any{"key": "invalid", "value": map[string]any{"doubleValue": "1_0"}}}
		}),
	} {
		t.Run(name, func(t *testing.T) {
			d := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, raw)
			if len(d.Diagnostics) != 1 || len(d.Shape.Traces) != 0 {
				t.Fatalf("sink-invalid span entered topology: %+v", d)
			}
		})
	}
}
func TestCaptureSelectsDiagnosticsDeterministically(t *testing.T) {
	span := captureSpan(1, 1, 0, "invalid")
	span["name"], span["traceState"] = 7, true
	raw := captureFixture(span)
	for i := 0; i < 50; i++ {
		d := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, raw)
		if len(d.Diagnostics) != 1 || !strings.Contains(d.Diagnostics[0], `field "name"`) {
			t.Fatalf("map iteration changed the selected diagnostic: %+v", d.Diagnostics)
		}
	}
}
func TestCaptureAcceptsFiniteDoubleUnderflow(t *testing.T) {
	span := captureSpan(1, 1, 0, "underflow")
	span["attributes"] = []any{map[string]any{"key": "tiny", "value": map[string]any{"doubleValue": "1e-9999"}}}
	d := decodedFixture(t, "finite double underflow", span)
	if got := canonical(d.Spans[0].Fields["attributes"]); !strings.Contains(got, `"doubleValue":"0"`) {
		t.Fatalf("finite underflow was not canonicalized to zero: %s", got)
	}
}
func TestCaptureUsesEncodingSpecificTimestampBounds(t *testing.T) {
	span := captureSpan(1, 1, 0, "large timestamp")
	span["startTimeUnixNano"] = "18446744073709551616"
	span["endTimeUnixNano"] = "18446744073709551617"
	jsonCapture := DecodeCapture(ValidationReceipt{}, captureFixtureWithEncoding("json", span))
	protobufCapture := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, captureFixtureWithEncoding("protobuf", span))
	jsonOverflow := captureSpan(1, 1, 0, "JSON overflow")
	jsonOverflow["startTimeUnixNano"] = "170141183460469231731687303715884105727"
	jsonOverflow["endTimeUnixNano"] = "170141183460469231731687303715884105728"
	overflowCapture := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, captureFixtureWithEncoding("json", jsonOverflow))
	if len(jsonCapture.Diagnostics) != 0 || len(jsonCapture.Shape.Traces) != 1 {
		t.Fatalf("sink-accepted JSON timestamps were discarded: %+v", jsonCapture)
	}
	if len(protobufCapture.Diagnostics) != 1 || len(protobufCapture.Shape.Traces) != 0 {
		t.Fatalf("protobuf timestamp overflow entered topology: %+v", protobufCapture)
	}
	if len(overflowCapture.Diagnostics) != 1 || len(overflowCapture.Shape.Traces) != 0 {
		t.Fatalf("JSON i128 timestamp overflow entered topology: %+v", overflowCapture)
	}
}
func TestCaptureCanonicalizesSpanAndEventTimestamps(t *testing.T) {
	span := captureSpan(1, 1, 0, "timestamps")
	span["startTimeUnixNano"] = "+01"
	span["endTimeUnixNano"] = "002"
	span["events"] = []any{map[string]any{"name": "event", "timeUnixNano": "+003"}}
	d := decodedFixture(t, "timestamps", span)
	event := object(array(d.Spans[0].Fields["events"])[0])
	if d.Spans[0].Fields["startTimeUnixNano"] != "1" || d.Spans[0].Fields["endTimeUnixNano"] != "2" || event["timeUnixNano"] != "3" {
		t.Fatalf("timestamps were not canonicalized: %+v", d.Spans[0].Fields)
	}
}
func TestCaptureRetainsMissingAndInvalidLinkIdentities(t *testing.T) {
	span := captureSpan(1, 1, 0, "links")
	span["links"] = []any{map[string]any{}, map[string]any{"traceId": "not-hex", "spanId": "bad"}}
	d := decodedFixture(t, "invalid links", span)
	if len(d.Spans[0].LinkTargets) != 2 || !strings.Contains(d.Spans[0].LinkTargets[0], "missing trace/span") || !strings.Contains(d.Spans[0].LinkTargets[1], "invalid trace/span") {
		t.Fatalf("sink-accepted invalid links were discarded: %+v", d.Spans[0].LinkTargets)
	}
}
func TestCaptureDoesNotShareUnidentifiedLinkTargets(t *testing.T) {
	first, second := captureSpan(1, 1, 0, "first"), captureSpan(2, 1, 0, "second")
	first["links"], second["links"] = []any{map[string]any{}}, []any{map[string]any{}}
	d := decodedFixture(t, "unidentified links", first, second)
	for _, span := range d.Spans {
		if len(span.LinkTargets) != 1 || strings.Contains(span.LinkTargets[0], "shared target") {
			t.Fatalf("unidentified links were assigned a shared target: %+v", d.Spans)
		}
	}
}
func TestCaptureRepresentsZeroTelemetry(t *testing.T) {
	for name, raw := range map[string][]byte{
		"empty traces":   []byte(`[{"signal":"traces","encoding":"json","payload":{"resourceSpans":[]}}]`),
		"non-trace only": []byte(`[{"signal":"metrics","encoding":"json","payload":{}}]`),
	} {
		t.Run(name, func(t *testing.T) {
			empty := DecodeCapture(ValidationReceipt{Profile: "empty"}, raw)
			if len(empty.Diagnostics) != 0 || len(empty.Shape.Traces) != 0 {
				t.Fatalf("zero telemetry became a diagnostic: %+v", empty)
			}
			nonempty := decodedFixture(t, "nonempty", captureSpan(1, 1, 0, "span"))
			alignment := AlignShapes(&empty.Shape, &nonempty.Shape)
			if alignment.Summary.TraceRightOnly != 1 {
				t.Fatalf("zero telemetry hid one-sided traces: %#v", alignment.Summary)
			}
		})
	}
}
func TestCaptureRejectsMistypedScopeName(t *testing.T) {
	valid := captureFixture(captureSpan(1, 1, 0, "span"))
	for name, raw := range map[string][]byte{
		"scope name":             bytes.Replace(valid, []byte(`"name":"fixture"`), []byte(`"name":7`), 1),
		"resource dropped count": bytes.Replace(valid, []byte(`"resource":{"attributes"`), []byte(`"resource":{"droppedAttributesCount":-1,"attributes"`), 1),
		"scope dropped count":    bytes.Replace(valid, []byte(`"scope":{"name"`), []byte(`"scope":{"droppedAttributesCount":"1","name"`), 1),
	} {
		t.Run(name, func(t *testing.T) {
			d := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, raw)
			if len(d.Diagnostics) != 1 || len(d.Shape.Traces) != 0 {
				t.Fatalf("mistyped metadata entered topology: %+v", d)
			}
		})
	}
}
func TestCaptureTreatsOmittedRepeatedTraceFieldsAsEmpty(t *testing.T) {
	raw := []byte(`[
		{"signal":"traces","payload":{}},
		{"signal":"traces","payload":{"resourceSpans":null}},
		{"signal":"traces","payload":{"resourceSpans":[{}, {"scopeSpans":null}, {"scopeSpans":[{}, {"spans":null}]}]}},
		{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"kept","startTimeUnixNano":"1","endTimeUnixNano":"2"}]}]}]}}
	]`)
	d := DecodeCapture(ValidationReceipt{}, raw)
	if len(d.Diagnostics) > 0 || len(d.Spans) != 1 || str(d.Spans[0].Fields["name"]) != "kept" {
		t.Fatalf("empty trace wrappers discarded valid spans: %+v", d)
	}
}
func TestCaptureRejectsCollidingWireFieldSpellings(t *testing.T) {
	raw := []byte(`[{"signal":"traces","payload":{"resource_spans":[],"resourceSpans":[{"scopeSpans":[]}]}}]`)
	for i := 0; i < 20; i++ {
		d := DecodeCapture(ValidationReceipt{}, raw)
		if len(d.Diagnostics) != 1 || !strings.Contains(d.Diagnostics[0], "duplicate OTLP JSON field spellings") {
			t.Fatalf("wire-field collision was not deterministic: %+v", d)
		}
	}
}
func TestCaptureRejectsMalformedTopLevelWireAlias(t *testing.T) {
	raw := bytes.Replace(captureFixture(captureSpan(1, 1, 0, "span")), []byte(`"resourceSpans"`), []byte(`"resource__spans"`), 1)
	d := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, raw)
	if len(d.Diagnostics) != 1 || len(d.Shape.Traces) != 0 {
		t.Fatalf("malformed resourceSpans alias entered topology: %+v", d)
	}
}
func TestCaptureRetainsSinkAcceptedEntityReferenceKeys(t *testing.T) {
	numericRaw := bytes.Replace(
		captureFixture(captureSpan(1, 1, 0, "span")),
		[]byte(`"resource":{"attributes"`),
		[]byte(`"resource":{"entityRefs":[{"type":7,"idKeys":[7],"descriptionKeys":9}],"attributes"`),
		1,
	)
	stringRaw := bytes.Replace(numericRaw, []byte(`{"type":7,"idKeys":[7],"descriptionKeys":9}`), []byte(`{"type":"7","idKeys":["7"],"descriptionKeys":"9"}`), 1)
	numeric := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, numericRaw)
	stringValue := DecodeCapture(ValidationReceipt{Outcome: "expected-failure"}, stringRaw)
	numericResources, stringResources := canonical(numeric.Resources), canonical(stringValue.Resources)
	if len(numeric.Diagnostics) != 0 || len(numeric.Shape.Traces) != 1 || !strings.Contains(numericResources, `"type":7`) || !strings.Contains(numericResources, `"idKeys":[7]`) || !strings.Contains(numericResources, `"descriptionKeys":9`) {
		t.Fatalf("sink-accepted entity reference keys were discarded: %+v", numeric)
	}
	if len(stringValue.Diagnostics) != 0 || numericResources == stringResources {
		t.Fatalf("entity reference value types were collapsed: %s", numericResources)
	}
}
func TestCaptureRejectsMultipleExplicitRoots(t *testing.T) {
	d := DecodeCapture(ValidationReceipt{}, captureFixture(captureSpan(1, 1, 0, "first"), captureSpan(1, 2, 0, "second")))
	if len(d.Diagnostics) != 1 || !strings.Contains(d.Diagnostics[0], "multiple explicit roots") || len(d.Shape.Traces) != 0 {
		t.Fatalf("multiple explicit roots entered topology: %+v", d)
	}
}
func TestCapturePreservesPartialTraceRootCooccurrence(t *testing.T) {
	root := func(trace, span int, value string) map[string]any {
		s := captureSpan(trace, span, 100+span, "root")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return s
	}
	left := decodedFixture(t, "left", root(1, 1, "A"), root(1, 2, "B"), root(2, 1, "C"), root(2, 2, "D"))
	right := decodedFixture(t, "right", root(1, 1, "A"), root(1, 2, "C"), root(2, 1, "B"), root(2, 2, "D"))
	if left.Spans[0].TraceRoots == "" || left.Spans[0].TraceRoots == right.Spans[0].TraceRoots {
		t.Fatalf("partial trace root co-occurrence was lost: %q == %q", left.Spans[0].TraceRoots, right.Spans[0].TraceRoots)
	}
}
func TestCapturePreservesCompleteTraceDescendantCooccurrence(t *testing.T) {
	child := func(trace, span int, value string) map[string]any {
		s := captureSpan(trace, span, 1, "child")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return s
	}
	fixture := func(first, second, third, fourth string) CaptureDataset {
		return decodedFixture(t, "complete",
			captureSpan(1, 1, 0, "root"), child(1, 2, first), child(1, 3, second),
			captureSpan(2, 1, 0, "root"), child(2, 2, third), child(2, 3, fourth))
	}
	left := fixture("A", "X", "B", "Y")
	right := fixture("A", "Y", "B", "X")
	if left.Spans[0].TraceRoots == "" || left.Spans[0].TraceRoots == right.Spans[0].TraceRoots {
		t.Fatalf("complete trace descendant co-occurrence was lost: %q == %q", left.Spans[0].TraceRoots, right.Spans[0].TraceRoots)
	}
}
func TestCapturePreservesRepeatedParentChildPartitions(t *testing.T) {
	child := func(trace, span, parent int, value string) map[string]any {
		s := captureSpan(trace, span, parent, "child")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return s
	}
	fixture := func(first, second, third, fourth string) CaptureDataset {
		return decodedFixture(t, "partitions",
			captureSpan(1, 1, 0, "root"), captureSpan(1, 2, 1, "parent"), captureSpan(1, 3, 1, "parent"),
			child(1, 4, 2, first), child(1, 5, 2, second), child(1, 6, 3, third), child(1, 7, 3, fourth))
	}
	left, right := fixture("A", "X", "B", "Y"), fixture("A", "Y", "B", "X")
	leftParents := left.Shape.Traces[0].Roots[0].Span.Children
	rightParents := right.Shape.Traces[0].Roots[0].Span.Children
	if len(leftParents) != 2 || len(rightParents) != 2 {
		t.Fatalf("repeated parent child partitions were lost:\n%s\n%s", canonical(leftParents), canonical(rightParents))
	}
}
func TestCaptureLinksAndEventOrder(t *testing.T) {
	s := captureSpan(1, 1, 0, "root")
	s["events"] = []any{map[string]any{"name": "second"}, map[string]any{"name": "first"}}
	s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", 1), "spanId": fmt.Sprintf("%016x", 2)}, map[string]any{"traceId": fmt.Sprintf("%032x", 2), "spanId": fmt.Sprintf("%016x", 3)}}
	d := decodedFixture(t, "p", s, captureSpan(1, 2, 1, "child"))
	if !strings.HasPrefix(d.Spans[0].LinkTargets[0], "captured") || d.Spans[0].LinkTargets[1] != "external trace/span" {
		t.Fatal(d.Spans[0].LinkTargets)
	}
	if str(object(array(d.Spans[0].Fields["events"])[0])["name"]) != "second" {
		t.Fatal("event order changed")
	}
}
func TestCapturePreservesSharedExternalLinkTargets(t *testing.T) {
	linked := func(trace, span, targetTrace, targetSpan int) map[string]any {
		s := captureSpan(trace, span, 0, "root")
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", targetSpan)}}
		return s
	}
	shared := decodedFixture(t, "shared", linked(1, 1, 99, 1), linked(2, 1, 99, 1))
	distinct := decodedFixture(t, "distinct", linked(1, 1, 98, 1), linked(2, 1, 99, 1))
	if shared.Spans[0].LinkTargets[0] != shared.Spans[1].LinkTargets[0] || !strings.Contains(shared.Spans[0].LinkTargets[0], "shared target") {
		t.Fatalf("shared external target was lost: %+v", shared.Spans)
	}
	if strings.Contains(distinct.Spans[0].LinkTargets[0], "shared target") || strings.Contains(distinct.Spans[1].LinkTargets[0], "shared target") {
		t.Fatalf("distinct external targets were conflated: %+v", distinct.Spans)
	}
}
func TestCaptureSharedTargetsPreserveSemanticSourcePairing(t *testing.T) {
	linked := func(trace, targetTrace int, value string) map[string]any {
		s := captureSpan(trace, 1, 0, "source")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", 1)}}
		return s
	}
	fixture := func(targets ...int) CaptureDataset {
		return decodedFixture(t, "sources",
			linked(1, targets[0], "A"), linked(2, targets[1], "B"),
			linked(3, targets[2], "C"), linked(4, targets[3], "D"))
	}
	left := fixture(98, 98, 99, 99)
	right := fixture(98, 99, 98, 99)
	if left.Spans[1].LinkTargets[0] == right.Spans[1].LinkTargets[0] {
		t.Fatalf("shared-target source pairing was lost: %q", left.Spans[1].LinkTargets[0])
	}
}
func TestCaptureSharedTargetsIncludeSourceLinkGraph(t *testing.T) {
	source := func(trace, sharedTarget int, capturedSecond bool) map[string]any {
		s := captureSpan(trace, 1, 0, "source")
		secondTarget := 100
		if capturedSecond {
			secondTarget = 10
		}
		s["links"] = []any{
			map[string]any{"traceId": fmt.Sprintf("%032x", sharedTarget), "spanId": fmt.Sprintf("%016x", 1)},
			map[string]any{"traceId": fmt.Sprintf("%032x", secondTarget), "spanId": fmt.Sprintf("%016x", 1)},
		}
		return s
	}
	fixture := func(targets ...int) CaptureDataset {
		return decodedFixture(t, "source links",
			source(1, targets[0], false), source(2, targets[1], false),
			source(3, targets[2], true), source(4, targets[3], true),
			captureSpan(10, 1, 0, "captured destination"))
	}
	left := fixture(98, 98, 99, 99)
	right := fixture(98, 99, 98, 99)
	if left.Spans[1].LinkTargets[0] == right.Spans[1].LinkTargets[0] {
		t.Fatalf("shared target ignored source link graph: %q", left.Spans[1].LinkTargets[0])
	}
}
func TestCapturePreservesSharedCapturedLinkTargets(t *testing.T) {
	linked := func(trace, span, targetTrace int) map[string]any {
		s := captureSpan(trace, span, 0, "source")
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", 1)}}
		return s
	}
	spans := func(secondTarget int) []map[string]any {
		return []map[string]any{captureSpan(1, 1, 0, "target"), captureSpan(2, 1, 0, "target"), linked(3, 1, 1), linked(4, 1, secondTarget)}
	}
	shared := decodedFixture(t, "shared", spans(1)...)
	distinct := decodedFixture(t, "distinct", spans(2)...)
	if shared.Spans[2].LinkTargets[0] != shared.Spans[3].LinkTargets[0] || !strings.Contains(shared.Spans[2].LinkTargets[0], "shared target") {
		t.Fatalf("shared captured target was lost: %+v", shared.Spans)
	}
	if strings.Contains(distinct.Spans[2].LinkTargets[0], "shared target") || strings.Contains(distinct.Spans[3].LinkTargets[0], "shared target") {
		t.Fatalf("distinct captured targets were conflated: %+v", distinct.Spans)
	}
}
func TestCaptureLinksPreserveSemanticTargetOccurrence(t *testing.T) {
	span := func(trace, id int, name, value string) map[string]any {
		s := captureSpan(trace, id, 0, name)
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return s
	}
	linked := func(trace, targetTrace int, value string) map[string]any {
		s := span(trace, 1, "source", value)
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", 1)}}
		return s
	}
	left := decodedFixture(t, "left", span(1, 1, "target", "A"), span(2, 1, "target", "B"), linked(3, 1, "X"), linked(4, 2, "Y"))
	right := decodedFixture(t, "right", span(1, 1, "target", "A"), span(2, 1, "target", "B"), linked(3, 2, "X"), linked(4, 1, "Y"))
	if left.Spans[2].LinkTargets[0] == right.Spans[2].LinkTargets[0] || !strings.Contains(left.Spans[2].LinkTargets[0], "occurrence") {
		t.Fatalf("semantic target reassignment was lost: %q == %q", left.Spans[2].LinkTargets[0], right.Spans[2].LinkTargets[0])
	}
}
func TestCaptureLinkTargetsIncludeDescendantSemantics(t *testing.T) {
	target := func(trace int, value string) []map[string]any {
		child := captureSpan(trace, 2, 1, "child")
		child["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return []map[string]any{captureSpan(trace, 1, 0, "target"), child}
	}
	source := func(trace, targetTrace int, value string) map[string]any {
		s := captureSpan(trace, 1, 0, "source")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", 1)}}
		return s
	}
	fixture := func(xTarget, yTarget int) CaptureDataset {
		spans := append(target(1, "A"), target(2, "B")...)
		spans = append(spans, source(3, xTarget, "X"), source(4, yTarget, "Y"))
		return decodedFixture(t, "descendants", spans...)
	}
	left, right := fixture(1, 2), fixture(2, 1)
	if left.Spans[4].LinkTargets[0] == right.Spans[4].LinkTargets[0] {
		t.Fatalf("linked target descendant semantics were lost: %q", left.Spans[4].LinkTargets[0])
	}
}
func TestCaptureLinksRecognizeOtherTraceExternalParents(t *testing.T) {
	partial := captureSpan(1, 1, 99, "partial root")
	source := func(targetTrace int) map[string]any {
		s := captureSpan(2, 1, 0, "source")
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", 99)}}
		return s
	}
	parentLink := decodedFixture(t, "parent", partial, source(1))
	unrelatedLink := decodedFixture(t, "unrelated", partial, source(3))
	if !strings.Contains(parentLink.Spans[1].LinkTargets[0], "external parent") || parentLink.Spans[1].LinkTargets[0] == unrelatedLink.Spans[1].LinkTargets[0] {
		t.Fatalf("external parent anchor was lost: %q / %q", parentLink.Spans[1].LinkTargets[0], unrelatedLink.Spans[1].LinkTargets[0])
	}
}
func TestCaptureLinkTargetOccurrenceIncludesOutgoingRelationships(t *testing.T) {
	linked := func(span map[string]any, targetTrace int) map[string]any {
		span["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", 1)}}
		return span
	}
	source := func(trace, targetTrace int, value string) map[string]any {
		s := captureSpan(trace, 1, 0, "source")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return linked(s, targetTrace)
	}
	spans := func(xTarget, yTarget int) []map[string]any {
		return []map[string]any{
			linked(captureSpan(1, 1, 0, "target"), 99),
			linked(captureSpan(2, 1, 0, "target"), 5),
			source(3, xTarget, "X"), source(4, yTarget, "Y"),
			captureSpan(5, 1, 0, "destination"),
		}
	}
	left := decodedFixture(t, "left", spans(1, 2)...)
	right := decodedFixture(t, "right", spans(2, 1)...)
	if left.Spans[2].LinkTargets[0] == right.Spans[2].LinkTargets[0] {
		t.Fatalf("target outgoing relationship was lost: %q", left.Spans[2].LinkTargets[0])
	}
}
func TestCaptureLinkTargetOccurrencePropagatesAcrossGraph(t *testing.T) {
	linked := func(trace, targetTrace int, name string) map[string]any {
		s := captureSpan(trace, 1, 0, name)
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", targetTrace), "spanId": fmt.Sprintf("%016x", 1)}}
		return s
	}
	destination := func(trace int, value string) map[string]any {
		s := captureSpan(trace, 1, 0, "destination")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return s
	}
	source := func(trace, targetTrace int, value string) map[string]any {
		s := linked(trace, targetTrace, "source")
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return s
	}
	spans := func(xTarget, yTarget int) []map[string]any {
		return []map[string]any{
			linked(1, 5, "target"), linked(2, 6, "target"),
			source(3, xTarget, "X"), source(4, yTarget, "Y"),
			linked(5, 7, "intermediate"), linked(6, 8, "intermediate"),
			destination(7, "A"), destination(8, "B"),
		}
	}
	left := decodedFixture(t, "left", spans(1, 2)...)
	right := decodedFixture(t, "right", spans(2, 1)...)
	if left.Spans[2].LinkTargets[0] == right.Spans[2].LinkTargets[0] {
		t.Fatalf("multi-hop target relationship was lost: %q", left.Spans[2].LinkTargets[0])
	}
}
func TestCaptureLinkTargetOccurrenceTraversesLongGraph(t *testing.T) {
	chain := func(first, count int, value string) []map[string]any {
		spans := make([]map[string]any, 0, count)
		for offset := 0; offset < count; offset++ {
			trace := first + offset
			s := captureSpan(trace, 1, 0, "chain")
			if offset+1 < count {
				s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", trace+1), "spanId": fmt.Sprintf("%016x", 1)}}
			} else {
				s["attributes"] = []any{map[string]any{"key": "endpoint", "value": map[string]any{"stringValue": value}}}
			}
			spans = append(spans, s)
		}
		return spans
	}
	fixture := func(xTarget, yTarget int) CaptureDataset {
		x, y := captureSpan(1, 1, 0, "source"), captureSpan(2, 1, 0, "source")
		x["attributes"], y["attributes"] = []any{map[string]any{"key": "source", "value": map[string]any{"stringValue": "X"}}}, []any{map[string]any{"key": "source", "value": map[string]any{"stringValue": "Y"}}}
		x["links"], y["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", xTarget), "spanId": fmt.Sprintf("%016x", 1)}}, []any{map[string]any{"traceId": fmt.Sprintf("%032x", yTarget), "spanId": fmt.Sprintf("%016x", 1)}}
		spans := []map[string]any{x, y}
		spans = append(spans, chain(10, 130, "A")...)
		spans = append(spans, chain(1000, 130, "B")...)
		return decodedFixture(t, "long graph", spans...)
	}
	left := fixture(10, 1000)
	right := fixture(1000, 10)
	if left.Spans[0].LinkTargets[0] == right.Spans[0].LinkTargets[0] {
		t.Fatalf("long graph endpoint was truncated: %q", left.Spans[0].LinkTargets[0])
	}
}
func TestCaptureLinkCyclePreservesInternalAdjacency(t *testing.T) {
	fixture := func(secondOffset int) CaptureDataset {
		spans := make([]map[string]any, 6)
		for i := range spans {
			spans[i] = captureSpan(i+1, 1, 0, "identical")
			spans[i]["links"] = []any{
				map[string]any{"traceId": fmt.Sprintf("%032x", (i+1)%6+1), "spanId": fmt.Sprintf("%016x", 1)},
				map[string]any{"traceId": fmt.Sprintf("%032x", (i+secondOffset)%6+1), "spanId": fmt.Sprintf("%016x", 1)},
			}
		}
		return decodedFixture(t, "cycle", spans...)
	}
	forwardOnly := fixture(2)
	withReciprocalEdges := fixture(3)
	if forwardOnly.Spans[0].LinkTargets[0] == withReciprocalEdges.Spans[0].LinkTargets[0] {
		t.Fatalf("distinct internal cycle adjacency was lost: %q", forwardOnly.Spans[0].LinkTargets[0])
	}
}
func TestCaptureLargeLinkCyclePreservesInternalAdjacency(t *testing.T) {
	const count = 65
	fixture := func(secondOffset int) CaptureDataset {
		spans := make([]map[string]any, count)
		for i := range spans {
			spans[i] = captureSpan(i+1, 1, 0, "identical")
			spans[i]["links"] = []any{
				map[string]any{"traceId": fmt.Sprintf("%032x", (i+1)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
				map[string]any{"traceId": fmt.Sprintf("%032x", (i+secondOffset)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
			}
		}
		return decodedFixture(t, "large cycle", spans...)
	}
	plusTwo, plusThree := fixture(2), fixture(3)
	if plusTwo.Spans[0].LinkTargets[0] == plusThree.Spans[0].LinkTargets[0] {
		t.Fatalf("large component internal adjacency was lost: %q", plusTwo.Spans[0].LinkTargets[0])
	}
}
func TestCaptureLargeLinkComponentIgnoresRecordOrder(t *testing.T) {
	const count = 65
	spans := make([]map[string]any, count)
	reversed := make([]map[string]any, count)
	for i := range spans {
		span := captureSpan(i+1, 1, 0, fmt.Sprintf("span-%03d", i))
		span["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", (i+1)%count+1), "spanId": fmt.Sprintf("%016x", 1)}}
		spans[i] = span
		reversed[count-1-i] = span
	}
	left := decodedFixture(t, "forward", spans...)
	right := decodedFixture(t, "reversed", reversed...)
	rightTargets := map[string]string{}
	for _, span := range right.Spans {
		rightTargets[str(span.Fields["name"])] = span.LinkTargets[0]
	}
	for _, span := range left.Spans {
		name := str(span.Fields["name"])
		if span.LinkTargets[0] != rightTargets[name] {
			t.Fatalf("record order changed %s link target: %q != %q", name, span.LinkTargets[0], rightTargets[name])
		}
	}
}
func TestCaptureLargeLocallyIdenticalComponentIgnoresRecordOrder(t *testing.T) {
	const count = 65
	spans := make([]map[string]any, count)
	reversed := make([]map[string]any, count)
	for i := range spans {
		secondOffset := 2
		if i == 0 {
			secondOffset = 3
		}
		span := captureSpan(i+1, 1, 0, "identical")
		span["links"] = []any{
			map[string]any{"traceId": fmt.Sprintf("%032x", (i+1)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
			map[string]any{"traceId": fmt.Sprintf("%032x", (i+secondOffset)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
		}
		spans[i] = span
		reversed[count-1-i] = span
	}
	left := decodedFixture(t, "forward identical", spans...)
	right := decodedFixture(t, "reversed identical", reversed...)
	rightTargets := map[string]string{}
	distinctTargets := map[string]bool{}
	for _, span := range right.Spans {
		rightTargets[str(span.Fields["traceId"])] = canonical(span.LinkTargets)
		for _, target := range span.LinkTargets {
			distinctTargets[target] = true
		}
	}
	if len(distinctTargets) == 1 {
		t.Fatal("non-automorphic large-component members collapsed to one target key")
	}
	for _, span := range left.Spans {
		traceID := str(span.Fields["traceId"])
		if canonical(span.LinkTargets) != rightTargets[traceID] {
			t.Fatalf("record order changed trace %s link targets: %s != %s", traceID, canonical(span.LinkTargets), rightTargets[traceID])
		}
	}
}
func TestCaptureLargeComponentRefinesUntilStable(t *testing.T) {
	const count = 129
	spans := make([]map[string]any, 0, count+2)
	for i := 0; i < count; i++ {
		secondOffset := 2
		if i == 0 {
			secondOffset = 3
		}
		span := captureSpan(i+1, 1, 0, "identical")
		span["links"] = []any{
			map[string]any{"traceId": fmt.Sprintf("%032x", (i+1)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
			map[string]any{"traceId": fmt.Sprintf("%032x", (i+secondOffset)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
		}
		spans = append(spans, span)
	}
	for source, target := range []int{40, 64} {
		span := captureSpan(1000+source, 1, 0, fmt.Sprintf("source-%d", source))
		span["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", target+1), "spanId": fmt.Sprintf("%016x", 1)}}
		spans = append(spans, span)
	}
	d := decodedFixture(t, "stable large component refinement", spans...)
	if d.Spans[count].LinkTargets[0] == d.Spans[count+1].LinkTargets[0] {
		t.Fatalf("distant non-equivalent members retained one target key: %q", d.Spans[count].LinkTargets[0])
	}
}
func TestCaptureLargeLinkGraphStaysBounded(t *testing.T) {
	const count = 4096
	spans := make([]map[string]any, 0, count)
	for trace := 1; trace <= count; trace++ {
		s := captureSpan(trace, 1, 0, "chain")
		target := trace + 1
		if target > count {
			target = 1
		}
		s["links"] = []any{map[string]any{"traceId": fmt.Sprintf("%032x", target), "spanId": fmt.Sprintf("%016x", 1)}}
		spans = append(spans, s)
	}
	d := decodedFixtureWithEncoding(t, "large link graph", "protobuf", spans...)
	if size := len(canonical(d)); size > 8000000 {
		t.Fatalf("large link graph projection grew to %d bytes", size)
	}
}
func TestCaptureLargeRegularLinkGraphStaysBounded(t *testing.T) {
	const count = 1000
	spans := make([]map[string]any, count)
	for i := range spans {
		span := captureSpan(i+1, 1, 0, "regular")
		span["links"] = []any{
			map[string]any{"traceId": fmt.Sprintf("%032x", (i+1)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
			map[string]any{"traceId": fmt.Sprintf("%032x", (i+2)%count+1), "spanId": fmt.Sprintf("%016x", 1)},
		}
		spans[i] = span
	}
	d := decodedFixtureWithEncoding(t, "large regular link graph", "protobuf", spans...)
	if len(d.Spans) != count {
		t.Fatalf("decoded %d spans, want %d", len(d.Spans), count)
	}
}
func TestCaptureRejectsAllZeroParentID(t *testing.T) {
	span := captureSpan(1, 1, 0, "invalid parent")
	span["parentSpanId"] = "0000000000000000"
	d := DecodeCapture(ValidationReceipt{}, captureFixture(span))
	if len(d.Diagnostics) != 1 || !strings.Contains(d.Diagnostics[0], "invalid trace/span identity") {
		t.Fatalf("all-zero parent ID was accepted: %+v", d)
	}
}
func TestCaptureRejectsSinkMaximumTraceDepth(t *testing.T) {
	spans := make([]map[string]any, 129)
	for i := range spans {
		parent := 0
		if i > 0 {
			parent = i
		}
		spans[i] = captureSpan(1, i+1, parent, "depth")
	}
	d := DecodeCapture(ValidationReceipt{}, captureFixture(spans...))
	if len(d.Diagnostics) != 1 || !strings.Contains(d.Diagnostics[0], "exceeds 128 levels") {
		t.Fatalf("sink-invalid trace depth was accepted: %+v", d.Diagnostics)
	}
}
func TestCapturePreservesCapturedParentOccurrenceIdentity(t *testing.T) {
	span := func(trace, id, parent int, name, value string) map[string]any {
		s := captureSpan(trace, id, parent, name)
		s["attributes"] = []any{map[string]any{"key": "variant", "value": map[string]any{"stringValue": value}}}
		return s
	}
	left := decodedFixture(t, "left", span(1, 1, 0, "parent", "A"), span(1, 2, 1, "child", "X"), span(2, 1, 0, "parent", "B"), span(2, 2, 1, "child", "Y"))
	right := decodedFixture(t, "right", span(1, 1, 0, "parent", "A"), span(1, 2, 1, "child", "Y"), span(2, 1, 0, "parent", "B"), span(2, 2, 1, "child", "X"))
	if left.Spans[1].Parent != right.Spans[1].Parent {
		t.Fatalf("the same semantic parent was not stable: %q != %q", left.Spans[1].Parent, right.Spans[1].Parent)
	}
	if left.Spans[1].Parent == right.Spans[3].Parent {
		t.Fatalf("child X was reassigned without changing its parent relationship: %q", left.Spans[1].Parent)
	}
}
func TestCaptureParentOccurrenceIdentityWithoutScope(t *testing.T) {
	fixture := func(scope string) []byte {
		spans := []any{captureSpan(1, 1, 0, "parent"), captureSpan(1, 2, 1, "child")}
		raw, _ := json.Marshal([]any{map[string]any{"signal": "traces", "payload": map[string]any{"resourceSpans": []any{map[string]any{"scopeSpans": []any{map[string]any{"scope": map[string]any{"name": scope}, "spans": spans}}}}}}})
		return raw
	}
	left := DecodeCapture(ValidationReceipt{}, fixture("scope-a"))
	right := DecodeCapture(ValidationReceipt{}, fixture("scope-b"))
	if len(left.Diagnostics) > 0 || len(right.Diagnostics) > 0 {
		t.Fatalf("scope fixtures failed: %v %v", left.Diagnostics, right.Diagnostics)
	}
	if left.Spans[1].Parent == right.Spans[1].Parent {
		t.Fatal("scope-sensitive parent relationships were conflated")
	}
	if left.Spans[1].ParentWithoutScope != right.Spans[1].ParentWithoutScope {
		t.Fatalf("hidden scope leaked into parent relationships: %q != %q", left.Spans[1].ParentWithoutScope, right.Spans[1].ParentWithoutScope)
	}
}
func TestPlannedChecksDoNotInflateVerification(t *testing.T) {
	proof := ProofPlanProof{FeatureID: "f", Assertion: "assert", Basis: "observed"}
	model := ReportModel{Manifests: []Manifest{{Profile: "p"}, {Profile: "unavailable"}}, Coverage: []CoverageCell{{Profile: "p", Scenario: "pass", Declared: true}, {Profile: "p", Scenario: "xfail", Declared: true}, {Profile: "p", Scenario: "unrun", Declared: true}, {Profile: "p", Scenario: "excluded"}, {Profile: "unavailable", Scenario: "unrun", Declared: true}}, Verification: map[string]map[string]Verification{"f": {"p": {State: "verified"}, "unavailable": {State: "not_exercised"}}}, Receipts: []ValidationReceipt{{Profile: "p", Scenario: "pass", Outcome: "verified", Proofs: []ReceiptProof{{FeatureID: "f", Assertion: "assert", Basis: "observed", Result: "pass"}}}, {Profile: "p", Scenario: "xfail", Outcome: "xfail", XFailReason: "reason"}}}
	before := canonical(model.Verification)
	plans := map[string]PlanArtifact{"p": {Plan: NormalizedProfilePlan{Proofs: []ProofPlanProof{proof}}}, "unavailable": {Plan: NormalizedProfilePlan{Proofs: []ProofPlanProof{proof}}}}
	AddReportProjections(&model, plans, nil)
	if before != canonical(model.Verification) {
		t.Fatal("projection altered verification")
	}
	c := model.PlannedChecks[0]
	if c.Passed != 1 || c.ExpectedFailure != 1 || c.NoResult != 1 || len(c.Executions) != 3 || c.Executions[1].Reason != "reason" {
		t.Fatalf("bad execution counts %+v", c)
	}
	if model.PlannedChecks[1].NoResult != 1 {
		t.Fatal("unavailable check lost")
	}
	proof.Scenarios = []string{"pass"}
	plans["p"] = PlanArtifact{Plan: NormalizedProfilePlan{Proofs: []ProofPlanProof{proof}}}
	model.PlannedChecks = nil
	AddReportProjections(&model, plans, nil)
	if len(model.PlannedChecks[0].Executions) != 1 {
		t.Fatal("scenario subset widened")
	}
}

// Export a representative, self-contained fixture for browser interaction tests.
func TestCapturedReportPreview(t *testing.T) {
	metadata, features, manifests, _, evidence := fixtureModel(t, false)
	model, e := BuildModel(metadata, features, manifests, nil, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...)
	if e != nil {
		t.Fatal(e)
	}
	// Keep the preview's verification consistent with its accepted proofs.
	model.Verification[features[0].ID]["python"] = model.Verification[features[0].ID]["go"]
	model.Verification[features[1].ID]["python"] = model.Verification[features[1].ID]["go"]
	plans := map[string]PlanArtifact{}
	captures := map[string][]byte{}
	for side, p := range []string{"go", "python"} {
		spans := []map[string]any{}
		for i := 0; i < 200; i++ {
			root := captureSpan(i+1, 1, 0, "GET /tags")
			child := captureSpan(i+1, 2, 1, "query")
			child["attributes"] = []any{map[string]any{"key": "query", "value": map[string]any{"stringValue": fmt.Sprintf("SELECT %d </script>", i%3)}}}
			if side == 1 {
				root["spanId"] = fmt.Sprintf("%016x", 3)
				child["parentSpanId"] = fmt.Sprintf("%016x", 3)
				root["startTimeUnixNano"] = "18446744073709551001"
			}
			spans = append(spans, root, child)
		}
		r := ValidationReceipt{Profile: p, Scenario: "case", Revision: strings.Repeat("a", 40), Outcome: "verified", Proofs: []ReceiptProof{{FeatureID: features[0].ID, Assertion: "span/root-present", Basis: "observed", Result: "pass"}}}
		model.Receipts = append(model.Receipts, r)
		captures[p+"\x00case"] = captureFixture(spans...)
		plans[p] = PlanArtifact{Plan: NormalizedProfilePlan{Proofs: []ProofPlanProof{{FeatureID: features[0].ID, Assertion: "span/root-present", Basis: "observed"}}}, Source: manifests[0].ProfileEvidence[0]}
	}
	AddReportProjections(&model, plans, captures)
	if len(model.CaptureComparisons) != 1 || len(model.CaptureComparisons[0].Traces) != 1 {
		t.Fatal("comparison unavailable without saved shapes")
	}
	html, e := RenderHTML(model)
	if e != nil {
		t.Fatal(e)
	}
	if len(html) > 2000000 {
		t.Fatalf("representative report expanded unexpectedly: %d bytes", len(html))
	}
	directory := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if directory == "" {
		directory = t.TempDir()
	}
	if e := os.WriteFile(filepath.Join(directory, "captured-report.html"), html, 0644); e != nil {
		t.Fatal(e)
	}
	t.Logf("800-span report: %d bytes", len(html))
}

func TestCaptureDeepStructureStaysBounded(t *testing.T) {
	spans := []map[string]any{}
	for i := 1; i <= 100; i++ {
		spans = append(spans, captureSpan(1, i, i-1, "nested"))
	}
	d := decodedFixture(t, "p", spans...)
	if size := len(canonical(d)); size > 1500000 {
		t.Fatalf("deep tree projection grew to %d bytes", size)
	}
}
func TestScopeCannotChangePairingScore(t *testing.T) {
	a := alignedSpan{node: SpanNode{Name: "root", Kind: "server", Scope: "one"}}
	b := a
	b.node.Scope = "two"
	if alignedSpanMatchScore(a, a) != alignedSpanMatchScore(a, b) {
		t.Fatal("scope influenced structural pairing")
	}
}
