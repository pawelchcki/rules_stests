package main

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/pawelchcki/rules_stests/report"
)

func TestReferenceProfileMustBeCompleteAndCompatible(t *testing.T) {
	proof := report.ProofPlanProof{FeatureID: "span/database-children", Assertion: "span/database-children", Basis: "observed", EvidencePolicy: "runtime"}
	plan := report.NormalizedProfilePlan{Family: "datadog", WireVersion: "v0.5", Application: "aiohttp", Signals: []string{"traces"}, Proofs: []report.ProofPlanProof{proof}}
	referencePlan, err := json.Marshal(report.NormalizedProfilePlan{Proofs: []report.ProofPlanProof{proof}})
	if err != nil {
		t.Fatal(err)
	}
	reference := manifestDocument{
		SchemaVersion: 2, Family: "datadog", Profile: "reference", WireVersion: "v0.5", Application: "aiohttp",
		ShapeNamespace: "datadog.realworld.shape.reference", Program: "(validate-profile)",
		Signals: []string{"traces"}, ProofPlan: string(referencePlan), ScenarioShapes: map[string]string{"articles": "shape", "tags": "shape"},
	}
	if err := validateAndApplyReference(&plan, reference, []string{"articles", "tags"}); err != nil {
		t.Fatal(err)
	}
	if plan.ReferenceProfile != "reference" {
		t.Fatal("reference identity was not applied")
	}

	tests := []struct {
		name   string
		mutate func(*manifestDocument)
		want   string
	}{
		{"incomplete scenarios", func(r *manifestDocument) { delete(r.ScenarioShapes, "tags") }, "scenario set is incomplete"},
		{"missing requested scenario", func(r *manifestDocument) { delete(r.ScenarioShapes, "tags"); r.ScenarioShapes["other"] = "shape" }, "lacks scenario"},
		{"wrong application", func(r *manifestDocument) { r.Application = "django" }, "does not match"},
		{"wrong wire version", func(r *manifestDocument) { r.WireVersion = "v0.4" }, "does not match"},
		{"wrong proof contract", func(r *manifestDocument) { r.ProofPlan = `{"proofs":[]}` }, "does not match"},
		{"wrong signals", func(r *manifestDocument) { r.Signals = []string{"metrics"} }, "does not match"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			changed := reference
			changed.ScenarioShapes = map[string]string{"articles": "shape", "tags": "shape"}
			tc.mutate(&changed)
			candidate := plan
			if err := validateAndApplyReference(&candidate, changed, []string{"articles", "tags"}); err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("got %v, want error containing %q", err, tc.want)
			}
		})
	}
}

func TestReferenceShapeNamespaceFollowsReferenceChain(t *testing.T) {
	reference := manifestDocument{ShapeNamespace: "candidate.shape", ReferenceShapeNamespace: "reviewed.shape"}
	if got := referenceShapeNamespace(reference); got != "reviewed.shape" {
		t.Fatalf("got %q, want ultimate reference namespace", got)
	}
	reference.ReferenceShapeNamespace = ""
	if got := referenceShapeNamespace(reference); got != "candidate.shape" {
		t.Fatalf("got %q, want direct reference namespace", got)
	}
}

func TestReferenceProfileRequiresReviewedProgram(t *testing.T) {
	reference := &manifestDocument{Program: "(validate-profile)"}
	if err := requireReferenceProgram([]byte(reference.Program), reference); err != nil {
		t.Fatal(err)
	}
	if err := requireReferenceProgram([]byte("(print-proof-markers-only)"), reference); err == nil {
		t.Fatal("reference mode accepted a validator override")
	}
}
