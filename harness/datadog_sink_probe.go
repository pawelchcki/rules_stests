// Native intake conformance exercises the public HTTP and Scheme interfaces.
package main

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"math"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

var ddEndpoint string
var ddAssertions []byte
var ddClient = http.DefaultClient

func main() {
	suffix := flag.String("service-suffix", "telemetry_sink_service", "assigned sink service suffix")
	assertions := flag.String("assertions", "", "Datadog capture assertion library")
	compiler := flag.String("compiler", "", "Scheme compiler executable")
	contractErrors := flag.String("contract-errors", "", "Shared contract error library")
	flag.Parse()
	var ports map[string]json.RawMessage
	must(json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports))
	for label, raw := range ports {
		if strings.HasSuffix(label, *suffix) {
			var port int
			if json.Unmarshal(raw, &port) != nil {
				var s string
				must(json.Unmarshal(raw, &s))
				port, _ = strconv.Atoi(s)
			}
			ddEndpoint = fmt.Sprintf("http://127.0.0.1:%d", port)
		}
	}
	if ddEndpoint == "" {
		panic("missing assigned sink port")
	}
	var err error
	ddAssertions, err = os.ReadFile(*assertions)
	must(err)
	if *contractErrors != "" {
		shared, err := os.ReadFile(*contractErrors)
		must(err)
		ddAssertions = append(append(shared, byte('\n')), ddAssertions...)
	}
	info := request("GET", "/info", "", nil, 200)
	if !bytes.Contains(info, []byte("/v0.5/traces")) || bytes.Contains(info, []byte("/v0.3")) {
		panic("incorrect advertised capabilities")
	}
	for _, version := range []string{"v0.4", "v0.5"} {
		for _, method := range []string{"POST", "PUT"} {
			reset()
			body := wire(version, nativeSpan())
			response := request(method, "/"+version+"/traces", "application/msgpack", body, 200)
			if string(response) != "{\"rate_by_service\":{}}\n" {
				panic("missing sampling acknowledgement")
			}
			validate("span/native-fields span/ids-valid span/completed span/http-classification span/exception-metadata request/headers-and-counts capture/semantic-valid", 200)
			scheme := request("GET", "/dump.scm?protocol=datadog", "", nil, 200)
			for _, exact := range []string{"18446744073709551615", "18446744073709551614", "1800000000000000001", "4bf92f3577b34da6"} {
				if !bytes.Contains(scheme, []byte("\""+exact+"\"")) {
					panic("integer/tag precision lost: " + exact)
				}
			}
			checkStats("datadog", 1, 1)
			candidate := request("GET", "/candidate?app=aiohttp&scenario=probe&protocol=datadog", "", nil, 200)
			source := append([]byte{}, ddAssertions...)
			source = append(source, []byte("\n(import (scheme base) (scheme read) (datadog capture shapes))\n")...)
			source = append(source, candidate...)
			source = append(source, []byte("\n(check (equal? scenario-shape (field 'trace-shapes (read))) \"exact topology\")")...)
			request("POST", "/validate?protocol=datadog", "text/x-scheme", source, 200)
			source = bytes.Replace(source, []byte("(count 1)"), []byte("(count 2)"), 1)
			request("POST", "/validate?protocol=datadog", "text/x-scheme", source, 409)
		}
	}
	if *compiler != "" {
		compiledEquivalence(*compiler)
	}
	exactMutationCoverage()
	// v0.4 omits zero/empty defaults. Native dumps preserve absence and exact
	// topology records that field-presence difference.
	reset()
	defaults := nativeSpan()
	defaults["name"], defaults["type"], defaults["metrics"] = "aiohttp.request", "", map[string]any{}
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", defaults), 200)
	explicitShape := request("GET", "/candidate?app=aiohttp&scenario=probe&protocol=datadog", "", nil, 200)
	reset()
	for _, field := range []string{"parent_id", "error", "type", "metrics"} {
		delete(defaults, field)
	}
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", defaults), 200)
	validate("span/native-fields span/ids-valid span/completed capture/semantic-valid", 200)
	omittedShape := request("GET", "/candidate?app=aiohttp&scenario=probe&protocol=datadog", "", nil, 200)
	if bytes.Equal(explicitShape, omittedShape) {
		panic("omitted v0.4 defaults lost exact field-presence evidence")
	}
	dump := request("GET", "/dump?protocol=datadog", "", nil, 200)
	for _, field := range []string{"parent_id", "error", "type", "metrics"} {
		if bytes.Contains(dump, []byte(`"`+field+`":`)) {
			panic("raw v0.4 capture synthesized field " + field)
		}
	}
	// v0.4 JSON independently retains unsigned integer precision.
	reset()
	encoded, err := json.Marshal([]any{[]any{nativeSpan()}})
	must(err)
	request("POST", "/v0.4/traces", "application/json", encoded, 200)
	validate("span/native-fields span/ids-valid span/completed capture/semantic-valid", 200)
	request("POST", "/v0.5/traces", "application/json", encoded, 400)
	request("POST", "/v0.4/traces", "application/msgpack", []byte{0xc1}, 400)
	request("POST", "/v0.4/traces", "application/msgpack", []byte{0x91, 0x91}, 400)
	request("POST", "/v0.4/traces", "application/msgpack", []byte{0x90, 0x90}, 400)
	request("POST", "/v0.4/traces", "application/msgpack", []byte{0xdd, 0xff, 0xff, 0xff, 0xff}, 400)
	request("POST", "/v0.4/traces", "application/msgpack", bytes.Repeat([]byte{0x91}, 100), 400)
	request("POST", "/v0.4/traces", "application/msgpack", []byte{0x81, 0xa1, 0xff, 0x00}, 400)
	invalidDictionary := []any{[]any{""}, []any{[]any{[]any{uint64(9), 0, 0, 1, 2, 0, 1, 1, 0, map[string]any{}, map[string]any{}, 0}}}}
	request("POST", "/v0.5/traces", "application/msgpack", pack(invalidDictionary), 400)
	invalidDictionaryKeys := []any{[]any{""}, []any{[]any{[]any{uint64(0), 0, 0, 1, 2, 0, 1, 1, 0, map[string]any{"\x01index:0": uint64(0)}, map[uint64]any{}, 0}}}}
	request("POST", "/v0.5/traces", "application/msgpack", pack(invalidDictionaryKeys), 400)
	// A compact v0.5 dictionary cannot expand into unbounded native storage.
	largeSpans := []any{}
	for i := 0; i < 20; i++ {
		largeSpans = append(largeSpans, []any{uint64(0), 0, 0, 1, 2, 0, 1, 1, 0, map[uint64]any{}, map[uint64]any{}, 0})
	}
	request("POST", "/v0.5/traces", "application/msgpack", pack([]any{[]any{strings.Repeat("a", 60000)}, []any{largeSpans}}), 400)
	// Every decodable semantic failure is retained and rejected by Scheme.
	mutations := []struct {
		name      string
		mutate    func(map[string]any)
		assertion string
	}{
		{"null parent", func(s map[string]any) { s["parent_id"] = nil }, "capture/semantic-valid"},
		{"wrong parent type", func(s map[string]any) { s["parent_id"] = "0" }, "capture/semantic-valid"},
		{"null error", func(s map[string]any) { s["error"] = nil }, "capture/semantic-valid"},
		{"wrong error type", func(s map[string]any) { s["error"] = "0" }, "capture/semantic-valid"},
		{"null type", func(s map[string]any) { s["type"] = nil }, "capture/semantic-valid"},
		{"wrong type type", func(s map[string]any) { s["type"] = 0 }, "capture/semantic-valid"},
		{"null metrics", func(s map[string]any) { s["metrics"] = nil }, "capture/semantic-valid"},
		{"wrong metrics type", func(s map[string]any) { s["metrics"] = "" }, "capture/semantic-valid"},
		{"zero ID", func(s map[string]any) { s["span_id"] = uint64(0) }, "span/ids-valid"},
		{"negative duration", func(s map[string]any) { s["duration"] = int64(-1) }, "span/completed"},
		{"missing name", func(s map[string]any) { delete(s, "name") }, "span/native-fields"},
		{"invalid error", func(s map[string]any) { s["error"] = 2 }, "capture/semantic-valid"},
		{"4xx error", func(s map[string]any) { s["error"] = 1 }, "span/http-classification"},
		{"partial exception", func(s map[string]any) { s["meta"].(map[string]any)["error.type"] = "ValueError"; s["error"] = 1 }, "span/exception-metadata"},
		{"invalid meta", func(s map[string]any) { s["meta"].(map[string]any)["bad"] = 3 }, "capture/semantic-valid"},
		{"invalid tid", func(s map[string]any) { s["meta"].(map[string]any)["_dd.p.tid"] = "no" }, "capture/semantic-valid"},
		{"malformed runtime id", func(s map[string]any) { s["meta"].(map[string]any)["runtime-id"] = "no" }, "capture/semantic-valid"},
		{"misplaced runtime id separator", func(s map[string]any) { s["meta"].(map[string]any)["runtime-id"] = "01234567-89abcdef0123456789abcdef" }, "capture/semantic-valid"},
		{"invalid loopback port", func(s map[string]any) { s["meta"].(map[string]any)["http.url"] = "http://127.0.0.1:999999/api/tags" }, "capture/semantic-valid"},
		{"malformed process id", func(s map[string]any) { s["metrics"].(map[string]any)["process_id"] = 0 }, "capture/semantic-valid"},
		{"additional native field", func(s map[string]any) { s["private"] = "unclassified" }, "capture/semantic-valid"},
		{"self cycle", func(s map[string]any) { s["parent_id"] = s["span_id"] }, "capture/semantic-valid"},
	}
	for _, tc := range mutations {
		reset()
		span := nativeSpan()
		tc.mutate(span)
		request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", span), 200)
		validate(tc.assertion, 409)
		checkStats("datadog", 1, 1)
	}

	reset()
	goError := nativeSpan()
	goError["error"] = 1
	meta := goError["meta"].(map[string]any)
	meta["language"] = "go"
	meta["error.type"] = "*errors.errorString"
	meta["error.message"] = "controlled"
	meta["error.handling_stack"] = "example/fixture.failure\n\tfixture.go:12"
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", goError), 200)
	validate("span/exception-metadata capture/semantic-valid", 200)
	reset()
	meta["error.handling_stack"] = "invalid stack"
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", goError), 200)
	validate("capture/semantic-valid", 409)
	reset()
	duplicate := nativeSpan()
	request("POST", "/v0.4/traces", "application/msgpack", pack([]any{[]any{duplicate, duplicate}}), 200)
	validate("capture/semantic-valid", 409)
	// Same low trace ID and span ID in two 128-bit traces remain independent.
	reset()
	first, second := nativeSpan(), nativeSpan()
	second["meta"].(map[string]any)["_dd.p.tid"] = "8c1e0a5b6d2f4739"
	request("POST", "/v0.4/traces", "application/msgpack", pack([]any{[]any{first}, []any{second}}), 200)
	validate("capture/semantic-valid", 200)
	checkStats("datadog", 1, 2)
	reset()
	request("POST", "/v0.4/traces", "application/msgpack", pack([]any{[]any{first, second}}), 200)
	validate("capture/semantic-valid", 409)

	// A completed child may arrive before its held parent in another intake.
	reset()
	parent, child := nativeSpan(), nativeSpan()
	parent["parent_id"] = uint64(0)
	child["span_id"] = uint64(77)
	child["parent_id"] = parent["span_id"]
	child["name"] = "sqlite.query"
	child["type"] = "sql"
	child["resource"] = "SELECT 1"
	delete(child["meta"].(map[string]any), "_dd.p.tid")
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", child), 200)
	request("GET", "/dump?protocol=datadog", "", nil, 200)
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", parent), 200)
	validate("capture/semantic-valid span/database-children", 200)
	// Parentage, not shared low bits, resolves an untagged partial chunk.
	other := nativeSpan()
	other["span_id"] = uint64(999)
	other["meta"].(map[string]any)["_dd.p.tid"] = "8c1e0a5b6d2f4739"
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", other), 200)
	validate("capture/semantic-valid span/database-children", 200)
	// If two full trace identities can own the same untagged child, reject it.
	other["span_id"] = parent["span_id"]
	reset()
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", child), 200)
	request("POST", "/v0.4/traces", "application/msgpack", pack([]any{[]any{parent}, []any{other}}), 200)
	validate("capture/semantic-valid", 409)
	// Empty and structurally malformed JSON are decodable diagnostic evidence.
	reset()
	request("POST", "/v0.4/traces", "application/json", []byte(`{"unexpected":true}`), 200)
	validate("capture/semantic-valid", 409)
	// Large native batches must acknowledge within the actual tracer's 2s
	// timeout. Full-heap allocator scans previously exceeded this deadline.
	reset()
	largeTrace := make([]map[string]any, 1000)
	for i := range largeTrace {
		span := nativeSpan()
		span["span_id"] = uint64(i + 1)
		if i > 0 {
			span["parent_id"] = uint64(1)
		}
		largeTrace[i] = span
	}
	largeBatch := wireSpans("v0.5", largeTrace)
	ddClient = &http.Client{Timeout: 2 * time.Second}
	request("POST", "/v0.5/traces", "application/msgpack", largeBatch, 200)
	ddClient = http.DefaultClient
	checkStats("datadog", 1, 1000)
	validate("request/headers-and-counts span/native-fields span/ids-valid span/completed capture/semantic-valid", 200)
	// Reviewed Datadog topology sources can exceed the legacy OTel budget.
	reset()
	largeSource := []byte(";" + strings.Repeat(" ", 300*1024) + "\n(import (scheme base))\n#t\n")
	request("POST", "/validate?protocol=datadog", "text/x-scheme", largeSource, 200)
	rejectOversizedValidation(len(largeSource))
	// Explicit OTLP and unqualified endpoints retain the legacy state independently.
	reset()
	request("POST", "/reset", "", nil, 200)
	request("POST", "/v1/traces", "application/json", []byte(`{"resourceSpans":[]}`), 200)
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", nativeSpan()), 200)
	request("GET", "/dump?protocol=datadog", "", nil, 200)
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", nativeSpan()), 200)
	checkStats("otlp", 1, 0)
	checkStats("datadog", 2, 2)
	request("POST", "/reset/traces-and-metrics?protocol=datadog", "", nil, 200)
	checkStats("datadog", 0, 0)
	checkStats("otlp", 1, 0)
	if string(request("GET", "/dump", "", nil, 200)) != string(request("GET", "/dump?protocol=otlp", "", nil, 200)) {
		panic("legacy dump changed")
	}
	request("POST", "/v1/traces?protocol=datadog", "application/json", []byte(`{"resourceSpans":[]}`), 400)
	request("POST", "/v0.4/traces?protocol=otlp", "application/msgpack", wire("v0.4", nativeSpan()), 400)
	request("POST", "/v0.4/traces", "application/json", []byte(`[[{"name":"one","name":"two"}]]`), 400)
	request("POST", "/v0.4/traces", "application/json", []byte(strings.Repeat("[", 40)+strings.Repeat("]", 40)), 400)
	request("POST", "/validate?protocol=unknown", "text/x-scheme", nil, 400)
	fmt.Println("Datadog native intake conformance passed")
}

// Send only the headers: the sink correctly rejects before consuming an
// oversized body, which can otherwise race Go's request writer with TCP reset.
func rejectOversizedValidation(length int) {
	conn, err := net.DialTimeout("tcp", strings.TrimPrefix(ddEndpoint, "http://"), 2*time.Second)
	must(err)
	defer conn.Close()
	must(conn.SetDeadline(time.Now().Add(2 * time.Second)))
	_, err = fmt.Fprintf(conn, "POST /validate HTTP/1.1\r\nHost: localhost\r\nContent-Type: text/x-scheme\r\nContent-Length: %d\r\n\r\n", length)
	must(err)
	response, err := http.ReadResponse(bufio.NewReader(conn), nil)
	must(err)
	defer response.Body.Close()
	if response.StatusCode != http.StatusRequestEntityTooLarge {
		panic("legacy validation source budget changed")
	}
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
func reset() { request("POST", "/reset?protocol=datadog", "", nil, 200) }
func request(method, path, contentType string, body []byte, status int) []byte {
	req, err := http.NewRequest(method, ddEndpoint+path, bytes.NewReader(body))
	must(err)
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}
	req.Header.Set("Datadog-Meta-Lang", "python")
	req.Header.Set("Datadog-Meta-Tracer-Version", "4.14.0")
	req.Header.Set("X-Datadog-Trace-Count", "1")
	res, err := ddClient.Do(req)
	must(err)
	defer res.Body.Close()
	data, err := io.ReadAll(res.Body)
	must(err)
	if res.StatusCode != status {
		panic(fmt.Sprintf("%s %s: expected %d got %d: %s", method, path, status, res.StatusCode, data))
	}
	return data
}
func validate(assertions string, status int) {
	source := append([]byte{}, ddAssertions...)
	source = append(source, []byte("\n(import (scheme base) (scheme read) (datadog capture shapes))\n(define capture (read))\n")...)
	for _, assertion := range strings.Fields(assertions) {
		source = append(source, []byte(fmt.Sprintf("(assert-capture-shape \"probe\" '%s capture)\n", assertion))...)
	}
	request("POST", "/validate?protocol=datadog", "text/x-scheme", source, status)
}
func checkStats(protocol string, requests, spans int) {
	var stats map[string]any
	must(json.Unmarshal(request("GET", "/stats?protocol="+protocol, "", nil, 200), &stats))
	if stats["trace_requests"] != float64(requests) || stats["trace_spans"] != float64(spans) {
		panic(fmt.Sprintf("%s stats mismatch: %v", protocol, stats))
	}
}
func nativeSpan() map[string]any {
	return map[string]any{
		"service": "probe", "name": "aiohttp.request", "resource": "GET /missing", "type": "web",
		"trace_id": uint64(math.MaxUint64), "span_id": uint64(math.MaxUint64 - 1), "parent_id": uint64(0),
		"start": uint64(1800000000000000001), "duration": uint64(120001), "error": 0,
		"meta":    map[string]any{"http.method": "GET", "http.status_code": "404", "component": "aiohttp", "span.kind": "server", "_dd.p.tid": "4bf92f3577b34da6"},
		"metrics": map[string]any{"_dd.measured": 1, "_sampling_priority_v1": 1},
	}
}

// Exercise the reviewed HTTP/database shape as one exact comparison program.
// Semantically valid mutations must produce distinct shapes; a trace without
// its HTTP server span must not be eligible for candidate generation at all.
func exactMutationCoverage() {
	type mutation struct {
		name   string
		mutate func([]map[string]any) []map[string]any
	}
	mutations := []mutation{
		{"dropped database span", func(spans []map[string]any) []map[string]any { return spans[:1] }},
		{"extra database span", func(spans []map[string]any) []map[string]any {
			extra := databaseSpan(uint64(math.MaxUint64-4), uint64(math.MaxUint64-1), "SELECT 1")
			return append(spans, extra)
		}},
		{"detached commit", func(spans []map[string]any) []map[string]any { spans[2]["parent_id"] = uint64(0); return spans }},
		{"wrong database parent", func(spans []map[string]any) []map[string]any { spans[1]["parent_id"] = uint64(12345); return spans }},
		{"altered SQL", func(spans []map[string]any) []map[string]any {
			spans[1]["resource"] = "SELECT title FROM articles WHERE slug = 'changed'"
			return spans
		}},
		{"altered row count", func(spans []map[string]any) []map[string]any {
			spans[1]["metrics"].(map[string]any)["db.row_count"] = 2
			return spans
		}},
		{"altered HTTP URL", func(spans []map[string]any) []map[string]any {
			spans[0]["meta"].(map[string]any)["http.url"] = "http://127.0.0.1:9000/changed?literal=1"
			return spans
		}},
		{"altered user agent", func(spans []map[string]any) []map[string]any {
			spans[0]["meta"].(map[string]any)["http.useragent"] = "mutation-agent"
			return spans
		}},
		{"altered Django metadata", func(spans []map[string]any) []map[string]any {
			spans[0]["meta"].(map[string]any)["django.view"] = "changed:view"
			return spans
		}},
		{"missing metadata field", func(spans []map[string]any) []map[string]any {
			delete(spans[0]["meta"].(map[string]any), "http.useragent")
			return spans
		}},
		{"additional private tag", func(spans []map[string]any) []map[string]any {
			spans[1]["meta"].(map[string]any)["_private.unreviewed"] = "present"
			return spans
		}},
	}

	reset()
	request("POST", "/v0.4/traces", "application/msgpack", wireSpans("v0.4", richTrace()), 200)
	baseline := request("GET", "/candidate?app=aiohttp&scenario=mutations&protocol=datadog", "", nil, 200)
	for _, literal := range []string{"slug = 'literal'", "include=author", "keep-rules-stests-literal"} {
		if !bytes.Contains(baseline, []byte(literal)) {
			panic("exact candidate normalized stable context: " + literal)
		}
	}
	source := append([]byte{}, ddAssertions...)
	source = append(source, []byte("\n(import (scheme base) (scheme read) (datadog capture shapes))\n")...)
	source = append(source, baseline...)
	source = append(source, []byte("(define actual-shape (field 'trace-shapes (read)))\n(check (equal? scenario-shape actual-shape) \"mutation baseline\")\n")...)

	for _, tc := range mutations {
		reset()
		spans := tc.mutate(richTrace())
		request("POST", "/v0.4/traces", "application/msgpack", wireSpans("v0.4", spans), 200)
		candidate := request("GET", "/candidate?app=aiohttp&scenario=mutations&protocol=datadog", "", nil, 200)
		shape := candidateDatum(candidate)
		source = append(source, []byte("(check (not (equal? ")...)
		source = append(source, shape...)
		source = append(source, []byte(" actual-shape)) ")...)
		source = append(source, strconv.AppendQuote(nil, tc.name)...)
		source = append(source, []byte(")\n")...)
	}

	reset()
	withoutHTTP := richTrace()[1:]
	request("POST", "/v0.4/traces", "application/msgpack", wireSpans("v0.4", withoutHTTP), 200)
	request("GET", "/candidate?app=aiohttp&scenario=mutations&protocol=datadog", "", nil, 422)

	reset()
	request("POST", "/v0.4/traces", "application/msgpack", wireSpans("v0.4", richTrace()), 200)
	request("POST", "/validate?app=aiohttp&scenario=mutations&protocol=datadog", "text/x-scheme", source, 200)
}

func candidateDatum(candidate []byte) []byte {
	start := bytes.IndexByte(candidate, '\'')
	if start < 0 || len(candidate) < start+3 || !bytes.HasSuffix(candidate, []byte(")\n")) {
		panic("malformed Datadog candidate source")
	}
	return candidate[start : len(candidate)-2]
}

func richTrace() []map[string]any {
	root := nativeSpan()
	root["resource"] = "GET /api/articles/{slug}"
	root["meta"].(map[string]any)["http.url"] = "http://127.0.0.1:9000/api/articles/literal?include=author"
	root["meta"].(map[string]any)["http.useragent"] = "hurl/8.0.1"
	root["meta"].(map[string]any)["django.view"] = "api-1.0.0:retrieve"
	root["meta"].(map[string]any)["test.context"] = "keep-rules-stests-literal"
	query := databaseSpan(uint64(math.MaxUint64-2), uint64(math.MaxUint64-1), "SELECT title FROM articles WHERE slug = 'literal'")
	commit := databaseSpan(uint64(math.MaxUint64-3), uint64(math.MaxUint64-2), "COMMIT")
	commit["name"], commit["type"], commit["resource"] = "sqlite.connection.commit", "", "sqlite.connection.commit"
	return []map[string]any{root, query, commit}
}

func databaseSpan(id, parent uint64, resource string) map[string]any {
	return map[string]any{
		"service": "sqlite", "name": "sqlite.query", "resource": resource, "type": "sql",
		"trace_id": uint64(math.MaxUint64), "span_id": id, "parent_id": parent,
		"start": uint64(1800000000000000002), "duration": uint64(12000), "error": 0,
		"meta":    map[string]any{"_dd.base_service": "probe", "component": "sqlite", "span.kind": "client", "sql.db": "/tmp/rules_stests_fixture/realworld.sqlite3"},
		"metrics": map[string]any{"db.row_count": 1},
	}
}
func wire(version string, span map[string]any) []byte {
	return wireSpans(version, []map[string]any{span})
}
func wireSpans(version string, spans []map[string]any) []byte {
	if version == "v0.4" {
		chunk := []any{}
		for _, span := range spans {
			chunk = append(chunk, span)
		}
		return pack([]any{chunk})
	}
	dictionary := []any{""}
	indexes := map[string]uint64{"": 0}
	index := func(s string) uint64 {
		if i, ok := indexes[s]; ok {
			return i
		}
		i := uint64(len(dictionary))
		indexes[s] = i
		dictionary = append(dictionary, s)
		return i
	}
	encodedSpans := []any{}
	for _, span := range spans {
		fields := []any{}
		for _, key := range []string{"service", "name", "resource", "trace_id", "span_id", "parent_id", "start", "duration", "error", "meta", "metrics", "type"} {
			value := span[key]
			switch key {
			case "service", "name", "resource", "type":
				value = index(value.(string))
			case "meta", "metrics":
				converted := map[uint64]any{}
				original := value.(map[string]any)
				keys := []string{}
				for key := range original {
					keys = append(keys, key)
				}
				sort.Strings(keys)
				for _, k := range keys {
					v := original[k]
					if key == "meta" {
						v = index(v.(string))
					}
					converted[index(k)] = v
				}
				value = converted
			}
			fields = append(fields, value)
		}
		encodedSpans = append(encodedSpans, fields)
	}
	return pack([]any{dictionary, []any{encodedSpans}})
}
func pack(value any) []byte {
	out := []byte{}
	appendLength := func(tag byte, n int) { out = append(out, tag, byte(n>>8), byte(n)) }
	switch v := value.(type) {
	case nil:
		out = append(out, 0xc0)
	case int:
		return pack(int64(v))
	case int64:
		out = append(out, 0xd3)
		out = binary.BigEndian.AppendUint64(out, uint64(v))
	case uint64:
		out = append(out, 0xcf)
		out = binary.BigEndian.AppendUint64(out, v)
	case string:
		appendLength(0xda, len(v))
		out = append(out, []byte(v)...)
	case []any:
		appendLength(0xdc, len(v))
		for _, v := range v {
			out = append(out, pack(v)...)
		}
	case map[string]any:
		appendLength(0xde, len(v))
		keys := []string{}
		for k := range v {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			out = append(out, pack(k)...)
			out = append(out, pack(v[k])...)
		}
	case map[uint64]any:
		appendLength(0xde, len(v))
		keys := []uint64{}
		for k := range v {
			keys = append(keys, k)
		}
		sort.Slice(keys, func(i, j int) bool { return keys[i] < keys[j] })
		for _, k := range keys {
			out = append(out, pack(k)...)
			out = append(out, pack(v[k])...)
		}
	default:
		panic(fmt.Sprintf("unsupported test value %T", value))
	}
	return out
}

func compiledEquivalence(compiler string) {
	reset()
	request("POST", "/v0.4/traces", "application/msgpack", wire("v0.4", nativeSpan()), 200)
	directory, err := os.MkdirTemp("", "compiled-equivalence-")
	must(err)
	defer os.RemoveAll(directory)
	for _, failure := range []bool{false, true} {
		source := append([]byte{}, ddAssertions...)
		source = append(source, []byte("\n(import (scheme base) (scheme read) (datadog capture shapes))\n(check (pair? (read)) \"capture\")\n")...)
		status := 200
		if failure {
			source = append(source, []byte("(check #f \"deliberate mutation\")")...)
			status = 409
		}
		input, output := filepath.Join(directory, "source.scm"), filepath.Join(directory, "validator.sbc")
		must(os.WriteFile(input, source, 0600))
		result, err := exec.Command(compiler, "--compile", input, "--output", output).CombinedOutput()
		if err != nil {
			panic(fmt.Sprintf("compile: %v: %s", err, result))
		}
		bytecode, err := os.ReadFile(output)
		must(err)
		original := request("POST", "/validate?protocol=datadog", "text/x-scheme", source, status)
		compiled := request("POST", "/validate-bytecode?protocol=datadog", "application/vnd.stak.bytecode", bytecode, status)
		if !bytes.Equal(original, compiled) {
			panic("compiled/source validation differs")
		}
	}
	request("POST", "/validate-bytecode?protocol=datadog", "application/vnd.stak.bytecode", []byte{255}, 422)
}
