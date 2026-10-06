package main

import (
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/pawelchcki/rules_stests/report"
)

func labDecode(t *testing.T, fixture string) labObject {
	t.Helper()
	var response labObject
	if err := json.Unmarshal([]byte(fixture), &response); err != nil {
		t.Fatal(err)
	}
	return response
}

// labCheckMutations runs a verifier against a conforming fixture, permitted
// variants of it, and single-defect mutations that each must be rejected.
func labCheckMutations(t *testing.T, fixture string, verify func(labObject) error, accepted, rejected map[string]func(labObject)) {
	t.Helper()
	if err := verify(labDecode(t, fixture)); err != nil {
		t.Fatalf("conforming result rejected: %v", err)
	}
	for name, mutate := range accepted {
		t.Run("accepts "+name, func(t *testing.T) {
			response := labDecode(t, fixture)
			mutate(response)
			if err := verify(response); err != nil {
				t.Fatalf("conforming variant rejected: %v", err)
			}
		})
	}
	for name, mutate := range rejected {
		t.Run("rejects "+name, func(t *testing.T) {
			response := labDecode(t, fixture)
			mutate(response)
			if err := verify(response); err == nil {
				t.Fatal("incorrect SDK result accepted")
			}
		})
	}
}

func labCopy(value labObject) labObject {
	result := make(labObject, len(value))
	for key, item := range value {
		result[key] = item
	}
	return result
}

func TestLabPlanProofsRequireExecutedChecks(t *testing.T) {
	for language, groups := range labLanguageClaimsByCheck {
		t.Run(language, func(t *testing.T) {
			plan := report.NormalizedProfilePlan{SchemaVersion: 1, Profile: language + "-telemetry-lab", Language: language}
			observed := map[string]bool{}
			base := map[string]bool{}
			for _, id := range labScenarioClaims(language, "base") {
				check := labCheckFor(language, "base", id)
				if check == "" {
					t.Fatalf("unbound feature %s", id)
				}
				base[id] = true
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
			// Every remaining base check, capture or response, gates its own IDs.
			for check := range groups {
				delete(observed, check)
				if _, err := labPlanProofs(encoded, language, "base", observed); err == nil || !strings.Contains(err.Error(), "no passing "+check+" check") {
					t.Fatalf("missing %s should reject its feature IDs: %v", check, err)
				}
				observed[check] = true
			}
			// Shared contracts run in their own scenarios and never leak into base.
			for _, shared := range labSharedChecks {
				for _, id := range shared.Features {
					if base[id] {
						t.Fatalf("shared %s feature %s is also a base claim", shared.Name, id)
					}
				}
			}
			leaked := plan
			leaked.Proofs = append(append([]report.ProofPlanProof{}, plan.Proofs...), report.ProofPlanProof{
				FeatureID: "baggage.basic-support", Assertion: "telemetry-lab/response/baggage/baggage.basic-support", Basis: "observed", Scenarios: []string{"base"},
			})
			leakedBytes, err := json.Marshal(leaked)
			if err != nil {
				t.Fatal(err)
			}
			observed["response/baggage"] = true
			if _, err := labPlanProofs(leakedBytes, language, "base", observed); err == nil || !strings.Contains(err.Error(), "unexpected lab plan proof baggage.basic-support") {
				t.Fatalf("shared baggage proof in a base plan should be rejected: %v", err)
			}
			delete(observed, "response/baggage")
			plan.Proofs[0].Assertion = "telemetry-lab/unchecked/" + plan.Proofs[0].FeatureID
			encoded, err = json.Marshal(plan)
			if err != nil {
				t.Fatal(err)
			}
			if _, err := labPlanProofs(encoded, language, "base", observed); err == nil || !strings.Contains(err.Error(), "unexpected lab plan proof") {
				t.Fatalf("wrong assertion binding should be rejected: %v", err)
			}
		})
	}
}

func TestLabClaimBindingsAreUnambiguous(t *testing.T) {
	for language, groups := range labLanguageClaimsByCheck {
		owner := map[string]string{}
		for check, ids := range groups {
			for _, id := range ids {
				if previous, exists := owner[id]; exists {
					t.Errorf("%s feature %s is bound to both %s and %s", language, id, previous, check)
				}
				owner[id] = check
			}
		}
	}
	names := map[string]bool{}
	scenarios := map[string]bool{}
	for _, check := range labSharedChecks {
		if names[check.Name] || scenarios[check.Scenario] {
			t.Errorf("shared check %s reuses a name or scenario", check.Name)
		}
		names[check.Name], scenarios[check.Scenario] = true, true
		if labSharedVerifiers[check.Name] == nil {
			t.Errorf("shared check %s has no verifier", check.Name)
		}
		if _, exists := labVariantClaims[check.Scenario]; exists || check.Scenario == "base" {
			t.Errorf("shared scenario %s collides with a base or variant scenario", check.Scenario)
		}
		for _, language := range check.Languages {
			if labLanguageClaimsByCheck[language] == nil {
				t.Errorf("shared check %s names unknown language %q", check.Name, language)
			}
		}
	}
	for name := range labSharedVerifiers {
		if !names[name] {
			t.Errorf("verifier %s has no shared check", name)
		}
	}
}

func TestAmbientContextClaimsExcludeGo(t *testing.T) {
	var ambient labSharedCheck
	for _, check := range labSharedChecks {
		if check.Name == "response/context" {
			ambient = check
		}
	}
	if ambient.Name == "" || ambient.Scenario != "context" || ambient.Path != "/v1/context" {
		t.Fatalf("ambient context check is absent: %+v", ambient)
	}
	if !reflect.DeepEqual(ambient.Languages, []string{"python", "ruby"}) {
		t.Fatalf("ambient context languages = %v, want python and ruby", ambient.Languages)
	}
	for _, language := range []string{"python", "ruby"} {
		check, ok := labSharedScenario(language, "context")
		if !ok || check.Name != ambient.Name {
			t.Fatalf("%s context scenario is not the shared ambient check", language)
		}
		if !reflect.DeepEqual(labScenarioClaims(language, "context"), ambient.Features) {
			t.Fatalf("%s context claims differ from the shared check", language)
		}
		claimed := map[string]bool{}
		for _, id := range labClaims[language] {
			claimed[id] = true
		}
		for _, id := range ambient.Features {
			if !claimed[id] || labCheckFor(language, "context", id) != ambient.Name {
				t.Fatalf("%s lost ambient context claim %s", language, id)
			}
		}
	}
	if _, ok := labSharedScenario("go", "context"); ok {
		t.Fatal("Go selected the ambient context scenario")
	}
	if _, ok := labVariantClaims["context"]; ok {
		t.Fatal("context is registered as a variant and would run for Go")
	}
	if claims := labScenarioClaims("go", "context"); len(claims) != 0 {
		t.Fatalf("Go context scenario claims %v", claims)
	}
	if _, ok := labClaimsByCheck["go"][ambient.Name]; ok {
		t.Fatal("Go claims are bound to the ambient context check")
	}
	goClaims := map[string]bool{}
	for _, id := range labClaims["go"] {
		goClaims[id] = true
	}
	plan := report.NormalizedProfilePlan{SchemaVersion: 1, Profile: "go-telemetry-lab", Language: "go"}
	for _, id := range ambient.Features {
		if goClaims[id] {
			t.Errorf("Go claims ambient context feature %s", id)
		}
		for _, scenario := range []string{"context", "base"} {
			if check := labCheckFor("go", scenario, id); check != "" {
				t.Errorf("Go binds %s in %s to %s", id, scenario, check)
			}
		}
		plan.Proofs = append(plan.Proofs, report.ProofPlanProof{FeatureID: id, Assertion: "telemetry-lab/" + ambient.Name + "/" + id, Basis: "observed", Scenarios: []string{"context"}})
	}
	encoded, err := json.Marshal(plan)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := labPlanProofs(encoded, "go", "context", map[string]bool{ambient.Name: true}); err == nil || !strings.Contains(err.Error(), "unexpected lab plan proof") {
		t.Fatalf("Go ambient context proofs must be rejected even when observed: %v", err)
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
	labCheckMutations(t, labTraceContextResponse, verify, nil, map[string]func(labObject){
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
	})
}

func TestTraceSDKProofsRequireExecutedEndpoints(t *testing.T) {
	for language := range labClaims {
		t.Run(language, func(t *testing.T) {
			for _, check := range labSharedChecks {
				if !check.appliesTo(language) {
					continue
				}
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
	response := labDecode(t, labTraceContextResponse)
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
	labCheckMutations(t, labTraceLimitsResponse, labVerifyTraceLimits, map[string]func(labObject){
		// SDKs may retain different entries under count limits. Both ordered
		// subsets use the same validator; no SDK name chooses an expectation.
		"alternate retained links": func(r labObject) {
			r["links"] = []any{
				labObject{"span_id": "0100000000000000", "attributes": labObject{"lab.second": float64(0)}, "index": float64(0)},
				labObject{"span_id": "0200000000000000", "attributes": labObject{"lab.second": float64(1)}, "index": float64(1)},
			}
		},
		"ellipsis within limit": func(r labObject) {
			r["value_attributes"].(map[string]any)["lab.text"] = string([]rune(strings.Repeat("κόσμος", 6))[:29]) + "..."
		},
		// The common specification requires at most the configured character
		// limit, so a shorter prefix of an oversized value is also conforming.
		"shorter truncation": func(r labObject) {
			r["value_attributes"].(map[string]any)["lab.text"] = "κ"
			r["value_attributes"].(map[string]any)["lab.array"] = []any{"a", "κ", "short"}
		},
		// The span limit contract does not require a contiguous retained subset.
		"noncontiguous retention": func(r labObject) {
			r["events"].([]any)[0] = labObject{"name": "event.0", "attributes": labObject{"lab.first": float64(0)}, "index": float64(0)}
			r["links"].([]any)[0] = labObject{"span_id": "0100000000000000", "attributes": labObject{"lab.first": float64(0)}, "index": float64(0)}
		},
	}, map[string]func(labObject){
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
	})
}

// Child timestamps come from the SDK clock and are not part of the contract.
const labTraceLifecycleResponse = `{
  "recording_before":true,"recording_after":false,"active_matches":true,"child_active_matches":true,"restored":true,"after_end_unchanged":true,
  "spans":[
    {"name":"lab.lifecycle.child","trace_id":"0102030405060708090a0b0c0d0e0f10","span_id":"0000000000000002","parent_id":"0000000000000001"},
    {"name":"lab.lifecycle","trace_id":"0102030405060708090a0b0c0d0e0f10","span_id":"0000000000000001","parent_id":"0000000000000000","start":"1700000000123000000","end":"1700000000173000000"}
  ]
}`

func TestTraceLifecycleProofRejectsIncorrectSDKResults(t *testing.T) {
	parent := func(r labObject) labObject { return labNamed(labObjects(r, "spans"), "lab.lifecycle") }
	child := func(r labObject) labObject { return labNamed(labObjects(r, "spans"), "lab.lifecycle.child") }
	labCheckMutations(t, labTraceLifecycleResponse, labVerifyTraceLifecycle, map[string]func(labObject){
		"exporter order": func(r labObject) { spans := r["spans"].([]any); spans[0], spans[1] = spans[1], spans[0] },
	}, map[string]func(labObject){
		"not recording before end":        func(r labObject) { r["recording_before"] = false },
		"recording after end":             func(r labObject) { r["recording_after"] = true },
		"recording after end omitted":     func(r labObject) { delete(r, "recording_after") },
		"bound context lost parent":       func(r labObject) { r["active_matches"] = false },
		"active match reported as string": func(r labObject) { r["active_matches"] = "true" },
		"child not active":                func(r labObject) { r["child_active_matches"] = false },
		"previous context not restored":   func(r labObject) { r["restored"] = false },
		"post-end mutation exported":      func(r labObject) { r["after_end_unchanged"] = false },
		"post-end observation omitted":    func(r labObject) { delete(r, "after_end_unchanged") },
		"rename after end exported":       func(r labObject) { parent(r)["name"] = "lab.changed-after-end" },
		"child missing": func(r labObject) {
			r["spans"] = []any{parent(r)}
		},
		"child exported twice": func(r labObject) {
			r["spans"] = append(r["spans"].([]any), labCopy(child(r)))
		},
		"parent exported twice": func(r labObject) {
			r["spans"] = append(r["spans"].([]any), labCopy(parent(r)))
		},
		"ambient request span became parent": func(r labObject) { parent(r)["parent_id"] = "00f067aa0ba902b7" },
		"zero parent omitted":                func(r labObject) { delete(parent(r), "parent_id") },
		"generator unused for trace": func(r labObject) {
			parent(r)["trace_id"] = "4bf92f3577b34da6a3ce929d0e0e4736"
			child(r)["trace_id"] = "4bf92f3577b34da6a3ce929d0e0e4736"
		},
		"generator unused for root":   func(r labObject) { parent(r)["span_id"] = "00f067aa0ba902b7" },
		"generator unused for child":  func(r labObject) { child(r)["span_id"] = "0000000000000003" },
		"child in another trace":      func(r labObject) { child(r)["trace_id"] = "0123456789abcdef0123456789abcdef" },
		"child parented to root":      func(r labObject) { child(r)["parent_id"] = "0000000000000000" },
		"numeric start":               func(r labObject) { parent(r)["start"] = float64(1_700_000_000_123_000_000) },
		"numeric end":                 func(r labObject) { parent(r)["end"] = float64(1_700_000_000_173_000_000) },
		"leading zero start":          func(r labObject) { parent(r)["start"] = "01700000000123000000" },
		"signed start":                func(r labObject) { parent(r)["start"] = "+1700000000123000000" },
		"padded end":                  func(r labObject) { parent(r)["end"] = " 1700000000173000000" },
		"start off by one nanosecond": func(r labObject) { parent(r)["start"] = "1700000000123000001" },
		"end off by one nanosecond":   func(r labObject) { parent(r)["end"] = "1700000000173000001" },
		"microsecond start":           func(r labObject) { parent(r)["start"] = "1700000000123000" },
		"start ignored":               func(r labObject) { parent(r)["start"] = "1700000000124000000" },
		"second end applied":          func(r labObject) { parent(r)["end"] = "1700000000223000000" },
		"start omitted":               func(r labObject) { delete(parent(r), "start") },
		"end omitted":                 func(r labObject) { delete(parent(r), "end") },
	})
}

const labResourcesResponse = `{
  "empty":0,
  "merged":{"lab.left":"one","lab.integer":42,"lab.right":"two","lab.boolean":true,"lab.shared":"right"},
  "originals":{
    "left":{"lab.left":"one","lab.integer":42,"lab.shared":"left"},
    "right":{"lab.right":"two","lab.boolean":true,"lab.shared":"right"}
  }
}`

func TestResourcesProofRejectsIncorrectSDKResults(t *testing.T) {
	merged := func(r labObject) labObject { return r["merged"].(map[string]any) }
	original := func(r labObject, side string) labObject {
		return r["originals"].(map[string]any)[side].(map[string]any)
	}
	labCheckMutations(t, labResourcesResponse, labVerifyResources, nil, map[string]func(labObject){
		"empty resource has defaults": func(r labObject) { r["empty"] = float64(1) },
		"empty count omitted":         func(r labObject) { delete(r, "empty") },
		"left won precedence":         func(r labObject) { merged(r)["lab.shared"] = "left" },
		"merge dropped left value":    func(r labObject) { delete(merged(r), "lab.integer") },
		"merge dropped right value":   func(r labObject) { delete(merged(r), "lab.boolean") },
		"integer stringified":         func(r labObject) { merged(r)["lab.integer"] = "42" },
		"boolean stringified":         func(r labObject) { merged(r)["lab.boolean"] = "true" },
		"integer changed":             func(r labObject) { merged(r)["lab.integer"] = float64(43) },
		"boolean flipped":             func(r labObject) { merged(r)["lab.boolean"] = false },
		"merge added SDK defaults":    func(r labObject) { merged(r)["service.name"] = "unknown_service" },
		"merged omitted":              func(r labObject) { delete(r, "merged") },
		"merge updated left in place": func(r labObject) {
			left := original(r, "left")
			left["lab.right"], left["lab.boolean"], left["lab.shared"] = "two", true, "right"
		},
		"merge updated right in place": func(r labObject) {
			right := original(r, "right")
			right["lab.left"], right["lab.integer"] = "one", float64(42)
		},
		"left shared value overwritten": func(r labObject) { original(r, "left")["lab.shared"] = "right" },
		"left typed value lost":         func(r labObject) { delete(original(r, "left"), "lab.integer") },
		"right typed value stringified": func(r labObject) { original(r, "right")["lab.boolean"] = "true" },
		"originals omitted":             func(r labObject) { delete(r, "originals") },
	})
}

const labBaggageResponse = `{
  "value":"lab-value","extracted":"lab-value","incoming":"value","original":"two","removed":null,
  "outgoing":{"baggage":"incoming=value,lab-key=lab-value"}
}`

func TestBaggageProofRejectsIncorrectSDKResults(t *testing.T) {
	outgoing := func(r labObject) labObject { return r["outgoing"].(map[string]any) }
	labCheckMutations(t, labBaggageResponse, labVerifyBaggage, map[string]func(labObject){
		"members reordered": func(r labObject) { outgoing(r)["baggage"] = "lab-key=lab-value,incoming=value" },
	}, map[string]func(labObject){
		"set value lost":              func(r labObject) { r["value"] = nil },
		"set value changed":           func(r labObject) { r["value"] = "other" },
		"roundtrip value lost":        func(r labObject) { r["extracted"] = nil },
		"roundtrip value omitted":     func(r labObject) { delete(r, "extracted") },
		"incoming member lost":        func(r labObject) { r["incoming"] = nil },
		"incoming member omitted":     func(r labObject) { delete(r, "incoming") },
		"remove mutated original":     func(r labObject) { r["original"] = nil },
		"original omitted":            func(r labObject) { delete(r, "original") },
		"remove ignored":              func(r labObject) { r["removed"] = "two" },
		"removed omitted":             func(r labObject) { delete(r, "removed") },
		"removed member still sent":   func(r labObject) { outgoing(r)["baggage"] = "incoming=value,lab-key=lab-value,lab.other=two" },
		"incoming member not sent":    func(r labObject) { outgoing(r)["baggage"] = "lab-key=lab-value" },
		"set member not sent":         func(r labObject) { outgoing(r)["baggage"] = "incoming=value" },
		"duplicate member sent":       func(r labObject) { outgoing(r)["baggage"] = "incoming=value,lab-key=lab-value,lab-key=lab-value" },
		"member metadata added":       func(r labObject) { outgoing(r)["baggage"] = "incoming=value,lab-key=lab-value;lab=meta" },
		"value changed on the wire":   func(r labObject) { outgoing(r)["baggage"] = "incoming=value,lab-key=other" },
		"semicolon separated members": func(r labObject) { outgoing(r)["baggage"] = "incoming=value;lab-key=lab-value" },
		"empty header":                func(r labObject) { outgoing(r)["baggage"] = "" },
		"header as list": func(r labObject) {
			outgoing(r)["baggage"] = []any{"incoming=value", "lab-key=lab-value"}
		},
		"capitalized header name": func(r labObject) {
			out := outgoing(r)
			out["Baggage"] = out["baggage"]
			delete(out, "baggage")
		},
		"underscored header name": func(r labObject) {
			out := outgoing(r)
			out["bag_gage"] = out["baggage"]
			delete(out, "baggage")
		},
		"legacy header name": func(r labObject) {
			out := outgoing(r)
			out["otel-baggage"] = out["baggage"]
			delete(out, "baggage")
		},
		"extra outgoing header": func(r labObject) {
			outgoing(r)["traceparent"] = "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
		},
		"outgoing omitted": func(r labObject) { delete(r, "outgoing") },
	})
}

const labAmbientContextResponse = `{
  "distinct_keys":true,"original_unchanged":true,"active_matches":true,"child_active_matches":true,"restored":true,
  "states":[null,"one","two","one",null]
}`

func TestAmbientContextProofRejectsIncorrectSDKResults(t *testing.T) {
	states := func(r labObject) []any { return r["states"].([]any) }
	rejected := map[string]func(labObject){
		"nested attach not observed":     func(r labObject) { states(r)[2] = "one" },
		"value visible before attach":    func(r labObject) { states(r)[0] = "one" },
		"inner detach did not restore":   func(r labObject) { states(r)[3] = "two" },
		"inner detach dropped outer":     func(r labObject) { states(r)[3] = nil },
		"outer detach leaked value":      func(r labObject) { states(r)[4] = "one" },
		"absent value spelled as string": func(r labObject) { states(r)[0] = "null" },
		"absent value as empty string":   func(r labObject) { states(r)[4] = "" },
		"states truncated":               func(r labObject) { r["states"] = states(r)[:4] },
		"extra state":                    func(r labObject) { r["states"] = append(states(r), nil) },
		"states reported as object":      func(r labObject) { r["states"] = labObject{"0": nil} },
		"states omitted":                 func(r labObject) { delete(r, "states") },
	}
	for key, defect := range map[string]string{
		"distinct_keys":        "same-named keys collide",
		"original_unchanged":   "set_value mutated its context",
		"active_matches":       "attached context is not current",
		"child_active_matches": "nested attached context is not current",
		"restored":             "detach did not restore",
	} {
		rejected[defect] = func(r labObject) { r[key] = false }
		rejected[key+" omitted"] = func(r labObject) { delete(r, key) }
		rejected[key+" reported as string"] = func(r labObject) { r[key] = "true" }
	}
	labCheckMutations(t, labAmbientContextResponse, labVerifyAmbientContext, nil, rejected)
}

// Every shared check needs a conforming fixture so its HTTP flow is exercised.
var labSharedFixtures = map[string]string{
	"response/trace-context":         labTraceContextResponse,
	"response/trace-invalid-headers": labTraceContextResponse,
	"response/trace-limits":          labTraceLimitsResponse,
	"response/trace-lifecycle":       labTraceLifecycleResponse,
	"response/resources":             labResourcesResponse,
	"response/baggage":               labBaggageResponse,
	"response/context":               labAmbientContextResponse,
}

func labSharedCheckNamed(t *testing.T, name string) labSharedCheck {
	t.Helper()
	for _, check := range labSharedChecks {
		if check.Name == name {
			return check
		}
	}
	t.Fatalf("shared check %s is absent", name)
	return labSharedCheck{}
}

// labSharedServer serves check.Path only. An empty body yields HTTP 500.
func labSharedServer(t *testing.T, check labSharedCheck, respond func(attempt int) string) (*httptest.Server, *atomic.Int32) {
	t.Helper()
	requests := &atomic.Int32{}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet || r.URL.Path != check.Path {
			http.Error(w, "unexpected "+r.Method+" "+r.URL.Path, http.StatusNotFound)
			return
		}
		body := respond(int(requests.Add(1)))
		if body == "" {
			http.Error(w, "lab failure", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, body)
	}))
	t.Cleanup(server.Close)
	return server, requests
}

func labEncode(t *testing.T, response labObject) string {
	t.Helper()
	encoded, err := json.Marshal(response)
	if err != nil {
		t.Fatal(err)
	}
	return string(encoded)
}

func TestSharedCheckRunsTwiceAgainstLiveEndpoint(t *testing.T) {
	for _, check := range labSharedChecks {
		t.Run(check.Name, func(t *testing.T) {
			fixture, ok := labSharedFixtures[check.Name]
			if !ok {
				t.Fatalf("shared check %s has no conforming fixture", check.Name)
			}
			server, requests := labSharedServer(t, check, func(int) string { return fixture })
			result, err := labRunSharedCheck(server.Client(), server.URL, check)
			if err != nil {
				t.Fatal(err)
			}
			if requests.Load() != 2 {
				t.Fatalf("%s requested %d times, want 2", check.Path, requests.Load())
			}
			if result.Check.Name != check.Name || result.Outcome != (labReceiptOutcome{Outcome: "verified"}) {
				t.Fatalf("unexpected result %+v", result)
			}
			if !reflect.DeepEqual(result.Response, labDecode(t, fixture)) {
				t.Fatalf("recorded response differs from the endpoint: %v", result.Response)
			}
		})
	}
}

func TestSharedCheckRejectsNonRepeatableEndpoint(t *testing.T) {
	lifecycle := labSharedCheckNamed(t, "response/trace-lifecycle")
	for name, test := range map[string]struct {
		check    labSharedCheck
		respond  func(t *testing.T, attempt int) string
		requests int32
		want     string
	}{
		// A valid but different second response means the lab is not isolated.
		"unverified field changed": {lifecycle, func(t *testing.T, attempt int) string {
			response := labDecode(t, labTraceLifecycleResponse)
			response["attempt"] = float64(attempt)
			return labEncode(t, response)
		}, 2, "changed on repeated execution"},
		// A process-wide ID generator keeps counting across requests.
		"shared ID generator": {lifecycle, func(t *testing.T, attempt int) string {
			response := labDecode(t, labTraceLifecycleResponse)
			if attempt == 2 {
				spans := labObjects(response, "spans")
				labNamed(spans, "lab.lifecycle")["span_id"] = "0000000000000003"
				labNamed(spans, "lab.lifecycle.child")["span_id"] = "0000000000000004"
				labNamed(spans, "lab.lifecycle.child")["parent_id"] = "0000000000000003"
			}
			return labEncode(t, response)
		}, 2, "attempt 2"},
		// A process-wide exporter accumulates spans from the first request.
		"shared exporter": {lifecycle, func(t *testing.T, attempt int) string {
			response := labDecode(t, labTraceLifecycleResponse)
			if attempt == 2 {
				response["spans"] = append(response["spans"].([]any), labDecode(t, labTraceLifecycleResponse)["spans"].([]any)...)
			}
			return labEncode(t, response)
		}, 2, "attempt 2"},
		"first attempt fails": {lifecycle, func(t *testing.T, attempt int) string {
			response := labDecode(t, labTraceLifecycleResponse)
			response["restored"] = false
			return labEncode(t, response)
		}, 1, "attempt 1"},
		"server error": {lifecycle, func(*testing.T, int) string { return "" }, 1, "returned 500"},
		"malformed JSON": {lifecycle, func(*testing.T, int) string {
			return labTraceLifecycleResponse[:20]
		}, 1, "unexpected end of JSON"},
	} {
		t.Run(name, func(t *testing.T) {
			server, requests := labSharedServer(t, test.check, func(attempt int) string { return test.respond(t, attempt) })
			if _, err := labRunSharedCheck(server.Client(), server.URL, test.check); err == nil || !strings.Contains(err.Error(), test.want) {
				t.Fatalf("want error containing %q, got %v", test.want, err)
			}
			if requests.Load() != test.requests {
				t.Fatalf("%d requests, want %d", requests.Load(), test.requests)
			}
		})
	}
}

func TestSharedCheckExpectedFailureMustReproduceEveryTime(t *testing.T) {
	check := labSharedCheckNamed(t, "response/trace-invalid-headers")
	defective := func(t *testing.T, reproduced bool) string {
		response := labDecode(t, labTraceContextResponse)
		response["invalid_headers"].(map[string]any)["uppercase"] = reproduced
		response["expected_failures"] = labObject{check.Scenario: labObject{
			"error": "invalid uppercase traceparent was accepted", "reason": "pinned SDK accepts uppercase hexadecimal IDs",
		}}
		return labEncode(t, response)
	}
	server, _ := labSharedServer(t, check, func(int) string { return defective(t, true) })
	result, err := labRunSharedCheck(server.Client(), server.URL, check)
	if err != nil || result.Outcome != (labReceiptOutcome{Outcome: "xfail", Reason: "pinned SDK accepts uppercase hexadecimal IDs"}) {
		t.Fatalf("consistently reproduced defect: %+v, %v", result.Outcome, err)
	}
	flaky, _ := labSharedServer(t, check, func(attempt int) string { return defective(t, attempt == 1) })
	if _, err := labRunSharedCheck(flaky.Client(), flaky.URL, check); err == nil || !strings.Contains(err.Error(), "attempt 2") || !strings.Contains(err.Error(), "unexpectedly passed") {
		t.Fatalf("defect reproduced only once must fail: %v", err)
	}
}

func labCaptureRecords(t *testing.T, accepted []byte) []map[string]json.RawMessage {
	t.Helper()
	var records []map[string]json.RawMessage
	if err := json.Unmarshal(accepted, &records); err != nil {
		t.Fatal(err)
	}
	return records
}

func labSameJSON(t *testing.T, left, right []byte) bool {
	t.Helper()
	var leftValue, rightValue any
	if err := json.Unmarshal(left, &leftValue); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(right, &rightValue); err != nil {
		t.Fatal(err)
	}
	return reflect.DeepEqual(leftValue, rightValue)
}

func TestSharedCaptureIsAnIndependentControlRecord(t *testing.T) {
	accepted := map[string][]byte{}
	responses := map[string][]byte{}
	for _, check := range labSharedChecks {
		body, err := json.Marshal(map[string]labObject{check.Path: labDecode(t, labSharedFixtures[check.Name])})
		if err != nil {
			t.Fatal(err)
		}
		capture := []byte("[]")
		first, err := labAcceptedCapture(capture, body, check.Scenario)
		if err != nil {
			t.Fatalf("%s rejected an empty capture: %v", check.Scenario, err)
		}
		if string(capture) != "[]" {
			t.Fatalf("%s mutated its input capture", check.Scenario)
		}
		records := labCaptureRecords(t, first)
		if len(records) != 1 || len(records[0]) != 2 || string(records[0]["signal"]) != `"lab-control"` {
			t.Fatalf("%s capture is not a single control record: %s", check.Scenario, first)
		}
		if !labSameJSON(t, records[0]["labResponses"], body) {
			t.Fatalf("%s control record changed its responses", check.Scenario)
		}
		accepted[check.Scenario], responses[check.Scenario] = first, body
	}
	// Each scenario's capture depends only on its own responses, regardless of
	// what other scenarios produced before it.
	for _, check := range labSharedChecks {
		again, err := labAcceptedCapture([]byte("[]"), responses[check.Scenario], check.Scenario)
		if err != nil || string(again) != string(accepted[check.Scenario]) {
			t.Fatalf("%s capture is not reproducible: %v", check.Scenario, err)
		}
		for _, other := range labSharedChecks {
			if other.Scenario != check.Scenario && other.Path != check.Path && strings.Contains(string(accepted[check.Scenario]), other.Path) {
				t.Fatalf("%s capture includes %s responses", check.Scenario, other.Path)
			}
		}
	}
}

func TestBaseCaptureRequiresTelemetry(t *testing.T) {
	responses := []byte(`{"/v1/spans":{"spans":true}}`)
	for _, scenario := range []string{"base", "log-count", "sampler-arg-one", "otlp-retry-after"} {
		if _, err := labAcceptedCapture([]byte("[]"), responses, scenario); err == nil || !strings.Contains(err.Error(), "needs captured telemetry") {
			t.Fatalf("%s accepted an empty capture: %v", scenario, err)
		}
	}
	if accepted, err := labAcceptedCapture([]byte("[]"), responses, "disabled"); err != nil || string(labCaptureRecords(t, accepted)[0]["signal"]) != `"lab-control"` {
		t.Fatalf("disabled SDK control record: %v", err)
	}
	if _, err := labAcceptedCapture([]byte("null"), responses, "base"); err == nil {
		t.Fatal("base accepted a null capture")
	}
	capture := []byte(`[{"signal":"traces","resource_spans":[]},{"signal":"metrics"}]`)
	original := string(capture)
	accepted, err := labAcceptedCapture(capture, responses, "base")
	if err != nil {
		t.Fatal(err)
	}
	if string(capture) != original {
		t.Fatal("base capture input was mutated")
	}
	records := labCaptureRecords(t, accepted)
	if len(records) != 2 || string(records[0]["signal"]) != `"traces"` || !labSameJSON(t, records[0]["labResponses"], responses) || records[1]["labResponses"] != nil {
		t.Fatalf("responses were not attached to the first telemetry record only: %s", accepted)
	}
	if _, err := labAcceptedCapture(accepted, responses, "base"); err == nil || !strings.Contains(err.Error(), "already has labResponses") {
		t.Fatalf("capture with responses was accepted twice: %v", err)
	}
}

func TestSharedReceiptBindsControlRecord(t *testing.T) {
	t.Setenv("OTEL_TEST_REVISION", strings.Repeat("a", 40))
	root := t.TempDir()
	plan := []byte(`{"schemaVersion":1}`)
	baggage := labSharedCheckNamed(t, "response/baggage")
	responses := []byte(fmt.Sprintf(`{%q:%s}`, baggage.Path, labBaggageResponse))
	var proofs []report.ReceiptProof
	for _, id := range baggage.Features {
		proofs = append(proofs, report.ReceiptProof{FeatureID: id, Assertion: "telemetry-lab/" + baggage.Name + "/" + id, Basis: "observed", Result: "pass"})
	}
	read := func(t *testing.T, language, scenario string) (report.ValidationReceipt, []byte) {
		t.Helper()
		directory := filepath.Join(root, "receipts", language+"-telemetry-lab")
		capture, err := os.ReadFile(filepath.Join(directory, scenario+".capture.json"))
		if err != nil {
			t.Fatal(err)
		}
		encoded, err := os.ReadFile(filepath.Join(directory, scenario+".json"))
		if err != nil {
			t.Fatal(err)
		}
		receipt, err := report.DecodeReceipt(encoded)
		if err != nil {
			t.Fatal(err)
		}
		if receipt.CaptureSHA256 != fmt.Sprintf("%x", sha256.Sum256(capture)) || receipt.ProofPlanSHA256 != fmt.Sprintf("%x", sha256.Sum256(plan)) {
			t.Fatalf("%s receipt digests do not bind its files", scenario)
		}
		return receipt, capture
	}
	if err := labWriteReceipt(root, "go", baggage.Scenario, plan, []byte("[]"), responses, proofs, labReceiptOutcome{Outcome: "verified"}); err != nil {
		t.Fatal(err)
	}
	receipt, capture := read(t, "go", baggage.Scenario)
	if receipt.Scenario != baggage.Scenario || receipt.Outcome != "verified" || receipt.XFailReason != "" || !reflect.DeepEqual(receipt.Proofs, proofs) {
		t.Fatalf("verified shared receipt: %+v", receipt)
	}
	records := labCaptureRecords(t, capture)
	if len(records) != 1 || string(records[0]["signal"]) != `"lab-control"` || !labSameJSON(t, records[0]["labResponses"], responses) {
		t.Fatalf("shared receipt capture is not the control record: %s", capture)
	}
	headers := labSharedCheckNamed(t, "response/trace-invalid-headers")
	xfail := labReceiptOutcome{Outcome: "xfail", Reason: "pinned SDK accepts uppercase hexadecimal IDs"}
	if err := labWriteReceipt(root, "python", headers.Scenario, plan, []byte("[]"), responses, nil, xfail); err != nil {
		t.Fatal(err)
	}
	if receipt, _ := read(t, "python", headers.Scenario); receipt.Outcome != "xfail" || receipt.XFailReason != xfail.Reason || len(receipt.Proofs) != 0 {
		t.Fatalf("xfail shared receipt: %+v", receipt)
	}
	if err := labWriteReceipt(root, "go", "base", plan, []byte("[]"), responses, nil); err == nil || !strings.Contains(err.Error(), "needs captured telemetry") {
		t.Fatalf("base receipt without telemetry: %v", err)
	}
	for _, name := range []string{"base.json", "base.capture.json"} {
		if _, err := os.Stat(filepath.Join(root, "receipts", "go-telemetry-lab", name)); !errors.Is(err, fs.ErrNotExist) {
			t.Fatalf("rejected base receipt wrote %s: %v", name, err)
		}
	}
}
