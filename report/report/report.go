package report

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"sort"
	"strings"
)

var verificationStates = map[string]bool{"verified": true, "known_gap": true, "not_exercised": true, "not_applicable": true}
var coverageStates = map[string]bool{"contract_only": true, "unavailable": true}

func DecodeMetadata(data []byte) (CatalogMetadata, error) {
	var metadata CatalogMetadata
	if err := decodeStrict(data, &metadata); err != nil {
		return metadata, fmt.Errorf("decode catalog metadata: %w", err)
	}
	if metadata.SchemaVersion != 1 {
		return metadata, fmt.Errorf("catalog schemaVersion must be 1")
	}
	if metadata.MaturitySource == "" {
		return metadata, fmt.Errorf("catalog maturitySource is required")
	}
	for _, language := range []string{"go", "python", "ruby"} {
		maturity, ok := metadata.Maturity[language]
		if !ok || maturity.Traces == "" || maturity.Metrics == "" || maturity.Logs == "" {
			return metadata, fmt.Errorf("catalog maturity for %s must include traces, metrics, and logs", language)
		}
	}
	return metadata, nil
}

func DecodeManifest(data []byte) (Manifest, error) {
	var manifest Manifest
	if err := decodeStrict(data, &manifest); err != nil {
		return manifest, fmt.Errorf("decode manifest: %w", err)
	}
	return manifest, nil
}

func PinRepositoryRevision(manifests []Manifest, shapes []ScenarioShape, revision string, coverageSets ...[]ProfileProofCoverage) error {
	if revision == "" || revision == "main" {
		return nil
	}
	if len(revision) != 40 {
		return fmt.Errorf("repository revision must be main or a 40-character commit SHA")
	}
	if _, err := hex.DecodeString(revision); err != nil {
		return fmt.Errorf("repository revision must be main or a 40-character commit SHA")
	}
	pin := func(href string) string {
		href = strings.Replace(href, "https://github.com/pawelchcki/rules_stests/blob/main/", "https://github.com/pawelchcki/rules_stests/blob/"+revision+"/", 1)
		return strings.Replace(href, "https://github.com/pawelchcki/rules_stests/tree/main/", "https://github.com/pawelchcki/rules_stests/tree/"+revision+"/", 1)
	}
	for i := range manifests {
		for j := range manifests[i].ProfileEvidence {
			manifests[i].ProfileEvidence[j].Href = pin(manifests[i].ProfileEvidence[j].Href)
		}
		for j := range manifests[i].Verifications {
			for k := range manifests[i].Verifications[j].Evidence {
				manifests[i].Verifications[j].Evidence[k].Href = pin(manifests[i].Verifications[j].Evidence[k].Href)
			}
		}
	}
	for i := range shapes {
		shapes[i].Source = pin(shapes[i].Source)
	}
	for _, coverages := range coverageSets {
		for i := range coverages {
			coverages[i].Source.Href = pin(coverages[i].Source.Href)
			for j := range coverages[i].Claims {
				for k := range coverages[i].Claims[j].Evidence {
					coverages[i].Claims[j].Evidence[k].Href = pin(coverages[i].Claims[j].Evidence[k].Href)
				}
			}
		}
	}
	return nil
}

func VerifyMatrixDigest(markdown []byte, expected string) error {
	digest := sha256.Sum256(markdown)
	actual := hex.EncodeToString(digest[:])
	if actual != expected {
		return fmt.Errorf("matrix SHA256 is %s, metadata requires %s", actual, expected)
	}
	return nil
}

func BuildModel(metadata CatalogMetadata, features []Feature, manifests []Manifest, shapes []ScenarioShape, profiles, scenarios []string, evidencePaths map[string]bool, proofCoverages ...ProfileProofCoverage) (ReportModel, error) {
	profileScenarios := make(map[string][]string, len(profiles))
	for _, profile := range profiles {
		profileScenarios[profile] = scenarios
	}
	return BuildModelForProfiles(metadata, features, manifests, shapes, profiles, scenarios, profileScenarios, evidencePaths, proofCoverages...)
}

// BuildModelForProfiles preserves the exact scenario membership declared for
// each profile while retaining the global scenario union used by the report UI.
func BuildModelForProfiles(metadata CatalogMetadata, features []Feature, manifests []Manifest, shapes []ScenarioShape, profiles, scenarios []string, profileScenarios map[string][]string, evidencePaths map[string]bool, proofCoverages ...ProfileProofCoverage) (ReportModel, error) {
	model := ReportModel{GeneratedFrom: metadata.Source.Revision, Metadata: metadata, Features: features, Manifests: manifests, Scenarios: append([]string(nil), scenarios...), Verification: map[string]map[string]Verification{}}
	profileSet, scenarioSet, featureSet := stringSet(profiles), stringSet(scenarios), map[string]bool{}
	profileScenarioSets := make(map[string]map[string]bool, len(profiles))
	for profile, declaredScenarios := range profileScenarios {
		if !profileSet[profile] {
			return model, fmt.Errorf("scenario membership declared for unknown profile %q", profile)
		}
		profileScenarioSets[profile] = map[string]bool{}
		for _, scenario := range declaredScenarios {
			if !scenarioSet[scenario] {
				return model, fmt.Errorf("profile %q declares unknown scenario %q", profile, scenario)
			}
			profileScenarioSets[profile][scenario] = true
		}
	}
	for _, profile := range profiles {
		if len(profileScenarioSets[profile]) == 0 {
			return model, fmt.Errorf("profile %q has no declared scenarios", profile)
		}
	}
	for _, feature := range features {
		if featureSet[feature.ID] {
			return model, fmt.Errorf("duplicate feature id %q", feature.ID)
		}
		featureSet[feature.ID] = true
	}
	coverageClaims := map[string]map[string]FeatureClaim{}
	for _, coverage := range proofCoverages {
		if !profileSet[coverage.Profile] {
			return model, fmt.Errorf("normalized proof plan has unknown profile %q", coverage.Profile)
		}
		if coverageClaims[coverage.Profile] != nil {
			return model, fmt.Errorf("duplicate normalized proof plan profile %q", coverage.Profile)
		}
		if err := validateEvidence([]Evidence{coverage.Source}, evidencePaths); err != nil {
			return model, fmt.Errorf("normalized proof plan %q: %w", coverage.Profile, err)
		}
		coverageClaims[coverage.Profile] = map[string]FeatureClaim{}
		for _, claim := range coverage.Claims {
			if !featureSet[claim.FeatureID] {
				return model, fmt.Errorf("normalized proof plan %q references unknown feature id %q", coverage.Profile, claim.FeatureID)
			}
			if _, exists := coverageClaims[coverage.Profile][claim.FeatureID]; exists {
				return model, fmt.Errorf("normalized proof plan %q duplicates feature id %q", coverage.Profile, claim.FeatureID)
			}
			if claim.Basis != "observed" && claim.Basis != "corroborated" {
				return model, fmt.Errorf("normalized proof plan %q feature %q has invalid basis %q", coverage.Profile, claim.FeatureID, claim.Basis)
			}
			if claim.Assertion == "" {
				return model, fmt.Errorf("normalized proof plan %q feature %q has no capture assertion", coverage.Profile, claim.FeatureID)
			}
			if claim.AllScenarios == (len(claim.Scenarios) > 0) {
				return model, fmt.Errorf("normalized proof plan %q feature %q has invalid scenario scope", coverage.Profile, claim.FeatureID)
			}
			for _, scenario := range claim.Scenarios {
				if !scenarioSet[scenario] {
					return model, fmt.Errorf("normalized proof plan %q feature %q has unknown scenario %q", coverage.Profile, claim.FeatureID, scenario)
				}
				if !profileScenarioSets[coverage.Profile][scenario] {
					return model, fmt.Errorf("normalized proof plan %q feature %q has undeclared scenario %q", coverage.Profile, claim.FeatureID, scenario)
				}
			}
			if err := validateEvidence(claim.Evidence, evidencePaths); err != nil {
				return model, fmt.Errorf("normalized proof plan %q feature %q: %w", coverage.Profile, claim.FeatureID, err)
			}
			if claim.Basis == "corroborated" {
				if len(claim.Evidence) < 2 {
					return model, fmt.Errorf("normalized proof plan %q corroborated feature %q has no upstream evidence", coverage.Profile, claim.FeatureID)
				}
				for _, item := range claim.Evidence[1:] {
					if err := validateImmutableSource(item.Href); err != nil {
						return model, fmt.Errorf("normalized proof plan %q feature %q: %w", coverage.Profile, claim.FeatureID, err)
					}
				}
			}
			coverageClaims[coverage.Profile][claim.FeatureID] = claim
		}
	}
	manifestProfiles := map[string]bool{}
	for i := range manifests {
		manifest := &manifests[i]
		if manifest.SchemaVersion != 1 {
			return model, fmt.Errorf("manifest %q schemaVersion must be 1", manifest.Profile)
		}
		if manifest.Profile == "" || manifest.DisplayName == "" || manifest.Language == "" || manifest.Framework == "" || manifest.InstrumentationVersion == "" {
			return model, fmt.Errorf("manifest is missing required implementation metadata")
		}
		if !profileSet[manifest.Profile] {
			return model, fmt.Errorf("manifest profile %q is absent from REALWORLD_PROFILES", manifest.Profile)
		}
		if manifestProfiles[manifest.Profile] {
			return model, fmt.Errorf("duplicate manifest profile %q", manifest.Profile)
		}
		manifestProfiles[manifest.Profile] = true
		if manifest.Version == "" {
			manifest.Version = manifest.InstrumentationVersion
		}
		if manifest.ShortLabel == "" {
			manifest.ShortLabel = FormatProfileLabel(manifest.Language, manifest.Framework, nil)
		}
		if manifest.Language != "go" && manifest.Language != "python" && manifest.Language != "ruby" {
			return model, fmt.Errorf("manifest %q has unsupported language %q", manifest.Profile, manifest.Language)
		}
		if !verificationStates[manifest.DefaultVerification] {
			return model, fmt.Errorf("manifest %q has invalid default verification %q", manifest.Profile, manifest.DefaultVerification)
		}
		if manifest.DefaultVerification == "verified" {
			return model, fmt.Errorf("manifest %q cannot declare verified as its default; use executable normalized proof plan", manifest.Profile)
		}
		if !coverageStates[manifest.BaseCoverage] {
			return model, fmt.Errorf("manifest %q has invalid base coverage %q", manifest.Profile, manifest.BaseCoverage)
		}
		if err := validateEvidence(manifest.ProfileEvidence, evidencePaths); err != nil {
			return model, fmt.Errorf("manifest %q profile evidence: %w", manifest.Profile, err)
		}
		seen := map[string]bool{}
		for _, verification := range manifest.Verifications {
			if !featureSet[verification.FeatureID] {
				return model, fmt.Errorf("manifest %q references unknown feature id %q", manifest.Profile, verification.FeatureID)
			}
			if seen[verification.FeatureID] {
				return model, fmt.Errorf("manifest %q duplicates feature id %q", manifest.Profile, verification.FeatureID)
			}
			seen[verification.FeatureID] = true
			if !verificationStates[verification.State] {
				return model, fmt.Errorf("manifest %q feature %q has invalid state %q", manifest.Profile, verification.FeatureID, verification.State)
			}
			if verification.State == "verified" {
				return model, fmt.Errorf("manifest %q feature %q cannot manually declare verified; use executable normalized proof plan", manifest.Profile, verification.FeatureID)
			}
			if coverageClaims[manifest.Profile] != nil {
				if _, claimed := coverageClaims[manifest.Profile][verification.FeatureID]; claimed {
					return model, fmt.Errorf("manifest %q feature %q contradicts executable normalized proof plan", manifest.Profile, verification.FeatureID)
				}
			}
			if len(verification.Evidence) == 0 {
				return model, fmt.Errorf("manifest %q feature %q has no evidence", manifest.Profile, verification.FeatureID)
			}
			if err := validateEvidence(verification.Evidence, evidencePaths); err != nil {
				return model, fmt.Errorf("manifest %q feature %q: %w", manifest.Profile, verification.FeatureID, err)
			}
		}
	}
	for _, profile := range profiles {
		if !manifestProfiles[profile] {
			return model, fmt.Errorf("REALWORLD_PROFILES entry %q has no manifest", profile)
		}
		if coverageClaims[profile] == nil {
			return model, fmt.Errorf("REALWORLD_PROFILES entry %q has no executable normalized proof plan", profile)
		}
	}
	shapeIndex := map[string]*ScenarioShape{}
	for i := range shapes {
		shape := &shapes[i]
		if !profileSet[shape.Profile] {
			return model, fmt.Errorf("shape has unknown profile %q", shape.Profile)
		}
		if !scenarioSet[shape.Scenario] {
			return model, fmt.Errorf("shape has unknown scenario %q", shape.Scenario)
		}
		if !profileScenarioSets[shape.Profile][shape.Scenario] {
			return model, fmt.Errorf("shape has undeclared scenario %q for profile %q", shape.Scenario, shape.Profile)
		}
		key := shape.Profile + "\x00" + shape.Scenario
		if shapeIndex[key] != nil {
			return model, fmt.Errorf("duplicate shape for %s/%s", shape.Profile, shape.Scenario)
		}
		shapeIndex[key] = shape
	}
	for _, feature := range features {
		model.Verification[feature.ID] = map[string]Verification{}
		for _, manifest := range manifests {
			verification := Verification{FeatureID: feature.ID, State: manifest.DefaultVerification, Evidence: manifest.ProfileEvidence}
			for _, candidate := range manifest.Verifications {
				if candidate.FeatureID == feature.ID {
					verification = candidate
					break
				}
			}
			if claim, ok := coverageClaims[manifest.Profile][feature.ID]; ok {
				claimScenarios := append([]string(nil), claim.Scenarios...)
				if claim.AllScenarios {
					claimScenarios = append([]string(nil), profileScenarios[manifest.Profile]...)
				}
				verification = Verification{
					FeatureID: feature.ID,
					State:     "verified",
					Basis:     claim.Basis,
					Assertion: claim.Assertion,
					Scenarios: claimScenarios,
					Evidence:  append([]Evidence(nil), claim.Evidence...),
				}
			}
			model.Verification[feature.ID][manifest.Profile] = verification
		}
	}
	for _, scenario := range scenarios {
		for _, manifest := range manifests {
			state := "unavailable"
			if profileScenarioSets[manifest.Profile][scenario] {
				state = manifest.BaseCoverage
			}
			if profileScenarioSets[manifest.Profile][scenario] && shapeIndex[manifest.Profile+"\x00"+scenario] != nil {
				state = "exact_shape"
			}
			model.Coverage = append(model.Coverage, CoverageCell{Profile: manifest.Profile, Scenario: scenario, State: state})
		}
	}
	for left := 0; left < len(profiles); left++ {
		for right := left + 1; right < len(profiles); right++ {
			for _, scenario := range scenarios {
				comparison := Comparison{LeftProfile: profiles[left], RightProfile: profiles[right], Scenario: scenario, ScopeDelta: map[string]int{}, StatusDelta: map[string]int{}}
				leftScenarioShape, rightScenarioShape := shapeIndex[profiles[left]+"\x00"+scenario], shapeIndex[profiles[right]+"\x00"+scenario]
				if leftScenarioShape != nil && rightScenarioShape != nil && leftScenarioShape.ExactCounts && rightScenarioShape.ExactCounts {
					comparison.Available = true
					comparison.TraceDelta -= leftScenarioShape.TraceCount
					comparison.SpanDelta -= leftScenarioShape.SpanCount
					comparison.CountDelta -= len(leftScenarioShape.Traces)
					mergeDelta(comparison.ScopeDelta, leftScenarioShape.Scopes, -1)
					mergeDelta(comparison.StatusDelta, leftScenarioShape.Statuses, -1)
					comparison.TraceDelta += rightScenarioShape.TraceCount
					comparison.SpanDelta += rightScenarioShape.SpanCount
					comparison.CountDelta += len(rightScenarioShape.Traces)
					mergeDelta(comparison.ScopeDelta, rightScenarioShape.Scopes, 1)
					mergeDelta(comparison.StatusDelta, rightScenarioShape.Statuses, 1)
				}
				comparison.Alignment = AlignShapes(leftScenarioShape, rightScenarioShape)
				model.Comparisons = append(model.Comparisons, comparison)
			}
		}
	}
	model.Manifests, model.Shapes = manifests, shapes
	return model, nil
}

func validateEvidence(items []Evidence, paths map[string]bool) error {
	if len(items) == 0 {
		return fmt.Errorf("missing evidence")
	}
	for _, item := range items {
		if item.Label == "" || item.Href == "" {
			return fmt.Errorf("evidence requires label and href")
		}
		if !(strings.HasPrefix(item.Href, "https://") || strings.HasPrefix(item.Href, "http://") || strings.HasPrefix(item.Href, "//")) {
			return fmt.Errorf("invalid evidence href %q", item.Href)
		}
		if item.Path != "" && !paths[item.Path] {
			return fmt.Errorf("broken evidence path %q", item.Path)
		}
	}
	return nil
}

func RenderHTML(model ReportModel) ([]byte, error) {
	data, err := json.Marshal(model)
	if err != nil {
		return nil, fmt.Errorf("marshal report model: %w", err)
	}
	safe := strings.ReplaceAll(string(data), "</", "<\\/")
	return []byte(strings.Replace(reportHTML, "__REPORT_DATA__", safe, 1)), nil
}

func decodeStrict(data []byte, destination any) error {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(destination); err != nil {
		return err
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		if err == nil {
			return fmt.Errorf("unexpected trailing JSON")
		}
		return err
	}
	return nil
}

func stringSet(values []string) map[string]bool {
	out := map[string]bool{}
	for _, value := range values {
		out[value] = true
	}
	return out
}
func mergeDelta(destination, values map[string]int, sign int) {
	for key, value := range values {
		destination[key] += sign * value
		if destination[key] == 0 {
			delete(destination, key)
		}
	}
}

func SortInputs(features []Feature, manifests []Manifest, shapes []ScenarioShape) {
	sort.Slice(features, func(i, j int) bool {
		if features[i].Category != features[j].Category {
			return features[i].Category < features[j].Category
		}
		return features[i].ID < features[j].ID
	})
	sort.Slice(manifests, func(i, j int) bool { return manifests[i].Profile < manifests[j].Profile })
	sort.Slice(shapes, func(i, j int) bool {
		if shapes[i].Scenario != shapes[j].Scenario {
			return shapes[i].Scenario < shapes[j].Scenario
		}
		return shapes[i].Profile < shapes[j].Profile
	})
}
