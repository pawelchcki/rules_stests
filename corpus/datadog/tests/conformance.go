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
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const capture = `'((protocol datadog) (semantic-valid #t)
 (requests (((method "POST") (wire-version "v0.5") (path "/v0.5/traces")
  (content-type "application/msgpack") (trace-count "1") (chunk-count 1) (span-count 1)
  (headers (("X-Datadog-Trace-Count" "1") ("Datadog-Meta-Lang" "python") ("Datadog-Meta-Tracer-Version" "4.14.0"))))))
 (spans (((name "aiohttp.request") (service "test-datadog") (resource "GET /api/profiles/{username}")
  (type "web") (error 0) (trace-id "18446744073709551615") (span-id "18446744073709551614") (parent-id "0")
  (start "18446744073709550000") (duration "1000") (ids-valid #t) (completed #t)
  (meta (("http.method" "GET") ("http.status_code" "404"))) (metrics (("_dd.measured" 1))))))
 (trace-shapes (((count 1) (root ((name "aiohttp.request") (children ())))))))`

const program = `
(import (scheme base) (datadog capture shapes) (datadog profile) (datadog catalog))
(define capture CAPTURE)
(define profile
 (realworld-profile (service-name "test-datadog") (wire-version "v0.5")
  (all (observed span/native-fields span/ids-valid span/completed span/root-present
                 span/http-classification span/exception-metadata span/service-present
                 request/headers-and-counts capture/semantic-valid))))
(validate-profile profile 'unicode capture
 (cons 'exact '(((count 1) (root ((name "aiohttp.request") (children ())))))))
`

type testCase struct{ name, old, replacement string }

func main() {
	filter := flag.String("filter", "", "run cases whose names contain this text")
	endpoint := flag.String("endpoint", "", "sink URL, otherwise read ASSIGNED_PORTS")
	suffix := flag.String("service-suffix", "//harness:telemetry_sink_service", "sink service label suffix")
	library := flag.String("shape-library", "corpus/datadog/capture/shapes.scm", "Datadog capture library path")
	flag.Parse()
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
	root := filepath.Dir(filepath.Dir(*library))
	var source strings.Builder
	for _, path := range []string{"../telemetry/contract-error.scm", "catalog.scm", "capture/shapes.scm", "proofs.scm", "trace-shape.scm", "../realworld/scenarios.scm", "profile.scm"} {
		data, err := os.ReadFile(filepath.Join(root, path))
		must(err)
		source.Write(data)
		source.WriteByte('\n')
	}
	client := &http.Client{Timeout: 60 * time.Second}
	run := func(name, value, body string, expected int) {
		if *filter != "" && !strings.Contains(name, *filter) {
			return
		}
		payload := source.String() + strings.Replace(body, "CAPTURE", value, 1)
		response, err := client.Post(*endpoint+"/validate?protocol=datadog", "text/x-scheme", bytes.NewBufferString(payload))
		must(err)
		output, err := io.ReadAll(response.Body)
		response.Body.Close()
		must(err)
		if response.StatusCode != expected {
			must(fmt.Errorf("%s: got HTTP %d, want %d: %s", name, response.StatusCode, expected, output))
		}
		if expected == 200 && body == program && !bytes.Contains(output, []byte("[[DATADOG-PROOF-V2|")) {
			must(fmt.Errorf("%s: no Datadog proof markers: %s", name, output))
		}
		fmt.Println("PASS", name)
	}
	run("unsigned IDs and default 404 classification", capture, program, 200)
	run("wide metric integers remain lossless", strings.Replace(capture,
		`("_dd.measured" 1)`, `("_dd.measured" 1) ("wide.unsigned" "18446744073709551615") ("wide.signed" "-9223372036854775808")`, 1), program, 200)
	for _, tc := range []testCase{
		{"zero trace ID", `(trace-id "18446744073709551615")`, `(trace-id "0")`},
		{"overflow trace ID", `(trace-id "18446744073709551615")`, `(trace-id "18446744073709551616")`},
		{"rounded numeric trace ID", `(trace-id "18446744073709551615")`, `(trace-id 18446744073709551615)`},
		{"unfinished span", `(completed #t)`, `(completed #f)`},
		{"zero start", `(start "18446744073709550000")`, `(start "0")`},
		{"semantic violation", `(semantic-valid #t)`, `(semantic-valid #f)`},
		{"wrong intake count", `(trace-count "1")`, `(trace-count "2")`},
		{"wrong tracer version", `"4.14.0"`, `"0.0.0"`},
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
  ((name "sqlite.query") (type "sql") (trace-id "1") (span-id "4") (parent-id "3")))))`
	run("database HTTP ancestry", databaseCapture, databaseBody, 200)
	run("detached database root", strings.Replace(databaseCapture, `(parent-id "3")`, `(parent-id "0")`, 1), databaseBody, 409)
	run("database wrong trace", strings.Replace(databaseCapture, `(type "sql") (trace-id "1")`, `(type "sql") (trace-id "5")`, 1), databaseBody, 409)
	run("database ancestry cycle", strings.Replace(databaseCapture, `(span-id "3") (parent-id "2")`, `(span-id "3") (parent-id "4")`, 1), databaseBody, 409)

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
		propagationSpans = append(propagationSpans, fmt.Sprintf(`((name "aiohttp.request") (type "web") (trace-id "%s") (parent-id "67667974448284343") (meta (("_dd.p.tid" "%s"))))`, identity[0], identity[1]))
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

}
func must(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
