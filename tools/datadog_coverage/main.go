// datadog_coverage is the trust gate for native Datadog parity receipts.
package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"regexp"
)

type manifest struct {
	Family                        string            `json:"family"`
	Profile                       string            `json:"profile"`
	Application                   string            `json:"application"`
	ProofPlan                     string            `json:"proofPlan"`
	ScenarioShapes                map[string]string `json:"scenarioShapes"`
	ValidationPolicySHA256        string            `json:"validationPolicySha256"`
	CandidateImplementationSHA256 string            `json:"candidateImplementationSha256"`
	ReferenceProfile              string            `json:"referenceProfile,omitempty"`
	ReferenceProofPlanSHA256      string            `json:"referenceProofPlanSha256,omitempty"`
}
type coverage struct {
	SchemaVersion      int            `json:"schemaVersion"`
	Application        string         `json:"application"`
	Scenario           string         `json:"scenario"`
	IntegrationSpans   map[string]int `json:"integrationSpans"`
	FieldPolicies      map[string]int `json:"fieldPolicies"`
	SpanOccurrences    int            `json:"spanOccurrences"`
	FieldOccurrences   int            `json:"fieldOccurrences"`
	UnclassifiedFields int            `json:"unclassifiedFields"`
}
type proofPlan struct {
	Proofs []proofPlanProof `json:"proofs"`
}
type proofPlanProof struct {
	FeatureID string   `json:"featureId"`
	Assertion string   `json:"assertion"`
	Basis     string   `json:"basis"`
	Scenarios []string `json:"scenarios,omitempty"`
}
type receiptProof struct {
	FeatureID string `json:"featureId"`
	Assertion string `json:"assertion"`
	Basis     string `json:"basis"`
	Result    string `json:"result"`
}
type receipt struct {
	Family                        string         `json:"family"`
	SchemaVersion                 int            `json:"schemaVersion"`
	Revision                      string         `json:"revision"`
	Profile                       string         `json:"profile"`
	Scenario                      string         `json:"scenario"`
	ValidationMode                string         `json:"validationMode"`
	Outcome                       string         `json:"outcome"`
	ProofPlanSHA256               string         `json:"proofPlanSha256"`
	CaptureSHA256                 string         `json:"captureSha256"`
	ScenarioShapeSHA256           string         `json:"scenarioShapeSha256"`
	ValidationPolicySHA256        string         `json:"validationPolicySha256"`
	CandidateImplementationSHA256 string         `json:"candidateImplementationSha256"`
	Coverage                      coverage       `json:"coverage"`
	Proofs                        []receiptProof `json:"proofs"`
	ReferenceProfile              string         `json:"referenceProfile,omitempty"`
	ReferenceProofPlanSHA256      string         `json:"referenceProofPlanSha256,omitempty"`
}

var revisionRE = regexp.MustCompile(`^[0-9a-f]{40}$`)
var digestRE = regexp.MustCompile(`^[0-9a-f]{64}$`)

func decode(path string, value any) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	if err := decoder.Decode(value); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return fmt.Errorf("trailing JSON")
	}
	return nil
}

func validate(revision string, manifests []manifest, receipts []receipt) error {
	if !revisionRE.MatchString(revision) {
		return fmt.Errorf("revision must be a lowercase 40-character commit")
	}
	expected := map[string]manifest{}
	for _, m := range manifests {
		hasReference := m.ReferenceProfile != "" || m.ReferenceProofPlanSHA256 != ""
		if m.Family != "datadog" || m.Profile == "" || m.Application == "" || m.ProofPlan == "" || len(m.ScenarioShapes) == 0 ||
			!digestRE.MatchString(m.ValidationPolicySHA256) || !digestRE.MatchString(m.CandidateImplementationSHA256) ||
			(hasReference && (m.ReferenceProfile == "" || !digestRE.MatchString(m.ReferenceProofPlanSHA256))) {
			return fmt.Errorf("incomplete Datadog manifest")
		}
		for scenario := range m.ScenarioShapes {
			key := m.Profile + "\x00" + scenario
			if _, exists := expected[key]; exists {
				return fmt.Errorf("duplicate Datadog manifest identity %s/%s", m.Profile, scenario)
			}
			expected[key] = m
		}
	}
	seen := map[string]bool{}
	for _, r := range receipts {
		key := r.Profile + "\x00" + r.Scenario
		m, ok := expected[key]
		if !ok || seen[key] {
			return fmt.Errorf("unexpected or duplicate receipt %s/%s", r.Profile, r.Scenario)
		}
		seen[key] = true
		if r.Family != "datadog" || r.SchemaVersion != 2 || r.Revision != revision || r.ValidationMode != "exact" || r.Outcome != "verified" {
			return fmt.Errorf("non-verifying receipt %s/%s", r.Profile, r.Scenario)
		}
		for _, value := range []string{r.ProofPlanSHA256, r.CaptureSHA256, r.ScenarioShapeSHA256, r.ValidationPolicySHA256, r.CandidateImplementationSHA256} {
			if !digestRE.MatchString(value) {
				return fmt.Errorf("unbound receipt %s/%s", r.Profile, r.Scenario)
			}
		}
		proofPlanDigest := fmt.Sprintf("%x", sha256.Sum256([]byte(m.ProofPlan)))
		shapeDigest := fmt.Sprintf("%x", sha256.Sum256([]byte(m.ScenarioShapes[r.Scenario])))
		if r.ProofPlanSHA256 != proofPlanDigest || r.ScenarioShapeSHA256 != shapeDigest ||
			r.ValidationPolicySHA256 != m.ValidationPolicySHA256 || r.CandidateImplementationSHA256 != m.CandidateImplementationSHA256 ||
			r.ReferenceProfile != m.ReferenceProfile || r.ReferenceProofPlanSHA256 != m.ReferenceProofPlanSHA256 {
			return fmt.Errorf("receipt digest binding mismatch %s/%s", r.Profile, r.Scenario)
		}
		if err := validateReceiptProofSet(m.ProofPlan, r.Scenario, r.Proofs); err != nil {
			return fmt.Errorf("invalid proof evidence %s/%s: %w", r.Profile, r.Scenario, err)
		}
		c := r.Coverage
		if c.SchemaVersion != 1 || c.Application != m.Application || c.Scenario != r.Scenario || c.UnclassifiedFields != 0 || c.IntegrationSpans["http.server"] < 1 || c.IntegrationSpans["database"] < 1 || c.SpanOccurrences < c.IntegrationSpans["http.server"]+c.IntegrationSpans["database"] || c.FieldOccurrences != c.FieldPolicies["exact"]+c.FieldPolicies["normalized"]+c.FieldPolicies["runtime-validated"] {
			return fmt.Errorf("incomplete field coverage %s/%s", r.Profile, r.Scenario)
		}
	}
	if len(seen) != len(expected) {
		return fmt.Errorf("missing Datadog receipts: got %d want %d", len(seen), len(expected))
	}
	return nil
}

func validateReceiptProofSet(encodedPlan, scenario string, actual []receiptProof) error {
	var plan proofPlan
	decoder := json.NewDecoder(bytes.NewReader([]byte(encodedPlan)))
	if err := decoder.Decode(&plan); err != nil {
		return fmt.Errorf("decode proof plan: %w", err)
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return fmt.Errorf("proof plan has trailing JSON")
	}
	expected := map[string]bool{}
	for _, proof := range plan.Proofs {
		if len(proof.Scenarios) != 0 && !contains(proof.Scenarios, scenario) {
			continue
		}
		if proof.FeatureID == "" || proof.Assertion == "" || proof.Basis == "" {
			return fmt.Errorf("proof plan contains an incomplete proof")
		}
		key := proof.FeatureID + "\x00" + proof.Assertion + "\x00" + proof.Basis
		if expected[key] {
			return fmt.Errorf("proof plan contains duplicate proof %s/%s", proof.FeatureID, proof.Assertion)
		}
		expected[key] = true
	}
	if len(expected) == 0 {
		return fmt.Errorf("proof plan has no proof for scenario %s", scenario)
	}
	seen := map[string]bool{}
	for _, proof := range actual {
		key := proof.FeatureID + "\x00" + proof.Assertion + "\x00" + proof.Basis
		if proof.Result != "pass" || !expected[key] || seen[key] {
			return fmt.Errorf("unexpected, duplicate, or non-passing proof %s/%s", proof.FeatureID, proof.Assertion)
		}
		seen[key] = true
	}
	if len(seen) != len(expected) {
		return fmt.Errorf("proof set has %d entries, want %d", len(seen), len(expected))
	}
	return nil
}

func contains(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}

func main() {
	revision := flag.String("revision", "", "expected repository revision")
	var manifestPaths, receiptPaths stringsFlag
	flag.Var(&manifestPaths, "manifest", "profile manifest (repeatable)")
	flag.Var(&receiptPaths, "receipt", "verified receipt (repeatable)")
	flag.Parse()
	manifests := make([]manifest, len(manifestPaths))
	for i, p := range manifestPaths {
		if err := decode(p, &manifests[i]); err != nil {
			fatal(err)
		}
	}
	receipts := make([]receipt, len(receiptPaths))
	for i, p := range receiptPaths {
		if err := decode(p, &receipts[i]); err != nil {
			fatal(err)
		}
	}
	if err := validate(*revision, manifests, receipts); err != nil {
		fatal(err)
	}
	fmt.Printf("Datadog coverage gate passed: %d profiles, %d scenarios\n", len(manifests), len(receipts))
}

type stringsFlag []string

func (v *stringsFlag) String() string     { return fmt.Sprint([]string(*v)) }
func (v *stringsFlag) Set(s string) error { *v = append(*v, s); return nil }
func fatal(err error)                     { fmt.Fprintln(os.Stderr, "datadog coverage:", err); os.Exit(1) }
