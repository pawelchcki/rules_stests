package main

import (
	"crypto/sha256"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCoverageGateRequiresCompleteExactEvidence(t *testing.T) {
	revision := strings.Repeat("a", 40)
	digest := strings.Repeat("b", 64)
	capture := []byte("capture")
	plan := `{"proofs":[{"featureId":"feature","assertion":"assertion","basis":"observed"}]}`
	proof := receiptProof{FeatureID: "feature", Assertion: "assertion", Basis: "observed", Result: "pass"}
	m := manifest{Family: "datadog", WireVersion: "v0.5", Profile: "p", Application: "aiohttp", ProofPlan: plan, Scenarios: []string{"tags"}, ScenarioShapes: map[string]string{"tags": "shape"}, ValidationPolicySHA256: digest, CandidateImplementationSHA256: digest}
	r := receipt{Family: "datadog", WireVersion: "v0.5", SchemaVersion: 2, Revision: revision, Profile: "p", Scenario: "tags", ValidationMode: "exact", Outcome: "verified", ProofPlanSHA256: sum(plan), CaptureSHA256: sum(string(capture)), ScenarioShapeSHA256: sum("shape"), ValidationPolicySHA256: digest, CandidateImplementationSHA256: digest, Proofs: []receiptProof{proof}, Coverage: coverage{SchemaVersion: 1, Application: "aiohttp", Scenario: "tags", IntegrationSpans: map[string]int{"http.server": 1, "database": 1}, FieldPolicies: map[string]int{"exact": 3, "normalized": 1, "runtime-validated": 2}, SpanOccurrences: 2, FieldOccurrences: 6}}
	if err := validate(revision, []manifest{m}, []receipt{r}, [][]byte{capture}); err != nil {
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
		{"wrong wire version", func(r *receipt) { r.WireVersion = "v0.4" }},
		{"wrong reference binding", func(r *receipt) { r.ReferenceProfile, r.ReferenceProofPlanSHA256 = "other", strings.Repeat("c", 64) }},
		{"missing proofs", func(r *receipt) { r.Proofs = nil }},
		{"duplicate proof", func(r *receipt) { r.Proofs = append(r.Proofs, proof) }},
		{"non-passing proof", func(r *receipt) { r.Proofs[0].Result = "fail" }},
		{"empty field inventory", func(r *receipt) { r.Coverage.FieldOccurrences = 0; r.Coverage.FieldPolicies = map[string]int{} }},
		{"negative field policy", func(r *receipt) { r.Coverage.FieldPolicies["exact"], r.Coverage.FieldPolicies["normalized"] = -1, 5 }},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			changed := r
			changed.Proofs = append([]receiptProof(nil), r.Proofs...)
			changed.Coverage.IntegrationSpans = map[string]int{"http.server": 1, "database": 1}
			changed.Coverage.FieldPolicies = map[string]int{"exact": 3, "normalized": 1, "runtime-validated": 2}
			tc.mutate(&changed)
			if validate(revision, []manifest{m}, []receipt{changed}, [][]byte{capture}) == nil {
				t.Fatal("invalid evidence passed")
			}
		})
	}

	artifact := compiledValidator{Path: "p.validators/tags.sbc", SourceSHA256: digest, CompilerSHA256: digest, BytecodeSHA256: digest}
	compiledManifest, compiledReceipt := m, r
	compiledManifest.CompiledValidators = map[string]compiledValidator{"tags": artifact}
	compiledReceipt.Validator = &artifact
	if err := validate(revision, []manifest{compiledManifest}, []receipt{compiledReceipt}, [][]byte{capture}); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"source", "compiler", "bytecode", "path", "missing"} {
		t.Run("compiled-"+key, func(t *testing.T) {
			changed := artifact
			changedReceipt := compiledReceipt
			changedReceipt.Validator = &changed
			switch key {
			case "source":
				changed.SourceSHA256 = strings.Repeat("c", 64)
			case "compiler":
				changed.CompilerSHA256 = strings.Repeat("c", 64)
			case "bytecode":
				changed.BytecodeSHA256 = strings.Repeat("c", 64)
			case "path":
				changed.Path = "different.sbc"
			case "missing":
				changedReceipt.Validator = nil
			}
			if validate(revision, []manifest{compiledManifest}, []receipt{changedReceipt}, [][]byte{capture}) == nil {
				t.Fatal("accepted mismatched selected validator")
			}
		})
	}
	if validate(revision, []manifest{m}, []receipt{compiledReceipt}, [][]byte{capture}) == nil {
		t.Fatal("accepted undeclared compiled validator")
	}
	if validate(revision, []manifest{m}, nil, nil) == nil {
		t.Fatal("missing receipt passed")
	}
	if validate(revision, []manifest{m, m}, []receipt{r}, [][]byte{capture}) == nil {
		t.Fatal("duplicate manifest identity passed")
	}
	partialScenarios := m
	partialScenarios.Scenarios = []string{"tags", "articles"}
	if validate(revision, []manifest{partialScenarios}, []receipt{r}, [][]byte{capture}) == nil {
		t.Fatal("partial scenario shapes passed")
	}
	incompleteReference := m
	incompleteReference.ReferenceProfile = "reference"
	if validate(revision, []manifest{incompleteReference}, []receipt{r}, [][]byte{capture}) == nil {
		t.Fatal("incomplete reference identity passed")
	}
	if validate(revision, []manifest{m}, []receipt{r}, nil) == nil {
		t.Fatal("missing capture passed")
	}
	if validate(revision, []manifest{m}, []receipt{r}, [][]byte{[]byte("tampered")}) == nil {
		t.Fatal("tampered capture passed")
	}
}

func sum(value string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(value)))
}

func TestRetainedCompiledBytecodeBinding(t *testing.T) {
	newArtifact := func(t *testing.T) (string, manifest, compiledValidator) {
		t.Helper()
		directory := t.TempDir()
		artifact := compiledValidator{
			Path:           "p.validators/tags.sbc",
			SourceSHA256:   sum("effective-source"),
			CompilerSHA256: sum("compiler"),
			BytecodeSHA256: sum("bytecode"),
		}
		path := filepath.Join(directory, artifact.Path)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte("bytecode"), 0o644); err != nil {
			t.Fatal(err)
		}
		return filepath.Join(directory, "p.profile.json"), manifest{Profile: "p", CompiledValidators: map[string]compiledValidator{"tags": artifact}}, artifact
	}

	manifestPath, m, _ := newArtifact(t)
	if err := verifyCompiledArtifacts(manifestPath, m); err != nil {
		t.Fatalf("valid retained bytecode rejected: %v", err)
	}
	for _, test := range []struct {
		name   string
		mutate func(*manifest, *compiledValidator, string)
	}{
		{"missing", func(m *manifest, artifact *compiledValidator, path string) {
			artifact.Path = "p.validators/missing.sbc"
		}},
		{"replaced", func(m *manifest, artifact *compiledValidator, path string) {
			if err := os.WriteFile(path, []byte("replacement"), 0o644); err != nil {
				t.Fatal(err)
			}
		}},
		{"traversal", func(m *manifest, artifact *compiledValidator, path string) { artifact.Path = "../tags.sbc" }},
	} {
		t.Run(test.name, func(t *testing.T) {
			manifestPath, m, artifact := newArtifact(t)
			path := filepath.Join(filepath.Dir(manifestPath), artifact.Path)
			test.mutate(&m, &artifact, path)
			m.CompiledValidators["tags"] = artifact
			if err := verifyCompiledArtifacts(manifestPath, m); err == nil {
				t.Fatal("invalid retained bytecode passed")
			}
		})
	}
}
