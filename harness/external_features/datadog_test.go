package main

import (
	"errors"
	"fmt"
	"testing"
)

func TestUpstreamReceiptBindsMethodSourceAndSpanCount(t *testing.T) {
	method := "test_distributed_headers_extract_datadog_D001"
	valid := fmt.Sprintf(`{"sourceSha256":%q,"method":%q,"spans":4}`, datadogHeadersSourceSHA256, method)
	if _, err := validateUpstreamReceipt(method, []byte(valid)); err != nil {
		t.Fatal(err)
	}
	for name, receipt := range map[string]string{
		"source": fmt.Sprintf(`{"sourceSha256":"wrong","method":%q,"spans":4}`, method),
		"method": fmt.Sprintf(`{"sourceSha256":%q,"method":"wrong","spans":4}`, datadogHeadersSourceSHA256),
		"spans":  fmt.Sprintf(`{"sourceSha256":%q,"method":%q,"spans":3}`, datadogHeadersSourceSHA256, method),
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := validateUpstreamReceipt(method, []byte(receipt)); err == nil {
				t.Fatal("accepted unbound upstream receipt")
			}
		})
	}
}

func ddBaselineFixture() []ddNativeSpan {
	var result []ddNativeSpan
	for i := 1; i <= 4; i++ {
		result = append(result, ddNativeSpan{Start: 100, Duration: 10, TraceID: uint64(i), SpanID: uint64(i), Name: "aiohttp.request", Service: "external-probe", Type: "web", Meta: map[string]string{"probe.request_id": fmt.Sprint(i), "span.kind": "server", "env": "test", "version": "1", "http.method": "GET", "http.status_code": "200", "probe.header": "visible", "http.useragent": "datadog-external-probe"}, Metrics: map[string]float64{"_sampling_priority_v1": 2}})
	}
	return result
}

func TestDatadogNativeAssertionsRejectMutations(t *testing.T) {
	baseline := ddBaselineFixture()
	for _, c := range ddCases() {
		t.Run(c.Name, func(t *testing.T) {
			spans := ddBaselineFixture()
			for i := range spans {
				s := &spans[i]
				if c.Service != "" {
					s.Service = c.Service
					s.Meta["env"] = c.Environment
					s.Meta["version"] = c.Version
				}
				for key, value := range c.ExpectedTags {
					s.Meta[key] = value
				}
				if c.Bits == 128 {
					s.Meta["_dd.p.tid"] = "1234567890abcdef"
				}
				if c.Propagated {
					s.TraceID = 123456789
					s.ParentID = 987654321
					if c.Bits != 64 {
						s.Meta["_dd.p.tid"] = "1234567890abcdef"
					}
				}
				if c.Priority != nil {
					s.Metrics["_sampling_priority_v1"] = float64(*c.Priority)
				}
				if c.Name == "origin" {
					s.Meta["_dd.origin"] = "synthetics"
				}
			}
			if c.Disabled {
				spans = nil
			}
			if err := validateDatadogCase(c, baseline, spans); err != nil {
				t.Fatal(err)
			}
			if c.Disabled {
				spans = ddBaselineFixture()
			} else if c.UpstreamMethod != "" {
				spans[0].Service = "wrong"
			} else if c.Priority != nil {
				delete(spans[0].Metrics, "_sampling_priority_v1")
			} else if c.Propagated {
				spans[0].Meta["_dd.p.tid"] = "bad"
			} else {
				spans[0].Service = "wrong"
			}
			if err := validateDatadogCase(c, baseline, spans); err == nil {
				t.Fatal("accepted targeted corruption")
			}
		})
	}
}

func TestDatadogConfiguredTagsRejectMissingChangedAndBaselineTags(t *testing.T) {
	baseline := ddBaselineFixture()
	for _, c := range ddCases() {
		if len(c.ExpectedTags) == 0 {
			continue
		}
		t.Run(c.Name, func(t *testing.T) {
			configured := ddBaselineFixture()
			for i := range configured {
				for key, value := range c.ExpectedTags {
					configured[i].Meta[key] = value
				}
				if c.Service != "" {
					configured[i].Service = c.Service
					configured[i].Meta["env"] = c.Environment
					configured[i].Meta["version"] = c.Version
				}
			}
			if err := validateDatadogCase(c, baseline, configured); err != nil {
				t.Fatal(err)
			}
			for key := range c.ExpectedTags {
				for i := range configured {
					changed := append([]ddNativeSpan(nil), configured...)
					changed[i].Meta = map[string]string{}
					for k, v := range configured[i].Meta {
						changed[i].Meta[k] = v
					}
					delete(changed[i].Meta, key)
					if err := validateDatadogCase(c, baseline, changed); err == nil {
						t.Fatalf("accepted missing %s on request %d", key, i+1)
					}
					changed[i].Meta[key] = "wrong"
					if err := validateDatadogCase(c, baseline, changed); err == nil {
						t.Fatalf("accepted changed %s on request %d", key, i+1)
					}
				}
				contaminated := ddBaselineFixture()
				contaminated[0].Meta[key] = c.ExpectedTags[key]
				if err := validateDatadogCase(c, contaminated, configured); err == nil {
					t.Fatalf("accepted baseline containing %s", key)
				}
			}
			if c.Name == "tags-identity-precedence" {
				for _, field := range []string{"service", "env", "version"} {
					changed := append([]ddNativeSpan(nil), configured...)
					changed[2].Meta = map[string]string{}
					for k, v := range configured[2].Meta {
						changed[2].Meta[k] = v
					}
					switch field {
					case "service":
						changed[2].Service = "shadow-service"
					case "env":
						changed[2].Meta["env"] = "shadow-env"
					case "version":
						changed[2].Meta["version"] = "shadow-version"
					}
					if err := validateDatadogCase(c, baseline, changed); err == nil {
						t.Fatalf("accepted shadow %s", field)
					}
				}
			}
		})
	}
}

func TestDatadogConfigurationEvidencePinsSourceAndAgentURL(t *testing.T) {
	if got := ddSourceURL(ddCase{Source: "test_tracer.py"}); got != datadogUpstream+"test_tracer.py" {
		t.Fatalf("legacy source changed: %s", got)
	}
	if got := ddSourceURL(ddCase{Source: "test_config_consistency.py", SourceRevision: "another-revision"}); got != "https://github.com/DataDog/system-tests/blob/another-revision/tests/parametric/test_config_consistency.py" {
		t.Fatalf("nonempty revision silently changed: %s", got)
	}
	for _, c := range ddCases() {
		if c.SourceRevision == "" {
			continue
		}
		if got := ddSourceURL(c); got != datadogConfigUpstream+"test_config_consistency.py" {
			t.Fatalf("incorrect source for %s: %s", c.Name, got)
		}
		if c.ReferenceClass == "" || c.ReferenceTest == "" {
			t.Fatalf("missing upstream test identifier for %s", c.Name)
		}
	}
	c := ddCase{Env: map[string]string{"DD_AGENT_HOST": "invalid-agent-host.invalid", "DD_TRACE_AGENT_PORT": "1", "DD_TRACE_AGENT_URL": "http://127.0.0.1:8126"}}
	effective := ddEffectiveEnvironment("http://127.0.0.1:8126", c, []string{"--env=DD_TRACE_SQLALCHEMY_ENABLED=true", "--env=DD_TRACE_SQLITE3_ENABLED=false", "--env=DD_TRACE_AGENT_URL=http://wrong.example:8126", "--"})
	if effective["DD_AGENT_HOST"] != "invalid-agent-host.invalid" || effective["DD_TRACE_AGENT_PORT"] != "1" || effective["DD_TRACE_AGENT_URL"] != "http://127.0.0.1:8126" {
		t.Fatal("agent precedence evidence lost an effective setting")
	}
	if effective["DD_TRACE_SQLALCHEMY_ENABLED"] != "true" || effective["DD_TRACE_SQLITE3_ENABLED"] != "false" {
		t.Fatal("effective configuration lost launcher injection controls")
	}
	c.AgentURLPrecedence = true
	if err := ddValidateAgentURLPrecedenceConfiguration(c, "http://127.0.0.1:8126"); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"DD_TRACE_AGENT_URL", "DD_AGENT_HOST", "DD_TRACE_AGENT_PORT"} {
		changed := ddCase{AgentURLPrecedence: true, Env: map[string]string{}}
		for k, v := range c.Env {
			changed.Env[k] = v
		}
		changed.Env[key] = "other"
		if err := ddValidateAgentURLPrecedenceConfiguration(changed, "http://127.0.0.1:8126"); err == nil {
			t.Fatalf("accepted changed %s", key)
		}
	}
}

func TestDatadogHTTPMetadataMutations(t *testing.T) {
	for _, key := range []string{"env", "version", "http.method", "http.status_code", "probe.header", "http.useragent", "probe.request_id", "span.kind"} {
		t.Run(key, func(t *testing.T) {
			spans := ddBaselineFixture()
			spans[0].Meta[key] = "wrong"
			if err := validateDatadogCase(ddCase{}, ddBaselineFixture(), spans); err == nil {
				t.Fatal("accepted wrong " + key)
			}
		})
	}
	baseline := ddBaselineFixture()
	for i := range baseline {
		baseline[i].Meta["http.url"] = "/echo?token=probe-secret&safe=visible"
	}
	c := ddCase{Name: "query-redaction"}
	for _, tagged := range []string{"/echo?<redacted>&safe=visible", "/echo?token=probe-secret&safe=visible", "/echo?<redacted>", "/echo?"} {
		spans := ddBaselineFixture()
		for i := range spans {
			spans[i].Meta["http.url"] = tagged
		}
		err := validateDatadogCase(c, baseline, spans)
		if (err == nil) != (tagged == "/echo?<redacted>&safe=visible") {
			t.Fatalf("query %q: %v", tagged, err)
		}
	}
}

func TestDuplicateOriginWaiverIsPythonOnly(t *testing.T) {
	oldWire := datadogWire
	t.Cleanup(func() { datadogWire = oldWire })
	datadogWire = "v0.4"
	log := []byte("intake Response: duplicate MessagePack map key")
	origin := ddCase{Name: "origin"}

	for _, app := range []string{"aiohttp", "django"} {
		if !knownPythonDuplicateOrigin(app, origin, log, nil) {
			t.Fatalf("Python duplicate-origin failure not recognized for %s", app)
		}
	}
	for _, app := range []string{"rails", "falcon", "gin"} {
		if knownPythonDuplicateOrigin(app, origin, log, nil) {
			t.Fatalf("duplicate-origin failure incorrectly waived for %s", app)
		}
	}
	if knownPythonDuplicateOrigin("aiohttp", ddCase{Name: "tags"}, log, nil) {
		t.Fatal("non-origin case was waived")
	}
	if knownPythonDuplicateOrigin("aiohttp", origin, []byte("different failure"), nil) {
		t.Fatal("different intake failure was waived")
	}
	if knownPythonDuplicateOrigin("aiohttp", origin, log, errors.New("log unavailable")) {
		t.Fatal("unreadable rejection log was waived")
	}
	datadogWire = "v0.5"
	if knownPythonDuplicateOrigin("aiohttp", origin, log, nil) {
		t.Fatal("v0.5 duplicate-origin failure was waived")
	}
}
