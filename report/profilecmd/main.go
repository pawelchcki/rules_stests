package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"regexp"
	"strings"

	"github.com/pawelchcki/rules_stests/report"
)

type repeated []string

func (values *repeated) String() string         { return fmt.Sprint([]string(*values)) }
func (values *repeated) Set(value string) error { *values = append(*values, value); return nil }

var digestRE = regexp.MustCompile(`^[0-9a-f]{64}$`)

func main() {
	var profilePath, registryPath, captureShapesPath, outputPath, manifestPath, profileID, programPath, family, wireVersion, referenceManifestPath string
	var implementationPaths, proofRulePaths, policyLibraryPaths, policySourcePaths, libraryPaths, importNames, signals, scenarios, shapeSpecs repeated
	flag.StringVar(&profilePath, "profile", "", "Scheme profile")
	flag.StringVar(&registryPath, "registry", "", "standard registry JSON")
	flag.Var(&proofRulePaths, "proof-rules", "Scheme proof table (repeatable)")
	flag.StringVar(&captureShapesPath, "capture-shapes", "", "Scheme capture-shape registry")
	flag.Var(&policyLibraryPaths, "policy-library", "validation policy library source (repeatable)")
	flag.Var(&policySourcePaths, "policy-source", "executable validation policy source (repeatable)")
	flag.StringVar(&outputPath, "out", "", "normalized plan output")
	flag.StringVar(&manifestPath, "manifest-out", "", "atomic profile manifest output")
	flag.StringVar(&profileID, "profile-id", "", "profile identity")
	flag.StringVar(&programPath, "program", "", "validation program")
	flag.Var(&implementationPaths, "implementation", "implementation layer (repeatable)")
	flag.Var(&libraryPaths, "library", "Scheme library to embed (repeatable)")
	flag.Var(&importNames, "import", "Scheme library import (repeatable)")
	flag.Var(&signals, "signal", "required signal (repeatable)")
	flag.Var(&scenarios, "scenario", "valid workload scenario (repeatable)")
	flag.Var(&shapeSpecs, "shape", "scenario,path exact shape (repeatable)")
	flag.StringVar(&family, "family", "", "telemetry family")
	flag.StringVar(&wireVersion, "wire-version", "", "intake wire version")
	flag.StringVar(&referenceManifestPath, "reference-manifest", "", "reviewed Datadog reference profile manifest")
	flag.Parse()
	profile, err := os.ReadFile(profilePath)
	if err != nil {
		fail(err)
	}
	registry, err := os.ReadFile(registryPath)
	if err != nil {
		fail(err)
	}
	var rules []byte
	for _, path := range proofRulePaths {
		contents, readErr := os.ReadFile(path)
		if readErr != nil {
			fail(readErr)
		}
		rules = append(rules, contents...)
		rules = append(rules, '\n')
	}
	captureShapes, err := os.ReadFile(captureShapesPath)
	if err != nil {
		fail(err)
	}
	policyMaterial := append([]byte("datadog-field-policy-v1\x00"), captureShapes...)
	policyMaterial = append(policyMaterial, '\x00')
	policyMaterial = append(policyMaterial, rules...)
	if len(policyLibraryPaths) > 0 {
		policyMaterial = []byte("datadog-validation-policy-v2")
		for _, path := range policyLibraryPaths {
			contents, readErr := os.ReadFile(path)
			if readErr != nil {
				fail(readErr)
			}
			policyMaterial = append(policyMaterial, '\x00')
			policyMaterial = append(policyMaterial, contents...)
		}
	}
	for _, path := range policySourcePaths {
		contents, readErr := os.ReadFile(path)
		if readErr != nil {
			fail(readErr)
		}
		policyMaterial = append(policyMaterial, '\x00')
		policyMaterial = append(policyMaterial, contents...)
	}
	policyDigest := sha256.Sum256(policyMaterial)
	validationPolicySHA256 := fmt.Sprintf("%x", policyDigest)
	implementations := make([]string, 0, len(implementationPaths))
	for _, path := range implementationPaths {
		contents, readErr := os.ReadFile(path)
		if readErr != nil {
			fail(readErr)
		}
		implementations = append(implementations, string(contents))
	}
	plan, err := report.CompileTelemetryProfile(string(profile), implementations, registry, rules, captureShapes, scenarios)
	if err != nil {
		fail(err)
	}
	if plan.Family != family || plan.WireVersion != wireVersion {
		fail(fmt.Errorf("profile family/wire version does not match target"))
	}
	if plan.Profile != profileID {
		fail(fmt.Errorf("profile id %q does not match target id %q", plan.Profile, profileID))
	}
	if !sameStrings(plan.Signals, signals) {
		fail(fmt.Errorf("profile signals %v do not match target signals %v", plan.Signals, []string(signals)))
	}
	var referenceManifest *manifestDocument
	if referenceManifestPath != "" {
		contents, readErr := os.ReadFile(referenceManifestPath)
		if readErr != nil {
			fail(readErr)
		}
		var reference manifestDocument
		decoder := json.NewDecoder(strings.NewReader(string(contents)))
		decoder.DisallowUnknownFields()
		if decodeErr := decoder.Decode(&reference); decodeErr != nil {
			fail(fmt.Errorf("decode reference profile: %w", decodeErr))
		}
		if referenceErr := validateAndApplyReference(&plan, reference, scenarios, validationPolicySHA256); referenceErr != nil {
			fail(referenceErr)
		}
		referenceManifest = &reference
	}
	encoded, err := json.MarshalIndent(plan, "", "  ")
	if err != nil {
		fail(err)
	}
	encoded = append(encoded, '\n')
	if err := os.WriteFile(outputPath, encoded, 0o644); err != nil {
		fail(err)
	}
	if manifestPath != "" {
		libraries := make([]string, 0, len(libraryPaths))
		for _, path := range libraryPaths {
			contents, readErr := os.ReadFile(path)
			if readErr != nil {
				fail(readErr)
			}
			libraries = append(libraries, string(contents))
		}
		program, readErr := os.ReadFile(programPath)
		if readErr != nil {
			fail(readErr)
		}
		if programErr := requireReferenceProgram(program, referenceManifest); programErr != nil {
			fail(programErr)
		}
		shapes := map[string]string{}
		knownScenarios := map[string]bool{}
		for _, scenario := range scenarios {
			knownScenarios[scenario] = true
		}
		for _, spec := range shapeSpecs {
			parts := strings.SplitN(spec, ",", 2)
			if len(parts) != 2 {
				fail(fmt.Errorf("invalid --shape %q", spec))
			}
			contents, shapeErr := os.ReadFile(parts[1])
			if shapeErr != nil {
				fail(shapeErr)
			}
			if _, exists := shapes[parts[0]]; exists {
				fail(fmt.Errorf("duplicate shape %q", parts[0]))
			}
			if !knownScenarios[parts[0]] {
				fail(fmt.Errorf("shape has unknown scenario %q", parts[0]))
			}
			shapes[parts[0]] = string(contents)
		}
		if referenceManifest != nil {
			shapes = referenceManifest.ScenarioShapes
		}
		document := manifestDocument{
			Family: plan.Family, WireVersion: plan.WireVersion, Application: plan.Application,
			ShapeNamespace: plan.ShapeNamespace, TracerVersion: plan.TracerVersion,
			SchemaVersion: plan.SchemaVersion, Profile: profileID, Signals: signals,
			ProofPlan: string(encoded), Program: string(program), Libraries: libraries,
			Imports: importNames, Scenarios: scenarios, ScenarioShapes: shapes,
		}
		implementationDeclaration := strings.Join([]string{plan.Language, plan.TracerVersion, strings.Join(plan.Implementations, "\x00"), strings.Join(implementations, "\x00")}, "\x00")
		implementationDigest := sha256.Sum256([]byte(implementationDeclaration))
		document.ValidationPolicySHA256 = validationPolicySHA256
		document.CandidateImplementationSHA256 = fmt.Sprintf("%x", implementationDigest)
		if referenceManifest != nil {
			document.ReferenceProfile = referenceManifest.Profile
			document.ReferenceShapeNamespace = referenceShapeNamespace(*referenceManifest)
			referenceDigest := sha256.Sum256([]byte(referenceManifest.ProofPlan))
			document.ReferenceProofPlanSHA256 = fmt.Sprintf("%x", referenceDigest)
		}
		manifest, marshalErr := json.Marshal(document)
		if marshalErr != nil {
			fail(marshalErr)
		}
		manifest = append(manifest, '\n')
		if writeErr := os.WriteFile(manifestPath, manifest, 0o644); writeErr != nil {
			fail(writeErr)
		}
	}
}

func validateAndApplyReference(plan *report.NormalizedProfilePlan, reference manifestDocument, scenarios []string, validationPolicySHA256 string) error {
	var referencePlan report.NormalizedProfilePlan
	if err := json.Unmarshal([]byte(reference.ProofPlan), &referencePlan); err != nil {
		return fmt.Errorf("decode reference proof plan: %w", err)
	}
	if reference.SchemaVersion != 2 || reference.Family != "datadog" || reference.Profile == "" || reference.ShapeNamespace == "" || reference.Program == "" || len(reference.ScenarioShapes) == 0 ||
		!digestRE.MatchString(reference.ValidationPolicySHA256) || reference.ValidationPolicySHA256 != validationPolicySHA256 ||
		reference.Family != plan.Family || reference.WireVersion != plan.WireVersion || reference.Application != plan.Application ||
		!sameProofContracts(referencePlan.Proofs, plan.Proofs) || !sameStringsPlain(reference.Signals, plan.Signals) {
		return fmt.Errorf("candidate profile does not match complete Datadog reference contract")
	}
	if len(reference.ScenarioShapes) != len(scenarios) {
		return fmt.Errorf("reference profile scenario set is incomplete")
	}
	for _, scenario := range scenarios {
		if reference.ScenarioShapes[scenario] == "" {
			return fmt.Errorf("reference profile lacks scenario %q", scenario)
		}
	}
	plan.ReferenceProfile = reference.Profile
	return nil
}

func referenceShapeNamespace(reference manifestDocument) string {
	if reference.ReferenceShapeNamespace != "" {
		return reference.ReferenceShapeNamespace
	}
	return reference.ShapeNamespace
}

func requireReferenceProgram(program []byte, reference *manifestDocument) error {
	if reference != nil && !bytes.Equal(program, []byte(reference.Program)) {
		return fmt.Errorf("reference mode requires the reviewed validation program")
	}
	return nil
}

type manifestDocument struct {
	CompiledValidators            map[string]json.RawMessage `json:"compiledValidators,omitempty"`
	Family                        string                     `json:"family,omitempty"`
	WireVersion                   string                     `json:"wireVersion,omitempty"`
	Application                   string                     `json:"application,omitempty"`
	ShapeNamespace                string                     `json:"shapeNamespace,omitempty"`
	ReferenceShapeNamespace       string                     `json:"referenceShapeNamespace,omitempty"`
	TracerVersion                 string                     `json:"tracerVersion,omitempty"`
	ReferenceProfile              string                     `json:"referenceProfile,omitempty"`
	ReferenceProofPlanSHA256      string                     `json:"referenceProofPlanSha256,omitempty"`
	ValidationPolicySHA256        string                     `json:"validationPolicySha256,omitempty"`
	CandidateImplementationSHA256 string                     `json:"candidateImplementationSha256,omitempty"`
	SchemaVersion                 int                        `json:"schemaVersion"`
	Profile                       string                     `json:"profile"`
	Signals                       []string                   `json:"signals"`
	ProofPlan                     string                     `json:"proofPlan"`
	Program                       string                     `json:"program"`
	Libraries                     []string                   `json:"libraries"`
	Imports                       []string                   `json:"imports"`
	Scenarios                     []string                   `json:"scenarios"`
	ScenarioShapes                map[string]string          `json:"scenarioShapes"`
}

func sameStringsPlain(left, right []string) bool {
	if len(left) != len(right) {
		return false
	}
	for i := range left {
		if left[i] != right[i] {
			return false
		}
	}
	return true
}
func sameProofContracts(left, right []report.ProofPlanProof) bool {
	if len(left) != len(right) {
		return false
	}
	for i := range left {
		if left[i].FeatureID != right[i].FeatureID || left[i].Assertion != right[i].Assertion || left[i].Basis != right[i].Basis || left[i].EvidencePolicy != right[i].EvidencePolicy || !sameStringsPlain(left[i].Scenarios, right[i].Scenarios) {
			return false
		}
	}
	return true
}

func sameStrings(left []string, right repeated) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}

func fail(err error) { fmt.Fprintln(os.Stderr, "profile compiler:", err); os.Exit(1) }
