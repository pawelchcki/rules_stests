package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

const datadogUpstream = "https://github.com/DataDog/system-tests/blob/ea8a5976064509df0a5232e314b22e7e90ca4d40/tests/parametric/"

var telemetryProtocol = "otlp"
var datadogWire = "v0.5"
var activeDatadogCase ddCase

type ddCase struct {
	Name                          string
	Env                           map[string]string
	Headers                       map[string]string
	Source                        string
	Propagated                    bool
	Priority                      *int
	Service, Environment, Version string
	Disabled                      bool
	Kind                          string
	Bits                          int
	Method, Query                 string
	Partial                       bool
}

type ddNativeSpan struct {
	TraceID  uint64             `json:"trace_id"`
	SpanID   uint64             `json:"span_id"`
	ParentID uint64             `json:"parent_id"`
	Name     string             `json:"name"`
	Service  string             `json:"service"`
	Resource string             `json:"resource"`
	Type     string             `json:"type"`
	Error    int                `json:"error"`
	Meta     map[string]string  `json:"meta"`
	Metrics  map[string]float64 `json:"metrics"`
}

type ddResult struct {
	Name               string `json:"name"`
	Status             string `json:"status"`
	Source             string `json:"source"`
	BaselineSHA256     string `json:"baselineSha256"`
	CaptureSHA256      string `json:"captureSha256"`
	Configuration      ddCase `json:"configuration"`
	Detail             string `json:"detail,omitempty"`
	EarlyCaptureSHA256 string `json:"earlyCaptureSha256,omitempty"`
	RejectionLogSHA256 string `json:"rejectionLogSha256,omitempty"`
}

func ddCases() []ddCase {
	keep, drop := 2, -1
	propagated := map[string]string{"x-datadog-trace-id": "123456789", "x-datadog-parent-id": "987654321", "x-datadog-sampling-priority": "2", "x-datadog-tags": "_dd.p.tid=1234567890abcdef"}
	originHeaders := map[string]string{}
	for key, value := range propagated {
		originHeaders[key] = value
	}
	originHeaders["x-datadog-origin"] = "synthetics"
	traceparent := "00-1234567890abcdef00000000075bcd15-000000003ade68b1-01"
	return []ddCase{
		{Name: "generate-128", Source: "test_128_bit_traceids.py", Bits: 128, Env: map[string]string{"DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED": "true"}},
		{Name: "generate-64", Source: "test_128_bit_traceids.py", Bits: 64, Env: map[string]string{"DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED": "false"}},
		{Name: "extract-64", Source: "test_headers_datadog.py", Bits: 64, Propagated: true, Headers: map[string]string{"x-datadog-trace-id": "123456789", "x-datadog-parent-id": "987654321"}},
		{Name: "malformed-zero", Source: "test_headers_datadog.py", Headers: map[string]string{"x-datadog-trace-id": "0", "x-datadog-parent-id": "987654321"}},
		{Name: "malformed-overflow", Source: "test_headers_datadog.py", Headers: map[string]string{"x-datadog-trace-id": "18446744073709551616", "x-datadog-parent-id": "987654321"}},
		{Name: "datadog", Source: "test_headers_datadog.py", Headers: propagated, Propagated: true, Priority: &keep},
		{Name: "origin", Source: "test_headers_datadog.py", Headers: originHeaders, Propagated: true, Priority: &keep},
		{Name: "tracecontext", Source: "test_headers_tracecontext.py", Env: map[string]string{"DD_TRACE_PROPAGATION_STYLE_EXTRACT": "tracecontext"}, Headers: map[string]string{"traceparent": traceparent}, Propagated: true},
		{Name: "b3", Source: "test_headers_b3.py", Env: map[string]string{"DD_TRACE_PROPAGATION_STYLE_EXTRACT": "b3"}, Headers: map[string]string{"b3": "1234567890abcdef00000000075bcd15-000000003ade68b1-1"}, Propagated: true},
		{Name: "b3multi", Source: "test_headers_b3multi.py", Env: map[string]string{"DD_TRACE_PROPAGATION_STYLE_EXTRACT": "b3multi"}, Headers: map[string]string{"x-b3-traceid": "1234567890abcdef00000000075bcd15", "x-b3-spanid": "000000003ade68b1", "x-b3-sampled": "1"}, Propagated: true},
		{Name: "none", Source: "test_headers_none.py", Env: map[string]string{"DD_TRACE_PROPAGATION_STYLE_EXTRACT": "none"}, Headers: propagated},
		{Name: "malformed", Source: "test_headers_datadog.py", Headers: map[string]string{"x-datadog-trace-id": "not-a-number", "x-datadog-parent-id": "987654321"}},
		{Name: "precedence", Source: "test_headers_precedence.py", Env: map[string]string{"DD_TRACE_PROPAGATION_STYLE_EXTRACT": "datadog,tracecontext"}, Headers: map[string]string{"x-datadog-trace-id": "123456789", "x-datadog-parent-id": "987654321", "x-datadog-tags": "_dd.p.tid=1234567890abcdef", "traceparent": "00-aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb-cccccccccccccccc-01"}, Propagated: true},
		{Name: "identity", Source: "test_tracer.py", Env: map[string]string{"DD_SERVICE": "configured-service", "DD_ENV": "configured-env", "DD_VERSION": "configured-version"}, Service: "configured-service", Environment: "configured-env", Version: "configured-version"},
		{Name: "sample-one", Source: "test_trace_sampling.py", Env: map[string]string{"DD_TRACE_SAMPLING_RULES": "[{\"sample_rate\":1}]"}, Priority: &keep},
		{Name: "sample-zero", Source: "test_trace_sampling.py", Env: map[string]string{"DD_TRACE_SAMPLING_RULES": "[{\"sample_rate\":0}]"}, Priority: &drop},
		{Name: "rule-precedence", Source: "test_trace_sampling.py", Env: map[string]string{"DD_TRACE_SAMPLING_RULES": "[{\"service\":\"external-probe\",\"sample_rate\":0},{\"sample_rate\":1}]"}, Priority: &drop},
		{Name: "disabled", Source: "test_tracer.py", Env: map[string]string{"DD_TRACE_ENABLED": "false"}, Disabled: true},
	}
}

func datadogEnvironment(sink string) map[string]string {
	return map[string]string{
		"DD_SERVICE": "external-probe", "DD_ENV": "test", "DD_VERSION": "1", "DD_TRACE_ENABLED": "true",
		"DD_TRACE_AGENT_URL": sink, "DD_TRACE_API_VERSION": datadogWire,
		"DD_TRACE_SAMPLING_RULES": "[{\"sample_rate\":1}]", "DD_TRACE_RATE_LIMIT": "-1",
		"DD_TRACE_WRITER_INTERVAL_SECONDS": "0.1", "DD_TRACE_PARTIAL_FLUSH_ENABLED": "false",
		"DD_TRACE_PROPAGATION_STYLE_EXTRACT": "datadog,tracecontext", "DD_TRACE_PROPAGATION_STYLE_INJECT": "datadog,tracecontext",
		"DD_TRACE_HEADER_TAGS":                        "x-probe-request-id:probe.request_id,x-probe-feature:probe.header,user-agent:http.useragent",
		"DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED": "true",
		"DD_INSTRUMENTATION_TELEMETRY_ENABLED":        "false", "DD_REMOTE_CONFIGURATION_ENABLED": "false", "DD_RUNTIME_METRICS_ENABLED": "false",
		"DD_PROFILING_ENABLED": "false", "DD_APPSEC_ENABLED": "false", "DD_IAST_ENABLED": "false", "DD_TRACE_STARTUP_LOGS": "false",
	}
}

func protocolEndpoint(sink, path string) string {
	if telemetryProtocol == "datadog" {
		return sink + path + "?protocol=datadog"
	}
	return sink + path
}

func datadogWorkload(base string, ownership func() error) error {
	count := 4
	if activeDatadogCase.Kind == "partial" {
		count = 1
	}
	for i := 0; i < count; i++ {
		if err := ownership(); err != nil {
			return err
		}
		target := base + "/api/tags"
		if activeDatadogCase.Kind != "" {
			target = ddProbeURL(base, activeDatadogCase.Kind)
		}
		if activeDatadogCase.Query != "" {
			target += "?" + activeDatadogCase.Query
		}
		method := activeDatadogCase.Method
		if method == "" {
			method = "GET"
		}
		req, err := http.NewRequest(method, target, nil)
		if err != nil {
			return err
		}
		req.Header.Set("X-Probe-Request-Id", strconv.Itoa(i+1))
		req.Header.Set("X-Probe-Feature", "visible")
		req.Header.Set("User-Agent", "datadog-external-probe")
		for k, v := range activeDatadogCase.Headers {
			req.Header.Set(k, v)
		}
		if activeDatadogCase.Kind == "partial" {
			return ddPartialWorkload(base, req)
		}
		resp, err := client.Do(req)
		if err != nil {
			return err
		}
		io.Copy(io.Discard, resp.Body)
		resp.Body.Close()
		expected := 200
		if activeDatadogCase.Kind == "exception" {
			expected = 500
		}
		if resp.StatusCode != expected {
			return fmt.Errorf("Datadog probe returned %d", resp.StatusCode)
		}
	}
	return ownership()
}

func decodeDatadog(data []byte) ([]ddNativeSpan, error) {
	var records []struct {
		Payload struct {
			Traces [][]ddNativeSpan `json:"traces"`
		} `json:"payload"`
	}
	if err := json.Unmarshal(data, &records); err != nil {
		return nil, err
	}
	var spans []ddNativeSpan
	for _, r := range records {
		for _, chunk := range r.Payload.Traces {
			high := ""
			for _, s := range chunk {
				if s.Meta["_dd.p.tid"] != "" {
					if high != "" && high != s.Meta["_dd.p.tid"] {
						return nil, fmt.Errorf("conflicting chunk high bits")
					}
					high = s.Meta["_dd.p.tid"]
				}
			}
			for i := range chunk {
				if chunk[i].Meta == nil {
					chunk[i].Meta = map[string]string{}
				}
				chunk[i].Meta["_dd.p.tid"] = high
			}
			spans = append(spans, chunk...)
		}
	}
	return spans, nil
}

func ddServers(spans []ddNativeSpan) []ddNativeSpan {
	var servers []ddNativeSpan
	for _, s := range spans {
		if s.Meta["probe.request_id"] != "" {
			servers = append(servers, s)
		}
	}
	return servers
}

func validateDatadogCase(c ddCase, baseline, spans []ddNativeSpan) error {
	expected := 4
	if c.Kind == "partial" {
		expected = 1
	}
	if len(ddServers(baseline)) != expected {
		return fmt.Errorf("baseline does not retain all four request identifiers")
	}
	if c.Disabled {
		if len(spans) != 0 {
			return fmt.Errorf("disabled tracer exported %d spans", len(spans))
		}
		return nil
	}
	servers := ddServers(spans)
	if len(servers) != expected {
		return fmt.Errorf("expected four native server spans, got %d; transport omission is not sampling-decision evidence", len(servers))
	}
	seen := map[string]bool{}
	for _, s := range servers {
		id := s.Meta["probe.request_id"]
		if seen[id] || (id != "1" && id != "2" && id != "3" && id != "4") {
			return fmt.Errorf("duplicate or unexpected request identifier %q", id)
		}
		seen[id] = true
		service, env, version := c.Service, c.Environment, c.Version
		if service == "" {
			service = "external-probe"
		}
		if env == "" {
			env = "test"
		}
		if version == "" {
			version = "1"
		}
		if s.Service != service || s.Meta["env"] != env || s.Meta["version"] != version {
			return fmt.Errorf("incorrect service/environment/version")
		}
		status, errorFlag := "200", 0
		if c.Kind == "exception" {
			status, errorFlag = "500", 1
		}
		if s.Type != "web" || s.Error != errorFlag || s.Meta["http.method"] != ddMethod(c) || s.Meta["http.status_code"] != status || s.Meta["probe.header"] != "visible" || s.Meta["http.useragent"] != "datadog-external-probe" {
			return fmt.Errorf("incorrect native HTTP metadata or header tags")
		}
		if c.Bits == 128 {
			high, err := strconv.ParseUint(s.Meta["_dd.p.tid"], 16, 64)
			if len(s.Meta["_dd.p.tid"]) != 16 || err != nil || high == 0 {
				return fmt.Errorf("expected a 128-bit trace identity")
			}
		}
		if c.Bits == 64 && s.Meta["_dd.p.tid"] != "" {
			return fmt.Errorf("expected a 64-bit trace identity")
		}
		if c.Name == "query-redaction" {
			rawBaseline := false
			for _, b := range ddServers(baseline) {
				if strings.Contains(b.Meta["http.url"]+b.Meta["http.query.string"], "probe-secret") {
					rawBaseline = true
				}
			}
			if !rawBaseline {
				return fmt.Errorf("query baseline did not expose the controlled value")
			}
			tagged := s.Meta["http.url"] + s.Meta["http.query.string"]
			if strings.Contains(tagged, "probe-secret") || !strings.Contains(tagged, "redacted") || !strings.Contains(tagged, "safe=visible") {
				return fmt.Errorf("query string was not selectively redacted")
			}
		}
		if c.Propagated {
			high := "1234567890abcdef"
			if c.Bits == 64 {
				high = ""
			}
			if s.TraceID != 123456789 || s.ParentID != 987654321 || s.Meta["_dd.p.tid"] != high {
				return fmt.Errorf("incorrect extracted full trace identity/parent")
			}
		} else if s.ParentID != 0 || s.TraceID == 123456789 {
			return fmt.Errorf("disabled/malformed propagation unexpectedly continued a caller")
		}
		if c.Priority != nil {
			p, ok := s.Metrics["_sampling_priority_v1"]
			if !ok || p != float64(*c.Priority) {
				return fmt.Errorf("incorrect or missing sampling priority")
			}
		}
		if c.Name == "origin" && s.Meta["_dd.origin"] != "synthetics" {
			return fmt.Errorf("origin was not propagated")
		}
	}
	return nil
}

func runDatadog(app, launcher string, args []string) error {
	sink, err := sinkEndpoint()
	if err != nil {
		return err
	}
	out := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if out == "" {
		return fmt.Errorf("Datadog probes require an evidence directory")
	}
	collectCase := func(c ddCase) ([]byte, []ddNativeSpan, error) {
		if app == "gin" && c.Name == "b3" {
			c.Env["DD_TRACE_PROPAGATION_STYLE_EXTRACT"] = "b3 single header"
		}
		activeDatadogCase = c
		ddEarlyCapture = nil
		data, err := collect(app, launcher, args, sink, out, experiment{Name: c.Name, Env: c.Env})
		if err != nil {
			return nil, nil, err
		}
		if err = os.WriteFile(filepath.Join(out, c.Name+".capture.json"), data, 0644); err != nil {
			return nil, nil, err
		}
		spans, err := decodeDatadog(data)
		return data, spans, err
	}
	ddProbeSink, ddProbeOutput = sink, out
	data, baseline, err := collectCase(ddCase{Name: "baseline"})
	if err != nil {
		return err
	}
	if err = validateDatadogCase(ddCase{}, baseline, baseline); err != nil {
		return fmt.Errorf("baseline: %w", err)
	}
	baselineHash := fmt.Sprintf("%x", sha256.Sum256(data))
	var results []ddResult
	var failures []string
	for _, c := range append(ddCases(), ddProbeCases()...) {
		control, controlHash := baseline, baselineHash
		if c.Kind != "" {
			kind := c.Kind
			if kind == "keep" || kind == "drop" {
				kind = "nested"
			}
			b, bsp, berr := collectCase(ddCase{Name: "control-" + c.Name, Kind: kind, Method: c.Method, Query: c.Query, Env: map[string]string{"RULES_STESTS_PROBES": "true", "DD_TRACE_OBFUSCATION_QUERY_STRING_REGEXP": "rules_stests_value_that_never_occurs"}})
			if berr != nil {
				return berr
			}
			control, controlHash = bsp, fmt.Sprintf("%x", sha256.Sum256(b))
		}
		data, spans, err := collectCase(c)
		if err != nil {
			return fmt.Errorf("%s: %w", c.Name, err)
		}
		result := ddResult{Name: c.Name, Status: "passed", Source: datadogUpstream + c.Source, BaselineSHA256: controlHash, CaptureSHA256: fmt.Sprintf("%x", sha256.Sum256(data)), Configuration: c}
		validationErr := validateDatadogCase(c, control, spans)
		if c.Kind != "" && validationErr == nil {
			validationErr = validateDatadogProbes(c, spans, ddEarlyCapture)
		}
		if ddEarlyCapture != nil {
			result.EarlyCaptureSHA256 = fmt.Sprintf("%x", sha256.Sum256(ddEarlyCapture))
		}
		if err := validationErr; err != nil {
			result.Status = "failed"
			result.Detail = err.Error()
			log, readErr := os.ReadFile(filepath.Join(out, c.Name+".app.log"))
			if c.Name == "origin" && datadogWire == "v0.4" && readErr == nil && strings.Contains(string(log), "Response: duplicate MessagePack map key") {
				result.Status = "unsupported"
				result.Detail = "Pinned Python tracer encodes duplicate origin metadata in v0.4; native intake rejects it. This is not a passing propagation check."
				result.RejectionLogSHA256 = fmt.Sprintf("%x", sha256.Sum256(log))
			} else {
				failures = append(failures, c.Name+": "+err.Error())
			}
		}
		results = append(results, result)
	}
	encoded, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return err
	}
	if err = os.WriteFile(filepath.Join(out, "datadog-features.json"), encoded, 0644); err != nil {
		return err
	}
	if len(failures) > 0 {
		return fmt.Errorf("Datadog feature assertions: %s", strings.Join(failures, "; "))
	}
	return nil
}

func ddMethod(c ddCase) string {
	if c.Method != "" {
		return c.Method
	}
	return "GET"
}
