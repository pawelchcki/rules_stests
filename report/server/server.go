package server

import (
	"fmt"
	"io"
	"net/http"
	"os"
)

const ReportPath = "/feature-parity-report.html"

func NewHandler(reportFile string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(response http.ResponseWriter, _ *http.Request) {
		response.Header().Set("Content-Type", "text/plain; charset=utf-8")
		response.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(response, "ok\n")
	})
	mux.HandleFunc("HEAD /healthz", func(response http.ResponseWriter, _ *http.Request) {
		response.Header().Set("Content-Type", "text/plain; charset=utf-8")
		response.WriteHeader(http.StatusOK)
	})
	mux.HandleFunc("GET /", func(response http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/" {
			http.NotFound(response, request)
			return
		}
		http.Redirect(response, request, ReportPath, http.StatusTemporaryRedirect)
	})
	serveReport := func(response http.ResponseWriter, request *http.Request) {
		file, err := os.Open(reportFile)
		if err != nil {
			http.Error(response, "feature parity report is not built", http.StatusServiceUnavailable)
			return
		}
		defer file.Close()
		info, err := file.Stat()
		if err != nil || !info.Mode().IsRegular() {
			http.Error(response, "feature parity report is unavailable", http.StatusServiceUnavailable)
			return
		}
		response.Header().Set("Cache-Control", "no-cache")
		response.Header().Set("Content-Type", "text/html; charset=utf-8")
		response.Header().Set("X-Content-Type-Options", "nosniff")
		http.ServeContent(response, request, "feature-parity-report.html", info.ModTime(), file)
	}
	mux.HandleFunc("GET "+ReportPath, serveReport)
	mux.HandleFunc("HEAD "+ReportPath, serveReport)
	return mux
}

func ValidateReport(reportFile string) error {
	info, err := os.Stat(reportFile)
	if err != nil {
		return fmt.Errorf("stat report: %w", err)
	}
	if !info.Mode().IsRegular() {
		return fmt.Errorf("report is not a regular file: %s", reportFile)
	}
	return nil
}
