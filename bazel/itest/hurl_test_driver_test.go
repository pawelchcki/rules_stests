package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

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

func TestGoldenCandidateParts(t *testing.T) {
	app, scenario, err := goldenCandidateParts("aiohttp/errors_profiles")
	if err != nil || app != "aiohttp" || scenario != "errors_profiles" {
		t.Fatalf("goldenCandidateParts(valid) = %q, %q, %v", app, scenario, err)
	}
	for _, value := range []string{
		"aiohttp/../../../tmp",
		"aiohttp/errors/profiles",
		"../aiohttp/articles",
		"aiohttp/.",
		"aiohttp/",
		"/articles",
	} {
		if _, _, err := goldenCandidateParts(value); err == nil {
			t.Errorf("goldenCandidateParts(%q) unexpectedly succeeded", value)
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

func TestImplementationProfile(t *testing.T) {
	profile, err := implementationProfile("custom-app", "go-realworld-v1")
	if err != nil || profile != "go-realworld-v1" {
		t.Fatalf("custom profile = %q, %v", profile, err)
	}
	if _, err := implementationProfile("custom-app", "not/a-symbol"); err == nil {
		t.Fatal("invalid custom profile unexpectedly succeeded")
	}
	profile, err = implementationProfile("aiohttp", "")
	if err != nil || profile != "python-aiohttp-auto-v0-65b0" {
		t.Fatalf("default profile = %q, %v", profile, err)
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
			payload: `{"resource_metrics":[{"resource":{"attributes":[{"key":"service.name","value":{"value":{"string_value":"service"}}}]}}]}`,
			want:    true,
		},
		{
			name:    "OTLP JSON",
			signal:  "logs",
			payload: `{"resourceLogs":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"service"}}]}}]}`,
			want:    true,
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
