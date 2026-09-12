package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"sync/atomic"
	"testing"
	"time"
)

func TestPartialWorkloadOutlivesSharedControlTimeout(t *testing.T) {
	var held atomic.Bool
	released := make(chan struct{})
	app := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/__rules_stests/partial":
			// The held state becomes visible late enough that the fixed 2.5s
			// observation window exceeds the shared client's 5s timeout.
			time.Sleep(3 * time.Second)
			held.Store(true)
			select {
			case <-released:
				w.WriteHeader(http.StatusOK)
			case <-r.Context().Done():
			}
		case "/__rules_stests/state":
			json.NewEncoder(w).Encode(map[string]bool{"held": held.Load()})
		case "/__rules_stests/release":
			held.Store(false)
			close(released)
			w.WriteHeader(http.StatusOK)
		default:
			http.NotFound(w, r)
		}
	}))
	defer app.Close()
	sink := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Write([]byte("[]"))
	}))
	defer sink.Close()

	oldSink, oldOutput, oldCase := ddProbeSink, ddProbeOutput, activeDatadogCase
	ddProbeSink, ddProbeOutput, activeDatadogCase = sink.URL, t.TempDir(), ddCase{Name: "partial-test"}
	t.Cleanup(func() { ddProbeSink, ddProbeOutput, activeDatadogCase = oldSink, oldOutput, oldCase })
	req, err := http.NewRequest(http.MethodGet, app.URL+"/__rules_stests/partial", nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := ddPartialWorkload(app.URL, req); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(ddProbeOutput + "/partial-test.early.capture.json"); err != nil {
		t.Fatal(err)
	}
}

func TestPartialWorkloadCancelsHeldRequestOnControlFailure(t *testing.T) {
	canceled := make(chan struct{})
	started := make(chan struct{})
	app := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/__rules_stests/partial":
			close(started)
			<-r.Context().Done()
			close(canceled)
		case "/__rules_stests/state":
			<-started
			w.Write([]byte("not-json"))
		default:
			http.NotFound(w, r)
		}
	}))
	defer app.Close()
	req, err := http.NewRequest(http.MethodGet, app.URL+"/__rules_stests/partial", nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := ddPartialWorkload(app.URL, req); err == nil {
		t.Fatal("accepted malformed held-state response")
	}
	select {
	case <-canceled:
	case <-time.After(time.Second):
		t.Fatal("held request was not canceled after control failure")
	}
}

func probeFixture(kind string, partial bool) ([]ddNativeSpan, []byte) {
	roots := ddBaselineFixture()
	if kind == "partial" {
		roots = roots[:1]
	}
	var spans []ddNativeSpan
	var chunks [][]ddNativeSpan
	for i, root := range roots {
		base := uint64(100 + i*10)
		root.Meta["_dd.p.tid"] = "1234567890abcdef"
		makeSpan := func(id, parent uint64, name, resource string) ddNativeSpan {
			return ddNativeSpan{Start: 101, Duration: 1, TraceID: root.TraceID, SpanID: id, ParentID: parent, Name: name, Resource: resource, Service: root.Service, Meta: map[string]string{"_dd.p.tid": "1234567890abcdef"}, Metrics: map[string]float64{}}
		}
		switch kind {
		case "nested", "keep", "drop", "partial":
			parent := makeSpan(base, root.SpanID, "probe.parent", kind)
			for n := 0; n < 3; n++ {
				child := makeSpan(base+uint64(n+1), base, "probe.child", fmt.Sprint(n))
				child.Meta["probe.index"] = fmt.Sprint(n)
				if partial {
					child.Meta["_dd.p.dm"] = "-3"
					child.Metrics["_sampling_priority_v1"] = 2
					chunks = append(chunks, []ddNativeSpan{child})
				}
				spans = append(spans, child)
			}
			if partial {
				parent.Meta["_dd.p.dm"] = "-3"
				parent.Metrics["_sampling_priority_v1"] = 2
				chunks = append(chunks, []ddNativeSpan{parent})
			}
			spans = append(spans, parent)
		case "exception":
			root.Error = 1
			root.Meta["http.status_code"] = "500"
			exception := makeSpan(base, root.SpanID, "probe.exception", "")
			exception.Error = 1
			exception.Meta["error.type"] = "RuntimeError"
			exception.Meta["error.message"] = "controlled rules_stests exception"
			exception.Meta["error.stack"] = "Traceback fixture"
			spans = append(spans, exception)
		case "outbound":
			client := makeSpan(base, root.SpanID, "http.client", "")
			client.Type = "http"
			server := makeSpan(base+1, client.SpanID, "http.request", "")
			server.Type = "web"
			after := makeSpan(base+2, root.SpanID, "probe.after_outbound", "")
			spans = append(spans, client, server, after)
		}
		spans = append(spans, root)
	}
	early, _ := json.Marshal([]any{map[string]any{"payload": map[string]any{"traces": chunks}}})
	return spans, early
}

func TestSharedProbeGraphs(t *testing.T) {
	for _, kind := range []string{"nested", "keep", "drop", "exception", "outbound", "partial"} {
		t.Run(kind, func(t *testing.T) {
			spans, early := probeFixture(kind, kind == "partial")
			c := ddCase{Kind: kind, Partial: kind == "partial"}
			if err := validateDatadogProbes(c, spans, early); err != nil {
				t.Fatal(err)
			}
			spans[0].ParentID = 999999
			if err := validateDatadogProbes(c, spans, early); err == nil {
				t.Fatal("accepted crossed or orphaned probe")
			}
		})
	}
	for _, mutate := range []func([]ddNativeSpan) []ddNativeSpan{
		func(s []ddNativeSpan) []ddNativeSpan { return s[1:] },
		func(s []ddNativeSpan) []ddNativeSpan { return append(s, s[0]) },
		func(s []ddNativeSpan) []ddNativeSpan { s[0].Meta["probe.index"] = "9"; return s },
	} {
		spans, early := probeFixture("nested", false)
		if err := validateDatadogProbes(ddCase{Kind: "nested"}, mutate(spans), early); err == nil {
			t.Fatal("accepted wrong child multiplicity or metadata")
		}
	}
}

func TestPartialFlushControlsAndReconstruction(t *testing.T) {
	for _, enabled := range []bool{false, true} {
		spans, early := probeFixture("partial", enabled)
		c := ddCase{Kind: "partial", Partial: enabled}
		if err := validateDatadogProbes(c, spans, early); err != nil {
			t.Fatal(err)
		}
		c.Partial = !enabled
		if err := validateDatadogProbes(c, spans, early); err == nil {
			t.Fatal("ignored partial flush control")
		}
	}
	spans, early := probeFixture("partial", true)
	delete(spans[0].Metrics, "_sampling_priority_v1")
	if err := validateDatadogProbes(ddCase{Kind: "partial", Partial: true}, spans, early); err == nil {
		t.Fatal("accepted changed chunk during reconstruction")
	}
	spans, early = probeFixture("partial", true)
	var records []map[string]any
	json.Unmarshal(early, &records)
	chunk := records[0]["payload"].(map[string]any)["traces"].([]any)[0].([]any)
	delete(chunk[0].(map[string]any)["meta"].(map[string]any), "_dd.p.dm")
	early, _ = json.Marshal(records)
	if err := validateDatadogProbes(ddCase{Kind: "partial", Partial: true}, spans, early); err == nil {
		t.Fatal("accepted missing chunk metadata")
	}
}

func TestExceptionMetadataRequired(t *testing.T) {
	for _, key := range []string{"error.type", "error.message", "error.stack"} {
		t.Run(key, func(t *testing.T) {
			spans, early := probeFixture("exception", false)
			delete(spans[0].Meta, key)
			if err := validateDatadogProbes(ddCase{Kind: "exception"}, spans, early); err == nil {
				t.Fatal("accepted missing " + key)
			}
		})
	}
}

func TestPartialFlushThreshold(t *testing.T) {
	spans, early := probeFixture("partial", true)
	c := ddCase{Kind: "partial", Partial: true, Env: map[string]string{"DD_TRACE_PARTIAL_FLUSH_MIN_SPANS": "1"}}
	if err := validateDatadogProbes(c, spans, early); err != nil {
		t.Fatal(err)
	}
	c.Env["DD_TRACE_PARTIAL_FLUSH_MIN_SPANS"] = "2"
	if err := validateDatadogProbes(c, spans, early); err == nil {
		t.Fatal("accepted flush below configured threshold")
	}
}

func TestKnownGoManualDropRuleRequiresCompleteEvidence(t *testing.T) {
	spans, _ := probeFixture("drop", false)
	for i := range spans {
		s := &spans[i]
		if s.Meta["probe.request_id"] != "" {
			s.Meta["_dd.p.dm"] = "-3"
			s.Metrics["_dd.rule_psr"] = 1
		} else {
			s.Metrics["_sampling_priority_v1"] = -1
		}
	}
	c := ddCase{Name: "manual-drop-rule", Kind: "drop"}
	if !knownGoManualDropRule(c, ddBaselineFixture(), spans) {
		t.Fatal("did not recognize retained native evidence")
	}
	spans[0].Metrics["_sampling_priority_v1"] = 2
	if knownGoManualDropRule(c, ddBaselineFixture(), spans) {
		t.Fatal("masked a different sampling failure")
	}
	spans[0].Metrics["_sampling_priority_v1"] = -1
	if knownGoManualDropRule(c, ddBaselineFixture(), spans[1:]) {
		t.Fatal("masked lost spans")
	}
}

func TestRubyPartialChunkMetadataAtEnd(t *testing.T) {
	spans, _ := probeFixture("partial", true)
	// Ruby attaches chunk metadata to the last finished span in each chunk.
	for _, i := range []int{0, 2} {
		delete(spans[i].Meta, "_dd.p.dm")
		delete(spans[i].Metrics, "_sampling_priority_v1")
	}
	early, _ := json.Marshal([]any{map[string]any{"payload": map[string]any{"traces": [][]ddNativeSpan{spans[:2], spans[2:4]}}}})
	c := ddCase{Kind: "partial", Partial: true, ChunkMetadataPosition: "last", Env: map[string]string{"DD_TRACE_PARTIAL_FLUSH_MIN_SPANS": "2"}}
	if err := validateDatadogProbes(c, spans, early); err != nil {
		t.Fatal(err)
	}
	c.ChunkMetadataPosition = "first"
	if err := validateDatadogProbes(c, spans, early); err == nil {
		t.Fatal("accepted metadata on the wrong chunk span")
	}
}

func TestOutboundContextRestoration(t *testing.T) {
	spans, early := probeFixture("outbound", false)
	spans[2].ParentID = spans[0].SpanID
	if err := validateDatadogProbes(ddCase{Kind: "outbound"}, spans, early); err == nil {
		t.Fatal("accepted leaked outbound context")
	}
}

func TestPartialReconstructionPreservesNativeTiming(t *testing.T) {
	spans, early := probeFixture("partial", true)
	spans[0].Duration++
	if err := validateDatadogProbes(ddCase{Kind: "partial", Partial: true}, spans, early); err == nil {
		t.Fatal("accepted changed duration in reconstructed chunk")
	}
}
