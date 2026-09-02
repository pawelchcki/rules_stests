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

func TestValidateReceiptSetForProfilesPreservesScenarioMembership(t *testing.T) {
	revision := strings.Repeat("a", 40)
	profiles := []string{"go", "python"}
	profileScenarios := map[string][]string{"go": {"articles"}, "python": {"auth"}}
	plans := map[string]PlanArtifact{}
	captures := map[string][]byte{}
	var receipts []ValidationReceipt
	for _, pair := range []struct{ profile, scenario string }{{"go", "articles"}, {"python", "auth"}} {
		planBytes := []byte(pair.profile + " plan\n")
		capture := []byte(pair.profile + " capture\n")
		key := pair.profile + "\x00" + pair.scenario
		plans[pair.profile] = PlanArtifact{Plan: NormalizedProfilePlan{SchemaVersion: 1, Profile: pair.profile}, Bytes: planBytes}
		captures[key] = capture
		receipts = append(receipts, ValidationReceipt{
			SchemaVersion: 1, Revision: revision, Profile: pair.profile, Scenario: pair.scenario,
			ProofPlanSHA256: digest(planBytes), CaptureSHA256: digest(capture),
			ValidationMode: "contract", Outcome: "verified",
		})
	}
	if err := ValidateReceiptSetForProfiles(revision, profiles, profileScenarios, plans, map[string][]byte{}, captures, receipts); err != nil {
		t.Fatal(err)
	}

	unexpected := receipts[0]
	unexpected.Scenario = "auth"
	captures["go\x00auth"] = captures["go\x00articles"]
	if err := ValidateReceiptSetForProfiles(revision, profiles, profileScenarios, plans, map[string][]byte{}, captures, append(receipts, unexpected)); err == nil || !strings.Contains(err.Error(), "unexpected receipt go/auth") {
		t.Fatalf("undeclared profile/scenario pair was accepted: %v", err)
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

func TestPartitionExercisedProfilesSeparatesProfilesWithoutReceipts(t *testing.T) {
	_, _, _, _, _, _, receipt := receiptFixture()
	exercised, unexercised := PartitionExercisedProfiles([]string{"go", "python", "ruby"}, []ValidationReceipt{receipt})
	if len(exercised) != 1 || exercised[0] != "python" {
		t.Fatalf("unexpected exercised profiles %v", exercised)
	}
	if len(unexercised) != 2 || unexercised[0] != "go" || unexercised[1] != "ruby" {
		t.Fatalf("unexpected unexercised profiles %v", unexercised)
	}
	// A profile with a partial receipt set must stay exercised so the strict
	// validator still rejects the missing scenario.
	partial, missing := PartitionExercisedProfiles([]string{"python"}, []ValidationReceipt{receipt})
	if len(partial) != 1 || len(missing) != 0 {
		t.Fatalf("a partial receipt set must not be treated as unexercised: %v %v", partial, missing)
	}
	if err := ValidateReceiptSetForProfiles(strings.Repeat("a", 40), partial, map[string][]string{"python": {"articles", "auth"}}, map[string]PlanArtifact{}, nil, nil, []ValidationReceipt{receipt}); err == nil {
		t.Fatal("a partial receipt set must remain a validation failure")
	}
}

func TestCoveragesFromPlansForProfilesWithheldWithoutReceipts(t *testing.T) {
	revision, _, _, plans, shapes, captures, receipt := receiptFixture()
	profileScenarios := map[string][]string{"python": {"articles"}}

	// With a verified receipt the planned proof becomes a claim over every
	// declared scenario.
	coverages := CoveragesFromPlansForProfiles(plans, []ValidationReceipt{receipt}, profileScenarios)
	if len(coverages) != 1 || len(coverages[0].Claims) != 1 || !coverages[0].Claims[0].AllScenarios {
		t.Fatalf("verified receipt did not produce an all-scenario claim: %#v", coverages)
	}
	if err := ValidateReceiptSetForProfiles(revision, []string{"python"}, profileScenarios, plans, shapes, captures, []ValidationReceipt{receipt}); err != nil {
		t.Fatal(err)
	}

	// With no receipts at all the plan proves nothing, so the profile keeps its
	// coverage entry but contributes no claims.
	empty := CoveragesFromPlansForProfiles(plans, nil, profileScenarios)
	if len(empty) != 1 || empty[0].Profile != "python" {
		t.Fatalf("an unexercised profile must keep its coverage entry: %#v", empty)
	}
	if len(empty[0].Claims) != 0 {
		t.Fatalf("a plan without receipts must prove nothing, got %#v", empty[0].Claims)
	}

	// A scenario that only expectedly failed cannot carry the claim either.
	xfail := receipt
	xfail.Outcome, xfail.XFailReason, xfail.Proofs = "xfail", "issue #1", nil
	if claims := CoveragesFromPlansForProfiles(plans, []ValidationReceipt{xfail}, profileScenarios); len(claims[0].Claims) != 0 {
		t.Fatalf("an xfail receipt must not produce a claim: %#v", claims[0].Claims)
	}
}

func TestCoveragesFromPlansForProfilesNarrowsPartiallyVerifiedClaims(t *testing.T) {
	revision, _, _, plans, _, _, receipt := receiptFixture()
	profileScenarios := map[string][]string{"python": {"articles", "auth"}}
	xfail := ValidationReceipt{
		SchemaVersion: 1, Revision: revision, Profile: "python", Scenario: "auth",
		ValidationMode: "contract", Outcome: "xfail", XFailReason: "issue #123",
	}
	coverages := CoveragesFromPlansForProfiles(plans, []ValidationReceipt{receipt, xfail}, profileScenarios)
	claim := coverages[0].Claims[0]
	if claim.AllScenarios || len(claim.Scenarios) != 1 || claim.Scenarios[0] != "articles" {
		t.Fatalf("claim was not narrowed to the verified scenario: %#v", claim)
	}
}
