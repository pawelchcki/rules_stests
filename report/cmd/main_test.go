package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pawelchcki/rules_stests/report"
)

func TestCollectBEPRequiresUncachedRunAndCollectsArtifacts(t *testing.T) {
	root := t.TempDir()
	directory := filepath.Join(root, "test.outputs", "receipts", "profile")
	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}
	receiptPath := filepath.Join(directory, "articles.json")
	capturePath := filepath.Join(directory, "articles.capture.json")
	if err := os.WriteFile(receiptPath, []byte("receipt"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(capturePath, []byte("capture"), 0o644); err != nil {
		t.Fatal(err)
	}
	writeBEP := func(name string, options string) string {
		path := filepath.Join(root, name)
		data := fmt.Sprintf("{\"optionsParsed\":{\"cmdLine\":[%s]},\"outputs\":[{\"uri\":\"file://%s\"},{\"uri\":\"file://%s\"}]}\n", options, receiptPath, capturePath)
		if err := os.WriteFile(path, []byte(data), 0o644); err != nil {
			t.Fatal(err)
		}
		return path
	}

	if _, _, err := collectBEP(writeBEP("cached.json", `"--cache_test_results=1"`)); err == nil || !strings.Contains(err.Error(), "nocache_test_results") {
		t.Fatalf("cached BEP was accepted: %v", err)
	}
	receipts, captures, err := collectBEP(writeBEP("uncached.json", `"--cache_test_results=0"`))
	if err != nil {
		t.Fatal(err)
	}
	if string(receipts["profile/articles"]) != "receipt" || string(captures["profile\x00articles"]) != "capture" {
		t.Fatalf("unexpected artifacts: receipts=%v captures=%v", receipts, captures)
	}
}

func TestLoadReportManifestDerivesLegacyInputs(t *testing.T) {
	path := filepath.Join(t.TempDir(), "manifest.json")
	manifest := `[
  {"id":"go-profile","repository":"rules_stests","spec":"corpus/realworld/profile/go-profile.scm","plan":"bazel-out/go.proof-plan.json","scenarios":["articles","tags"],"shapes":{"tags":"external/rules_stests+/corpus/realworld/shape/go-profile/tags.scm","articles":"external/rules_stests+/corpus/realworld/shape/go-profile/articles.scm"},"shapeSources":{"tags":"corpus/realworld/shape/go-profile/tags.scm","articles":"corpus/realworld/shape/go-profile/articles.scm"}},
  {"id":"python-profile","repository":"","spec":"profile/python-profile.scm","plan":"bazel-out/python.proof-plan.json","scenarios":["articles","auth","tags"],"shapes":{"tags":"shape/python-profile/tags.scm"},"shapeSources":{"tags":"shape/python-profile/tags.scm"}},
  {"id":"contract-profile","repository":"","spec":"profile/contract-profile.scm","plan":"bazel-out/contract.proof-plan.json","scenarios":["comments"],"shapes":{},"shapeSources":{}}
]`
	if err := os.WriteFile(path, []byte(manifest), 0o644); err != nil {
		t.Fatal(err)
	}
	profiles, scenarios, plans, shapes, profileScenarios, err := loadReportManifest(path, "https://example.test/consumer/", "https://example.test/corpus/")
	if err != nil {
		t.Fatal(err)
	}
	if got := strings.Join(profiles, ","); got != "go-profile,python-profile,contract-profile" {
		t.Fatalf("profiles = %q", got)
	}
	if got := strings.Join(scenarios, ","); got != "articles,auth,comments,tags" {
		t.Fatalf("scenarios = %q", got)
	}
	if got := strings.Join(profileScenarios["go-profile"], ","); got != "articles,tags" {
		t.Fatalf("go-profile scenarios = %q", got)
	}
	if got := strings.Join(profileScenarios["contract-profile"], ","); got != "comments" {
		t.Fatalf("contract-profile scenarios = %q", got)
	}
	if got := strings.Join(plans, "\n"); !strings.Contains(got, "go-profile,bazel-out/go.proof-plan.json,https://example.test/corpus/corpus/realworld/profile/go-profile.scm") || !strings.Contains(got, "python-profile,bazel-out/python.proof-plan.json,https://example.test/consumer/profile/python-profile.scm") {
		t.Fatalf("plans = %q", got)
	}
	if got := strings.Join(shapes, "\n"); !strings.Contains(got, "go-profile,articles,external/rules_stests+/corpus/realworld/shape/go-profile/articles.scm,https://example.test/corpus/corpus/realworld/shape/go-profile/articles.scm") {
		t.Fatalf("shapes = %q", got)
	}
	if _, _, _, _, _, err := loadReportManifest(path, "", "https://example.test/corpus"); err == nil || !strings.Contains(err.Error(), "source-root") {
		t.Fatalf("missing source root was accepted: %v", err)
	}
	if _, _, _, _, _, err := loadReportManifest(path, "https://example.test/consumer", ""); err == nil || !strings.Contains(err.Error(), "corpus-source-root") {
		t.Fatalf("missing corpus source root was accepted: %v", err)
	}
	unsupportedPath := filepath.Join(t.TempDir(), "manifest.json")
	unsupported := strings.Replace(manifest, `"repository":"rules_stests"`, `"repository":"third_party+"`, 1)
	if err := os.WriteFile(unsupportedPath, []byte(unsupported), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, _, _, _, _, err := loadReportManifest(unsupportedPath, "https://example.test/consumer", "https://example.test/corpus"); err == nil || !strings.Contains(err.Error(), "unsupported external repository") {
		t.Fatalf("unsupported external repository was accepted: %v", err)
	}
}

func TestExecutionPathResolvesManifestArtifactsFromExecRoot(t *testing.T) {
	root := filepath.Join("tmp", "execroot")
	if got, want := executionPath(root, "external/rules_stests+/shape.scm"), filepath.Join(root, "external/rules_stests+/shape.scm"); got != want {
		t.Fatalf("execution path = %q, want %q", got, want)
	}
	absolute := filepath.Join(string(filepath.Separator), "tmp", "shape.scm")
	if got := executionPath(root, absolute); got != absolute {
		t.Fatalf("absolute execution path = %q", got)
	}
}

func TestLegacyCoverageWithholdsClaimsWithoutReceipts(t *testing.T) {
	proof := report.ProofPlanProof{FeatureID: "traces.span.end", Basis: "observed", Assertion: "span/all-completed"}
	plans := map[string]report.PlanArtifact{
		"exercised":   {Plan: report.NormalizedProfilePlan{Profile: "exercised", Proofs: []report.ProofPlanProof{proof}}},
		"unexercised": {Plan: report.NormalizedProfilePlan{Profile: "unexercised", Proofs: []report.ProofPlanProof{proof}}},
	}
	receipts := []report.ValidationReceipt{{Profile: "exercised", Scenario: "articles", Outcome: "verified"}}
	coverages := coveragesForInvocation(plans, receipts, []string{"exercised", "unexercised"}, []string{"articles"}, nil)
	if len(coverages) != 2 || len(coverages[0].Claims) != 1 || len(coverages[1].Claims) != 0 {
		t.Fatalf("legacy coverage trusted a plan without receipts: %#v", coverages)
	}
}
