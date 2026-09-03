package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestResetStartupTelemetryWaitsForTraceAndClearsAllSignals(t *testing.T) {
	statsCalls := 0
	resetPath := ""
	server := httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/stats":
			statsCalls++
			if statsCalls == 1 {
				response.Write([]byte(`{"trace_requests":0,"trace_spans":0,"metric_requests":0}`))
			} else if statsCalls == 2 {
				response.Write([]byte(`{"trace_requests":1,"trace_spans":1,"metric_requests":0}`))
			} else {
				response.Write([]byte(`{"trace_requests":1,"trace_spans":1,"metric_requests":1}`))
			}
		case "/reset/traces-and-metrics":
			resetPath = request.URL.Path
			response.Write([]byte("{}\n"))
		default:
			http.NotFound(response, request)
		}
	}))
	defer server.Close()

	err := resetStartupTelemetryAt(
		server.Client(), server.URL, time.Second, 5*time.Millisecond, time.Millisecond,
		map[string]bool{"traces": true, "metrics": true},
	)
	if err != nil {
		t.Fatal(err)
	}
	if statsCalls < 3 {
		t.Fatalf("startup reset happened before a trace arrived; stats calls = %d", statsCalls)
	}
	if resetPath != "/reset/traces-and-metrics" {
		t.Fatalf("reset path = %q, want selective startup reset", resetPath)
	}
}

func TestResetStartupTelemetryRejectsEmptySink(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		response.Write([]byte(`{"trace_requests":0,"trace_spans":0}`))
	}))
	defer server.Close()

	err := resetStartupTelemetryAt(
		server.Client(), server.URL, 10*time.Millisecond, time.Millisecond, time.Millisecond,
		map[string]bool{"traces": true},
	)
	if err == nil || !strings.Contains(err.Error(), "did not arrive and quiesce") {
		t.Fatalf("empty sink error = %v", err)
	}
}

func TestEmitFailedCapture(t *testing.T) {
	root := t.TempDir()
	t.Setenv("TEST_UNDECLARED_OUTPUTS_DIR", root)
	emitFailedCapture("django/errors_auth", []byte("capture"))
	contents, err := os.ReadFile(filepath.Join(root, "django-errors_auth-failed-capture.json"))
	if err != nil {
		t.Fatal(err)
	}
	if string(contents) != "capture" {
		t.Fatalf("capture = %q, want %q", contents, "capture")
	}
}

func TestValidateProofSetMatchesNormalizedPlanExactly(t *testing.T) {
	expected := []proofPlanProof{
		{FeatureID: "traces.span.end", Assertion: "span/all-completed", Basis: "observed"},
		{FeatureID: "traces.tracer.create-a-new-span", Assertion: "span/present", Basis: "corroborated"},
	}
	output := []byte("[[OTLP-PROOF-V1|traces.span.end|span/all-completed|observed]]\n[[OTLP-PROOF-V1|traces.tracer.create-a-new-span|span/present|corroborated]]\n")
	proofs, err := validateProofSet(expected, output)
	if err != nil || len(proofs) != 2 || proofs[0].Result != "pass" {
		t.Fatalf("valid proof set rejected: %#v, %v", proofs, err)
	}
	for name, invalid := range map[string][]byte{
		"missing":    output[:bytes.IndexByte(output, '\n')+1],
		"unexpected": bytes.Replace(output, []byte("traces.span.end"), []byte("traces.span.unknown"), 1),
		"duplicate":  append(append([]byte(nil), output...), output...),
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := validateProofSet(expected, invalid); err == nil {
				t.Fatal("invalid proof set accepted")
			}
		})
	}
}

func TestEmitValidationReceiptIsOptInAndWritesDigests(t *testing.T) {
	root := t.TempDir()
	t.Setenv("TEST_UNDECLARED_OUTPUTS_DIR", root)
	t.Setenv("OTEL_TEST_REVISION", "")
	profile := atomicProfile{ID: "python-test", Scenario: "articles", ValidationMode: "exact", Plan: []byte("plan\n"), Shape: []byte("shape\n")}
	proofs := []receiptProof{{FeatureID: "traces.span.end", Assertion: "span/all-completed", Basis: "observed", Result: "pass"}}
	if err := emitValidationReceipt(profile, []byte("capture\n"), proofs); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(root, "receipts", "python-test", "articles.json")
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("receipt emitted without an opted-in revision: %v", err)
	}
	t.Setenv("OTEL_TEST_REVISION", "invalid")
	if err := emitValidationReceipt(profile, []byte("capture\n"), proofs); err == nil {
		t.Fatal("malformed opted-in revision accepted")
	}
	t.Setenv("OTEL_TEST_REVISION", strings.Repeat("a", 40))
	if err := emitValidationReceipt(profile, []byte("capture\n"), proofs); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var receipt validationReceipt
	if err := json.Unmarshal(data, &receipt); err != nil {
		t.Fatal(err)
	}
	if receipt.ValidationMode != "exact" || len(receipt.ProofPlanSHA256) != 64 || len(receipt.CaptureSHA256) != 64 || len(receipt.ScenarioShapeSHA256) != 64 {
		t.Fatalf("malformed emitted receipt: %#v", receipt)
	}
	if receipt.Outcome != "verified" || receipt.XFailReason != "" {
		t.Fatalf("validation receipt has wrong outcome: %#v", receipt)
	}
	capture, err := os.ReadFile(filepath.Join(root, "receipts", "python-test", "articles.capture.json"))
	if err != nil || string(capture) != "capture\n" {
		t.Fatalf("accepted capture was not emitted: %q, %v", capture, err)
	}
}

func TestEmitExpectedFailureReceiptPreservesRejectedCapture(t *testing.T) {
	root := t.TempDir()
	t.Setenv("TEST_UNDECLARED_OUTPUTS_DIR", root)
	t.Setenv("OTEL_TEST_REVISION", strings.Repeat("b", 40))
	profile := atomicProfile{ID: "python-test", Scenario: "comments", ValidationMode: "contract", Plan: []byte("plan\n")}
	if err := emitExpectedFailureReceipt(profile, []byte("rejected capture\n"), "issue #123"); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(filepath.Join(root, "receipts", "python-test", "comments.json"))
	if err != nil {
		t.Fatal(err)
	}
	var receipt validationReceipt
	if err := json.Unmarshal(data, &receipt); err != nil {
		t.Fatal(err)
	}
	if receipt.Outcome != "xfail" || receipt.XFailReason != "issue #123" || len(receipt.Proofs) != 0 {
		t.Fatalf("malformed xfail receipt: %#v", receipt)
	}
	capture, err := os.ReadFile(filepath.Join(root, "receipts", "python-test", "comments.capture.json"))
	if err != nil || string(capture) != "rejected capture\n" {
		t.Fatalf("rejected capture was not emitted: %q, %v", capture, err)
	}
}

func TestClassifyOTLPValidation(t *testing.T) {
	assertion := &otlpAssertionFailure{cause: errors.New("span shape changed")}
	infrastructure := errors.New("sink unavailable")

	tests := []struct {
		name       string
		failure    error
		reason     string
		wantError  string
		wantOutput string
	}{
		{name: "pass", failure: nil},
		{name: "ordinary failure", failure: assertion, wantError: "span shape changed"},
		{name: "expected failure", failure: assertion, reason: "issue #123", wantOutput: "XFAIL: OTLP contract aiohttp/articles violated as expected (issue #123):\nspan shape changed\n"},
		{name: "unexpected pass", failure: nil, reason: "issue #123", wantError: "XPASS:"},
		{name: "infrastructure is never expected", failure: infrastructure, reason: "issue #123", wantError: "infrastructure failed instead: sink unavailable"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			var output bytes.Buffer
			err := classifyOTLPValidation(test.failure, test.reason, "aiohttp/articles", &output)
			if test.wantError == "" && err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if test.wantError != "" && (err == nil || !strings.Contains(err.Error(), test.wantError)) {
				t.Fatalf("error = %v, want substring %q", err, test.wantError)
			}
			if output.String() != test.wantOutput {
				t.Fatalf("output = %q, want %q", output.String(), test.wantOutput)
			}
		})
	}
}

func TestSchemeIdentifier(t *testing.T) {
	for _, value := range []string{"articles", "errors_profiles", "python-aiohttp+v1"} {
		if err := schemeIdentifier(value); err != nil {
			t.Errorf("schemeIdentifier(%q) returned an error: %v", value, err)
		}
	}
	for _, value := range []string{"", "123", "articles/profile", "x) (error"} {
		if err := schemeIdentifier(value); err == nil {
			t.Errorf("schemeIdentifier(%q) unexpectedly succeeded", value)
		}
	}
}

func TestSchemeValidationFailureClassification(t *testing.T) {
	contractFailure := schemeValidationFailure(409, []byte("OTLP contract assertion: changed"))
	var assertion *otlpAssertionFailure
	if !errors.As(contractFailure, &assertion) {
		t.Fatalf("HTTP 409 was not classified as a contract assertion: %v", contractFailure)
	}
	validatorFailure := schemeValidationFailure(422, []byte("Stak compilation failed"))
	if errors.As(validatorFailure, &assertion) {
		t.Fatalf("HTTP 422 validator fault was classified as a contract assertion: %v", validatorFailure)
	}
}

func TestPayloadHasServiceName(t *testing.T) {
	tests := []struct {
		name    string
		signal  string
		payload string
		want    bool
	}{
		{
			name:    "typed protobuf JSON",
			signal:  "metrics",
			payload: `{"resource_metrics":[{"resource":{"attributes":[{"key":"service.name","value":{"value":{"string_value":"service"}}}]},"scope_metrics":[{"metrics":[{}]}]}]}`,
			want:    true,
		},
		{
			name:    "OTLP JSON",
			signal:  "logs",
			payload: `{"resourceLogs":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"service"}}]},"scopeLogs":[{"logRecords":[{}]}]}]}`,
			want:    true,
		},
		{
			name:    "resource without signal items",
			signal:  "metrics",
			payload: `{"resourceMetrics":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"service"}}]},"scopeMetrics":[]}]}`,
		},
		{
			name:    "ordinary payload string",
			signal:  "logs",
			payload: `{"resourceLogs":[{"resource":{"attributes":[]},"scopeLogs":[{"logRecords":[{"body":{"stringValue":"service.name"}}]}]}]}`,
		},
		{
			name:    "empty service name",
			signal:  "traces",
			payload: `{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":""}}]}}]}`,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := payloadHasServiceName(json.RawMessage(test.payload), test.signal); got != test.want {
				t.Fatalf("payloadHasServiceName() = %v, want %v", got, test.want)
			}
		})
	}
}
