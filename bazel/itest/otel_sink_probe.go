package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
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
		{"metrics", "application/json", []byte(`{"resourceMetrics":[{"scopeMetrics":[{"scope":{"name":"probe"},"metrics":[{"name":"probe-metric","sum":{"dataPoints":[{"timeUnixNano":"2","asInt":"1"}],"aggregationTemporality":2,"isMonotonic":true}}]}]}]}`), "metric-json"},
		{"logs", "application/json", []byte(`{"resourceLogs":[{"resource":{"attributes":[]},"scopeLogs":[{"scope":{"name":"probe-log"},"logRecords":[{"timeUnixNano":"1","observedTimeUnixNano":"2","severityNumber":9,"severityText":"INFO","body":{"bytesValue":"AQID/w=="},"attributes":[{"key":"probe.attribute","value":{"stringValue":"present"}}]}]}]}]}`), "log-json"},
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
	oversizedValidation := bytes.Repeat([]byte(" "), 256*1024+1)
	oversizedResponse, err := http.Post(endpoint+"/validate", "text/x-scheme", bytes.NewReader(oversizedValidation))
	if err != nil {
		fatal(fmt.Errorf("send oversized validation source: %w", err))
	}
	oversizedBody, readErr := io.ReadAll(oversizedResponse.Body)
	oversizedResponse.Body.Close()
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
                 (eq? (cadr (assq 'data-type (car metrics))) 'sum)
                 (= (length logs) 1)
                 (equal? (cadr (assq 'body (car logs))) '(bytes (1 2 3 255)))
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
	duplicateSpellingsTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"duplicate.probe"},"spans":[{"trace_id":"dddddddddddddddddddddddddddddddd","traceId":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","spanId":"5555555555555555","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	duplicateResponse, err := http.Post(endpoint+"/v1/traces", "application/json", bytes.NewReader(duplicateSpellingsTrace))
	if err != nil {
		fatal(fmt.Errorf("send duplicate-spelling trace: %w", err))
	}
	duplicateBody, readErr := io.ReadAll(duplicateResponse.Body)
	duplicateResponse.Body.Close()
	if readErr != nil || duplicateResponse.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send duplicate-spelling trace: HTTP %d: %s: %v", duplicateResponse.StatusCode, duplicateBody, readErr))
	}
	duplicateDump, err := http.Get(endpoint + "/dump.scm")
	if err != nil {
		fatal(fmt.Errorf("read duplicate-spelling Scheme dump: %w", err))
	}
	duplicateDumpBody, readErr := io.ReadAll(duplicateDump.Body)
	duplicateDump.Body.Close()
	if readErr != nil || duplicateDump.StatusCode != http.StatusOK || !bytes.Contains(duplicateDumpBody, []byte("(json-field-spellings-valid #f)")) {
		fatal(fmt.Errorf("duplicate-spelling Scheme dump: HTTP %d: %s: %v", duplicateDump.StatusCode, duplicateDumpBody, readErr))
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
	reset, err := http.Post(endpoint+"/reset", "application/json", nil)
	if err != nil {
		fatal(fmt.Errorf("reset sink: %w", err))
	}
	resetBody, readErr := io.ReadAll(reset.Body)
	reset.Body.Close()
	if readErr != nil {
		fatal(fmt.Errorf("read reset response: %w", readErr))
	}
	if reset.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("reset sink: HTTP %d: %s", reset.StatusCode, resetBody))
	}
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
