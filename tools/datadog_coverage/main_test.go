package main

import (
	"crypto/sha256"
	"fmt"
	"strings"
	"testing"
)

func TestCoverageGateRequiresCompleteExactEvidence(t *testing.T) {
	revision := strings.Repeat("a", 40)
	digest := strings.Repeat("b", 64)
	m := manifest{Family: "datadog", Profile: "p", Application: "aiohttp", ProofPlan: "plan", ScenarioShapes: map[string]string{"tags": "shape"}, ValidationPolicySHA256: digest, CandidateImplementationSHA256: digest}
	r := receipt{Family: "datadog", SchemaVersion: 2, Revision: revision, Profile: "p", Scenario: "tags", ValidationMode: "exact", Outcome: "verified", ProofPlanSHA256: sum("plan"), CaptureSHA256: digest, ScenarioShapeSHA256: sum("shape"), ValidationPolicySHA256: digest, CandidateImplementationSHA256: digest, Coverage: coverage{SchemaVersion: 1, Application: "aiohttp", Scenario: "tags", IntegrationSpans: map[string]int{"http.server": 1, "database": 1}, FieldPolicies: map[string]int{"exact": 3, "normalized": 1, "runtime-validated": 2}, SpanOccurrences: 2, FieldOccurrences: 6}}
	if err := validate(revision, []manifest{m}, []receipt{r}); err != nil {
		t.Fatal(err)
	}
	tests := []struct {
		name   string
		mutate func(*receipt)
	}{
		{"contract only", func(r *receipt) { r.ValidationMode = "contract" }},
		{"candidate only", func(r *receipt) { r.ValidationMode = "candidate" }},
		{"xfail", func(r *receipt) { r.Outcome = "xfail" }},
		{"unclassified", func(r *receipt) { r.Coverage.UnclassifiedFields = 1 }},
		{"missing database", func(r *receipt) { r.Coverage.IntegrationSpans["database"] = 0 }},
		{"unbound candidate", func(r *receipt) { r.CandidateImplementationSHA256 = "" }},
		{"wrong policy binding", func(r *receipt) { r.ValidationPolicySHA256 = strings.Repeat("c", 64) }},
		{"wrong shape binding", func(r *receipt) { r.ScenarioShapeSHA256 = strings.Repeat("c", 64) }},
		{"wrong reference binding", func(r *receipt) { r.ReferenceProfile, r.ReferenceProofPlanSHA256 = "other", strings.Repeat("c", 64) }},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			changed := r
			changed.Coverage.IntegrationSpans = map[string]int{"http.server": 1, "database": 1}
			tc.mutate(&changed)
			if validate(revision, []manifest{m}, []receipt{changed}) == nil {
				t.Fatal("invalid evidence passed")
			}
		})
	}
	if validate(revision, []manifest{m}, nil) == nil {
		t.Fatal("missing receipt passed")
	}
	incompleteReference := m
	incompleteReference.ReferenceProfile = "reference"
	if validate(revision, []manifest{incompleteReference}, []receipt{r}) == nil {
		t.Fatal("incomplete reference identity passed")
	}
}

func sum(value string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(value)))
}
