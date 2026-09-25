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
	for _, id := range labClaims[language] {
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
