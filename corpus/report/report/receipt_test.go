package report

import (
	"strings"
	"testing"
)

func receiptFixture() (string, []string, []string, map[string]PlanArtifact, map[string][]byte, map[string][]byte, ValidationReceipt) {
	revision := strings.Repeat("a", 40)
	proof := ProofPlanProof{FeatureID: "traces.span.end", Assertion: "span/all-completed", Basis: "observed", EvidencePolicy: "wire-sufficient"}
	planBytes := []byte("normalized-plan\n")
	plans := map[string]PlanArtifact{"python": {Plan: NormalizedProfilePlan{SchemaVersion: 1, Profile: "python", Proofs: []ProofPlanProof{proof}}, Bytes: planBytes}}
	key := "python\x00articles"
	shapes := map[string][]byte{key: []byte("shape\n")}
	captures := map[string][]byte{key: []byte("capture\n")}
	receipt := ValidationReceipt{SchemaVersion: 1, Revision: revision, Profile: "python", Scenario: "articles", ProofPlanSHA256: digest(planBytes), CaptureSHA256: digest(captures[key]), ValidationMode: "exact", Outcome: "verified", ScenarioShapeSHA256: digest(shapes[key]), Proofs: []ReceiptProof{{FeatureID: proof.FeatureID, Assertion: proof.Assertion, Basis: proof.Basis, Result: "pass"}}}
	return revision, []string{"python"}, []string{"articles"}, plans, shapes, captures, receipt
}

func TestValidateReceiptSetAcceptsXFailAndScopesCoverageToVerifiedScenarios(t *testing.T) {
	revision, profiles, _, plans, _, _, verified := receiptFixture()
	verified.ValidationMode = "contract"
	verified.ScenarioShapeSHA256 = ""
	shapes := map[string][]byte{}
	verifiedCapture := []byte("verified capture\n")
	verified.CaptureSHA256 = digest(verifiedCapture)
	captures := map[string][]byte{"python\x00articles": verifiedCapture}
	xfailCapture := []byte("rejected capture\n")
	xfail := ValidationReceipt{
		SchemaVersion: 1, Revision: revision, Profile: "python", Scenario: "auth",
		ProofPlanSHA256: verified.ProofPlanSHA256, CaptureSHA256: digest(xfailCapture),
		ValidationMode: "contract", Outcome: "xfail", XFailReason: "issue #123",
	}
	captures["python\x00auth"] = xfailCapture
	receipts := []ValidationReceipt{verified, xfail}
	if err := ValidateReceiptSet(revision, profiles, []string{"articles", "auth"}, plans, shapes, captures, receipts); err != nil {
		t.Fatal(err)
	}
	coverages := CoveragesFromPlans(plans, receipts)
	if len(coverages) != 1 || len(coverages[0].Claims) != 1 || coverages[0].Claims[0].AllScenarios || len(coverages[0].Claims[0].Scenarios) != 1 || coverages[0].Claims[0].Scenarios[0] != "articles" {
		t.Fatalf("xfail was represented as verified coverage: %#v", coverages)
	}
}

func TestValidateReceiptSetAcceptsCompleteCurrentProof(t *testing.T) {
	revision, profiles, scenarios, plans, shapes, captures, receipt := receiptFixture()
	if err := ValidateReceiptSet(revision, profiles, scenarios, plans, shapes, captures, []ValidationReceipt{receipt}); err != nil {
		t.Fatal(err)
	}
}

func TestValidateReceiptSetRejectsUntrustedInputs(t *testing.T) {
	tests := []struct {
		name               string
		mutate             func(*ValidationReceipt, map[string]PlanArtifact, map[string][]byte, map[string][]byte)
		duplicate, missing bool
		want               string
	}{
		{"stale", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.Revision = strings.Repeat("b", 40)
		}, false, false, "stale"},
		{"plan digest", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.ProofPlanSHA256 = strings.Repeat("0", 64)
		}, false, false, "plan digest"},
		{"shape digest", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.ScenarioShapeSHA256 = strings.Repeat("0", 64)
		}, false, false, "shape digest"},
		{"capture digest", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.CaptureSHA256 = strings.Repeat("0", 64)
		}, false, false, "capture digest"},
		{"wrong validation mode", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.ValidationMode = "contract"
		}, false, false, "shape digest"},
		{"missing capture", func(_ *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, captures map[string][]byte) {
			delete(captures, "python\x00articles")
		}, false, false, "missing capture"},
		{"failed proof", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.Proofs[0].Result = "fail"
		}, false, false, "failed proof"},
		{"missing outcome", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.Outcome = ""
		}, false, false, "invalid receipt outcome"},
		{"duplicate proof", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.Proofs = append(r.Proofs, r.Proofs[0])
		}, false, false, "duplicate proof"},
		{"incomplete proof", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.Proofs = nil
		}, false, false, "incomplete proof set"},
		{"unexpected proof", func(r *ValidationReceipt, _ map[string]PlanArtifact, _ map[string][]byte, _ map[string][]byte) {
			r.Proofs[0].FeatureID = "unexpected"
		}, false, false, "missing planned proof"},
		{"duplicate", func(*ValidationReceipt, map[string]PlanArtifact, map[string][]byte, map[string][]byte) {}, true, false, "duplicate receipt"},
		{"missing", func(*ValidationReceipt, map[string]PlanArtifact, map[string][]byte, map[string][]byte) {}, false, true, "missing receipt"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			revision, profiles, scenarios, plans, shapes, captures, receipt := receiptFixture()
			test.mutate(&receipt, plans, shapes, captures)
			receipts := []ValidationReceipt{receipt}
			if test.duplicate {
				receipts = append(receipts, receipt)
			}
			if test.missing {
				receipts = nil
			}
			err := ValidateReceiptSet(revision, profiles, scenarios, plans, shapes, captures, receipts)
			if err == nil || !strings.Contains(err.Error(), test.want) {
				t.Fatalf("want %q, got %v", test.want, err)
			}
		})
	}
}

func TestValidateReceiptSetRequiresEveryScenarioForAllScenarioClaims(t *testing.T) {
	revision, profiles, _, plans, shapes, captures, receipt := receiptFixture()
	err := ValidateReceiptSet(revision, profiles, []string{"articles", "auth"}, plans, shapes, captures, []ValidationReceipt{receipt})
	if err == nil || !strings.Contains(err.Error(), "missing receipt python/auth") {
		t.Fatalf("incomplete all-scenario run was accepted: %v", err)
	}
}

func TestDecodeReceiptRejectsMalformedSchema(t *testing.T) {
	if _, err := DecodeReceipt([]byte(`{"schemaVersion":1,"revision":"bad","profile":"p","scenario":"s","proofPlanSha256":"x","captureSha256":"x","validationMode":"contract","outcome":"verified","proofs":[]}`)); err == nil {
		t.Fatal("malformed receipt accepted")
	}
	if _, err := DecodeReceipt([]byte(`{"schemaVersion":1,"unknown":true}`)); err == nil {
		t.Fatal("unknown field accepted")
	}
}
