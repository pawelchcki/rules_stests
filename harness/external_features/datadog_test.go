package main

import (
	"errors"
	"fmt"
	"testing"
)

func ddBaselineFixture() []ddNativeSpan {
	var result []ddNativeSpan
	for i := 1; i <= 4; i++ {
		result = append(result, ddNativeSpan{Start: 100, Duration: 10, TraceID: uint64(i), SpanID: uint64(i), Name: "aiohttp.request", Service: "external-probe", Type: "web", Meta: map[string]string{"probe.request_id": fmt.Sprint(i), "env": "test", "version": "1", "http.method": "GET", "http.status_code": "200", "probe.header": "visible", "http.useragent": "datadog-external-probe"}, Metrics: map[string]float64{"_sampling_priority_v1": 2}})
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

func TestDatadogHTTPMetadataMutations(t *testing.T) {
	for _, key := range []string{"env", "version", "http.method", "http.status_code", "probe.header", "http.useragent", "probe.request_id"} {
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
	for _, app := range []string{"rails", "gin"} {
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
