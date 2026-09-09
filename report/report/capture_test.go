package report

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func captureFixture(spans ...map[string]any) []byte {
	values := make([]any, len(spans))
	for i, s := range spans {
		values[i] = s
	}
	b, _ := json.Marshal([]any{map[string]any{"signal": "traces", "payload": map[string]any{"resourceSpans": []any{map[string]any{"resource": map[string]any{"attributes": []any{map[string]any{"key": "service.name", "value": map[string]any{"stringValue": "realworld"}}}}, "scopeSpans": []any{map[string]any{"scope": map[string]any{"name": "fixture", "version": "1"}, "spans": values}}}}}}})
	return b
}
func captureSpan(trace, span, parent int, name string) map[string]any {
	p := ""
	if parent != 0 {
		p = fmt.Sprintf("%016x", parent)
	}
	return map[string]any{"traceId": fmt.Sprintf("%032x", trace), "spanId": fmt.Sprintf("%016x", span), "parentSpanId": p, "name": name, "kind": 2, "startTimeUnixNano": "18446744073709551000", "endTimeUnixNano": "18446744073709551615"}
}
func decodedFixture(t *testing.T, profile string, spans ...map[string]any) CaptureDataset {
	t.Helper()
	d := DecodeCapture(ValidationReceipt{Profile: profile, Scenario: "case", Outcome: "verified", Revision: strings.Repeat("a", 40)}, captureFixture(spans...))
	if len(d.Diagnostics) > 0 {
		t.Fatal(d.Diagnostics)
	}
	return d
}
func TestCaptureWireFormatsAndPrecision(t *testing.T) {
	otlp := `[{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"GET /tags","kind":"SPAN_KIND_SERVER","status":{"code":"STATUS_CODE_OK"},"attributes":[{"key":"large","value":{"intValue":"9223372036854775807"}},{"key":"bytes","value":{"bytesValue":"AQI="}},{"key":"array","value":{"arrayValue":{"values":[{"boolValue":true},{"stringValue":"9223372036854775807"}]}}}]}]}]}]}}]`
	proto := `[{"signal":"traces","payload":{"resource_spans":[{"resource":null,"schema_url":"","scope_spans":[{"scope":null,"schema_url":"","spans":[{"trace_id":"00000000000000000000000000000001","span_id":"0000000000000001","parent_span_id":"","name":"GET /tags","kind":2,"status":{"code":1,"message":""},"attributes":[{"key":"array","value":{"value":{"array_value":{"values":[{"value":{"bool_value":true}},{"value":{"string_value":"9223372036854775807"}}]}}}},{"key":"bytes","value":{"value":{"bytes_value":[1,2]}}},{"key":"large","value":{"value":{"int_value":9223372036854775807}}}],"events":[],"links":[],"flags":0,"dropped_attributes_count":0,"dropped_events_count":0,"dropped_links_count":0,"start_time_unix_nano":0,"end_time_unix_nano":0,"trace_state":""}]}]}]}}]`
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
	direct := `[{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","attributes":[{"key":"unset","value":{"stringValue":null}}]}]}]}]}}]`
	wrapped := `[{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","attributes":[{"key":"unset","value":{"value":null}}]}]}]}]}}]`
	a, b := DecodeCapture(ValidationReceipt{}, []byte(direct)), DecodeCapture(ValidationReceipt{}, []byte(wrapped))
	if len(a.Diagnostics) > 0 || len(b.Diagnostics) > 0 || !reflect.DeepEqual(a, b) {
		t.Fatalf("null AnyValue variants differ:\n%s\n%s", canonical(a), canonical(b))
	}
}
func TestCapturePreservesKeyValueAroundWrappedAnyValue(t *testing.T) {
	direct := `[{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","attributes":[{"value":{"stringValue":"x"}}]}]}]}]}}]`
	wrapped := `[{"signal":"traces","payload":{"resource_spans":[{"scope_spans":[{"spans":[{"trace_id":"00000000000000000000000000000001","span_id":"0000000000000001","attributes":[{"key":"","value":{"value":{"string_value":"x"}}}]}]}]}]}}]`
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
	protobuf := DecodeCapture(ValidationReceipt{}, fixture([]any{251}))
	if len(standard.Diagnostics) > 0 || len(urlSafe.Diagnostics) > 0 || len(protobuf.Diagnostics) > 0 ||
		!reflect.DeepEqual(standard, urlSafe) || !reflect.DeepEqual(standard, protobuf) {
		t.Fatalf("base64 variants differ:\n%s\n%s\n%s", canonical(standard), canonical(urlSafe), canonical(protobuf))
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
func TestCaptureTreatsOmittedRepeatedTraceFieldsAsEmpty(t *testing.T) {
	raw := []byte(`[
		{"signal":"traces","payload":{}},
		{"signal":"traces","payload":{"resourceSpans":null}},
		{"signal":"traces","payload":{"resourceSpans":[{}, {"scopeSpans":null}, {"scopeSpans":[{}, {"spans":null}]}]}},
		{"signal":"traces","payload":{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"00000000000000000000000000000001","spanId":"0000000000000001","name":"kept"}]}]}]}}
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
func TestCaptureMarksMultipleRootsPartial(t *testing.T) {
	multipleRoots := decodedFixture(t, "multiple-roots", captureSpan(1, 1, 0, "first"), captureSpan(1, 2, 0, "second"))
	if multipleRoots.Shape.Traces[0].Coverage != "partial" {
		t.Fatalf("multi-root trace reported as complete: %+v", multipleRoots.Shape.Traces)
	}
}
func TestCapturePreservesPartialTraceRootCooccurrence(t *testing.T) {
	root := func(trace, span int, value string) map[string]any {
		s := captureSpan(trace, span, 0, "root")
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
func TestCaptureRejectsAllZeroParentID(t *testing.T) {
	span := captureSpan(1, 1, 0, "invalid parent")
	span["parentSpanId"] = "0000000000000000"
	d := DecodeCapture(ValidationReceipt{}, captureFixture(span))
	if len(d.Diagnostics) != 1 || !strings.Contains(d.Diagnostics[0], "invalid trace/span identity") {
		t.Fatalf("all-zero parent ID was accepted: %+v", d)
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
