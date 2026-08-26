package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

type sinkRecord struct {
	Signal   string          `json:"signal"`
	Encoding string          `json:"encoding"`
	Request  sinkRequest     `json:"request"`
	Payload  json.RawMessage `json:"payload"`
}

type sinkRequest struct {
	Path    string       `json:"path"`
	Headers []sinkHeader `json:"headers"`
}

type sinkHeader struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

func main() {
	serviceSuffix := flag.String("service-suffix", "", "suffix of the OTLP sink service label")
	flag.Parse()
	if *serviceSuffix == "" {
		fatal(errors.New("--service-suffix is required"))
	}
	port, err := assignedSinkPort(*serviceSuffix)
	if err != nil {
		fatal(err)
	}
	endpoint := fmt.Sprintf("http://127.0.0.1:%d", port)

	requests := []struct {
		signal      string
		contentType string
		body        []byte
		marker      string
	}{
		{"traces", "application/x-protobuf", []byte{0x0a, 0x00}, "trace-protobuf"},
		{"metrics", "application/json", []byte(`{"resourceMetrics":[{"scopeMetrics":[{"scope":{"name":"probe","version":"1.2.3","attributes":[],"droppedAttributesCount":0},"metrics":[{"name":"probe-metric","sum":{"dataPoints":[{"timeUnixNano":"2","asInt":"1"}],"aggregationTemporality":2,"isMonotonic":true}}]}]}]}`), "metric-json"},
		{"logs", "application/json", []byte(`{"resourceLogs":[{"resource":{"attributes":[]},"scopeLogs":[{"scope":{"name":"probe-log","version":"4.5.6","attributes":[],"droppedAttributesCount":0},"logRecords":[{"timeUnixNano":"1","observedTimeUnixNano":"2","severityNumber":9,"severityText":"INFO","body":{"arrayValue":{"values":[{"bytesValue":"AQID/w=="},{"kvlistValue":{"values":[{"key":"nested","value":{"stringValue":"present"}}]}},{"doubleValue":"NaN"}]}},"attributes":[{"key":"probe.attribute","value":{"stringValue":"present"}}]}]}]}]}`), "log-json"},
	}
	for _, item := range requests {
		req, err := http.NewRequest(http.MethodPost, endpoint+"/v1/"+item.signal, bytes.NewReader(item.body))
		if err != nil {
			fatal(err)
		}
		req.Header.Set("Content-Type", item.contentType)
		req.Header.Set("X-Otel-Sink-Probe", item.marker)
		response, err := http.DefaultClient.Do(req)
		if err != nil {
			fatal(fmt.Errorf("send %s: %w", item.signal, err))
		}
		contents, readErr := io.ReadAll(response.Body)
		response.Body.Close()
		if readErr != nil {
			fatal(readErr)
		}
		if response.StatusCode != http.StatusOK {
			fatal(fmt.Errorf("send %s: HTTP %d: %s", item.signal, response.StatusCode, contents))
		}
	}

	response, err := http.Get(endpoint + "/dump")
	if err != nil {
		fatal(err)
	}
	defer response.Body.Close()
	var records []sinkRecord
	if err := json.NewDecoder(response.Body).Decode(&records); err != nil {
		fatal(fmt.Errorf("decode sink dump: %w", err))
	}
	if len(records) != len(requests) {
		fatal(fmt.Errorf("got %d records, want %d", len(records), len(requests)))
	}
	for index, item := range requests {
		record := records[index]
		if record.Signal != item.signal || record.Request.Path != "/v1/"+item.signal {
			fatal(fmt.Errorf("record %d routes %q to %q", index, record.Request.Path, record.Signal))
		}
		wantEncoding := "json"
		if strings.Contains(item.contentType, "protobuf") {
			wantEncoding = "protobuf"
		}
		if record.Encoding != wantEncoding {
			fatal(fmt.Errorf("record %d encoding is %q, want %q", index, record.Encoding, wantEncoding))
		}
		if !hasHeader(record.Request.Headers, "x-otel-sink-probe", item.marker) {
			fatal(fmt.Errorf("record %d did not preserve probe header", index))
		}
		if item.signal == "traces" && !bytes.Contains(record.Payload, []byte(`"resource_spans"`)) {
			fatal(fmt.Errorf("trace protobuf was not semantically decoded: %s", record.Payload))
		}
		if item.signal != "traces" && !bytes.Contains(record.Payload, []byte("probe-")) {
			fatal(fmt.Errorf("JSON payload was not preserved: %s", record.Payload))
		}
	}
	lateLog := []byte(`{"resourceLogs":[{"resource":{"attributes":[]},"scopeLogs":[{"scope":{"name":"late-log"},"logRecords":[{"timeUnixNano":"3","observedTimeUnixNano":"4","severityNumber":9,"severityText":"INFO","body":{"stringValue":"arrived after dump"},"attributes":[{"key":"probe.attribute","value":{"stringValue":"present"}}]}]}]}]}`)
	lateResponse, err := http.Post(endpoint+"/v1/logs", "application/json", bytes.NewReader(lateLog))
	if err != nil {
		fatal(fmt.Errorf("send post-dump log: %w", err))
	}
	lateBody, readErr := io.ReadAll(lateResponse.Body)
	lateResponse.Body.Close()
	if readErr != nil || lateResponse.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send post-dump log: HTTP %d: %s: %v", lateResponse.StatusCode, lateBody, readErr))
	}
	oversizedConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for oversized validation source: %w", err))
	}
	if _, err := fmt.Fprintf(oversizedConnection, "POST /validate HTTP/1.1\r\nHost: sink\r\nContent-Type: text/x-scheme\r\nContent-Length: %d\r\nConnection: close\r\n\r\n", 256*1024+1); err != nil {
		fatal(fmt.Errorf("send oversized validation headers: %w", err))
	}
	oversizedResponse, err := http.ReadResponse(bufio.NewReader(oversizedConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read oversized validation response: %w", err))
	}
	oversizedBody, readErr := io.ReadAll(oversizedResponse.Body)
	oversizedResponse.Body.Close()
	oversizedConnection.Close()
	if readErr != nil || oversizedResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(oversizedBody, []byte("validation source exceeds limit")) {
		fatal(fmt.Errorf("oversized validation source: HTTP %d: %s: %v", oversizedResponse.StatusCode, oversizedBody, readErr))
	}
	validRule := []byte(`(define-library (probe contract)
  (export validate-probe)
  (import (scheme base) (scheme write))
  (begin
    (define (validate-probe capture)
      (let ((requests (cadr (assq 'requests capture)))
            (resources (cadr (assq 'resources capture)))
            (metrics (cadr (assq 'metrics capture)))
            (logs (cadr (assq 'logs capture))))
        (if (and (= (length requests) 3)
                 (= (length resources) 3)
                 (= (length metrics) 1)
                 (= (cadr (assq 'data-points (car metrics))) 1)
                 (cadr (assq 'data-points-valid (car metrics)))
                 (eq? (cadr (assq 'data-type (car metrics))) 'sum)
                 (string=? (cadr (assq 'scope-version (car metrics))) "1.2.3")
                 (null? (cadr (assq 'scope-attributes (car metrics))))
                 (= (length logs) 1)
                 (string=? (cadr (assq 'scope-version (car logs))) "4.5.6")
                 (equal? (cadr (assq 'body (car logs)))
                         '(array ((bytes (1 2 3 255))
                                  (kvlist (("nested" (string "present"))))
                                  (double "NaN"))))
                 (= (length (cadr (assq 'attributes (car logs)))) 1))
            (display "standalone validation passed\n")
            (error "canonical OTLP JSON shape changed"))))))
(import (scheme base) (scheme read) (probe contract))
(validate-probe (read))`)
	if output, status, err := validateScheme(endpoint, validRule); err != nil {
		fatal(err)
	} else if status != http.StatusOK || !bytes.Contains(output, []byte("standalone validation passed")) {
		fatal(fmt.Errorf("valid Scheme rule returned HTTP %d: %s", status, output))
	}
	if output, status, err := validateScheme(endpoint, []byte(`(import (scheme base)) (error "OTLP contract assertion: intentional rejection")`)); err != nil {
		fatal(err)
	} else if status != http.StatusConflict || !bytes.Contains(output, []byte("intentional rejection")) {
		fatal(fmt.Errorf("contract-rejecting Scheme rule returned HTTP %d: %s", status, output))
	}
	statsResponse, err := http.Get(endpoint + "/stats")
	if err != nil {
		fatal(fmt.Errorf("read stats after failed validation: %w", err))
	}
	var failedStats struct {
		LastCalls int `json:"validation_last_calls"`
	}
	statsDecodeErr := json.NewDecoder(statsResponse.Body).Decode(&failedStats)
	statsResponse.Body.Close()
	if statsDecodeErr != nil || statsResponse.StatusCode != http.StatusOK || failedStats.LastCalls <= 0 {
		fatal(fmt.Errorf("failed validation stats: HTTP %d calls=%d: %v", statsResponse.StatusCode, failedStats.LastCalls, statsDecodeErr))
	}
	if output, status, err := validateScheme(endpoint, []byte(`(import (scheme base)) (error "validator fault")`)); err != nil {
		fatal(err)
	} else if status != http.StatusUnprocessableEntity || !bytes.Contains(output, []byte("validator fault")) {
		fatal(fmt.Errorf("faulting Scheme rule returned HTTP %d: %s", status, output))
	}
	if output, status, err := validateScheme(endpoint, []byte(`(import (scheme base)) (let loop () (loop))`)); err != nil {
		fatal(err)
	} else if status != http.StatusUnprocessableEntity || !bytes.Contains(output, []byte("sandbox budget")) {
		fatal(fmt.Errorf("nonterminating Scheme rule returned HTTP %d: %s", status, output))
	}
	if output, status, err := validateScheme(endpoint, []byte(`(import (scheme base) (scheme write)) (let loop () (display "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef") (loop))`)); err != nil {
		fatal(err)
	} else if status != http.StatusUnprocessableEntity || !bytes.Contains(output, []byte("output sandbox limit")) {
		fatal(fmt.Errorf("output-spamming Scheme rule returned HTTP %d: %s", status, output))
	}
	malformedLog := []byte(`{"resourceLogs":[{"resource":{"attributes":[]},"scopeLogs":[{"scope":{"name":"probe-log"},"logRecords":[{"timeUnixNano":"1","observedTimeUnixNano":"2","severityNumber":9,"severityText":"INFO","body":{"stringValue":"malformed numeric probe"},"attributes":[{"key":"probe.attribute","value":{"stringValue":"present"}}],"flags":"broken"}]}]}]}`)
	malformedResponse, err := http.Post(endpoint+"/v1/logs", "application/json", bytes.NewReader(malformedLog))
	if err != nil {
		fatal(fmt.Errorf("send malformed numeric probe: %w", err))
	}
	malformedBody, readErr := io.ReadAll(malformedResponse.Body)
	malformedResponse.Body.Close()
	if readErr != nil || malformedResponse.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send malformed numeric probe: HTTP %d: %s: %v", malformedResponse.StatusCode, malformedBody, readErr))
	}
	freezeCapture(endpoint, "/dump", "malformed numeric capture")
	malformedRule := []byte(`(import (scheme base) (scheme read) (scheme write))
(let* ((capture (read))
       (logs (cadr (assq 'logs capture)))
       (latest (car (reverse logs))))
  (if (= (cadr (assq 'flags latest)) -1)
      (display "malformed numeric preserved\n")
      (error "malformed numeric was normalized")))`)
	if output, status, err := validateScheme(endpoint, malformedRule); err != nil {
		fatal(err)
	} else if status != http.StatusOK || !bytes.Contains(output, []byte("malformed numeric preserved")) {
		fatal(fmt.Errorf("malformed numeric Scheme rule returned HTTP %d: %s", status, output))
	}
	customTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"example.custom/db-client"},"spans":[{"traceId":"11111111111111111111111111111111","spanId":"2222222222222222","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	customResponse, err := http.Post(endpoint+"/v1/traces", "application/json", bytes.NewReader(customTrace))
	if err != nil {
		fatal(fmt.Errorf("send custom candidate trace: %w", err))
	}
	customBody, readErr := io.ReadAll(customResponse.Body)
	customResponse.Body.Close()
	if readErr != nil || customResponse.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send custom candidate trace: HTTP %d: %s: %v", customResponse.StatusCode, customBody, readErr))
	}
	collidingScopesTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"foo.bar"},"spans":[{"traceId":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","spanId":"3333333333333333","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]},{"scope":{"name":"foo/bar"},"spans":[{"traceId":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","spanId":"3333333333333333","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]},{"scope":{"name":"Foo.Bar"},"spans":[{"traceId":"cccccccccccccccccccccccccccccccc","spanId":"4444444444444444","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	collidingResponse, err := http.Post(endpoint+"/v1/traces", "application/json", bytes.NewReader(collidingScopesTrace))
	if err != nil {
		fatal(fmt.Errorf("send colliding-scope candidate traces: %w", err))
	}
	collidingBody, readErr := io.ReadAll(collidingResponse.Body)
	collidingResponse.Body.Close()
	if readErr != nil || collidingResponse.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send colliding-scope candidate traces: HTTP %d: %s: %v", collidingResponse.StatusCode, collidingBody, readErr))
	}
	freezeCapture(endpoint, "/dump", "custom candidate capture")
	candidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate custom candidate: %w", err))
	}
	candidateBody, readErr := io.ReadAll(candidate.Body)
	candidate.Body.Close()
	wantAliases := []string{
		"scope-example-custom-db-client-6578616d706c652e637573746f6d2f64622d636c69656e74",
		"scope-foo-bar-666f6f2e626172",
		"scope-foo-bar-666f6f2f626172",
		"scope-foo-bar-466f6f2e426172",
	}
	aliasesPresent := true
	for _, alias := range wantAliases {
		aliasesPresent = aliasesPresent && bytes.Contains(candidateBody, []byte(alias))
	}
	if readErr != nil || candidate.StatusCode != http.StatusOK || !aliasesPresent {
		fatal(fmt.Errorf("custom candidate: HTTP %d: %s: %v", candidate.StatusCode, candidateBody, readErr))
	}
	resetSink(endpoint)
	selfParentTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"self-parent.probe"},"spans":[{"traceId":"dddddddddddddddddddddddddddddddd","spanId":"5555555555555555","parentSpanId":"5555555555555555","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "self-parent trace", selfParentTrace)
	freezeCapture(endpoint, "/dump", "self-parent capture")
	selfParentCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate self-parent candidate: %w", err))
	}
	selfParentBody, readErr := io.ReadAll(selfParentCandidate.Body)
	selfParentCandidate.Body.Close()
	if readErr != nil || selfParentCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(selfParentBody, []byte("span is its own parent")) {
		fatal(fmt.Errorf("self-parent candidate: HTTP %d: %s: %v", selfParentCandidate.StatusCode, selfParentBody, readErr))
	}
	resetSink(endpoint)
	malformedCollectionTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"collection.probe"},"spans":[{"traceId":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","spanId":"6666666666666666","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","links":"corrupt","status":{"code":0}}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "malformed-collection trace", malformedCollectionTrace)
	malformedDumpBody := freezeCapture(endpoint, "/dump.scm", "malformed-collection Scheme capture")
	if !bytes.Contains(malformedDumpBody, []byte("(json-collections-valid #f)")) {
		fatal(fmt.Errorf("malformed collection was absent from Scheme capture: %s", malformedDumpBody))
	}
	malformedCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate malformed-collection candidate: %w", err))
	}
	malformedCandidateBody, readErr := io.ReadAll(malformedCandidate.Body)
	malformedCandidate.Body.Close()
	if readErr != nil || malformedCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(malformedCandidateBody, []byte("malformed OTLP JSON collection")) {
		fatal(fmt.Errorf("malformed-collection candidate: HTTP %d: %s: %v", malformedCandidate.StatusCode, malformedCandidateBody, readErr))
	}
	resetSink(endpoint)
	malformedStringTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"string.probe"},"spans":[{"traceId":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","spanId":"7777777777777777","traceState":0,"name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "malformed-string trace", malformedStringTrace)
	malformedStringDump := freezeCapture(endpoint, "/dump.scm", "malformed-string Scheme capture")
	if !bytes.Contains(malformedStringDump, []byte("(json-strings-valid #f)")) {
		fatal(fmt.Errorf("malformed string was absent from Scheme capture: %s", malformedStringDump))
	}
	malformedStringCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate malformed-string candidate: %w", err))
	}
	malformedStringBody, readErr := io.ReadAll(malformedStringCandidate.Body)
	malformedStringCandidate.Body.Close()
	if readErr != nil || malformedStringCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(malformedStringBody, []byte("malformed OTLP JSON string field")) {
		fatal(fmt.Errorf("malformed-string candidate: HTTP %d: %s: %v", malformedStringCandidate.StatusCode, malformedStringBody, readErr))
	}
	resetSink(endpoint)
	malformedMetric := []byte(`{"resourceMetrics":[{"scopeMetrics":[{"scope":{"name":"metric.probe"},"metrics":[{"name":"broken","gauge":{"dataPoints":[{"timeUnixNano":"0","flags":2}]}}]}]}]}`)
	postJSON(endpoint, "/v1/metrics", "malformed metric", malformedMetric)
	malformedMetricDump := freezeCapture(endpoint, "/dump.scm", "malformed-metric Scheme capture")
	if !bytes.Contains(malformedMetricDump, []byte("(data-points-valid #f)")) {
		fatal(fmt.Errorf("malformed metric point was absent from Scheme capture: %s", malformedMetricDump))
	}
	resetSink(endpoint)
	duplicateSpellingsTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"duplicate.probe"},"spans":[{"trace_id":"dddddddddddddddddddddddddddddddd","traceId":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","spanId":"5555555555555555","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "duplicate-spelling trace", duplicateSpellingsTrace)
	duplicateDumpBody := freezeCapture(endpoint, "/dump.scm", "duplicate-spelling Scheme capture")
	if !bytes.Contains(duplicateDumpBody, []byte("(json-field-spellings-valid #f)")) {
		fatal(fmt.Errorf("duplicate spelling was absent from Scheme capture: %s", duplicateDumpBody))
	}
	duplicateCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate duplicate-spelling candidate: %w", err))
	}
	duplicateCandidateBody, readErr := io.ReadAll(duplicateCandidate.Body)
	duplicateCandidate.Body.Close()
	if readErr != nil || duplicateCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(duplicateCandidateBody, []byte("duplicate OTLP JSON field spellings")) {
		fatal(fmt.Errorf("duplicate-spelling candidate: HTTP %d: %s: %v", duplicateCandidate.StatusCode, duplicateCandidateBody, readErr))
	}
	resetSink(endpoint)
	resetDump, err := http.Get(endpoint + "/dump")
	if err != nil {
		fatal(fmt.Errorf("read reset dump: %w", err))
	}
	var resetRecords []sinkRecord
	decodeErr := json.NewDecoder(resetDump.Body).Decode(&resetRecords)
	resetDump.Body.Close()
	if decodeErr != nil {
		fatal(fmt.Errorf("decode reset dump: %w", decodeErr))
	}
	if len(resetRecords) != 0 {
		fatal(fmt.Errorf("reset retained %d records", len(resetRecords)))
	}
	fmt.Printf("OTLP sink accepted and described traces, metrics, and logs at %s\n", endpoint)
}

func postJSON(endpoint, path, label string, body []byte) {
	response, err := http.Post(endpoint+path, "application/json", bytes.NewReader(body))
	if err != nil {
		fatal(fmt.Errorf("send %s: %w", label, err))
	}
	contents, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil || response.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send %s: HTTP %d: %s: %v", label, response.StatusCode, contents, readErr))
	}
}

func freezeCapture(endpoint, path, label string) []byte {
	response, err := http.Get(endpoint + path)
	if err != nil {
		fatal(fmt.Errorf("freeze %s: %w", label, err))
	}
	contents, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil || response.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("freeze %s: HTTP %d: %s: %v", label, response.StatusCode, contents, readErr))
	}
	return contents
}

func resetSink(endpoint string) {
	response, err := http.Post(endpoint+"/reset", "application/json", nil)
	if err != nil {
		fatal(fmt.Errorf("reset sink: %w", err))
	}
	contents, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil || response.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("reset sink: HTTP %d: %s: %v", response.StatusCode, contents, readErr))
	}
}

func validateScheme(endpoint string, source []byte) ([]byte, int, error) {
	request, err := http.NewRequest(http.MethodPost, endpoint+"/validate", bytes.NewReader(source))
	if err != nil {
		return nil, 0, err
	}
	request.Header.Set("Content-Type", "text/x-scheme")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		return nil, 0, err
	}
	defer response.Body.Close()
	output, err := io.ReadAll(response.Body)
	return output, response.StatusCode, err
}

func hasHeader(headers []sinkHeader, name, value string) bool {
	for _, header := range headers {
		if header.Name == name && header.Value == value {
			return true
		}
	}
	return false
}

func assignedSinkPort(serviceSuffix string) (int, error) {
	var ports map[string]json.RawMessage
	if err := json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports); err != nil {
		return 0, fmt.Errorf("decode ASSIGNED_PORTS: %w", err)
	}
	for label, encoded := range ports {
		if !strings.HasSuffix(label, serviceSuffix) {
			continue
		}
		var port int
		if err := json.Unmarshal(encoded, &port); err == nil {
			return port, nil
		}
		var value string
		if err := json.Unmarshal(encoded, &value); err != nil {
			return 0, err
		}
		return strconv.Atoi(value)
	}
	return 0, fmt.Errorf("service ending in %q is absent from ASSIGNED_PORTS", serviceSuffix)
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "otel_sink_probe:", err)
	time.Sleep(10 * time.Millisecond)
	os.Exit(1)
}
