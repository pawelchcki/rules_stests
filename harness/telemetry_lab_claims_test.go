package main

import (
	"flag"
	"os"
	"path/filepath"
	"regexp"
	"testing"

	"github.com/pawelchcki/rules_stests/report"
)

func readLabRunfile(path string) ([]byte, error) {
	candidates := []string{path}
	for _, root := range []string{os.Getenv("RUNFILES_DIR"), os.Getenv("TEST_SRCDIR")} {
		if root != "" {
			candidates = append(candidates, filepath.Join(root, path))
		}
	}
	for _, candidate := range candidates {
		if data, err := os.ReadFile(candidate); err == nil {
			return data, nil
		}
	}
	return os.ReadFile(path)
}

func TestLabClaimsAreNewPinnedFeatures(t *testing.T) {
	paths := flag.Args()
	if len(paths) < 3 {
		t.Fatal("matrix, proof-rule, and supplemental paths are required")
	}
	data, err := readLabRunfile(paths[0])
	if err != nil {
		t.Fatal(err)
	}
	features, err := report.ImportMatrix(string(data), report.CatalogSource{Revision: "pinned", URL: "pinned", RawURL: "pinned", SHA256: "pinned"})
	if err != nil {
		t.Fatal(err)
	}
	known := map[string]bool{}
	for _, feature := range features {
		known[feature.ID] = true
	}
	var proofRules []byte
	for _, path := range paths[1 : len(paths)-1] {
		contents, err := readLabRunfile(path)
		if err != nil {
			t.Fatal(err)
		}
		proofRules = append(proofRules, contents...)
	}
	existing, err := report.ParseProofRuleAssertions(proofRules)
	if err != nil {
		t.Fatal(err)
	}
	unique := map[string]bool{}
	for language, claims := range labClaims {
		seen := map[string]bool{}
		for _, id := range claims {
			if !known[id] {
				t.Errorf("%s claims unknown feature %s", language, id)
			}
			if existing[id] != "" {
				t.Errorf("%s claims already-covered feature %s", language, id)
			}
			if seen[id] {
				t.Errorf("%s repeats feature %s", language, id)
			}
			seen[id], unique[id] = true, true
		}
	}
	for scenario, claims := range labVariantClaims {
		for _, id := range claims {
			if !known[id] || existing[id] != "" || unique[id] {
				t.Errorf("%s variant has invalid or overlapping claim %s", scenario, id)
			}
			unique[id] = true
		}
	}
	supplementalSource, err := readLabRunfile(paths[len(paths)-1])
	if err != nil {
		t.Fatal(err)
	}
	supplementalIDs := map[string]bool{}
	for _, match := range regexp.MustCompile(`"([a-z][a-z0-9.-]*\.[a-z0-9.-]+)"`).FindAllStringSubmatch(string(supplementalSource), -1) {
		supplementalIDs[match[1]] = true
	}
	newCount, overlap := 0, 0
	for id := range unique {
		if supplementalIDs[id] {
			overlap++
		} else {
			newCount++
		}
	}
	for id := range supplementalIDs {
		if known[id] && existing[id] == "" && !unique[id] {
			t.Errorf("supplemental feature %s has no telemetry lab proof", id)
		}
	}
	if len(unique) != 122 || overlap != 22 || newCount != 100 {
		t.Fatalf("lab claims: %d total, %d previously supplemental, %d new; want 122/22/100", len(unique), overlap, newCount)
	}
}
