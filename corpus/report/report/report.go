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
	for _, language := range []string{"go", "python"} {
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

func VerifyMatrixDigest(markdown []byte, expected string) error {
	digest := sha256.Sum256(markdown)
	actual := hex.EncodeToString(digest[:])
	if actual != expected {
		return fmt.Errorf("matrix SHA256 is %s, metadata requires %s", actual, expected)
	}
	return nil
}

func BuildModel(metadata CatalogMetadata, features []Feature, manifests []Manifest, goldens []Golden, profiles, scenarios []string, evidencePaths map[string]bool) (ReportModel, error) {
	model := ReportModel{GeneratedFrom: metadata.Source.Revision, Metadata: metadata, Features: features, Manifests: manifests, Scenarios: append([]string(nil), scenarios...), Verification: map[string]map[string]Verification{}}
	profileSet, scenarioSet, featureSet := stringSet(profiles), stringSet(scenarios), map[string]bool{}
	for _, feature := range features {
		if featureSet[feature.ID] {
			return model, fmt.Errorf("duplicate feature id %q", feature.ID)
		}
		featureSet[feature.ID] = true
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
		if manifest.Language != "go" && manifest.Language != "python" {
			return model, fmt.Errorf("manifest %q has unsupported language %q", manifest.Profile, manifest.Language)
		}
		if !verificationStates[manifest.DefaultVerification] {
			return model, fmt.Errorf("manifest %q has invalid default verification %q", manifest.Profile, manifest.DefaultVerification)
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
	}
	goldenIndex := map[string]*Golden{}
	for i := range goldens {
		golden := &goldens[i]
		if !profileSet[golden.Profile] {
			return model, fmt.Errorf("golden has unknown profile %q", golden.Profile)
		}
		if !scenarioSet[golden.Scenario] {
			return model, fmt.Errorf("golden has unknown scenario %q", golden.Scenario)
		}
		key := golden.Profile + "\x00" + golden.Scenario
		if goldenIndex[key] != nil {
			return model, fmt.Errorf("duplicate golden for %s/%s", golden.Profile, golden.Scenario)
		}
		goldenIndex[key] = golden
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
			model.Verification[feature.ID][manifest.Profile] = verification
		}
	}
	for _, scenario := range scenarios {
		for _, manifest := range manifests {
			state := manifest.BaseCoverage
			if goldenIndex[manifest.Profile+"\x00"+scenario] != nil {
				state = "exact_golden"
			}
			model.Coverage = append(model.Coverage, CoverageCell{Profile: manifest.Profile, Scenario: scenario, State: state})
		}
	}
	for left := 0; left < len(profiles); left++ {
		for right := left + 1; right < len(profiles); right++ {
			for _, scenario := range scenarios {
				comparison := Comparison{LeftProfile: profiles[left], RightProfile: profiles[right], Scenario: scenario, ScopeDelta: map[string]int{}, StatusDelta: map[string]int{}}
				leftGolden, rightGolden := goldenIndex[profiles[left]+"\x00"+scenario], goldenIndex[profiles[right]+"\x00"+scenario]
				if leftGolden != nil && rightGolden != nil {
					comparison.Available = true
					comparison.TraceDelta -= leftGolden.TraceCount
					comparison.SpanDelta -= leftGolden.SpanCount
					comparison.CountDelta -= len(leftGolden.Traces)
					mergeDelta(comparison.ScopeDelta, leftGolden.Scopes, -1)
					mergeDelta(comparison.StatusDelta, leftGolden.Statuses, -1)
					comparison.TraceDelta += rightGolden.TraceCount
					comparison.SpanDelta += rightGolden.SpanCount
					comparison.CountDelta += len(rightGolden.Traces)
					mergeDelta(comparison.ScopeDelta, rightGolden.Scopes, 1)
					mergeDelta(comparison.StatusDelta, rightGolden.Statuses, 1)
				}
				model.Comparisons = append(model.Comparisons, comparison)
			}
		}
	}
	model.Manifests, model.Goldens = manifests, goldens
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

func SortInputs(features []Feature, manifests []Manifest, goldens []Golden) {
	sort.Slice(features, func(i, j int) bool {
		if features[i].Category != features[j].Category {
			return features[i].Category < features[j].Category
		}
		return features[i].ID < features[j].ID
	})
	sort.Slice(manifests, func(i, j int) bool { return manifests[i].Profile < manifests[j].Profile })
	sort.Slice(goldens, func(i, j int) bool {
		if goldens[i].Scenario != goldens[j].Scenario {
			return goldens[i].Scenario < goldens[j].Scenario
		}
		return goldens[i].Profile < goldens[j].Profile
	})
}
