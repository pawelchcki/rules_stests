package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

func nativeTestCapture(spans []nativeCapturedSpan) []byte {
	value, err := json.Marshal([]any{map[string]any{"payload": map[string]any{"traces": [][]nativeCapturedSpan{spans}}}})
	if err != nil {
		panic(err)
	}
	return value
}

func nativeConcurrencyCapture() []nativeCapturedSpan {
	var spans []nativeCapturedSpan
	for index := 0; index < 160; index++ {
		high, low, parent := nativeContext(index)
		if index%4 < 2 {
			low, parent = uint64(index+1000), 0
		}
		root := uint64(index*3 + 1)
		spans = append(spans,
			nativeCapturedSpan{TraceID: low, SpanID: root, ParentID: parent, Name: "rack.request", Type: "web", Meta: map[string]string{"http.status_code": "200", "_dd.p.tid": fmt.Sprintf("%016x", high)}},
			nativeCapturedSpan{TraceID: low, SpanID: root + 1, ParentID: root, Name: "rails.action_controller", Type: "web", Meta: map[string]string{"_dd.p.tid": fmt.Sprintf("%016x", high)}},
			nativeCapturedSpan{TraceID: low, SpanID: root + 2, ParentID: root + 1, Name: "sqlite.query", Type: "sql", Meta: map[string]string{"_dd.p.tid": fmt.Sprintf("%016x", high)}},
		)
	}
	return spans
}

func TestNativeConcurrencyRejectsMissingAndContaminatedEvidence(t *testing.T) {
	profile := atomicProfile{Scenario: "native_concurrency"}
	if err := validateNativeScenario(profile, nativeTestCapture(nativeConcurrencyCapture())); err != nil {
		t.Fatal(err)
	}
	cases := map[string]func([]nativeCapturedSpan) []nativeCapturedSpan{
		"missing request":      func(spans []nativeCapturedSpan) []nativeCapturedSpan { return spans[3:] },
		"duplicate completion": func(spans []nativeCapturedSpan) []nativeCapturedSpan { return append(spans, spans[0]) },
		"foreign controller": func(spans []nativeCapturedSpan) []nativeCapturedSpan {
			spans[1].ParentID = spans[3].SpanID
			return spans
		},
		"orphan query":  func(spans []nativeCapturedSpan) []nativeCapturedSpan { spans[2].ParentID = 999999; return spans },
		"missing query": func(spans []nativeCapturedSpan) []nativeCapturedSpan { return append(spans[:2], spans[3:]...) },
		"lost high trace ID": func(spans []nativeCapturedSpan) []nativeCapturedSpan {
			spans[6].Meta["_dd.p.tid"] = "0000000000000000"
			return spans
		},
		"foreign child high trace ID": func(spans []nativeCapturedSpan) []nativeCapturedSpan {
			spans[7].Meta["_dd.p.tid"] = "0000000000000000"
			return spans
		},
		"contaminated root": func(spans []nativeCapturedSpan) []nativeCapturedSpan {
			spans[0].ParentID = spans[3].SpanID
			return spans
		},
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			if err := validateNativeScenario(profile, nativeTestCapture(mutate(nativeConcurrencyCapture()))); err == nil {
				t.Fatal("invalid evidence accepted")
			}
		})
	}
}

func TestNativeClientRequiresExactParentageAndErrors(t *testing.T) {
	profile := atomicProfile{Scenario: "native_ruby_client"}
	directory := t.TempDir()
	t.Setenv("TEST_UNDECLARED_OUTPUTS_DIR", directory)
	wire := `[{"method":"GET","traceparent":"00-00000000000000000000000000000001-0000000000000003-01","datadog_parent":"3","datadog_trace":"1","datadog_tags":"_dd.p.tid=0000000000000000"},{"method":"POST","traceparent":"00-00000000000000000000000000000001-0000000000000004-01","datadog_parent":"4","datadog_trace":"1","datadog_tags":"_dd.p.tid=0000000000000000"},{"method":"GET","traceparent":"00-00000000000000000000000000000001-0000000000000005-01","datadog_parent":"5","datadog_trace":"1","datadog_tags":"_dd.p.tid=0000000000000000"}]`
	if err := os.WriteFile(filepath.Join(directory, "native-client-wire.json"), []byte(wire), 0644); err != nil {
		t.Fatal(err)
	}
	spans := []nativeCapturedSpan{
		{TraceID: 1, SpanID: 2, Name: "ruby.http.fixture", Type: "custom"},
		{TraceID: 1, SpanID: 3, ParentID: 2, Name: "http.request", Type: "http", Meta: map[string]string{"span.kind": "client", "http.method": "GET", "http.status_code": "200"}},
		{TraceID: 1, SpanID: 4, ParentID: 2, Name: "http.request", Type: "http", Error: 1, Meta: map[string]string{"span.kind": "client", "http.method": "POST", "http.status_code": "503"}},
		{TraceID: 1, SpanID: 5, ParentID: 2, Name: "http.request", Type: "http", Meta: map[string]string{"span.kind": "client", "http.method": "GET", "http.status_code": "200"}},
	}
	if err := validateNativeScenario(profile, nativeTestCapture(spans)); err != nil {
		t.Fatal(err)
	}
	spans[2].Error = 0
	if err := validateNativeScenario(profile, nativeTestCapture(spans)); err == nil {
		t.Fatal("missed response error accepted")
	}
	spans[2].Error = 1
	spans[2].ParentID = 3
	if err := validateNativeScenario(profile, nativeTestCapture(spans)); err == nil {
		t.Fatal("wrong client parent accepted")
	}
}

func TestNativeHasTraceIDHighRequiresExactTag(t *testing.T) {
	const high = "0123456789abcdef"
	for _, test := range []struct {
		name string
		tags string
		want bool
	}{
		{"single tag", "_dd.p.tid=" + high, true},
		{"comma-separated tag", "_dd.p.dm=-0,_dd.p.tid=" + high, true},
		{"trailing junk", "_dd.p.tid=" + high + "junk", false},
		{"embedded key", "other=_dd.p.tid=" + high, false},
		{"prefixed key", "prefix_dd.p.tid=" + high, false},
	} {
		t.Run(test.name, func(t *testing.T) {
			if got := nativeHasTraceIDHigh(test.tags, high); got != test.want {
				t.Fatalf("nativeHasTraceIDHigh(%q) = %t, want %t", test.tags, got, test.want)
			}
		})
	}
}
