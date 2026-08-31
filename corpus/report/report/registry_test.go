package report

import (
	"encoding/json"
	"flag"
	"os"
	"path/filepath"
	"testing"
)

func TestGeneratedStandardRegistryHasExactMatrixParity(t *testing.T) {
	args := flag.Args()
	if len(args) < 3 {
		t.Skip("registry runfile is supplied by Bazel")
	}
	runfile := func(path string) string {
		return filepath.Join(os.Getenv("TEST_SRCDIR"), os.Getenv("TEST_WORKSPACE"), path)
	}
	metadataBytes, err := os.ReadFile(runfile(args[0]))
	if err != nil {
		t.Fatal(err)
	}
	matrix, err := os.ReadFile(runfile(args[1]))
	if err != nil {
		t.Fatal(err)
	}
	registryBytes, err := os.ReadFile(runfile(args[2]))
	if err != nil {
		t.Fatal(err)
	}
	metadata, err := DecodeMetadata(metadataBytes)
	if err != nil {
		t.Fatal(err)
	}
	features, err := ImportMatrix(string(matrix), metadata.Source)
	if err != nil {
		t.Fatal(err)
	}
	var registry registryDocument
	if err := json.Unmarshal(registryBytes, &registry); err != nil {
		t.Fatal(err)
	}
	ids, bindings := map[string]bool{}, map[string]bool{}
	for _, entry := range registry.Features {
		if ids[entry.ID] {
			t.Fatalf("duplicate registry ID %q", entry.ID)
		}
		if entry.Binding == "" || bindings[entry.Binding] {
			t.Fatalf("empty or duplicate readable binding %q", entry.Binding)
		}
		ids[entry.ID], bindings[entry.Binding] = true, true
	}
	if len(ids) != len(features) {
		t.Fatalf("registry has %d IDs, matrix has %d", len(ids), len(features))
	}
	for _, feature := range features {
		if !ids[feature.ID] {
			t.Errorf("registry is missing %q", feature.ID)
		}
	}
}
