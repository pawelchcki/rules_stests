package report

import (
	"strings"
	"testing"
)

func fixtureModel(t *testing.T, includeScenarioShape bool) (CatalogMetadata, []Feature, []Manifest, []ScenarioShape, map[string]bool) {
	t.Helper()
	metadata := CatalogMetadata{SchemaVersion: 1, Source: testSource(), MaturitySource: "https://example.test/status", Maturity: map[string]SignalMaturity{"go": {Traces: "stable", Metrics: "stable", Logs: "beta"}, "python": {Traces: "stable", Metrics: "stable", Logs: "development"}, "ruby": {Traces: "stable", Metrics: "development", Logs: "development"}}}
	features := []Feature{
		{ID: "traces.span.create-root-span", Category: "Traces", Group: "Span", Name: "Create root span", Support: map[string]string{"go": "supported", "python": "supported"}, Source: "https://example.test/feature"},
		{ID: "traces.span.end", Category: "Traces", Group: "Span", Name: "End", Support: map[string]string{"go": "supported", "python": "supported"}, Source: "https://example.test/end"},
	}
	evidence := []Evidence{{Label: "profile", Href: "https://example.test/profile", Path: "profile.scm"}}
	manifests := []Manifest{
		{SchemaVersion: 1, Profile: "go", DisplayName: "Go", Language: "go", Framework: "Gin", InstrumentationVersion: "1", ProfileEvidence: evidence, BaseCoverage: "contract_only", DefaultVerification: "not_exercised"},
		{SchemaVersion: 1, Profile: "python", DisplayName: "Python", Language: "python", Framework: "aiohttp", InstrumentationVersion: "1", ProfileEvidence: evidence, BaseCoverage: "contract_only", DefaultVerification: "not_exercised"},
	}
	var shapes []ScenarioShape
	if includeScenarioShape {
		shape, err := ParseScenarioShape("python", "case", "https://example.test/shape", sampleScenarioShape)
		if err != nil {
			t.Fatal(err)
		}
		shapes = append(shapes, shape)
	}
	return metadata, features, manifests, shapes, map[string]bool{"profile.scm": true, "coverage-go.scm": true, "coverage-python.scm": true}
}

func fixtureProfileProofCoverage(features []Feature) []ProfileProofCoverage {
	goEvidence := Evidence{Label: "executable coverage", Href: "https://example.test/coverage-go", Path: "coverage-go.scm"}
	pythonEvidence := Evidence{Label: "executable coverage", Href: "https://example.test/coverage-python", Path: "coverage-python.scm"}
	return []ProfileProofCoverage{
		{Profile: "go", Source: goEvidence, Claims: []FeatureClaim{{FeatureID: features[0].ID, Basis: "observed", Assertion: "span/root-present", AllScenarios: true, Evidence: []Evidence{goEvidence}}}},
		{Profile: "python", Source: pythonEvidence, Claims: []FeatureClaim{{FeatureID: features[1].ID, Basis: "observed", Assertion: "span/all-completed", Scenarios: []string{"case"}, Evidence: []Evidence{pythonEvidence}}}},
	}
}

func TestBuildModelSeparatesScenarioShapeAndContractCoverage(t *testing.T) {
	metadata, features, manifests, shapes, evidence := fixtureModel(t, true)
	model, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...)
	if err != nil {
		t.Fatal(err)
	}
	if model.Coverage[0].State != "contract_only" || model.Coverage[1].State != "exact_shape" {
		t.Fatalf("unexpected coverage %#v", model.Coverage)
	}
	if model.Verification[features[0].ID]["go"].State != "verified" || model.Verification[features[0].ID]["python"].State != "not_exercised" {
		t.Fatalf("unexpected verification %#v", model.Verification)
	}
	if got := model.Verification[features[0].ID]["go"]; got.Basis != "observed" || len(got.Scenarios) != 1 || got.Scenarios[0] != "case" {
		t.Fatalf("coverage basis or scenarios were not preserved: %#v", got)
	}
	if len(model.Verification[features[0].ID]["python"].Evidence) == 0 {
		t.Fatal("default verification lacks manifest evidence")
	}
	if len(model.Comparisons) != 1 || model.Comparisons[0].Available || model.Comparisons[0].TraceDelta != 0 {
		t.Fatalf("unexpected comparison %#v", model.Comparisons)
	}
}

func TestBuildModelValidatesManifests(t *testing.T) {
	metadata, features, manifests, shapes, evidence := fixtureModel(t, false)
	manifests[0].Verifications = []Verification{{FeatureID: "unknown", State: "known_gap", Evidence: manifests[0].ProfileEvidence}}
	if _, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...); err == nil || !strings.Contains(err.Error(), "unknown feature") {
		t.Fatalf("expected unknown feature error, got %v", err)
	}
	metadata, features, manifests, shapes, evidence = fixtureModel(t, false)
	manifests[0].ProfileEvidence[0].Path = "missing.scm"
	if _, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...); err == nil || !strings.Contains(err.Error(), "broken evidence") {
		t.Fatalf("expected broken evidence error, got %v", err)
	}
	metadata, features, manifests, shapes, evidence = fixtureModel(t, false)
	if _, err := BuildModel(metadata, features, manifests[:1], shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...); err == nil || !strings.Contains(err.Error(), "has no manifest") {
		t.Fatalf("expected missing manifest error, got %v", err)
	}
	metadata, features, manifests, shapes, evidence = fixtureModel(t, false)
	manifests[0].Verifications = []Verification{{FeatureID: features[0].ID, State: "verified", Evidence: manifests[0].ProfileEvidence}}
	if _, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...); err == nil || !strings.Contains(err.Error(), "cannot manually declare verified") {
		t.Fatalf("expected manual verified error, got %v", err)
	}
	metadata, features, manifests, shapes, evidence = fixtureModel(t, false)
	manifests[0].DefaultVerification = "verified"
	if _, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...); err == nil || !strings.Contains(err.Error(), "cannot declare verified as its default") {
		t.Fatalf("expected verified default error, got %v", err)
	}
}

func TestBuildModelValidatesExecutableCoverage(t *testing.T) {
	tests := []struct {
		name string
		edit func([]ProfileProofCoverage, []Manifest)
		want string
	}{
		{"unknown feature", func(coverages []ProfileProofCoverage, _ []Manifest) { coverages[0].Claims[0].FeatureID = "unknown" }, "unknown feature id"},
		{"unknown profile", func(coverages []ProfileProofCoverage, _ []Manifest) { coverages[0].Profile = "unknown" }, "unknown profile"},
		{"duplicate profile", func(coverages []ProfileProofCoverage, _ []Manifest) { coverages[1].Profile = coverages[0].Profile }, "duplicate normalized proof plan profile"},
		{"invalid basis", func(coverages []ProfileProofCoverage, _ []Manifest) { coverages[0].Claims[0].Basis = "documented" }, "invalid basis"},
		{"missing assertion", func(coverages []ProfileProofCoverage, _ []Manifest) { coverages[0].Claims[0].Assertion = "" }, "has no capture assertion"},
		{"unknown scenario", func(coverages []ProfileProofCoverage, _ []Manifest) {
			coverages[1].Claims[0].Scenarios = []string{"unknown"}
		}, "unknown scenario"},
		{"invalid scope", func(coverages []ProfileProofCoverage, _ []Manifest) {
			coverages[0].Claims[0].Scenarios = []string{"case"}
		}, "invalid scenario scope"},
		{"missing local evidence", func(coverages []ProfileProofCoverage, _ []Manifest) { coverages[0].Claims[0].Evidence = nil }, "missing evidence"},
		{"corroborated without upstream", func(coverages []ProfileProofCoverage, _ []Manifest) { coverages[0].Claims[0].Basis = "corroborated" }, "has no upstream evidence"},
		{"mutable corroboration", func(coverages []ProfileProofCoverage, _ []Manifest) {
			coverages[0].Claims[0].Basis = "corroborated"
			coverages[0].Claims[0].Evidence = append(coverages[0].Claims[0].Evidence, Evidence{Label: "upstream", Href: "https://github.com/open-telemetry/repo/blob/main/file"})
		}, "mutable"},
		{"contradictory override", func(coverages []ProfileProofCoverage, manifests []Manifest) {
			manifests[0].Verifications = []Verification{{FeatureID: coverages[0].Claims[0].FeatureID, State: "known_gap", Evidence: manifests[0].ProfileEvidence}}
		}, "contradicts executable normalized proof plan"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			metadata, features, manifests, shapes, evidence := fixtureModel(t, false)
			coverages := fixtureProfileProofCoverage(features)
			test.edit(coverages, manifests)
			_, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, coverages...)
			if err == nil || !strings.Contains(err.Error(), test.want) {
				t.Fatalf("expected %q error, got %v", test.want, err)
			}
		})
	}

	metadata, features, manifests, shapes, evidence := fixtureModel(t, false)
	if _, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)[:1]...); err == nil || !strings.Contains(err.Error(), "no executable normalized proof plan") {
		t.Fatalf("expected missing normalized proof plan error, got %v", err)
	}
}

func TestRenderHTMLIsSelfContainedAndEscapesData(t *testing.T) {
	metadata, features, manifests, shapes, evidence := fixtureModel(t, true)
	features[0].Name = "</script><script>alert(1)</script>"
	model, err := BuildModel(metadata, features, manifests, shapes, []string{"go", "python"}, []string{"case"}, evidence, fixtureProfileProofCoverage(features)...)
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
	if !strings.Contains(text, "const manifests=lang?data.manifests.filter(m=>m.language===lang):data.manifests") {
		t.Fatal("verification filtering is not scoped to the selected language")
	}
	if !strings.Contains(text, "Evidence basis") || !strings.Contains(text, "badge('basis',v.basis)") || !strings.Contains(text, "assertion: ") {
		t.Fatal("report lacks basis badges, filtering, or capture assertions")
	}
}

func TestPinRepositoryRevisionRewritesReportEvidence(t *testing.T) {
	const revision = "0123456789abcdef0123456789abcdef01234567"
	manifests := []Manifest{{
		ProfileEvidence: []Evidence{{Href: "https://github.com/pawelchcki/rules_stests/blob/main/corpus/profile.scm"}},
		Verifications:   []Verification{{Evidence: []Evidence{{Href: "https://github.com/pawelchcki/rules_stests/tree/main/corpus/shapes"}}}},
	}}
	shapes := []ScenarioShape{{Source: "https://github.com/pawelchcki/rules_stests/blob/main/corpus/shape.scm"}}
	coverages := []ProfileProofCoverage{{Source: Evidence{Href: "https://github.com/pawelchcki/rules_stests/blob/main/corpus/coverage.scm"}, Claims: []FeatureClaim{{Evidence: []Evidence{{Href: "https://github.com/pawelchcki/rules_stests/blob/main/corpus/coverage.scm"}}}}}}
	if err := PinRepositoryRevision(manifests, shapes, revision, coverages); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(coverages[0].Source.Href, revision) || !strings.Contains(coverages[0].Claims[0].Evidence[0].Href, revision) {
		t.Fatal("normalized proof plan evidence was not revision-pinned")
	}
	for _, href := range []string{manifests[0].ProfileEvidence[0].Href, manifests[0].Verifications[0].Evidence[0].Href, shapes[0].Source} {
		if !strings.Contains(href, revision) || strings.Contains(href, "/main/") {
			t.Fatalf("evidence was not pinned: %s", href)
		}
	}
	if err := PinRepositoryRevision(nil, nil, "not-a-commit"); err == nil {
		t.Fatal("expected invalid revision to fail")
	}
}
