package server

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestHandlerServesReportAndHealth(t *testing.T) {
	reportFile := filepath.Join(t.TempDir(), "report.html")
	if err := os.WriteFile(reportFile, []byte("<!doctype html><title>feature parity</title>"), 0o600); err != nil {
		t.Fatal(err)
	}
	handler := NewHandler(reportFile)

	report := httptest.NewRecorder()
	handler.ServeHTTP(report, httptest.NewRequest(http.MethodGet, ReportPath, nil))
	if report.Code != http.StatusOK || !strings.Contains(report.Body.String(), "feature parity") {
		t.Fatalf("report response: status=%d body=%q", report.Code, report.Body.String())
	}
	if report.Header().Get("Content-Type") != "text/html; charset=utf-8" || report.Header().Get("Cache-Control") != "no-cache" {
		t.Fatalf("report headers: %#v", report.Header())
	}

	health := httptest.NewRecorder()
	handler.ServeHTTP(health, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if health.Code != http.StatusOK || health.Body.String() != "ok\n" {
		t.Fatalf("health response: status=%d body=%q", health.Code, health.Body.String())
	}
}

func TestHandlerRejectsUnknownPathAndMissingReport(t *testing.T) {
	handler := NewHandler(filepath.Join(t.TempDir(), "missing.html"))

	missing := httptest.NewRecorder()
	handler.ServeHTTP(missing, httptest.NewRequest(http.MethodGet, ReportPath, nil))
	if missing.Code != http.StatusServiceUnavailable {
		t.Fatalf("missing report status = %d", missing.Code)
	}

	unknown := httptest.NewRecorder()
	handler.ServeHTTP(unknown, httptest.NewRequest(http.MethodGet, "/unknown", nil))
	if unknown.Code != http.StatusNotFound {
		t.Fatalf("unknown path status = %d", unknown.Code)
	}
}
