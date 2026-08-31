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
