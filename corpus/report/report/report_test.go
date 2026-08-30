package report

import (
	"strings"
	"testing"
)

func fixtureModel(t *testing.T, includeGolden bool) (CatalogMetadata, []Feature, []Manifest, []Golden, map[string]bool) {
	t.Helper()
	metadata := CatalogMetadata{SchemaVersion: 1, Source: testSource(), MaturitySource: "https://example.test/status", Maturity: map[string]SignalMaturity{"go": {Traces: "stable", Metrics: "stable", Logs: "beta"}, "python": {Traces: "stable", Metrics: "stable", Logs: "development"}}}
	features := []Feature{{ID: "traces.span.create-root-span", Category: "Traces", Group: "Span", Name: "Create root span", Support: map[string]string{"go": "supported", "python": "supported"}, Source: "https://example.test/feature"}}
	evidence := []Evidence{{Label: "profile", Href: "https://example.test/profile", Path: "profile.scm"}}
	manifests := []Manifest{
		{SchemaVersion: 1, Profile: "go", DisplayName: "Go", Language: "go", Framework: "Gin", InstrumentationVersion: "1", ProfileEvidence: evidence, BaseCoverage: "contract_only", DefaultVerification: "not_exercised", Verifications: []Verification{{FeatureID: features[0].ID, State: "verified", Evidence: evidence}}},
		{SchemaVersion: 1, Profile: "python", DisplayName: "Python", Language: "python", Framework: "aiohttp", InstrumentationVersion: "1", ProfileEvidence: evidence, BaseCoverage: "contract_only", DefaultVerification: "not_exercised"},
	}
	var goldens []Golden
	if includeGolden {
		golden, err := ParseGolden("python", "case", "https://example.test/golden", sampleGolden)
		if err != nil {
			t.Fatal(err)
		}
		goldens = append(goldens, golden)
	}
	return metadata, features, manifests, goldens, map[string]bool{"profile.scm": true}
}

func TestBuildModelSeparatesGoldenAndContractCoverage(t *testing.T) {
	metadata, features, manifests, goldens, evidence := fixtureModel(t, true)
	model, err := BuildModel(metadata, features, manifests, goldens, []string{"go", "python"}, []string{"case"}, evidence)
	if err != nil {
		t.Fatal(err)
	}
	if model.Coverage[0].State != "contract_only" || model.Coverage[1].State != "exact_golden" {
		t.Fatalf("unexpected coverage %#v", model.Coverage)
	}
	if model.Verification[features[0].ID]["go"].State != "verified" || model.Verification[features[0].ID]["python"].State != "not_exercised" {
		t.Fatalf("unexpected verification %#v", model.Verification)
	}
	if len(model.Verification[features[0].ID]["python"].Evidence) == 0 {
		t.Fatal("default verification lacks manifest evidence")
	}
	if len(model.Comparisons) != 1 || model.Comparisons[0].Available || model.Comparisons[0].TraceDelta != 0 {
		t.Fatalf("unexpected comparison %#v", model.Comparisons)
	}
}

func TestBuildModelValidatesManifests(t *testing.T) {
	metadata, features, manifests, goldens, evidence := fixtureModel(t, false)
	manifests[0].Verifications[0].FeatureID = "unknown"
	if _, err := BuildModel(metadata, features, manifests, goldens, []string{"go", "python"}, []string{"case"}, evidence); err == nil || !strings.Contains(err.Error(), "unknown feature") {
		t.Fatalf("expected unknown feature error, got %v", err)
	}
	metadata, features, manifests, goldens, evidence = fixtureModel(t, false)
	manifests[0].ProfileEvidence[0].Path = "missing.scm"
	if _, err := BuildModel(metadata, features, manifests, goldens, []string{"go", "python"}, []string{"case"}, evidence); err == nil || !strings.Contains(err.Error(), "broken evidence") {
		t.Fatalf("expected broken evidence error, got %v", err)
	}
	metadata, features, manifests, goldens, evidence = fixtureModel(t, false)
	if _, err := BuildModel(metadata, features, manifests[:1], goldens, []string{"go", "python"}, []string{"case"}, evidence); err == nil || !strings.Contains(err.Error(), "has no manifest") {
		t.Fatalf("expected missing manifest error, got %v", err)
	}
}

func TestRenderHTMLIsSelfContainedAndEscapesData(t *testing.T) {
	metadata, features, manifests, goldens, evidence := fixtureModel(t, true)
	features[0].Name = "</script><script>alert(1)</script>"
	model, err := BuildModel(metadata, features, manifests, goldens, []string{"go", "python"}, []string{"case"}, evidence)
	if err != nil {
		t.Fatal(err)
	}
	html, err := RenderHTML(model)
	if err != nil {
		t.Fatal(err)
	}
	text := string(html)
	if strings.Contains(text, "</script><script>alert") {
		t.Fatal("embedded JSON can terminate its script element")
	}
	if !strings.Contains(text, "OpenTelemetry feature parity") || !strings.Contains(text, "application/json") {
		t.Fatal("missing report shell or embedded model")
	}
	if strings.Contains(text, "<link rel=") || strings.Contains(text, "<script src=") {
		t.Fatal("report depends on external assets")
	}
}
