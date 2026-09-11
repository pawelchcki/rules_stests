package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"reflect"
	"time"
)

var ddEarlyCapture []byte
var ddProbeSink, ddProbeOutput string

func ddProbeCases() []ddCase {
	keep, drop := 2, -1
	result := []ddCase{
		{Name: "head", Kind: "echo", Method: "HEAD", Source: "test_tracer.py"},
		{Name: "query-redaction", Kind: "echo", Query: "token=probe-secret&safe=visible", Source: "test_tracer.py", Env: map[string]string{"DD_HTTP_SERVER_TAG_QUERY_STRING": "true", "DD_TRACE_OBFUSCATION_QUERY_STRING_REGEXP": "token=[^&]*"}},
		{Name: "nested", Kind: "nested", Source: "test_tracer.py"},
		{Name: "manual-keep", Kind: "keep", Priority: &keep, Source: "test_sampling_manual.py"},
		{Name: "manual-drop", Kind: "drop", Priority: &drop, Source: "test_sampling_manual.py"},
		{Name: "exception", Kind: "exception", Source: "test_tracer.py"},
		{Name: "outbound", Kind: "outbound", Source: "test_headers_datadog.py"},
	}
	for _, threshold := range []string{"1", "2", "1000"} {
		result = append(result, ddCase{Name: "partial-" + threshold, Kind: "partial", Partial: threshold != "1000", Source: "test_partial_flushing.py", Env: map[string]string{"DD_TRACE_PARTIAL_FLUSH_ENABLED": "true", "DD_TRACE_PARTIAL_FLUSH_MIN_SPANS": threshold}})
	}
	result = append(result, ddCase{Name: "partial-disabled", Kind: "partial", Source: "test_partial_flushing.py", Env: map[string]string{"DD_TRACE_PARTIAL_FLUSH_ENABLED": "false", "DD_TRACE_PARTIAL_FLUSH_MIN_SPANS": "1"}})
	for i := range result {
		if result[i].Env == nil {
			result[i].Env = map[string]string{}
		}
		result[i].Env["RULES_STESTS_PROBES"] = "true"
	}
	return result
}

func ddPartialWorkload(base string, req *http.Request) error {
	done := make(chan error, 1)
	go func() {
		resp, err := client.Do(req)
		if err == nil {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			if resp.StatusCode != 200 {
				err = fmt.Errorf("held parent returned %d", resp.StatusCode)
			}
		}
		done <- err
	}()
	held := false
	for deadline := time.Now().Add(5 * time.Second); time.Now().Before(deadline); {
		resp, err := client.Get(base + "/__rules_stests/state?key=held")
		if err != nil {
			return err
		}
		var state struct {
			Held bool `json:"held"`
		}
		err = json.NewDecoder(resp.Body).Decode(&state)
		resp.Body.Close()
		if err != nil {
			return err
		}
		if state.Held {
			held = true
			break
		}
		time.Sleep(25 * time.Millisecond)
	}
	if !held {
		return fmt.Errorf("parent never entered held state")
	}
	// Give the writer several periods while the HTTP parent is definitely open.
	time.Sleep(2500 * time.Millisecond)
	var err error
	ddEarlyCapture, err = request("GET", protocolEndpoint(ddProbeSink, "/dump"), nil)
	if err != nil {
		return err
	}
	if err = os.WriteFile(filepath.Join(ddProbeOutput, activeDatadogCase.Name+".early.capture.json"), ddEarlyCapture, 0644); err != nil {
		return err
	}
	resp, err := client.Get(base + "/__rules_stests/release?key=held")
	if err != nil {
		return err
	}
	io.Copy(io.Discard, resp.Body)
	resp.Body.Close()
	select {
	case err := <-done:
		return err
	case <-time.After(5 * time.Second):
		return fmt.Errorf("held parent did not finish after release")
	}
}

func ddProbeURL(base, kind string) string {
	target := base + "/__rules_stests/" + kind
	if kind == "outbound" {
		target += "?url=" + url.QueryEscape(base+"/__rules_stests/echo")
	}
	if kind == "partial" {
		target += "?key=held"
	}
	return target
}

// The graph includes native framework spans between the HTTP root and probes.
// Walk those edges, retaining the full trace identity inherited by each chunk.
func validateDatadogProbes(c ddCase, spans []ddNativeSpan, early []byte) error {
	type identity struct {
		low  uint64
		high string
		span uint64
	}
	index := map[identity]ddNativeSpan{}
	for _, s := range spans {
		key := identity{s.TraceID, s.Meta["_dd.p.tid"], s.SpanID}
		if _, ok := index[key]; ok {
			return fmt.Errorf("duplicate probe span")
		}
		index[key] = s
	}
	ancestor := func(child, parent ddNativeSpan) bool {
		for n := 0; n < 64; n++ {
			if child.TraceID != parent.TraceID || child.Meta["_dd.p.tid"] != parent.Meta["_dd.p.tid"] {
				return false
			}
			if child.ParentID == parent.SpanID {
				return true
			}
			next, ok := index[identity{child.TraceID, child.Meta["_dd.p.tid"], child.ParentID}]
			if !ok {
				return false
			}
			child = next
		}
		return false
	}
	servers := ddServers(spans)
	expected := 4
	if c.Kind == "partial" {
		expected = 1
	}
	parents, children, after, clients, echoes := 0, 0, 0, 0, 0
	for _, root := range servers {
		perParent, perChild, perAfter, perClient, perEcho := 0, 0, 0, 0, 0
		var parent ddNativeSpan
		for _, s := range spans {
			if !ancestor(s, root) {
				continue
			}
			switch s.Name {
			case "probe.parent":
				perParent++
				parent = s
				if s.Resource != c.Kind {
					return fmt.Errorf("incorrect probe resource")
				}
			case "probe.child":
				perChild++
			case "probe.after_outbound":
				perAfter++
			}
			if s.Type == "http" {
				perClient++
			}
			if (s.Name == "aiohttp.request" || s.Name == "django.request" || s.Name == "rack.request" || s.Name == "gin.request" || s.Name == "http.request") && s.Type == "web" && s.Meta["probe.request_id"] == "" {
				perEcho++
			}
		}
		if c.Kind == "nested" || c.Kind == "keep" || c.Kind == "drop" || c.Kind == "partial" {
			if perParent != 1 || perChild != 3 {
				return fmt.Errorf("missing or extra nested probe spans")
			}
			indices := map[string]bool{}
			for _, s := range spans {
				if s.Name != "probe.child" || !ancestor(s, root) {
					continue
				}
				if s.ParentID != parent.SpanID || s.Error != 0 || s.Resource != s.Meta["probe.index"] || indices[s.Resource] || (s.Resource != "0" && s.Resource != "1" && s.Resource != "2") {
					return fmt.Errorf("incorrect child parentage/metadata/multiplicity")
				}
				indices[s.Resource] = true
			}
		}
		if c.Kind == "exception" {
			errors := 0
			for _, s := range spans {
				if s.Name == "probe.exception" && ancestor(s, root) {
					if s.Error != 1 || s.Meta["error.type"] == "" || s.Meta["error.message"] != "controlled rules_stests exception" || (s.Meta["error.stack"] == "" && s.Meta["error.handling_stack"] == "") {
						return fmt.Errorf("missing native exception metadata")
					}
					errors++
				}
			}
			if root.Error != 1 || errors != 1 {
				return fmt.Errorf("missing native exception span")
			}
		}
		if c.Kind == "outbound" {
			if perClient != 1 || perEcho != 1 || perAfter != 1 {
				return fmt.Errorf("incorrect outbound client/server multiplicities: %d/%d/%d", perClient, perEcho, perAfter)
			}
			var outbound ddNativeSpan
			for _, s := range spans {
				if ancestor(s, root) && s.Type == "http" {
					outbound = s
				}
			}
			for _, s := range spans {
				if !ancestor(s, root) {
					continue
				}
				if s.Name == "probe.after_outbound" && ancestor(s, outbound) {
					return fmt.Errorf("outbound context was not restored")
				}
				if s.Type == "web" && s.Meta["probe.request_id"] == "" && s.ParentID != outbound.SpanID {
					return fmt.Errorf("outbound server did not extract client parent")
				}
			}
		}
		parents += perParent
		children += perChild
		after += perAfter
		clients += perClient
		echoes += perEcho
	}
	// Count all custom spans too: an orphan must not disappear from the walk.
	for _, s := range spans {
		switch s.Name {
		case "probe.parent":
			parents--
		case "probe.child":
			children--
		case "probe.after_outbound":
			after--
		}
	}
	if parents != 0 || children != 0 || after != 0 || len(servers) != expected {
		return fmt.Errorf("orphan or missing probe spans")
	}
	if c.Kind == "partial" {
		if c.Partial {
			var records []struct {
				Payload struct {
					Traces [][]ddNativeSpan `json:"traces"`
				} `json:"payload"`
			}
			if err := json.Unmarshal(early, &records); err != nil {
				return err
			}
			for _, record := range records {
				for _, chunk := range record.Payload.Traces {
					probe := false
					for _, span := range chunk {
						if span.Name == "probe.parent" || span.Name == "probe.child" {
							probe = true
						}
					}
					if !probe {
						continue
					}
					first := chunk[0]
					if len(first.Meta["_dd.p.tid"]) != 16 || first.Meta["_dd.p.dm"] != "-3" || first.Metrics["_sampling_priority_v1"] != 2 {
						return fmt.Errorf("missing partial chunk propagation/sampling metadata")
					}
					for _, later := range chunk[1:] {
						if later.Meta["_dd.p.dm"] != "" {
							return fmt.Errorf("chunk propagation metadata repeated after first span")
						}
					}
				}
			}
		}
		captured, err := decodeDatadog(early)
		if err != nil {
			return err
		}
		p, ch := 0, 0
		for _, s := range captured {
			final, ok := index[identity{s.TraceID, s.Meta["_dd.p.tid"], s.SpanID}]
			if !ok || !reflect.DeepEqual(s, final) {
				return fmt.Errorf("partial chunk was lost or changed during reconstruction")
			}
			if s.Meta["probe.request_id"] != "" {
				return fmt.Errorf("held HTTP parent finished before early capture")
			}
			if s.Name == "probe.parent" {
				p++
			}
			if s.Name == "probe.child" {
				ch++
			}
		}
		if c.Partial {
			if p != 1 || ch != 3 {
				return fmt.Errorf("partial flush lost finished children: %d/%d", p, ch)
			}
		} else if p != 0 || ch != 0 {
			return fmt.Errorf("disabled/large-threshold partial flush exported children early")
		}
	}
	return nil
}
