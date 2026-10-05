package main

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/pawelchcki/rules_stests/report"
)

func TestLabPlanProofsRequireExecutedChecks(t *testing.T) {
	const language = "ruby"
	plan := report.NormalizedProfilePlan{SchemaVersion: 1, Profile: language + "-telemetry-lab", Language: language}
	observed := map[string]bool{}
	for _, id := range labScenarioClaims(language, "base") {
		check := labCheckFor(language, "base", id)
		if check == "" {
			t.Fatalf("unbound feature %s", id)
		}
		plan.Proofs = append(plan.Proofs, report.ProofPlanProof{
			FeatureID: id, Assertion: "telemetry-lab/" + check + "/" + id, Basis: "observed", Scenarios: []string{"base"},
		})
		observed[check] = true
	}
	encoded, err := json.Marshal(plan)
	if err != nil {
		t.Fatal(err)
	}
	if proofs, err := labPlanProofs(encoded, language, "base", observed); err != nil || len(proofs) != len(plan.Proofs) {
		t.Fatalf("complete checked proof set: %d proofs, %v", len(proofs), err)
	}
	delete(observed, "capture/span-events")
	if _, err := labPlanProofs(encoded, language, "base", observed); err == nil || !strings.Contains(err.Error(), "no passing capture/span-events check") {
		t.Fatalf("missing capture check should reject its feature IDs: %v", err)
	}
	observed["capture/span-events"] = true
	delete(observed, "response/baggage")
	if _, err := labPlanProofs(encoded, language, "base", observed); err == nil || !strings.Contains(err.Error(), "no passing response/baggage check") {
		t.Fatalf("missing response check should reject its feature ID: %v", err)
	}
	observed["response/baggage"] = true
	plan.Proofs[0].Assertion = "telemetry-lab/unchecked/" + plan.Proofs[0].FeatureID
	encoded, err = json.Marshal(plan)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := labPlanProofs(encoded, language, "base", observed); err == nil || !strings.Contains(err.Error(), "unexpected lab plan proof") {
		t.Fatalf("wrong assertion binding should be rejected: %v", err)
	}
}

const labTraceContextResponse = `{
	  "validity":{"valid":true,"zero-trace":false,"zero-span":false,"zero-both":false},
	  "invalid_headers":{"zero-trace":false,"zero-span":false,"short":false,"non-hex":false,"uppercase":false,"version-ff":false},
	  "parent_remote":true,"parent_valid":true,"generated_roots":1,"generated_spans":3,
	  "outgoing":{"traceparent":"00-0123456789abcdef0123456789abcdef-0000000000000003-01","tracestate":"lab=upstream"},
	  "spans":[
	    {"name":"lab.generated.root","trace_id":"0102030405060708090a0b0c0d0e0f10","span_id":"0000000000000001","parent_id":"0000000000000000","parent_remote":false,"remote":false},
	    {"name":"lab.generated.child","trace_id":"0102030405060708090a0b0c0d0e0f10","span_id":"0000000000000002","parent_id":"0000000000000001","parent_remote":false,"remote":false},
	    {"name":"lab.remote.child","trace_id":"0123456789abcdef0123456789abcdef","span_id":"0000000000000003","parent_id":"0123456789abcdef","parent_remote":true,"remote":false}
	  ]
	}`

func TestTraceContextProofRejectsIncorrectSDKResults(t *testing.T) {
	verify := func(r labObject) error {
		if err := labVerifyTraceContext(r); err != nil {
			return err
		}
		return labVerifyTraceInvalidHeaders(r)
	}
	decode := func(t *testing.T) labObject {
		t.Helper()
		var response labObject
		if err := json.Unmarshal([]byte(labTraceContextResponse), &response); err != nil {
			t.Fatal(err)
		}
		return response
	}
	if err := verify(decode(t)); err != nil {
		t.Fatal(err)
	}
	for name, mutate := range map[string]func(labObject){
		"zero ID accepted":          func(r labObject) { r["validity"].(map[string]any)["zero-span"] = true },
		"malformed header accepted": func(r labObject) { r["invalid_headers"].(map[string]any)["uppercase"] = true },
		"missing invalid header":    func(r labObject) { delete(r["invalid_headers"].(map[string]any), "short") },
		"local extracted parent":    func(r labObject) { r["parent_remote"] = false },
		"generator unused":          func(r labObject) { r["generated_roots"] = float64(0) },
		"wrong generated ID":        func(r labObject) { r["spans"].([]any)[1].(map[string]any)["span_id"] = "0000000000000001" },
		"child marked remote":       func(r labObject) { r["spans"].([]any)[2].(map[string]any)["remote"] = true },
		"missing exported child":    func(r labObject) { r["spans"] = r["spans"].([]any)[:2] },
		"lost trace flags": func(r labObject) {
			r["outgoing"].(map[string]any)["traceparent"] = "00-0123456789abcdef0123456789abcdef-0000000000000003-00"
		},
		"lost tracestate": func(r labObject) { delete(r["outgoing"].(map[string]any), "tracestate") },
	} {
		t.Run(name, func(t *testing.T) {
			response := decode(t)
			mutate(response)
			if err := verify(response); err == nil {
				t.Fatal("incorrect SDK result accepted")
			}
		})
	}
}

func TestTraceSDKProofsRequireExecutedEndpoints(t *testing.T) {
	for language := range labClaims {
		t.Run(language, func(t *testing.T) {
			for _, check := range labSharedChecks {
				plan := report.NormalizedProfilePlan{SchemaVersion: 1, Profile: language + "-telemetry-lab", Language: language}
				for _, id := range check.Features {
					if labCheckFor(language, check.Scenario, id) != check.Name {
						t.Fatalf("shared feature %s has no %s binding in %s", id, check.Name, language)
					}
					if labCheckFor(language, "base", id) != "" {
						t.Fatalf("shared feature %s leaks into the base scenario", id)
					}
					plan.Proofs = append(plan.Proofs, report.ProofPlanProof{FeatureID: id, Assertion: "telemetry-lab/" + check.Name + "/" + id, Basis: "observed", Scenarios: []string{check.Scenario}})
				}
				encoded, err := json.Marshal(plan)
				if err != nil {
					t.Fatal(err)
				}
				if labSharedVerifiers[check.Name] == nil {
					t.Fatalf("shared check %s has no verifier", check.Name)
				}
				proofs, err := labPlanProofs(encoded, language, check.Scenario, map[string]bool{check.Name: true})
				if err != nil || len(proofs) != len(check.Features) {
					t.Fatalf("incomplete shared check: %v", err)
				}
				if _, err := labPlanProofs(encoded, language, check.Scenario, map[string]bool{}); err == nil || !strings.Contains(err.Error(), "no passing "+check.Name+" check") {
					t.Fatalf("missing %s should reject its proofs: %v", check.Name, err)
				}
			}
		})
	}
}

func TestSharedExpectedFailureRequiresExactReproduction(t *testing.T) {
	var check labSharedCheck
	for _, candidate := range labSharedChecks {
		if candidate.Scenario == "trace-invalid-headers" {
			check = candidate
		}
	}
	decode := func() labObject {
		var response labObject
		if err := json.Unmarshal([]byte(labTraceContextResponse), &response); err != nil {
			t.Fatal(err)
		}
		return response
	}
	response := decode()
	if outcome, err := labSharedOutcome(check, response); err != nil || outcome.Outcome != "verified" {
		t.Fatalf("ordinary verified result: %v, %v", outcome, err)
	}
	response["invalid_headers"].(map[string]any)["uppercase"] = true
	if _, err := labSharedOutcome(check, response); err == nil {
		t.Fatal("unrecorded defect should fail the test")
	}
	response["expected_failures"] = labObject{check.Scenario: labObject{
		"error": "invalid uppercase traceparent was accepted", "reason": "pinned SDK accepts uppercase hexadecimal IDs",
	}}
	if outcome, err := labSharedOutcome(check, response); err != nil || outcome.Outcome != "xfail" || outcome.Reason == "" {
		t.Fatalf("precisely reproduced known defect: %v, %v", outcome, err)
	}
	response["invalid_headers"].(map[string]any)["version-ff"] = true
	if _, err := labSharedOutcome(check, response); err == nil || !strings.Contains(err.Error(), "version-ff") {
		t.Fatalf("known failure must not hide an additional defect: %v", err)
	}
	response["invalid_headers"].(map[string]any)["version-ff"] = false
	response["invalid_headers"].(map[string]any)["uppercase"] = false
	if _, err := labSharedOutcome(check, response); err == nil || !strings.Contains(err.Error(), "unexpectedly passed") {
		t.Fatalf("SDK fix must require reviewing the expected failure: %v", err)
	}
	response["invalid_headers"].(map[string]any)["zero-span"] = true
	if _, err := labSharedOutcome(check, response); err == nil || !strings.Contains(err.Error(), "zero-span") {
		t.Fatalf("different defect must fail: %v", err)
	}
}

const labTraceLimitsResponse = `{
  "value_attributes":{"lab.text":"κόσμοςκόσμοςκόσμοςκόσμοςκόσμοςκό","lab.array":["abcdefghijklmnopqrstuvwxyzabcdef","κόσμοςκόσμοςκόσμοςκόσμοςκόσμοςκό","short"]},"attribute_count":2,"dropped_attributes":2,
  "events":[{"name":"event.1","attributes":{"lab.first":1},"index":1},{"name":"event.2","attributes":{"lab.first":2},"index":2}],"dropped_events":1,
  "links":[{"span_id":"0200000000000000","attributes":{"lab.first":1},"index":1},{"span_id":"0300000000000000","attributes":{"lab.first":2},"index":2}],"dropped_links":1
}`

func TestTraceLimitsProofRejectsIncorrectSDKResults(t *testing.T) {
	decode := func(t *testing.T) labObject {
		t.Helper()
		var response labObject
		if err := json.Unmarshal([]byte(labTraceLimitsResponse), &response); err != nil {
			t.Fatal(err)
		}
		return response
	}
	if err := labVerifyTraceLimits(decode(t)); err != nil {
		t.Fatal(err)
	}
	// SDKs may retain different entries under count limits. Both ordered subsets
	// use the same validator; no SDK name chooses an expectation.
	alternate := decode(t)
	alternate["links"] = []any{
		labObject{"span_id": "0100000000000000", "attributes": labObject{"lab.second": float64(0)}, "index": float64(0)},
		labObject{"span_id": "0200000000000000", "attributes": labObject{"lab.second": float64(1)}, "index": float64(1)},
	}
	if err := labVerifyTraceLimits(alternate); err != nil {
		t.Fatal(err)
	}
	ellipsis := decode(t)
	ellipsis["value_attributes"].(map[string]any)["lab.text"] = string([]rune(strings.Repeat("κόσμος", 6))[:29]) + "..."
	if err := labVerifyTraceLimits(ellipsis); err != nil {
		t.Fatal(err)
	}
	for name, mutate := range map[string]func(labObject){
		"extra span attribute": func(r labObject) { r["attribute_count"] = float64(3) },
		"untruncated Unicode": func(r labObject) {
			r["value_attributes"].(map[string]any)["lab.text"] = strings.Repeat("κόσμος", 6)
		},
		"untruncated array": func(r labObject) {
			r["value_attributes"].(map[string]any)["lab.array"] = []any{strings.Repeat("abcdefghijklmnopqrstuvwxyz", 2), strings.Repeat("κόσμος", 6), "short"}
		},
		"wrong dropped span count": func(r labObject) { r["dropped_attributes"] = float64(1) },
		"wrong event identity":     func(r labObject) { r["events"].([]any)[0].(map[string]any)["name"] = "event.0" },
		"extra event attribute": func(r labObject) {
			r["events"].([]any)[0].(map[string]any)["attributes"].(map[string]any)["lab.second"] = float64(1)
		},
		"wrong dropped event count": func(r labObject) { r["dropped_events"] = float64(0) },
		"reversed links":            func(r labObject) { links := r["links"].([]any); links[0], links[1] = links[1], links[0] },
		"wrong link identity":       func(r labObject) { r["links"].([]any)[0].(map[string]any)["span_id"] = "0100000000000000" },
		"extra link attribute": func(r labObject) {
			r["links"].([]any)[0].(map[string]any)["attributes"].(map[string]any)["lab.second"] = float64(1)
		},
		"changed link attribute": func(r labObject) {
			r["links"].([]any)[0].(map[string]any)["attributes"].(map[string]any)["lab.first"] = float64(2)
		},
	} {
		t.Run(name, func(t *testing.T) {
			response := decode(t)
			mutate(response)
			if err := labVerifyTraceLimits(response); err == nil {
				t.Fatal("incorrect SDK result accepted")
			}
		})
	}
}
