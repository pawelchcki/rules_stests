package report

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"regexp"
	"sort"
)

type ReceiptProof struct {
	FeatureID string `json:"featureId"`
	Assertion string `json:"assertion"`
	Basis     string `json:"basis"`
	Result    string `json:"result"`
}

type ValidationReceipt struct {
	SchemaVersion       int            `json:"schemaVersion"`
	Revision            string         `json:"revision"`
	Profile             string         `json:"profile"`
	Scenario            string         `json:"scenario"`
	ProofPlanSHA256     string         `json:"proofPlanSha256"`
	CaptureSHA256       string         `json:"captureSha256"`
	ValidationMode      string         `json:"validationMode"`
	ScenarioShapeSHA256 string         `json:"scenarioShapeSha256,omitempty"`
	Proofs              []ReceiptProof `json:"proofs"`
}

type PlanArtifact struct {
	Plan   NormalizedProfilePlan
	Bytes  []byte
	Source Evidence
}

var receiptRevision = regexp.MustCompile(`^[0-9a-f]{40}$`)
var digestHex = regexp.MustCompile(`^[0-9a-f]{64}$`)

func DecodeReceipt(input []byte) (ValidationReceipt, error) {
	var receipt ValidationReceipt
	decoder := json.NewDecoder(bytes.NewReader(input))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&receipt); err != nil {
		return receipt, err
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return receipt, fmt.Errorf("receipt has trailing JSON")
	}
	if receipt.SchemaVersion != 1 || !receiptRevision.MatchString(receipt.Revision) || receipt.Profile == "" || receipt.Scenario == "" {
		return receipt, fmt.Errorf("malformed receipt identity")
	}
	if !digestHex.MatchString(receipt.ProofPlanSHA256) || !digestHex.MatchString(receipt.CaptureSHA256) {
		return receipt, fmt.Errorf("malformed receipt digest")
	}
	if receipt.ValidationMode != "exact" && receipt.ValidationMode != "contract" {
		return receipt, fmt.Errorf("invalid validation mode %q", receipt.ValidationMode)
	}
	return receipt, nil
}

// ValidateReceiptSet is the report's trust boundary. Only a complete set of
// current-revision E2E receipts can reach model construction.
func ValidateReceiptSet(revision string, profiles, scenarios []string, plans map[string]PlanArtifact, shapes, captures map[string][]byte, receipts []ValidationReceipt) error {
	if !receiptRevision.MatchString(revision) {
		return fmt.Errorf("revision must be a lowercase 40-character commit")
	}
	profileSet, scenarioSet := stringSet(profiles), stringSet(scenarios)
	seen := map[string]bool{}
	for _, receipt := range receipts {
		if !profileSet[receipt.Profile] || !scenarioSet[receipt.Scenario] {
			return fmt.Errorf("unexpected receipt %s/%s", receipt.Profile, receipt.Scenario)
		}
		key := receipt.Profile + "\x00" + receipt.Scenario
		if seen[key] {
			return fmt.Errorf("duplicate receipt %s/%s", receipt.Profile, receipt.Scenario)
		}
		seen[key] = true
		if receipt.Revision != revision {
			return fmt.Errorf("stale receipt %s/%s revision %s", receipt.Profile, receipt.Scenario, receipt.Revision)
		}
		artifact, ok := plans[receipt.Profile]
		if !ok || artifact.Plan.Profile != receipt.Profile {
			return fmt.Errorf("missing normalized plan for %s", receipt.Profile)
		}
		if digest(artifact.Bytes) != receipt.ProofPlanSHA256 {
			return fmt.Errorf("proof plan digest mismatch for %s/%s", receipt.Profile, receipt.Scenario)
		}
		capture, ok := captures[key]
		if !ok {
			return fmt.Errorf("missing capture for %s/%s", receipt.Profile, receipt.Scenario)
		}
		if digest(capture) != receipt.CaptureSHA256 {
			return fmt.Errorf("capture digest mismatch for %s/%s", receipt.Profile, receipt.Scenario)
		}
		shape, exact := shapes[key]
		if exact {
			if receipt.ValidationMode != "exact" || receipt.ScenarioShapeSHA256 != digest(shape) {
				return fmt.Errorf("scenario shape digest mismatch for %s/%s", receipt.Profile, receipt.Scenario)
			}
		} else if receipt.ValidationMode != "contract" || receipt.ScenarioShapeSHA256 != "" {
			return fmt.Errorf("unexpected exact validation for %s/%s", receipt.Profile, receipt.Scenario)
		}
		wanted := map[string]bool{}
		for _, proof := range artifact.Plan.Proofs {
			if len(proof.Scenarios) == 0 || stringSliceContains(proof.Scenarios, receipt.Scenario) {
				wanted[proof.FeatureID+"\x00"+proof.Assertion+"\x00"+proof.Basis] = true
			}
		}
		actual := map[string]bool{}
		for _, proof := range receipt.Proofs {
			proofKey := proof.FeatureID + "\x00" + proof.Assertion + "\x00" + proof.Basis
			if proof.Result != "pass" {
				return fmt.Errorf("failed proof %s in %s/%s", proof.FeatureID, receipt.Profile, receipt.Scenario)
			}
			if actual[proofKey] {
				return fmt.Errorf("duplicate proof %s in %s/%s", proof.FeatureID, receipt.Profile, receipt.Scenario)
			}
			actual[proofKey] = true
		}
		if len(actual) != len(wanted) {
			return fmt.Errorf("incomplete proof set for %s/%s", receipt.Profile, receipt.Scenario)
		}
		for proof := range wanted {
			if !actual[proof] {
				return fmt.Errorf("missing planned proof in %s/%s", receipt.Profile, receipt.Scenario)
			}
		}
		for proof := range actual {
			if !wanted[proof] {
				return fmt.Errorf("unexpected proof %q in %s/%s", proof, receipt.Profile, receipt.Scenario)
			}
		}
	}
	for _, profile := range profiles {
		if _, ok := plans[profile]; !ok {
			return fmt.Errorf("missing normalized plan for %s", profile)
		}
		for _, scenario := range scenarios {
			if !seen[profile+"\x00"+scenario] {
				return fmt.Errorf("missing receipt %s/%s", profile, scenario)
			}
		}
	}
	return nil
}

func digest(value []byte) string { sum := sha256.Sum256(value); return fmt.Sprintf("%x", sum) }

func CoveragesFromPlans(plans map[string]PlanArtifact) []ProfileProofCoverage {
	profiles := make([]string, 0, len(plans))
	for profile := range plans {
		profiles = append(profiles, profile)
	}
	sort.Strings(profiles)
	result := make([]ProfileProofCoverage, 0, len(profiles))
	for _, profile := range profiles {
		artifact := plans[profile]
		coverage := ProfileProofCoverage{Profile: profile, Source: artifact.Source}
		for _, proof := range artifact.Plan.Proofs {
			claim := FeatureClaim{FeatureID: proof.FeatureID, Basis: proof.Basis, Assertion: proof.Assertion, AllScenarios: len(proof.Scenarios) == 0, Scenarios: append([]string(nil), proof.Scenarios...), Evidence: []Evidence{artifact.Source}}
			for index, source := range proof.Sources {
				claim.Evidence = append(claim.Evidence, Evidence{Label: fmt.Sprintf("immutable source %d", index+1), Href: artifact.Plan.Sources[source]})
			}
			coverage.Claims = append(coverage.Claims, claim)
		}
		result = append(result, coverage)
	}
	return result
}
