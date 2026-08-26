package main

import (
	"bytes"
	"errors"
	"strings"
	"testing"
)

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
