package main

import (
	"bufio"
	"bytes"
	_ "embed"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/pawelchcki/rules_stests/report"
)

//go:embed scheme/otel_core.scm
var otelCoreLibrary []byte

//go:embed testdata/synthetic_capture.scm
var syntheticFeatureCaptureBytes []byte

var syntheticFeatureCapture = string(syntheticFeatureCaptureBytes)

// Mutation anchors that span more than one line of the fixture.
const (
	syntheticLogsBlock                 = " (logs (\n  ((scope \"logger.scope\") (schema-url \"https://opentelemetry.io/schemas/1.11.0\")))))"
	syntheticLogsBlockWithoutSchemaURL = " (logs (\n  ((scope \"logger.scope\") (schema-url \"\")))))"
)

type sinkRecord struct {
	Signal   string          `json:"signal"`
	Encoding string          `json:"encoding"`
	Request  sinkRequest     `json:"request"`
	Payload  json.RawMessage `json:"payload"`
}

type sinkRequest struct {
	Path            string       `json:"path"`
	ContentEncoding string       `json:"content_encoding"`
	Headers         []sinkHeader `json:"headers"`
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
	syntheticShapeByFeature, err := report.ParseProofRuleAssertions(otelCoreLibrary)
	if err != nil {
		fatal(fmt.Errorf("parse embedded Scheme proof tables: %w", err))
	}
	syntheticFeatureIDs := make([]string, 0, len(syntheticShapeByFeature))
	for featureID := range syntheticShapeByFeature {
		syntheticFeatureIDs = append(syntheticFeatureIDs, featureID)
	}
	sort.Strings(syntheticFeatureIDs)

	mismatchedTrace := []byte(`{"resourceLogs":[]}`)
	mismatchedResponse, err := http.Post(endpoint+"/v1/traces", "application/json", bytes.NewReader(mismatchedTrace))
	if err != nil {
		fatal(fmt.Errorf("send signal-mismatched trace: %w", err))
	}
	mismatchedBody, readErr := io.ReadAll(mismatchedResponse.Body)
	mismatchedResponse.Body.Close()
	if readErr != nil || mismatchedResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(mismatchedBody, []byte("invalid OTLP traces JSON export field")) {
		fatal(fmt.Errorf("signal-mismatched trace: HTTP %d: %s: %v", mismatchedResponse.StatusCode, mismatchedBody, readErr))
	}
	nestedUnknownTrace := []byte(`{"resourceSpans":[{"scopeSpans":[{"spans":[{"traceId":"11111111111111111111111111111111","spanId":"2222222222222222","name":"probe","status":{"code":1,"mysteryField":true}}]}]}]}`)
	nestedUnknownResponse, err := http.Post(endpoint+"/v1/traces", "application/json", bytes.NewReader(nestedUnknownTrace))
	if err != nil {
		fatal(fmt.Errorf("send nested-unknown trace: %w", err))
	}
	nestedUnknownBody, readErr := io.ReadAll(nestedUnknownResponse.Body)
	nestedUnknownResponse.Body.Close()
	if readErr != nil || nestedUnknownResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(nestedUnknownBody, []byte("invalid OTLP span status field")) {
		fatal(fmt.Errorf("nested-unknown trace: HTTP %d: %s: %v", nestedUnknownResponse.StatusCode, nestedUnknownBody, readErr))
	}
	rejectJSON(
		endpoint,
		"/v1/traces",
		"non-object status",
		[]byte("expected object"),
		[]byte(`{"resourceSpans":[{"scopeSpans":[{"spans":[{"status":"corrupt"}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"quoted span enum",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceSpans":[{"scopeSpans":[{"spans":[{"kind":"2"}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"quoted span flags",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceSpans":[{"scopeSpans":[{"spans":[{"flags":"256"}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"out-of-range span flags",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceSpans":[{"scopeSpans":[{"spans":[{"flags":4294967296}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"quoted span-link flags",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceSpans":[{"scopeSpans":[{"spans":[{"links":[{"flags":"256"}]}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"numeric resource schema URL",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceSpans":[{"schemaUrl":0}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"quoted resource dropped-attribute count",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceSpans":[{"resource":{"droppedAttributesCount":"0"}}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"out-of-range span dropped-event count",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceSpans":[{"scopeSpans":[{"spans":[{"droppedEventsCount":4294967296}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/metrics",
		"non-object repeated message",
		[]byte("expected object"),
		[]byte(`{"resourceMetrics":[{"scopeMetrics":[null,{"metrics":[]}]}]}`),
	)
	rejectContentType(
		endpoint,
		"application/json; not-a-parameter",
		[]byte("malformed Content-Type parameter"),
	)
	rejectJSON(
		endpoint,
		"/v1/logs",
		"multiple AnyValue variants",
		[]byte("expected at most one variant"),
		[]byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"body":{"stringValue":"ok","intValue":"5"}}]}]}]}`),
	)
	postJSON(
		endpoint,
		"/v1/logs",
		"unset AnyValue oneof",
		[]byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"body":{}}]}]}]}`),
	)
	postJSON(
		endpoint,
		"/v1/logs",
		"null AnyValue oneof",
		[]byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"body":{"stringValue":null}}]}]}]}`),
	)
	postJSON(
		endpoint,
		"/v1/logs",
		"populated AnyValue with null alternative",
		[]byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"body":{"stringValue":"ok","intValue":null}}]}]}]}`),
	)
	postJSON(
		endpoint,
		"/v1/logs",
		"null structured AnyValue oneof",
		[]byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"body":{"arrayValue":null}}]}]}]}`),
	)
	resetSink(endpoint)
	rejectJSON(
		endpoint,
		"/v1/logs",
		"non-canonical bytesValue base64",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"body":{"bytesValue":"AB=="}}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/logs",
		"invalid log trace flags",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"flags":256}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/metrics",
		"string monotonicity",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceMetrics":[{"scopeMetrics":[{"metrics":[{"sum":{"aggregationTemporality":2,"isMonotonic":"true"}}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/metrics",
		"non-array metric metadata",
		[]byte("expected array"),
		[]byte(`{"resourceMetrics":[{"scopeMetrics":[{"metrics":[{"name":"bad-metadata","metadata":{},"gauge":{"dataPoints":[]}}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/metrics",
		"out-of-range signed metric value",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceMetrics":[{"scopeMetrics":[{"metrics":[{"name":"bad-int","gauge":{"dataPoints":[{"timeUnixNano":"1","asInt":"18446744073709551615"}]}}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/metrics",
		"out-of-range exponential histogram offset",
		[]byte("unexpected JSON type"),
		[]byte(`{"resourceMetrics":[{"scopeMetrics":[{"metrics":[{"name":"bad-offset","exponentialHistogram":{"dataPoints":[{"positive":{"offset":"2147483648","bucketCounts":[]}}]}}]}]}]}`),
	)
	rejectJSON(
		endpoint,
		"/v1/metrics",
		"duplicate JSON key",
		[]byte("duplicate JSON key"),
		[]byte(`{"resourceMetrics":[],"resourceMetrics":[]}`),
	)
	unsupportedResponse, err := http.Post(endpoint+"/v1/metrics", "text/plain", bytes.NewReader([]byte("{}")))
	if err != nil {
		fatal(fmt.Errorf("send unsupported media type: %w", err))
	}
	unsupportedBody, readErr := io.ReadAll(unsupportedResponse.Body)
	unsupportedResponse.Body.Close()
	if readErr != nil || unsupportedResponse.StatusCode != http.StatusUnsupportedMediaType || !bytes.Contains(unsupportedBody, []byte("unsupported content type")) {
		fatal(fmt.Errorf("unsupported media type: HTTP %d: %s: %v", unsupportedResponse.StatusCode, unsupportedBody, readErr))
	}
	var headerCountRequest strings.Builder
	headerCountRequest.WriteString("POST /v1/metrics HTTP/1.1\r\n")
	for index := 0; index < 129; index++ {
		fmt.Fprintf(&headerCountRequest, "X-Probe-%d: value\r\n", index)
	}
	headerCountRequest.WriteString("\r\n")
	rejectRawRequest(
		endpoint,
		"oversized header count",
		headerCountRequest.String(),
		http.StatusRequestEntityTooLarge,
		[]byte("request header count exceeds limit"),
	)
	rejectRawRequest(
		endpoint,
		"control byte in field value",
		"POST /v1/metrics HTTP/1.1\r\nHost: sink\r\nX-Probe: bad\x00value\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n{}",
		http.StatusBadRequest,
		[]byte("invalid HTTP field value"),
	)
	rejectRawRequest(
		endpoint,
		"obs-text byte in field value",
		"GET /missing HTTP/1.1\r\nHost: sink\r\nX-Probe: valid\x80obs-text\r\nConnection: close\r\n\r\n",
		http.StatusMethodNotAllowed,
		[]byte("expected POST"),
	)
	rejectRawRequest(
		endpoint,
		"malformed bracketed IPv6 Host",
		"POST /v1/metrics HTTP/1.1\r\nHost: [2001:::1]\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n{}",
		http.StatusBadRequest,
		[]byte("invalid bracketed IPv6 Host field"),
	)

	duplicateEncodingConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for duplicate content encoding: %w", err))
	}
	if _, err := fmt.Fprint(duplicateEncodingConnection, "POST /v1/metrics HTTP/1.1\r\nHost: sink\r\nContent-Type: application/json\r\nContent-Encoding: identity\r\nContent-Encoding: gzip\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"); err != nil {
		fatal(fmt.Errorf("send duplicate content encoding: %w", err))
	}
	duplicateEncodingResponse, err := http.ReadResponse(bufio.NewReader(duplicateEncodingConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read duplicate content encoding response: %w", err))
	}
	duplicateEncodingBody, readErr := io.ReadAll(duplicateEncodingResponse.Body)
	duplicateEncodingResponse.Body.Close()
	duplicateEncodingConnection.Close()
	if readErr != nil || duplicateEncodingResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(duplicateEncodingBody, []byte("must be unique")) {
		fatal(fmt.Errorf("duplicate content encoding: HTTP %d: %s: %v", duplicateEncodingResponse.StatusCode, duplicateEncodingBody, readErr))
	}

	trailingTokenConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for trailing request-line token: %w", err))
	}
	if _, err := fmt.Fprint(trailingTokenConnection, "POST /v1/metrics HTTP/1.1 extra\r\nHost: sink\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"); err != nil {
		fatal(fmt.Errorf("send trailing request-line token: %w", err))
	}
	trailingTokenResponse, err := http.ReadResponse(bufio.NewReader(trailingTokenConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read trailing request-line token response: %w", err))
	}
	trailingTokenBody, readErr := io.ReadAll(trailingTokenResponse.Body)
	trailingTokenResponse.Body.Close()
	trailingTokenConnection.Close()
	if readErr != nil || trailingTokenResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(trailingTokenBody, []byte("invalid HTTP/1.1 request line")) {
		fatal(fmt.Errorf("trailing request-line token: HTTP %d: %s: %v", trailingTokenResponse.StatusCode, trailingTokenBody, readErr))
	}

	tabRequestConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for tab-delimited request line: %w", err))
	}
	if _, err := fmt.Fprint(tabRequestConnection, "POST\t/v1/metrics\tHTTP/1.1\r\nHost: sink\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"); err != nil {
		fatal(fmt.Errorf("send tab-delimited request line: %w", err))
	}
	tabRequestResponse, err := http.ReadResponse(bufio.NewReader(tabRequestConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read tab-delimited request-line response: %w", err))
	}
	tabRequestBody, readErr := io.ReadAll(tabRequestResponse.Body)
	tabRequestResponse.Body.Close()
	tabRequestConnection.Close()
	if readErr != nil || tabRequestResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(tabRequestBody, []byte("invalid HTTP/1.1 request line")) {
		fatal(fmt.Errorf("tab-delimited request line: HTTP %d: %s: %v", tabRequestResponse.StatusCode, tabRequestBody, readErr))
	}

	invalidFieldConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for invalid HTTP field name: %w", err))
	}
	if _, err := fmt.Fprint(invalidFieldConnection, "POST /v1/metrics HTTP/1.1\r\nHost: sink\r\nContent-Type : application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"); err != nil {
		fatal(fmt.Errorf("send invalid HTTP field name: %w", err))
	}
	invalidFieldResponse, err := http.ReadResponse(bufio.NewReader(invalidFieldConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read invalid HTTP field name response: %w", err))
	}
	invalidFieldBody, readErr := io.ReadAll(invalidFieldResponse.Body)
	invalidFieldResponse.Body.Close()
	invalidFieldConnection.Close()
	if readErr != nil || invalidFieldResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(invalidFieldBody, []byte("invalid HTTP field name")) {
		fatal(fmt.Errorf("invalid HTTP field name: HTTP %d: %s: %v", invalidFieldResponse.StatusCode, invalidFieldBody, readErr))
	}

	nonDecimalLengthConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for non-decimal Content-Length: %w", err))
	}
	if _, err := fmt.Fprint(nonDecimalLengthConnection, "POST /v1/metrics HTTP/1.1\r\nHost: sink\r\nContent-Type: application/json\r\nContent-Length: +2\r\nConnection: close\r\n\r\n{}"); err != nil {
		fatal(fmt.Errorf("send non-decimal Content-Length: %w", err))
	}
	nonDecimalLengthResponse, err := http.ReadResponse(bufio.NewReader(nonDecimalLengthConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read non-decimal Content-Length response: %w", err))
	}
	nonDecimalLengthBody, readErr := io.ReadAll(nonDecimalLengthResponse.Body)
	nonDecimalLengthResponse.Body.Close()
	nonDecimalLengthConnection.Close()
	if readErr != nil || nonDecimalLengthResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(nonDecimalLengthBody, []byte("invalid Content-Length")) {
		fatal(fmt.Errorf("non-decimal Content-Length: HTTP %d: %s: %v", nonDecimalLengthResponse.StatusCode, nonDecimalLengthBody, readErr))
	}

	transferEncodingConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for Transfer-Encoding: %w", err))
	}
	if _, err := fmt.Fprint(transferEncodingConnection, "POST /v1/metrics HTTP/1.1\r\nHost: sink\r\nContent-Type: application/json\r\nTransfer-Encoding: identity\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"); err != nil {
		fatal(fmt.Errorf("send Transfer-Encoding: %w", err))
	}
	transferEncodingResponse, err := http.ReadResponse(bufio.NewReader(transferEncodingConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read Transfer-Encoding response: %w", err))
	}
	transferEncodingBody, readErr := io.ReadAll(transferEncodingResponse.Body)
	transferEncodingResponse.Body.Close()
	transferEncodingConnection.Close()
	if readErr != nil || transferEncodingResponse.StatusCode != http.StatusBadRequest || !bytes.Contains(transferEncodingBody, []byte("Transfer-Encoding is not supported")) {
		fatal(fmt.Errorf("Transfer-Encoding: HTTP %d: %s: %v", transferEncodingResponse.StatusCode, transferEncodingBody, readErr))
	}

	oversizedJSONConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for oversized JSON: %w", err))
	}
	if _, err := fmt.Fprint(oversizedJSONConnection, "POST /v1/metrics HTTP/1.1\r\nHost: sink\r\nContent-Type: application/json\r\nContent-Length: 1048577\r\nConnection: close\r\n\r\n"); err != nil {
		fatal(fmt.Errorf("send oversized JSON headers: %w", err))
	}
	oversizedJSONResponse, err := http.ReadResponse(bufio.NewReader(oversizedJSONConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read oversized JSON response: %w", err))
	}
	oversizedJSONBody, readErr := io.ReadAll(oversizedJSONResponse.Body)
	oversizedJSONResponse.Body.Close()
	oversizedJSONConnection.Close()
	if readErr != nil || oversizedJSONResponse.StatusCode != http.StatusRequestEntityTooLarge || !bytes.Contains(oversizedJSONBody, []byte("request body exceeds limit")) {
		fatal(fmt.Errorf("oversized JSON: HTTP %d: %s: %v", oversizedJSONResponse.StatusCode, oversizedJSONBody, readErr))
	}

	oversizedProtobufConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for oversized protobuf: %w", err))
	}
	if _, err := fmt.Fprint(oversizedProtobufConnection, "POST /v1/metrics HTTP/1.1\r\nHost: sink\r\nContent-Type: application/x-protobuf\r\nContent-Length: 131073\r\nConnection: close\r\n\r\n"); err != nil {
		fatal(fmt.Errorf("send oversized protobuf headers: %w", err))
	}
	oversizedProtobufResponse, err := http.ReadResponse(bufio.NewReader(oversizedProtobufConnection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read oversized protobuf response: %w", err))
	}
	oversizedProtobufBody, readErr := io.ReadAll(oversizedProtobufResponse.Body)
	oversizedProtobufResponse.Body.Close()
	oversizedProtobufConnection.Close()
	if readErr != nil || oversizedProtobufResponse.StatusCode != http.StatusRequestEntityTooLarge || !bytes.Contains(oversizedProtobufBody, []byte("request body exceeds limit")) {
		fatal(fmt.Errorf("oversized protobuf: HTTP %d: %s: %v", oversizedProtobufResponse.StatusCode, oversizedProtobufBody, readErr))
	}

	expandedProtobuf := bytes.Repeat([]byte{0x0a, 0x00}, 64*1024)
	expandedResponse, err := http.Post(endpoint+"/v1/metrics", "application/x-protobuf", bytes.NewReader(expandedProtobuf))
	if err != nil {
		fatal(fmt.Errorf("send structurally expanded protobuf: %w", err))
	}
	expandedBody, readErr := io.ReadAll(expandedResponse.Body)
	expandedResponse.Body.Close()
	if readErr != nil || expandedResponse.StatusCode != http.StatusRequestEntityTooLarge || !bytes.Contains(expandedBody, []byte("decoded OTLP payload exceeds limit")) {
		fatal(fmt.Errorf("structurally expanded protobuf: HTTP %d: %s: %v", expandedResponse.StatusCode, expandedBody, readErr))
	}

	expandedJSON := append([]byte(`{"resourceMetrics":[`), bytes.Repeat([]byte(`{},`), 16*1024)...)
	expandedJSON = append(expandedJSON, []byte(`{}]}`)...)
	rejectJSON(
		endpoint,
		"/v1/metrics",
		"structurally expanded JSON",
		[]byte("structural limit"),
		expandedJSON,
	)

	partialConnection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect partial request: %w", err))
	}
	if _, err := fmt.Fprint(partialConnection, "POST /v1/metrics HTTP/1.1\r\nHost: sink"); err != nil {
		fatal(fmt.Errorf("send partial request: %w", err))
	}
	healthClient := http.Client{Timeout: 4 * time.Second}
	timeoutStarted := time.Now()
	healthResponse, err := healthClient.Get(endpoint + "/healthz")
	partialConnection.Close()
	if err != nil {
		fatal(fmt.Errorf("health check behind partial request: %w", err))
	}
	healthBody, readErr := io.ReadAll(healthResponse.Body)
	healthResponse.Body.Close()
	if readErr != nil || healthResponse.StatusCode != http.StatusOK || time.Since(timeoutStarted) > 3*time.Second {
		fatal(fmt.Errorf("partial request timeout: HTTP %d after %s: %s: %v", healthResponse.StatusCode, time.Since(timeoutStarted), healthBody, readErr))
	}

	requests := []struct {
		signal      string
		contentType string
		body        []byte
		marker      string
	}{
		{"traces", "application/x-protobuf", []byte{0x0a, 0x00}, "trace-protobuf"},
		{"traces", "application/json", []byte(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"probe-uppercase"},"spans":[{"traceId":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","spanId":"ABCDEFABCDEFABCD","name":"parent","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"},{"traceId":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","spanId":"FEDCBAFEDCBAFEDC","parentSpanId":"abcdefabcdefabcd","name":"child","kind":1,"startTimeUnixNano":"2","endTimeUnixNano":"3"}]}]}]}`), "trace-json-uppercase"},
		{"metrics", "application/x-protobuf", []byte{
			0x0a, 0x3e, 0x12, 0x3c, 0x0a, 0x11, 0x0a, 0x08,
			'p', 'r', 'o', 'b', 'e', '-', 'p', 'b', 0x12, 0x05,
			'1', '.', '2', '.', '3', 0x12, 0x27, 0x0a, 0x0f,
			'p', 'r', 'o', 'b', 'e', '-', 'p', 'b', '-', 'm', 'e', 't', 'r', 'i', 'c',
			0x2a, 0x14, 0x0a, 0x12, 0x19, 0x02, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f,
		}, "metric-protobuf"},
		{"logs", "application/json; charset=utf-8", []byte(`{"resourceLogs":[{"resource":{"attributes":[]},"scopeLogs":[{"scope":{"name":"probe-log","version":"4.5.6","attributes":[],"droppedAttributesCount":0},"logRecords":[{"timeUnixNano":"1","observedTimeUnixNano":"2","severityNumber":9,"severityText":"INFO","body":{"arrayValue":{"values":[{"bytesValue":"AQID/w=="},{"kvlistValue":{"values":[{"key":"nested","value":{"stringValue":"present"}}]}},{"doubleValue":"NaN"},{"doubleValue":"1.5"}]}},"attributes":[{"key":"probe.attribute","value":{"stringValue":"present"}}]}]}]}]}`), "log-json"},
	}
	for _, item := range requests {
		req, err := http.NewRequest(http.MethodPost, endpoint+"/v1/"+item.signal, bytes.NewReader(item.body))
		if err != nil {
			fatal(err)
		}
		req.Header.Set("Content-Type", item.contentType)
		req.Header.Set("X-Otel-Sink-Probe", item.marker)
		if item.marker == "trace-protobuf" {
			req.Header.Set("Content-Encoding", "Identity")
		}
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
		if item.marker == "trace-protobuf" && !bytes.Contains(record.Payload, []byte(`"resource_spans"`)) {
			fatal(fmt.Errorf("trace protobuf was not semantically decoded: %s", record.Payload))
		}
		if item.marker == "trace-protobuf" && record.Request.ContentEncoding != "identity" {
			fatal(fmt.Errorf("content encoding was not normalized: %q", record.Request.ContentEncoding))
		}
		if item.marker == "trace-json-uppercase" && !bytes.Contains(record.Payload, []byte("probe-uppercase")) {
			fatal(fmt.Errorf("trace JSON payload was not preserved: %s", record.Payload))
		}
		if item.signal != "traces" && !bytes.Contains(record.Payload, []byte("probe-")) {
			fatal(fmt.Errorf("JSON payload was not preserved: %s", record.Payload))
		}
		if item.marker == "metric-protobuf" && !bytes.Contains(record.Payload, []byte(`"NaN"`)) {
			fatal(fmt.Errorf("protobuf non-finite double was not preserved: %s", record.Payload))
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
	if readErr != nil || oversizedResponse.StatusCode != http.StatusRequestEntityTooLarge || !bytes.Contains(oversizedBody, []byte("validation source exceeds limit")) {
		fatal(fmt.Errorf("oversized validation source: HTTP %d: %s: %v", oversizedResponse.StatusCode, oversizedBody, readErr))
	}
	validRule := []byte(`(define-library (probe contract)
  (export validate-probe)
  (import (scheme base) (scheme write))
  (begin
    (define (validate-probe capture)
      (let ((requests (cadr (assq 'requests capture)))
            (resources (cadr (assq 'resources capture)))
            (spans (cadr (assq 'spans capture)))
            (metrics (cadr (assq 'metrics capture)))
            (logs (cadr (assq 'logs capture))))
        (if (and (= (length requests) 4)
                 (= (length resources) 4)
                 (string=? (cadr (assq 'schema-url (car resources))) "")
                 (= (length spans) 2)
                 (member 'child (map (lambda (span) (cadr (assq 'parent-class span))) spans))
                 (= (length metrics) 1)
                 (= (cadr (assq 'data-points (car metrics))) 1)
                 (cadr (assq 'data-points-valid (car metrics)))
                 (eq? (cadr (assq 'data-type (car metrics))) 'gauge)
                 (string=? (cadr (assq 'scope-version (car metrics))) "1.2.3")
                 (string=? (cadr (assq 'schema-url (car metrics))) "")
                 (null? (cadr (assq 'scope-attributes (car metrics))))
                 (= (length logs) 1)
                 (string=? (cadr (assq 'scope-version (car logs))) "4.5.6")
                 (string=? (cadr (assq 'schema-url (car logs))) "")
                 (equal? (cadr (assq 'body (car logs)))
                         '(array ((bytes (1 2 3 255))
                                  (kvlist (("nested" (string "present"))))
                                  (double "NaN")
                                  (double "1.5"))))
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
	assertSyntheticShapesPass(endpoint, syntheticFeatureIDs, syntheticShapeByFeature, syntheticFeatureCapture)
	featureFailures := []struct {
		featureID string
		capture   string
	}{
		{"traces.tracerprovider.get-a-tracer", strings.Replace(syntheticFeatureCapture, `((name "trace.scope")`, `((name "missing.scope")`, 1)},
		{"traces.tracerprovider.get-a-tracer-with-schema-url", strings.Replace(syntheticFeatureCapture, `(schema-url "https://opentelemetry.io/schemas/1.11.0")`, `(schema-url "")`, 1)},
		{"traces.tracer.create-a-new-span", strings.Replace(syntheticFeatureCapture, `(spans (`, `(spans ()) (unused-spans (`, 1)},
		{"traces.span.create-root-span", strings.Replace(syntheticFeatureCapture, `(parent-class root)`, `(parent-class external)`, 1)},
		{"traces.span.create-with-parent-from-context", strings.Replace(syntheticFeatureCapture, `(parent-class external)`, `(parent-class child)`, 1)},
		{"traces.span.create-with-default-parent-active-span", strings.NewReplacer(
			`(parent-class child)`, `(parent-class root)`,
			`(parent-class external)`, `(parent-class root)`,
		).Replace(syntheticFeatureCapture)},
		{"traces.span.end", strings.Replace(syntheticFeatureCapture, `(start 1) (end 4)`, `(start 1) (end 0)`, 1)},
		{"traces.span-attributes.string-type", strings.NewReplacer(
			`("string.key" (string `, `("string.key" (bytes `,
			`("unicode.key" (string `, `("unicode.key" (bytes `,
		).Replace(syntheticFeatureCapture)},
		{"traces.span-attributes.signed-int64-type", strings.ReplaceAll(syntheticFeatureCapture, `("integer.key" (integer `, `("integer.key" (double `)},
		{"traces.span-exceptions.recordexception", strings.Replace(syntheticFeatureCapture, `(name "exception")`, `(name "not-exception")`, 1)},
		{"metrics.meterprovider-provides-a-way-to-get-a-meter", strings.ReplaceAll(syntheticFeatureCapture, `(scope "meter.scope")`, `(scope "")`)},
		{"metrics.get-meter-accepts-name-version-and-schema-url", strings.ReplaceAll(syntheticFeatureCapture, `(scope-version "1.2.3") (schema-url "https://opentelemetry.io/schemas/1.11.0")`, `(scope-version "1.2.3") (schema-url "")`)},
		{"metrics.counter-instrument-is-supported", strings.Replace(syntheticFeatureCapture, `(data-type sum) (aggregation-temporality delta)`, `(data-type summary) (aggregation-temporality delta)`, 1)},
		{"metrics.updowncounter-instrument-is-supported", strings.Replace(syntheticFeatureCapture, `(data-type sum) (aggregation-temporality cumulative)`, `(data-type summary) (aggregation-temporality cumulative)`, 1)},
		{"metrics.histogram-instrument-is-supported", strings.Replace(syntheticFeatureCapture, `(data-type histogram)`, `(data-type summary)`, 1)},
		{"metrics.asynchronousgauge-instrument-is-supported", strings.Replace(syntheticFeatureCapture, `(data-type gauge)`, `(data-type summary)`, 1)},
		{"metrics.instruments-have-name", strings.Replace(syntheticFeatureCapture, `(name "counter")`, `(name "")`, 1)},
		{"metrics.instruments-have-kind", strings.Replace(syntheticFeatureCapture, `(data-type sum)`, `(data-type 7)`, 1)},
		{"metrics.instruments-have-an-optional-unit-of-measure", strings.Replace(syntheticFeatureCapture, `(unit "{item}")`, `(unit 7)`, 1)},
		{"metrics.instruments-have-an-optional-description", strings.Replace(syntheticFeatureCapture, `(description "counter description")`, `(description 7)`, 1)},
		{"metrics.a-specified-resource-can-be-associated-with-all-the-produced-metrics-from-any-meter-from-the-meterprovider", strings.Replace(syntheticFeatureCapture, `((signal metrics) (attributes`, `((signal traces) (attributes`, 1)},
		{"metrics.the-sum-aggregation-is-available", strings.ReplaceAll(syntheticFeatureCapture, `(data-type sum)`, `(data-type summary)`)},
		{"metrics.the-lastvalue-aggregation-is-available", strings.Replace(syntheticFeatureCapture, `(data-type gauge)`, `(data-type summary)`, 1)},
		{"metrics.the-explicitbuckethistogram-aggregation-is-available", strings.Replace(syntheticFeatureCapture, `(data-type histogram)`, `(data-type summary)`, 1)},
		{"logs.loggerprovider-get-logger", strings.Replace(syntheticFeatureCapture, syntheticLogsBlock, " (logs ()))", 1)},
		{"logs.logger-emit-logrecord", strings.Replace(syntheticFeatureCapture, syntheticLogsBlock, " (logs ()))", 1)},
		{"logs.otlp-http-exporter", strings.Replace(syntheticFeatureCapture, `(path "/v1/logs")`, `(path "/v1/logs/")`, 1)},
		{"resource.create-from-attributes", strings.Replace(syntheticFeatureCapture, `(attributes (("process.runtime.name" (string "go")) ("service.name" (string "synthetic-service"))))`, `(attributes ())`, 1)},
		{"resource.resource-detector-interface-mechanism", strings.Replace(syntheticFeatureCapture, `(string "go")`, `(string "rust")`, 1)},
		{"resource.resource-detectors-populate-schema-url", strings.Replace(syntheticFeatureCapture, `(schema-url "https://opentelemetry.io/schemas/1.43.0")`, `(schema-url "")`, 1)},
		{"exporters.otlp.otlp-http-binary-protobuf-exporter", strings.Replace(syntheticFeatureCapture, `(content-type "application/x-protobuf")`, `(content-type "application/json")`, 1)},
		{"traces.tracerprovider.create-tracerprovider", strings.Replace(syntheticFeatureCapture, `(spans (`, `(spans ()) (unused-spans (`, 1)},
		{"traces.span-attributes.setattribute", strings.NewReplacer(
			`(attributes (("string.key" (string "value")) ("integer.key" (integer 7)) ("unicode.key" (string "ünïcødé"))))`, `(attributes ())`,
			`(attributes (("string.key" (string "child")) ("integer.key" (integer 8))))`, `(attributes ())`,
		).Replace(syntheticFeatureCapture)},
		{"traces.spancontext.isvalid", strings.Replace(syntheticFeatureCapture, `(span-id "222222222222222a")`, `(span-id "0000000000000000")`, 1)},
		{"traces.spancontext.conforms-to-the-w3c-tracecontext-spec", strings.Replace(syntheticFeatureCapture, `(trace-state "")`, `(trace-state "bad key=1")`, 1)},
		{"traces.span.updatename", strings.Replace(syntheticFeatureCapture, `(name "GET /api/articles/:slug")`, `(name "HTTP GET")`, 1)},
		{"traces.span.set-status-with-statuscode-unset-ok-error", strings.Replace(syntheticFeatureCapture, `(status-code 2)`, `(status-code 0)`, 1)},
		{"traces.spancontext.isremote", strings.Replace(syntheticFeatureCapture, `(parent-class external)`, `(parent-class child)`, 1)},
		{"traces.span-attributes.unicode-support-for-keys-and-string-values", strings.Replace(syntheticFeatureCapture, `("unicode.key" (string "ünïcødé"))`, `("unicode.key" (string "ascii"))`, 1)},
		{"traces.span-events.addevent", strings.Replace(syntheticFeatureCapture, `(events (`, `(events ()) (unused-events (`, 1)},
		{"resource.retrieve-attributes", strings.Replace(syntheticFeatureCapture, `(attributes (("process.runtime.name" (string "go")) ("service.name" (string "synthetic-service"))))`, `(attributes ())`, 1)},
		{"environment-variables.otel-service-name", strings.Replace(syntheticFeatureCapture, `("service.name" (string "synthetic-service"))`, `("service.name" (string "unknown_service:python"))`, 1)},
		{"environment-variables.otel-traces-exporter", strings.Replace(syntheticFeatureCapture, `((signal traces) (received-unix-nano 1)`, `((signal metrics) (received-unix-nano 1)`, 1)},
		{"environment-variables.otel-metrics-exporter", strings.ReplaceAll(syntheticFeatureCapture, `((signal metrics) (received-unix-nano`, `((signal traces) (received-unix-nano`)},
		{"environment-variables.otel-logs-exporter", strings.Replace(syntheticFeatureCapture, `((signal logs) (received-unix-nano 4)`, `((signal traces) (received-unix-nano 4)`, 1)},
		{"environment-variables.otel-metric-export-interval", strings.Replace(syntheticFeatureCapture, `((signal metrics) (received-unix-nano 3)`, `((signal traces) (received-unix-nano 3)`, 1)},
		{"metrics.instrument-names-conform-to-the-specified-syntax", strings.Replace(syntheticFeatureCapture, `(name "counter")`, `(name "9counter")`, 1)},
		{"metrics.instrument-units-conform-to-the-specified-syntax", strings.Replace(syntheticFeatureCapture, `(unit "ms")`, `(unit "µs")`, 1)},
		{"metrics.instrument-descriptions-conform-to-the-specified-syntax", strings.Replace(syntheticFeatureCapture, `(description "gauge description")`, `(description 7)`, 1)},
		{"environment-variables.otel-exporter-otlp-metrics-temporality-preference", strings.ReplaceAll(syntheticFeatureCapture, `(aggregation-temporality delta)`, `(aggregation-temporality cumulative)`)},
		{"metrics.the-metrics-sdk-samples-exemplars-from-measurements", strings.NewReplacer(`(exemplars 2)`, `(exemplars 0)`, `(exemplars 1)`, `(exemplars 0)`).Replace(syntheticFeatureCapture)},
		{"metrics.exemplars-contain-the-associated-trace-id-and-span-id-of-the-active-span-in-the-context-when-the-measurement-was-taken", strings.Replace(syntheticFeatureCapture, `(exemplars-with-trace-context 2)`, `(exemplars-with-trace-context 1)`, 1)},
		{"metrics.exemplars-contain-the-timestamp-when-the-measurement-was-taken", strings.Replace(syntheticFeatureCapture, `(exemplars-with-time 2)`, `(exemplars-with-time 1)`, 1)},
		{"metrics.metric-sdk-supports-per-timeseries-cumulative-start-timestamps", strings.Replace(syntheticFeatureCapture, `(points-start-le-time 2)`, `(points-start-le-time 1)`, 1)},
		{"metrics.the-default-aggregation-is-available", strings.Replace(syntheticFeatureCapture, `(data-type histogram)`, `(data-type summary)`, 1)},
		{"exporters.otlp.honors-the-user-agent-spec", strings.Replace(syntheticFeatureCapture, `("user-agent" "OTel-OTLP-Exporter-Python/1.44.0")`, `("user-agent" "curl/8.0.0")`, 1)},
		{"exporters.otlp.schemaurl-in-resourcespans-and-scopespans", strings.Replace(syntheticFeatureCapture, `(schema-url "https://opentelemetry.io/schemas/1.11.0")`, `(schema-url "")`, 1)},
		{"exporters.otlp.schemaurl-in-resourcemetrics-and-scopemetrics", strings.NewReplacer(
			`(schema-url "https://opentelemetry.io/schemas/1.43.0")`, `(schema-url "")`,
			`(scope-version "1.2.3") (schema-url "https://opentelemetry.io/schemas/1.11.0")`, `(scope-version "1.2.3") (schema-url "")`,
		).Replace(syntheticFeatureCapture)},
		{"exporters.otlp.schemaurl-in-resourcelogs-and-scopelogs", strings.Replace(syntheticFeatureCapture, syntheticLogsBlock, syntheticLogsBlockWithoutSchemaURL, 1)},
	}
	// Every capture shape a proof rule asserts must also have a negative
	// mutation, or a shape that is trivially true would still read as proof.
	mutatedShapes := map[string]bool{}
	for _, failure := range featureFailures {
		if failure.capture == syntheticFeatureCapture {
			fatal(fmt.Errorf("mutation for %s did not change the synthetic capture", failure.featureID))
		}
		mutatedShapes[syntheticShapeByFeature[failure.featureID]] = true
	}
	uncoveredShapes := []string{}
	for featureID, shape := range syntheticShapeByFeature {
		if !mutatedShapes[shape] {
			uncoveredShapes = append(uncoveredShapes, shape+" ("+featureID+")")
		}
	}
	if len(uncoveredShapes) > 0 {
		sort.Strings(uncoveredShapes)
		fatal(fmt.Errorf("capture shapes without a negative mutation: %s", strings.Join(uncoveredShapes, ", ")))
	}
	for _, failure := range featureFailures {
		assertSyntheticShapeFailure(endpoint, failure.featureID, syntheticShapeByFeature[failure.featureID], failure.capture)
	}
	assertSyntheticShapeFailure(endpoint, "unknown.feature", "unknown/shape", syntheticFeatureCapture)
	structuredContractRule := []byte(`(import (scheme base) (scheme write))
(define (contract-error message)
  (display "[[OTLP-CONTRACT-V1:" (current-error-port))
  (display (string-length message) (current-error-port))
  (display "]]" (current-error-port))
  (display message (current-error-port))
  (error "OTLP contract sentinel"))
(contract-error "intentional réjection")`)
	if output, status, err := validateScheme(endpoint, structuredContractRule); err != nil {
		fatal(err)
	} else if status != http.StatusConflict || !bytes.Contains(output, []byte("intentional réjection")) {
		fatal(fmt.Errorf("contract-rejecting Scheme rule returned HTTP %d: %s", status, output))
	}
	forgedContractRule := []byte(`(import (scheme base) (scheme write))
(display "[[OTLP-CONTRACT-V1:6]]forged" (current-error-port))
(error "validator fault")`)
	if output, status, err := validateScheme(endpoint, forgedContractRule); err != nil {
		fatal(err)
	} else if status != http.StatusUnprocessableEntity || !bytes.Contains(output, []byte("validator fault")) {
		fatal(fmt.Errorf("forged contract diagnostic returned HTTP %d: %s", status, output))
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
	rejectJSON(endpoint, "/v1/logs", "malformed numeric log flags", []byte("unexpected JSON type"), []byte(`{"resourceLogs":[{"scopeLogs":[{"logRecords":[{"flags":"broken"}]}]}]}`))
	resetSink(endpoint)
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
	wantScopes := []string{
		"example.custom/db-client",
		"foo.bar",
		"foo/bar",
		"Foo.Bar",
	}
	scopesPresent := true
	for _, scope := range wantScopes {
		scopesPresent = scopesPresent && bytes.Contains(candidateBody, []byte(scope))
	}
	if readErr != nil || candidate.StatusCode != http.StatusOK || !scopesPresent || !bytes.Contains(candidateBody, []byte("scenario-shape")) {
		fatal(fmt.Errorf("custom candidate: HTTP %d: %s: %v", candidate.StatusCode, candidateBody, readErr))
	}
	resetSink(endpoint)
	var wideTrace strings.Builder
	wideTrace.WriteString(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"wide.probe"},"spans":[`)
	for index := 0; index < 33; index++ {
		if index > 0 {
			wideTrace.WriteByte(',')
		}
		parent := ""
		if index > 0 {
			parent = `,"parentSpanId":"0000000000000001"`
		}
		fmt.Fprintf(&wideTrace, `{"traceId":"99999999999999999999999999999999","spanId":"%016x"%s,"name":"span-%d","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"}`, index+1, parent, index)
	}
	wideTrace.WriteString(`]}]}]}`)
	postJSON(endpoint, "/v1/traces", "33-span trace", []byte(wideTrace.String()))
	freezeCapture(endpoint, "/dump", "33-span capture")
	wideCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate 33-span candidate: %w", err))
	}
	wideCandidateBody, readErr := io.ReadAll(wideCandidate.Body)
	wideCandidate.Body.Close()
	if readErr != nil || wideCandidate.StatusCode != http.StatusOK || !bytes.Contains(wideCandidateBody, []byte("wide.probe")) {
		fatal(fmt.Errorf("33-span candidate: HTTP %d: %s: %v", wideCandidate.StatusCode, wideCandidateBody, readErr))
	}
	resetSink(endpoint)
	topologyTrace := []byte(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"shape.probe"},"spans":[{"traceId":"12121212121212121212121212121212","spanId":"3333333333333333","parentSpanId":"1111111111111111","name":"beta","kind":1,"startTimeUnixNano":"30","endTimeUnixNano":"40"},{"traceId":"12121212121212121212121212121212","spanId":"1111111111111111","name":"root","kind":2,"startTimeUnixNano":"10","endTimeUnixNano":"50"},{"traceId":"12121212121212121212121212121212","spanId":"2222222222222222","parentSpanId":"1111111111111111","name":"alpha","kind":1,"startTimeUnixNano":"20","endTimeUnixNano":"30"}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "trace-shape topology", topologyTrace)
	matchingShape := `(traces
  (repeat 1
    (trace (coverage 'complete)
      (unordered
        (span (scope "shape.probe") (kind 'server) (status 'unset) (name (exact "root")) (http-status 'absent)
          (children (unordered
            (between 1 1 (span (scope "shape.probe") (kind 'internal) (status 'unset) (name (exact "beta")) (http-status 'absent)))
            (span (scope "shape.probe") (kind 'internal) (status 'unset) (name (one-of (exact "alpha") (exact "alternate"))) (http-status 'absent))
            (optional (span (scope "shape.probe") (name (exact "not-present")))))))))))`
	if output, status, err := validateShape(endpoint, matchingShape); err != nil {
		fatal(err)
	} else if status != http.StatusOK {
		fatal(fmt.Errorf("unordered/combinator trace shape returned HTTP %d: %s", status, output))
	}
	movedChildShape := `(traces
  (trace (coverage 'complete)
    (unordered
      (span (scope "shape.probe") (name (exact "root"))
        (children (unordered
          (span (scope "shape.probe") (name (exact "alpha"))
            (children (unordered (span (scope "shape.probe") (name (exact "beta"))))))))))))`
	if output, status, err := validateShape(endpoint, movedChildShape); err != nil {
		fatal(err)
	} else if status != http.StatusConflict || !bytes.Contains(output, []byte("trace-shape mismatch at traces")) || !bytes.Contains(output, []byte("nearest actual tree")) {
		fatal(fmt.Errorf("mis-parented child shape returned HTTP %d: %s", status, output))
	}
	resetSink(endpoint)
	partialTrace := []byte(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"shape.probe"},"spans":[{"traceId":"34343434343434343434343434343434","spanId":"5555555555555555","parentSpanId":"4444444444444444","name":"remote-child","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "partial trace shape", partialTrace)
	partialShape := `(traces (trace (coverage 'partial) (unordered (span (scope "shape.probe") (kind 'internal) (status 'unset) (name (exact "remote-child")) (http-status 'absent)))))`
	if output, status, err := validateShape(endpoint, partialShape); err != nil {
		fatal(err)
	} else if status != http.StatusOK {
		fatal(fmt.Errorf("partial trace shape returned HTTP %d: %s", status, output))
	}
	completeShape := `(traces (trace (coverage 'complete) (unordered (span (scope "shape.probe") (name (exact "remote-child"))))))`
	if output, status, err := validateShape(endpoint, completeShape); err != nil {
		fatal(err)
	} else if status != http.StatusConflict {
		fatal(fmt.Errorf("complete policy accepted a partial trace: HTTP %d: %s", status, output))
	}
	resetSink(endpoint)
	dualStatusTrace := []byte(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"status-alias.probe"},"spans":[{"traceId":"45454545454545454545454545454545","spanId":"6666666666666666","name":"GET /probe","kind":2,"startTimeUnixNano":"1","endTimeUnixNano":"2","attributes":[{"key":"http.status_code","value":{"intValue":"200"}},{"key":"http.response.status_code","value":{"intValue":"201"}}]}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "dual HTTP-status aliases", dualStatusTrace)
	dualStatusCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate dual HTTP-status candidate: %w", err))
	}
	dualStatusBody, readErr := io.ReadAll(dualStatusCandidate.Body)
	dualStatusCandidate.Body.Close()
	if readErr != nil || dualStatusCandidate.StatusCode != http.StatusOK || !bytes.Contains(dualStatusBody, []byte("(http-status 201)")) {
		fatal(fmt.Errorf("dual HTTP-status candidate: HTTP %d: %s: %v", dualStatusCandidate.StatusCode, dualStatusBody, readErr))
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
	if readErr != nil || selfParentCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(selfParentBody, []byte("span parent topology is cyclic")) {
		fatal(fmt.Errorf("self-parent candidate: HTTP %d: %s: %v", selfParentCandidate.StatusCode, selfParentBody, readErr))
	}
	resetSink(endpoint)
	cyclicTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"cycle.probe"},"spans":[{"traceId":"dddddddddddddddddddddddddddddddd","spanId":"1111111111111111","parentSpanId":"2222222222222222","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}},{"traceId":"dddddddddddddddddddddddddddddddd","spanId":"2222222222222222","parentSpanId":"1111111111111111","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "cyclic trace", cyclicTrace)
	freezeCapture(endpoint, "/dump", "cyclic capture")
	cyclicCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate cyclic candidate: %w", err))
	}
	cyclicBody, readErr := io.ReadAll(cyclicCandidate.Body)
	cyclicCandidate.Body.Close()
	if readErr != nil || cyclicCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(cyclicBody, []byte("span parent topology is cyclic")) {
		fatal(fmt.Errorf("cyclic candidate: HTTP %d: %s: %v", cyclicCandidate.StatusCode, cyclicBody, readErr))
	}
	resetSink(endpoint)
	multipleRootsTrace := []byte(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"roots.probe"},"spans":[{"traceId":"56565656565656565656565656565656","spanId":"1111111111111111","name":"root-one","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"},{"traceId":"56565656565656565656565656565656","spanId":"2222222222222222","name":"root-two","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "multiple-root trace", multipleRootsTrace)
	multipleRootsCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate multiple-root candidate: %w", err))
	}
	multipleRootsBody, readErr := io.ReadAll(multipleRootsCandidate.Body)
	multipleRootsCandidate.Body.Close()
	if readErr != nil || multipleRootsCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(multipleRootsBody, []byte("multiple explicit roots")) {
		fatal(fmt.Errorf("multiple-root candidate: HTTP %d: %s: %v", multipleRootsCandidate.StatusCode, multipleRootsBody, readErr))
	}
	resetSink(endpoint)
	duplicateSpanTrace := []byte(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"duplicate-span.probe"},"spans":[{"traceId":"78787878787878787878787878787878","spanId":"3333333333333333","name":"first","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"},{"traceId":"78787878787878787878787878787878","spanId":"3333333333333333","name":"second","kind":1,"startTimeUnixNano":"1","endTimeUnixNano":"2"}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "duplicate-span trace", duplicateSpanTrace)
	duplicateSpanCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate duplicate-span candidate: %w", err))
	}
	duplicateSpanBody, readErr := io.ReadAll(duplicateSpanCandidate.Body)
	duplicateSpanCandidate.Body.Close()
	if readErr != nil || duplicateSpanCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(duplicateSpanBody, []byte("duplicate span ID")) {
		fatal(fmt.Errorf("duplicate-span candidate: HTTP %d: %s: %v", duplicateSpanCandidate.StatusCode, duplicateSpanBody, readErr))
	}
	resetSink(endpoint)
	invalidTraceID := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"trace-id.probe"},"spans":[{"traceId":"00000000000000000000000000000000","spanId":"5555555555555555","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","status":{"code":0}}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "invalid trace-ID candidate", invalidTraceID)
	freezeCapture(endpoint, "/dump", "invalid trace-ID capture")
	invalidTraceIDCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate invalid trace-ID candidate: %w", err))
	}
	invalidTraceIDBody, readErr := io.ReadAll(invalidTraceIDCandidate.Body)
	invalidTraceIDCandidate.Body.Close()
	if readErr != nil || invalidTraceIDCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(invalidTraceIDBody, []byte("invalid trace ID")) {
		fatal(fmt.Errorf("invalid trace-ID candidate: HTTP %d: %s: %v", invalidTraceIDCandidate.StatusCode, invalidTraceIDBody, readErr))
	}
	resetSink(endpoint)
	malformedCollectionTrace := []byte(`{"resourceSpans":[{"resource":{"attributes":[]},"scopeSpans":[{"scope":{"name":"collection.probe"},"spans":[{"traceId":"eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","spanId":"6666666666666666","name":"SELECT","kind":3,"startTimeUnixNano":"1","endTimeUnixNano":"2","links":"corrupt","status":{"code":0}}]}]}]}`)
	rejectJSON(
		endpoint,
		"/v1/traces",
		"malformed-collection trace",
		[]byte("expected array"),
		malformedCollectionTrace,
	)
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
	malformedMetric := []byte(`{"resourceMetrics":[{"scopeMetrics":[{"scope":{"name":"metric.probe"},"metrics":[{"name":"broken","gauge":{"dataPoints":[{"timeUnixNano":"1","asInt":"1"}]},"sum":{"dataPoints":[{"timeUnixNano":"2","asInt":"2"}]}}]}]}]}`)
	postJSON(endpoint, "/v1/metrics", "malformed metric", malformedMetric)
	malformedMetricDump := freezeCapture(endpoint, "/dump.scm", "malformed-metric Scheme capture")
	if !bytes.Contains(malformedMetricDump, []byte("(data-type multiple)")) || !bytes.Contains(malformedMetricDump, []byte("(data-points-valid #f)")) {
		fatal(fmt.Errorf("malformed metric point was absent from Scheme capture: %s", malformedMetricDump))
	}
	resetSink(endpoint)
	nullOneofs := []byte(`{"resourceMetrics":[{"scopeMetrics":[{"scope":{"name":"metric.probe"},"metrics":[{"name":"null-oneofs","gauge":{"dataPoints":[{"timeUnixNano":"9","asInt":"1","asDouble":null,"exemplars":[{"timeUnixNano":"9","asInt":"1","asDouble":null}]}]},"summary":null}]}]}]}`)
	postJSON(endpoint, "/v1/metrics", "null oneof alternatives", nullOneofs)
	nullOneofsDump := freezeCapture(endpoint, "/dump.scm", "null-oneofs Scheme capture")
	if !bytes.Contains(nullOneofsDump, []byte("(data-type gauge)")) || !bytes.Contains(nullOneofsDump, []byte("(data-points-valid #t)")) {
		fatal(fmt.Errorf("null oneof alternatives were not treated as unset: %s", nullOneofsDump))
	}
	resetSink(endpoint)
	defaultedMetrics := []byte(`{"resourceMetrics":[{"scopeMetrics":[{"scope":{"name":"metric.probe"},"metrics":[{"name":"nullable-histogram","metadata":null,"histogram":{"dataPoints":[{"attributes":null,"startTimeUnixNano":null,"timeUnixNano":"3","count":"1","sum":null,"bucketCounts":["1"],"explicitBounds":[],"min":null,"max":null,"flags":null}],"aggregationTemporality":2}},{"name":"defaulted-summary","summary":{"dataPoints":[{"timeUnixNano":"4","count":"0"}]}},{"name":"maximum-uint64-histogram","histogram":{"dataPoints":[{"timeUnixNano":"18446744073709551615","count":"18446744073709551615","bucketCounts":["18446744073709551615"],"explicitBounds":[]}],"aggregationTemporality":2}},{"name":"aggregation-semantics","sum":{"dataPoints":[{"timeUnixNano":"5","asInt":"1"}],"aggregationTemporality":2,"isMonotonic":true}},{"name":"no-recorded-value","gauge":{"dataPoints":[{"timeUnixNano":"7","flags":1}]}}]}]}]}`)
	postJSON(endpoint, "/v1/metrics", "defaulted metrics", defaultedMetrics)
	defaultedMetricsDump := freezeCapture(endpoint, "/dump.scm", "defaulted-metrics Scheme capture")
	if bytes.Count(defaultedMetricsDump, []byte("(data-points-valid #t)")) != 5 || !bytes.Contains(defaultedMetricsDump, []byte("(aggregation-temporality cumulative) (monotonic #t)")) {
		fatal(fmt.Errorf("defaulted metric fields were rejected by Scheme projection: %s", defaultedMetricsDump))
	}
	resetSink(endpoint)
	invalidMetricSemantics := []byte(`{"resourceMetrics":[{"scopeMetrics":[{"scope":{"name":"metric.probe"},"metrics":[{"name":"missing-temporality","sum":{"dataPoints":[{"timeUnixNano":"2","asInt":"1"}],"aggregationTemporality":0,"isMonotonic":true}},{"name":"descending-bounds","histogram":{"dataPoints":[{"timeUnixNano":"3","count":"3","bucketCounts":["1","1","1"],"explicitBounds":[10,1]}],"aggregationTemporality":2}},{"name":"invalid-exemplar","gauge":{"dataPoints":[{"timeUnixNano":"4","asInt":"1","exemplars":[{"timeUnixNano":"0"}]}]}},{"name":"invalid-exponential-mapping","exponentialHistogram":{"dataPoints":[{"timeUnixNano":"5","count":"0","scale":21,"zeroThreshold":-1}],"aggregationTemporality":2}},{"name":"inverted-extrema","histogram":{"dataPoints":[{"timeUnixNano":"6","count":"0","bucketCounts":["0"],"explicitBounds":[],"min":2,"max":1}],"aggregationTemporality":2}},{"name":"no-recorded-value","gauge":{"dataPoints":[{"timeUnixNano":"7","asInt":"1","flags":1}]}},{"name":"unsorted-summary","summary":{"dataPoints":[{"timeUnixNano":"8","count":"2","sum":3,"quantileValues":[{"quantile":0.9,"value":1},{"quantile":0.5,"value":2}]}]}}]}]}]}`)
	postJSON(endpoint, "/v1/metrics", "invalid metric semantics", invalidMetricSemantics)
	invalidMetricDump := freezeCapture(endpoint, "/dump.scm", "invalid-metric-semantics Scheme capture")
	if bytes.Count(invalidMetricDump, []byte("(data-points-valid #f)")) != 6 {
		fatal(fmt.Errorf("invalid metric semantics were absent from Scheme capture: %s", invalidMetricDump))
	}
	resetSink(endpoint)
	invalidStatusSpan := append([]byte{}, lengthDelimited(0x0a, bytes.Repeat([]byte{0x11}, 16))...)
	invalidStatusSpan = append(invalidStatusSpan, lengthDelimited(0x12, bytes.Repeat([]byte{0x22}, 8))...)
	invalidStatusSpan = append(invalidStatusSpan, lengthDelimited(0x2a, []byte("GET /probe"))...)
	invalidStatusSpan = append(invalidStatusSpan, 0x30, 0x02)
	invalidStatusSpan = append(invalidStatusSpan, 0x39, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	invalidStatusSpan = append(invalidStatusSpan, 0x41, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	invalidStatusSpan = append(invalidStatusSpan, lengthDelimited(0x7a, []byte{0x18, 0x63})...)
	invalidStatusScope := lengthDelimited(0x0a, []byte("status.probe"))
	invalidStatusGroup := append(lengthDelimited(0x0a, invalidStatusScope), lengthDelimited(0x12, invalidStatusSpan)...)
	invalidStatusResource := lengthDelimited(0x12, invalidStatusGroup)
	invalidStatusRequest := lengthDelimited(0x0a, invalidStatusResource)
	invalidStatusResponse, err := http.Post(endpoint+"/v1/traces", "application/x-protobuf", bytes.NewReader(invalidStatusRequest))
	if err != nil {
		fatal(fmt.Errorf("send invalid-status candidate trace: %w", err))
	}
	invalidStatusBody, readErr := io.ReadAll(invalidStatusResponse.Body)
	invalidStatusResponse.Body.Close()
	if readErr != nil || invalidStatusResponse.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send invalid-status candidate trace: HTTP %d: %s: %v", invalidStatusResponse.StatusCode, invalidStatusBody, readErr))
	}
	if output, status, err := validateScheme(endpoint, []byte(`(import (scheme base)) #t`)); err != nil {
		fatal(err)
	} else if status != http.StatusConflict || !bytes.Contains(output, []byte("invalid span status")) {
		fatal(fmt.Errorf("invalid-status contract validation returned HTTP %d: %s", status, output))
	}
	freezeCapture(endpoint, "/dump", "invalid-status candidate capture")
	invalidStatusCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate invalid-status candidate: %w", err))
	}
	invalidStatusCandidateBody, readErr := io.ReadAll(invalidStatusCandidate.Body)
	invalidStatusCandidate.Body.Close()
	if readErr != nil || invalidStatusCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(invalidStatusCandidateBody, []byte("invalid span status 99")) {
		fatal(fmt.Errorf("invalid-status candidate: HTTP %d: %s: %v", invalidStatusCandidate.StatusCode, invalidStatusCandidateBody, readErr))
	}
	resetSink(endpoint)
	unnamedSpan := append([]byte{}, lengthDelimited(0x0a, bytes.Repeat([]byte{0x33}, 16))...)
	unnamedSpan = append(unnamedSpan, lengthDelimited(0x12, bytes.Repeat([]byte{0x44}, 8))...)
	unnamedSpan = append(unnamedSpan, 0x30, 0x02)
	unnamedSpan = append(unnamedSpan, 0x39, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	unnamedSpan = append(unnamedSpan, 0x41, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	unnamedScope := lengthDelimited(0x0a, []byte("unnamed.probe"))
	unnamedGroup := append(lengthDelimited(0x0a, unnamedScope), lengthDelimited(0x12, unnamedSpan)...)
	unnamedRequest := lengthDelimited(0x0a, lengthDelimited(0x12, unnamedGroup))
	unnamedResponse, err := http.Post(endpoint+"/v1/traces", "application/x-protobuf", bytes.NewReader(unnamedRequest))
	if err != nil {
		fatal(fmt.Errorf("send unnamed candidate trace: %w", err))
	}
	unnamedBody, readErr := io.ReadAll(unnamedResponse.Body)
	unnamedResponse.Body.Close()
	if readErr != nil || unnamedResponse.StatusCode != http.StatusOK {
		fatal(fmt.Errorf("send unnamed candidate trace: HTTP %d: %s: %v", unnamedResponse.StatusCode, unnamedBody, readErr))
	}
	freezeCapture(endpoint, "/dump", "unnamed candidate capture")
	unnamedCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate unnamed candidate: %w", err))
	}
	unnamedCandidateBody, readErr := io.ReadAll(unnamedCandidate.Body)
	unnamedCandidate.Body.Close()
	if readErr != nil || unnamedCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(unnamedCandidateBody, []byte("span has no name")) {
		fatal(fmt.Errorf("unnamed candidate: HTTP %d: %s: %v", unnamedCandidate.StatusCode, unnamedCandidateBody, readErr))
	}
	resetSink(endpoint)
	invalidTimestampTrace := []byte(`{"resourceSpans":[{"scopeSpans":[{"scope":{"name":"timestamp.probe"},"spans":[{"traceId":"55555555555555555555555555555555","spanId":"6666666666666666","name":"GET /probe","kind":2,"startTimeUnixNano":"2","endTimeUnixNano":"1","status":{"code":0}}]}]}]}`)
	postJSON(endpoint, "/v1/traces", "invalid-timestamp candidate trace", invalidTimestampTrace)
	freezeCapture(endpoint, "/dump", "invalid-timestamp candidate capture")
	invalidTimestampCandidate, err := http.Get(endpoint + "/candidate?app=custom-app")
	if err != nil {
		fatal(fmt.Errorf("generate invalid-timestamp candidate: %w", err))
	}
	invalidTimestampBody, readErr := io.ReadAll(invalidTimestampCandidate.Body)
	invalidTimestampCandidate.Body.Close()
	if readErr != nil || invalidTimestampCandidate.StatusCode != http.StatusUnprocessableEntity || !bytes.Contains(invalidTimestampBody, []byte("span timestamps are not ordered")) {
		fatal(fmt.Errorf("invalid-timestamp candidate: HTTP %d: %s: %v", invalidTimestampCandidate.StatusCode, invalidTimestampBody, readErr))
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
	largeUnknownProtobuf := bytes.Repeat([]byte{0x7d, 0x00, 0x00, 0x00, 0x00}, 24*1024)
	rejected := false
	for index := 0; index < 35; index++ {
		response, err := http.Post(endpoint+"/v1/metrics", "application/x-protobuf", bytes.NewReader(largeUnknownProtobuf))
		if err != nil {
			fatal(fmt.Errorf("send cumulative capture probe %d: %w", index, err))
		}
		contents, readErr := io.ReadAll(response.Body)
		response.Body.Close()
		wantStatus := http.StatusOK
		if rejected || response.StatusCode == http.StatusRequestEntityTooLarge {
			wantStatus = http.StatusRequestEntityTooLarge
			rejected = true
		}
		if readErr != nil || response.StatusCode != wantStatus || (wantStatus == http.StatusRequestEntityTooLarge && !bytes.Contains(contents, []byte("cumulative OTLP capture exceeds limit"))) {
			fatal(fmt.Errorf("cumulative capture probe %d: HTTP %d: %s: %v", index, response.StatusCode, contents, readErr))
		}
	}
	if !rejected {
		fatal(errors.New("cumulative capture probe never reached the retained-memory limit"))
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

func lengthDelimited(tag byte, payload []byte) []byte {
	field := []byte{tag}
	length := len(payload)
	for length >= 0x80 {
		field = append(field, byte(length)|0x80)
		length >>= 7
	}
	field = append(field, byte(length))
	return append(field, payload...)
}

func rejectJSON(endpoint, path, label string, want []byte, body []byte) {
	response, err := http.Post(endpoint+path, "application/json", bytes.NewReader(body))
	if err != nil {
		fatal(fmt.Errorf("send %s: %w", label, err))
	}
	contents, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil || response.StatusCode != http.StatusBadRequest || !bytes.Contains(contents, want) {
		fatal(fmt.Errorf("send %s: HTTP %d: %s: %v", label, response.StatusCode, contents, readErr))
	}
}

func rejectContentType(endpoint, contentType string, want []byte) {
	request, err := http.NewRequest(http.MethodPost, endpoint+"/v1/metrics", bytes.NewReader([]byte(`{}`)))
	if err != nil {
		fatal(fmt.Errorf("create malformed Content-Type request: %w", err))
	}
	request.Header.Set("Content-Type", contentType)
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		fatal(fmt.Errorf("send malformed Content-Type: %w", err))
	}
	contents, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil || response.StatusCode != http.StatusBadRequest || !bytes.Contains(contents, want) {
		fatal(fmt.Errorf("send malformed Content-Type: HTTP %d: %s: %v", response.StatusCode, contents, readErr))
	}
}

func rejectRawRequest(endpoint, label, request string, wantStatus int, want []byte) {
	connection, err := net.Dial("tcp", strings.TrimPrefix(endpoint, "http://"))
	if err != nil {
		fatal(fmt.Errorf("connect for %s: %w", label, err))
	}
	if _, err := fmt.Fprint(connection, request); err != nil {
		fatal(fmt.Errorf("send %s: %w", label, err))
	}
	response, err := http.ReadResponse(bufio.NewReader(connection), &http.Request{Method: http.MethodPost})
	if err != nil {
		fatal(fmt.Errorf("read %s response: %w", label, err))
	}
	contents, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	connection.Close()
	if readErr != nil || response.StatusCode != wantStatus || !bytes.Contains(contents, want) {
		fatal(fmt.Errorf("%s: HTTP %d: %s: %v", label, response.StatusCode, contents, readErr))
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

func validateShape(endpoint, expected string) ([]byte, int, error) {
	source := make([]byte, 0, len(otelCoreLibrary)+len(expected)+128)
	source = append(source, otelCoreLibrary...)
	source = append(source, []byte("\n(import (scheme base) (scheme read) (otel trace-shape) (otel trace-shape match))\n(define probe-expected ")...)
	source = append(source, expected...)
	source = append(source, []byte(")\n(otel-validate-trace-shapes probe-expected (read))\n")...)
	return validateScheme(endpoint, source)
}

func validateSyntheticShape(endpoint, featureID, shape, capture string) ([]byte, int, error) {
	source := make([]byte, 0, len(otelCoreLibrary)+len(capture)+len(featureID)+len(shape)+180)
	source = append(source, otelCoreLibrary...)
	source = append(source, []byte("\n(import (scheme base) (otel capture shapes))\n(define probe-capture '")...)
	source = append(source, capture...)
	source = append(source, []byte(")\n(assert-capture-shape ")...)
	source = append(source, []byte(fmt.Sprintf("%q '%s probe-capture)\n", featureID, shape))...)
	return validateScheme(endpoint, source)
}

// Every rule's shape is asserted by one program rather than one program each:
// the sink compiles the whole corpus bundle per request, so the compilation
// dominates, and the probe's runtime would otherwise grow with the corpus.
// assert-capture-shape raises a contract error naming the first shape that
// fails, so a single program still reports which rule broke.
func assertSyntheticShapesPass(endpoint string, featureIDs []string, shapeByFeature map[string]string, capture string) {
	var source bytes.Buffer
	source.Write(otelCoreLibrary)
	source.WriteString("\n(import (scheme base) (otel capture shapes))\n(define probe-capture '")
	source.WriteString(capture)
	source.WriteString(")\n")
	for _, featureID := range featureIDs {
		fmt.Fprintf(&source, "(assert-capture-shape %q '%s probe-capture)\n", featureID, shapeByFeature[featureID])
	}
	output, status, err := validateScheme(endpoint, source.Bytes())
	if err != nil {
		fatal(err)
	}
	if status != http.StatusOK {
		fatal(fmt.Errorf("passing capture shapes returned HTTP %d: %s", status, output))
	}
}

func assertSyntheticShapeFailure(endpoint, featureID, shape, capture string) {
	output, status, err := validateSyntheticShape(endpoint, featureID, shape, capture)
	if err != nil {
		fatal(err)
	}
	if status != http.StatusConflict || !bytes.Contains(output, []byte(featureID)) || !bytes.Contains(output, []byte(shape)) {
		fatal(fmt.Errorf("capture shape %s/%s returned HTTP %d: %s", featureID, shape, status, output))
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
