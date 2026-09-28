// Scheme regression probe, independent of transport decoder conformance.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/pawelchcki/rules_stests/harness/schemebytecode"
)

const capture = `'((protocol datadog) (semantic-valid #t)
 (requests (((method "POST") (wire-version "v0.5") (path "/v0.5/traces")
  (content-type "application/msgpack") (trace-count "1") (chunk-count 1) (span-count 1)
  (headers (("X-Datadog-Trace-Count" "1") ("Datadog-Meta-Lang" "python") ("Datadog-Meta-Tracer-Version" "4.14.0"))))))
 (spans (((name "aiohttp.request") (service "test-datadog") (resource "GET /api/profiles/{username}")
  (type "web") (error 0) (trace-id "18446744073709551615") (span-id "18446744073709551614") (parent-id "0")
  (start "18446744073709550000") (duration "1000") (ids-valid #t) (completed #t)
  (meta (("http.method" "GET") ("http.status_code" "404"))) (metrics (("_dd.measured" 1))))))
 (trace-shapes (((count 1) (roots (((name "aiohttp.request") (children ()))))))))`

const program = `
(import (scheme base) (datadog capture shapes) (datadog profile) (datadog catalog))
(define capture CAPTURE)
(define profile
 (realworld-profile (service-name "test-datadog") (language 'python) (tracer-version "4.14.0") (wire-version "v0.5")
  (all (observed span/native-fields span/ids-valid span/completed span/root-present
                 span/http-classification span/exception-metadata span/service-present
                 request/headers-and-counts capture/semantic-valid))))
(validate-profile profile 'unicode capture
 (cons 'exact '(((count 1) (roots (((name "aiohttp.request") (children ()))))))))
`

type testCase struct{ name, old, replacement string }

// probeCase is one validation program and the response it must produce.
type probeCase struct {
	name     string
	source   []byte
	status   int
	contains string
}

func main() {
	filter := flag.String("filter", "", "run cases whose names contain this text")
	endpoint := flag.String("endpoint", "", "sink URL, otherwise read ASSIGNED_PORTS")
	suffix := flag.String("service-suffix", "//harness:telemetry_sink_service", "sink service label suffix")
	compileTo := flag.String("compile-to", "", "write the cases' bytecode to this bundle and exit")
	compileShard := flag.String("compile-shard", "", "compile only shard k/n of the cases")
	compiler := flag.String("compiler", "", "telemetry sink used by --compile-to")
	var bytecode schemebytecode.Paths
	flag.Var(&bytecode, "bytecode", "precompiled bundle written by --compile-to (repeatable)")
	flag.Parse()
	// Positional arguments are the Scheme libraries, in dependency order.
	libraries := flag.Args()
	if len(libraries) == 0 {
		must(fmt.Errorf("usage: conformance [flags] LIBRARY..."))
	}
	// Cases that exercise one capture assertion compile only the assertion
	// libraries; the profile cases compile the whole bundle.
	var source, assertions strings.Builder
	for _, path := range libraries {
		data, err := os.ReadFile(path)
		must(err)
		source.Write(data)
		source.WriteByte('\n')
		if strings.Contains(path, "/capture/") || strings.HasSuffix(path, "/contract-error.scm") {
			assertions.Write(data)
			assertions.WriteByte('\n')
		}
	}
	var cases []probeCase
	expect := func(name, value, body string, expected int, contains string) {
		bundle := source.String()
		if !strings.Contains(body, "(datadog profile)") {
			bundle = assertions.String()
		}
		cases = append(cases, probeCase{name, []byte(bundle + strings.Replace(body, "CAPTURE", value, 1)), expected, contains})
	}
	run := func(name, value, body string, expected int) {
		contains := ""
		if expected == 200 && body == program {
			contains = "[[DATADOG-PROOF-V2|"
		}
		expect(name, value, body, expected, contains)
	}
	defineCases(run, expect)

	if *compileTo != "" {
		programs := make([]schemebytecode.Program, 0, len(cases))
		for _, tc := range cases {
			programs = append(programs, schemebytecode.Program{Name: tc.name, Source: tc.source})
		}
		programs, err := schemebytecode.Shard(programs, *compileShard)
		must(err)
		must(schemebytecode.WriteBundle(*compileTo, *compiler, programs))
		return
	}
	compiled, err := schemebytecode.ReadBundles(bytecode)
	must(err)
	if compiled != nil && len(compiled.Programs) != len(cases) {
		must(fmt.Errorf("bytecode bundles hold %d programs for %d cases", len(compiled.Programs), len(cases)))
	}
	if *endpoint == "" {
		var ports map[string]json.RawMessage
		must(json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports))
		for label, raw := range ports {
			if !strings.HasSuffix(label, *suffix) {
				continue
			}
			var port int
			if json.Unmarshal(raw, &port) != nil {
				var value string
				must(json.Unmarshal(raw, &value))
				var err error
				port, err = strconv.Atoi(value)
				must(err)
			}
			*endpoint = fmt.Sprintf("http://127.0.0.1:%d", port)
		}
	}
	if *endpoint == "" {
		must(fmt.Errorf("sink endpoint missing"))
	}
	client := &http.Client{Timeout: 60 * time.Second}
	for _, tc := range cases {
		if *filter != "" && !strings.Contains(tc.name, *filter) {
			continue
		}
		path, contentType, body := "/validate?protocol=datadog", "text/x-scheme", tc.source
		if compiled != nil {
			program, err := compiled.Bytecode(tc.name, tc.source)
			must(err)
			path, contentType, body = "/validate-bytecode?protocol=datadog", "application/vnd.stak.bytecode", program
		}
		response, err := client.Post(*endpoint+path, contentType, bytes.NewReader(body))
		must(err)
		output, err := io.ReadAll(response.Body)
		response.Body.Close()
		must(err)
		if response.StatusCode != tc.status {
			must(fmt.Errorf("%s: got HTTP %d, want %d: %s", tc.name, response.StatusCode, tc.status, output))
		}
		if !bytes.Contains(output, []byte(tc.contains)) {
			must(fmt.Errorf("%s: output lacks %q: %s", tc.name, tc.contains, output))
		}
		fmt.Println("PASS", tc.name)
	}
}

// defineCases declares every case: `run` expects a status, and `expect` also
// requires text in the response.
func defineCases(run func(name, value, body string, expected int), expect func(name, value, body string, expected int, contains string)) {
	run("unsigned IDs and default 404 classification", capture, program, 200)
	run("wide metric integers remain lossless", strings.Replace(capture,
		`("_dd.measured" 1)`, `("_dd.measured" 1) ("wide.unsigned" "18446744073709551615") ("wide.signed" "-9223372036854775808")`, 1), program, 200)
	consumerIdentity := "consumer-tracer/1.0"
	consumerProgram := strings.Replace(program, `"4.14.0"`, `"`+consumerIdentity+`"`, 1)
	consumerCapture := strings.Replace(capture, `"4.14.0"`, `"`+consumerIdentity+`"`, 1)
	run("declared consumer tracer identity", consumerCapture, consumerProgram, 200)
	run("incompatible consumer tracer identity", capture, consumerProgram, 409)
	for _, tc := range []testCase{
		{"zero trace ID", `(trace-id "18446744073709551615")`, `(trace-id "0")`},
		{"overflow trace ID", `(trace-id "18446744073709551615")`, `(trace-id "18446744073709551616")`},
		{"rounded numeric trace ID", `(trace-id "18446744073709551615")`, `(trace-id 18446744073709551615)`},
		{"unfinished span", `(completed #t)`, `(completed #f)`},
		{"zero start", `(start "18446744073709550000")`, `(start "0")`},
		{"semantic violation", `(semantic-valid #t)`, `(semantic-valid #f)`},
		{"wrong intake count", `(trace-count "1")`, `(trace-count "2")`},
		{"wrong tracer version", `"4.14.0"`, `"0.0.0"`},
		{"undeclared tracer language", `("Datadog-Meta-Lang" "python")`, `("Datadog-Meta-Lang" "ruby")`},
		{"duplicate tracer header", `("Datadog-Meta-Lang" "python")`, `("Datadog-Meta-Lang" "python") ("datadog-meta-lang" "python")`},
		{"duplicate count header", `("X-Datadog-Trace-Count" "1")`, `("X-Datadog-Trace-Count" "1") ("x-datadog-trace-count" "1")`},
		{"wrong wire version", `(wire-version "v0.5")`, `(wire-version "v0.4")`},
		{"wrong service", `(service "test-datadog")`, `(service "other")`},
		{"4xx marked error", `(error 0)`, `(error 1)`},
		{"partial exception metadata", `("http.method" "GET")`, `("error.type" "ValueError") ("http.method" "GET")`},
		{"missing HTTP request", `(name "aiohttp.request")`, `(name "other.request")`},
		{"wrong exact multiplicity", `(count 1)`, `(count 2)`},
		{"wrong exact children", `(children ())`, `(children (((name "unexpected.query"))))`},
	} {
		if !strings.Contains(capture, tc.old) {
			must(fmt.Errorf("missing mutation anchor %s", tc.name))
		}
		run(tc.name, strings.Replace(capture, tc.old, tc.replacement, 1), program, 409)
	}

	databaseBody := `(import (scheme base) (datadog capture shapes))
 (define capture CAPTURE)
 (assert-capture-shape "database" 'span/database-children capture)`
	databaseCapture := `'((spans (
  ((name "aiohttp.request") (type "web") (trace-id "1") (span-id "2") (parent-id "0"))
  ((name "view") (type "") (trace-id "1") (span-id "3") (parent-id "2"))
	  ((name "sqlite.connection.commit") (type "") (trace-id "1") (span-id "4") (parent-id "3")))))`
	run("database HTTP ancestry", databaseCapture, databaseBody, 200)
	run("detached database root", strings.Replace(databaseCapture, `(parent-id "3")`, `(parent-id "0")`, 1), databaseBody, 409)
	run("database wrong trace", strings.Replace(databaseCapture, `(type "") (trace-id "1")`, `(type "") (trace-id "5")`, 1), databaseBody, 409)
	run("database ancestry cycle", strings.Replace(databaseCapture, `(span-id "3") (parent-id "2")`, `(span-id "3") (parent-id "4")`, 1), databaseBody, 409)

	run("indexed ancestry rejection remains authoritative", strings.Replace(databaseCapture, `(span-id "4")`, `(span-id "4") (http-ancestor #f)`, 1), databaseBody, 409)
	highCapture := strings.Replace(databaseCapture, `(span-id "2")`, `(span-id "2") (meta (("_dd.p.tid" "aaaaaaaaaaaaaaaa")))`, 1)
	highCapture = strings.Replace(highCapture, `(span-id "4")`, `(span-id "4") (meta (("_dd.p.tid" "bbbbbbbbbbbbbbbb")))`, 1)
	run("source ancestry rejects crossed high bits", highCapture, databaseBody, 409)

	exceptionBody := `(import (scheme base) (datadog capture shapes))
 (define capture CAPTURE)
 (assert-capture-shape "exception" 'span/exception-metadata capture)`
	exceptionCapture := `'((spans (((error 1) (meta (("error.type" "sqlite3.IntegrityError") ("error.message" "constraint failed") ("error.stack" "Traceback: constraint failed")))))))`
	run("canonical exception message", exceptionCapture, exceptionBody, 200)
	run("legacy exception message", strings.Replace(exceptionCapture, "error.message", "error.msg", 1), exceptionBody, 200)
	run("exception message missing", strings.Replace(exceptionCapture, `("error.message" "constraint failed")`, "", 1), exceptionBody, 409)
	run("exception stack missing", strings.Replace(exceptionCapture, `("error.stack" "Traceback: constraint failed")`, "", 1), exceptionBody, 409)

	propagationSpans := []string{}
	for _, identity := range [][2]string{
		{"11803532876627986230", "4bf92f3577b34da6"},
		{"9965072336285547154", "8c1e0a5b6d2f4739"},
		{"11276220234964099125", "b3f7d21c9e6a4805"},
	} {
		propagationSpans = append(propagationSpans, fmt.Sprintf(`((name "aiohttp.request") (type "web") (trace-id "%s") (parent-id "67667974448284343") (meta (("_dd.p.tid" "%s"))) (metrics (("_sampling_priority_v1" 1))))`, identity[0], identity[1]))
	}
	propagationCapture := "'((spans (" + strings.Join(propagationSpans, " ") + ")))"
	for _, shape := range []string{"span/datadog-parent", "span/tracecontext-parent"} {
		body := `(import (scheme base) (datadog capture shapes))
   (define capture CAPTURE)
   (assert-capture-shape "propagation" '` + shape + ` capture)`
		run(shape+" exact 128-bit identity", propagationCapture, body, 200)
		for _, tc := range []testCase{
			{"wrong high bits", "4bf92f3577b34da6", "4bf92f3577b34da7"},
			{"wrong low bits", "11803532876627986230", "11803532876627986231"},
			{"wrong remote parent", "67667974448284343", "67667974448284344"},
		} {
			run(shape+" "+tc.name, strings.Replace(propagationCapture, tc.old, tc.replacement, 1), body, 409)
		}
	}
	callerBody := `(import (scheme base) (datadog capture shapes))
 (define capture CAPTURE)
 (assert-capture-shape "propagation" 'span/caller-sampling-kept capture)`
	run("continued traces keep the caller's priority", propagationCapture, callerBody, 200)
	for _, tc := range []testCase{
		{"continued trace reprioritized", `("_sampling_priority_v1" 1)`, `("_sampling_priority_v1" 2)`},
		{"continued trace re-sampled by rule", `("_sampling_priority_v1" 1)`, `("_sampling_priority_v1" 1) ("_dd.rule_psr" 1)`},
	} {
		run(tc.name, strings.Replace(propagationCapture, tc.old, tc.replacement, 1), callerBody, 409)
	}

	contractAssertions(run, expect)
}

// A capture that satisfies every themed contract assertion, and one mutation
// per assertion that must fail that assertion by name.
const contractCapture = `'((requests (((headers (("Datadog-Meta-Lang" "python") ("Datadog-Meta-Lang-Interpreter" "CPython")
  ("Datadog-Meta-Lang-Version" "3.12.1") ("Datadog-Meta-Tracer-Version" "4.14.0"))))))
 (spans (
  ((name "django.request") (resource "GET api/articles/<slug>") (service "svc") (type "web")
   (trace-id "11803532876627986230") (span-id "1") (parent-id "0") (parent-kind "root") (chunk-index 0) (error 0)
   (meta (("_dd.p.dm" "-3") ("_dd.p.tid" "6512bd4300000000") ("env" "test") ("version" "1")
          ("language" "python") ("runtime-id" "0f6a6b8e-1d2c-4c3b-9a8f-7e6d5c4b3a29")
          ("span.kind" "server") ("component" "django") ("http.method" "GET") ("http.status_code" "200")
          ("http.route" "api/articles/<slug>") ("http.url" "http://127.0.0.1:8000/api/articles/one?limit=1")
          ("http.useragent" "hurl/8.0.1")))
   (metrics (("_sampling_priority_v1" 2) ("_dd.rule_psr" 1) ("_dd.limit_psr" 1) ("process_id" 42))))
  ((name "sqlite.query") (resource "SELECT 1") (service "sqlite") (type "sql")
   (trace-id "11803532876627986230") (span-id "2") (parent-id "1") (parent-kind "child") (chunk-index 0) (error 1)
   (meta (("_dd.base_service" "svc") ("env" "test") ("span.kind" "client") ("db.system" "sqlite")
          ("error.type" "sqlite3.IntegrityError") ("error.message" "constraint failed")))
   (metrics ())))))`

type contractCase struct{ assertion, name, old, replacement string }

var contractCases = []contractCase{
	{"request/library-headers", "missing language version header", `("Datadog-Meta-Lang-Version" "3.12.1")`, ""},
	{"capture/chunk-coherence", "chunk mixes traces", `(trace-id "11803532876627986230") (span-id "2")`, `(trace-id "5") (span-id "2")`},
	{"span/trace-id-128", "generated high bits without timestamp", `"6512bd4300000000"`, `"0000000000000001"`},
	{"span/trace-id-128", "uppercase high bits", `"6512bd4300000000"`, `"6512BD4300000000"`},
	{"span/base-service", "integration span without base service", `("_dd.base_service" "svc") `, ""},
	{"span/unified-service-tags", "service span without version", `("env" "test") ("version" "1")`, `("env" "test")`},
	{"span/version-scoped", "integration span with version", `("_dd.base_service" "svc")`, `("_dd.base_service" "svc") ("version" "1")`},
	{"span/process-identity", "malformed runtime id", `"0f6a6b8e-1d2c-4c3b-9a8f-7e6d5c4b3a29"`, `"not-a-runtime-id"`},
	{"span/sampling-priority", "sampling rate on a child", `(metrics ())`, `(metrics (("_dd.rule_psr" 1)))`},
	{"span/decision-maker", "decision maker inside a chunk", `("_dd.base_service" "svc")`, `("_dd.base_service" "svc") ("_dd.p.dm" "-3")`},
	{"span/decision-maker", "malformed decision maker", `("_dd.p.dm" "-3")`, `("_dd.p.dm" "3")`},
	{"span/rule-keep", "local root not kept by the rule", `("_sampling_priority_v1" 2)`, `("_sampling_priority_v1" 1)`},
	{"span/http-server-tags", "server span without span.kind", `("span.kind" "server") `, ""},
	{"span/http-absolute-url", "relative URL", `"http://127.0.0.1:8000/api/articles/one?limit=1"`, `"/api/articles/one?limit=1"`},
	{"span/http-absolute-url", "URL without a host", `"http://127.0.0.1:8000/api/articles/one?limit=1"`, `"http:///api/articles/one?limit=1"`},
	{"span/http-route-template", "route does not match URL", `("http.route" "api/articles/<slug>")`, `("http.route" "api/profiles/<slug>")`},
	{"span/database-client", "database span not a client", `("span.kind" "client")`, `("span.kind" "internal")`},
	{"span/database-system", "database span without db.system", `("db.system" "sqlite")`, ""},
	{"span/errors-explained", "unexplained error", `("error.type" "sqlite3.IntegrityError") `, ""},
}

func contractAssertions(run func(name, value, body string, expected int), expect func(name, value, body string, expected int, contains string)) {
	body := func(assertion string) string {
		return `(import (scheme base) (datadog capture shapes))
 (define capture CAPTURE)
 (assert-capture-shape "contract" '` + assertion + ` capture)`
	}
	seen := map[string]bool{}
	for _, tc := range contractCases {
		if !seen[tc.assertion] {
			seen[tc.assertion] = true
			run(tc.assertion+" contract baseline", contractCapture, body(tc.assertion), 200)
		}
		if !strings.Contains(contractCapture, tc.old) {
			must(fmt.Errorf("missing mutation anchor %s", tc.name))
		}
		// The mutation must fail this assertion, not another check.
		expect(tc.assertion+" "+tc.name, strings.Replace(contractCapture, tc.old, tc.replacement, 1), body(tc.assertion), 409,
			"assertion "+tc.assertion+" failed")
	}

	// A second trace shares the first one's low trace id but not its high bits
	// or service. Only chunk 1's server span carries the high bits, so its
	// database span is attributed through its chunk.
	sameLowID := strings.TrimSuffix(contractCapture, ")))") + `
  ((name "django.request") (resource "GET api/articles/<slug>") (service "other") (type "web")
   (trace-id "11803532876627986230") (span-id "3") (parent-id "0") (parent-kind "root") (chunk-index 1) (error 0)
   (meta (("_dd.p.tid" "6512bd4400000000") ("env" "test") ("version" "1"))) (metrics ()))
  ((name "sqlite.query") (resource "SELECT 1") (service "sqlite") (type "sql")
   (trace-id "11803532876627986230") (span-id "4") (parent-id "3") (parent-kind "child") (chunk-index 1) (error 0)
   (meta (("_dd.base_service" "other") ("env" "test"))) (metrics ())))))`
	for _, assertion := range []string{"span/base-service", "span/unified-service-tags", "span/version-scoped"} {
		run(assertion+" keys services by full trace identity", sameLowID, body(assertion), 200)
	}
	// Without its chunk's high bits, that database span could belong to either trace.
	ambiguous := strings.Replace(sameLowID, `(parent-id "3") (parent-kind "child") (chunk-index 1)`, `(parent-id "3") (parent-kind "child") (chunk-index 2)`, 1)
	expect("span/base-service ambiguous trace identity", ambiguous, body("span/base-service"), 409, "assertion span/base-service failed")
}
func must(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
