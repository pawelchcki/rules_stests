package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
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
  {"id":"go-profile","repository":"rules_stests+","spec":"corpus/realworld/profile/go-profile.scm","plan":"bazel-out/go.proof-plan.json","shapes":{"tags":"corpus/realworld/shape/go-profile/tags.scm","articles":"corpus/realworld/shape/go-profile/articles.scm"}},
  {"id":"python-profile","repository":"","spec":"profile/python-profile.scm","plan":"bazel-out/python.proof-plan.json","shapes":{"tags":"shape/python-profile/tags.scm"}}
]`
	if err := os.WriteFile(path, []byte(manifest), 0o644); err != nil {
		t.Fatal(err)
	}
	profiles, scenarios, plans, shapes, err := loadReportManifest(path, "https://example.test/consumer/", "https://example.test/corpus/")
	if err != nil {
		t.Fatal(err)
	}
	if got := strings.Join(profiles, ","); got != "go-profile,python-profile" {
		t.Fatalf("profiles = %q", got)
	}
	if got := strings.Join(scenarios, ","); got != "articles,tags" {
		t.Fatalf("scenarios = %q", got)
	}
	if got := strings.Join(plans, "\n"); !strings.Contains(got, "go-profile,bazel-out/go.proof-plan.json,https://example.test/corpus/corpus/realworld/profile/go-profile.scm") || !strings.Contains(got, "python-profile,bazel-out/python.proof-plan.json,https://example.test/consumer/profile/python-profile.scm") {
		t.Fatalf("plans = %q", got)
	}
	if got := strings.Join(shapes, "\n"); !strings.Contains(got, "go-profile,articles,corpus/realworld/shape/go-profile/articles.scm,https://example.test/corpus/corpus/realworld/shape/go-profile/articles.scm") {
		t.Fatalf("shapes = %q", got)
	}
	if _, _, _, _, err := loadReportManifest(path, "", "https://example.test/corpus"); err == nil || !strings.Contains(err.Error(), "source-root") {
		t.Fatalf("missing source root was accepted: %v", err)
	}
}
