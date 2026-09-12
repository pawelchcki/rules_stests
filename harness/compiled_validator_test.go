package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCompiledValidatorRejectsArtifactMutations(t *testing.T) {
	dir := t.TempDir()
	source, code := []byte("(read)"), []byte{1, 2, 3}
	if err := os.WriteFile(filepath.Join(dir, "validator.sbc"), code, 0600); err != nil {
		t.Fatal(err)
	}
	original := compiledValidator{Path: "validator.sbc", SourceSHA256: digestBytes(source), CompilerSHA256: strings.Repeat("a", 64), BytecodeSHA256: digestBytes(code)}
	if _, err := loadCompiledValidator(filepath.Join(dir, "manifest.json"), original, source); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"source", "compiler", "bytecode", "escape", "missing"} {
		t.Run(name, func(t *testing.T) {
			artifact := original
			switch name {
			case "source":
				artifact.SourceSHA256 = digestBytes([]byte("(write 1)"))
			case "compiler":
				artifact.CompilerSHA256 = "wrong"
			case "bytecode":
				artifact.BytecodeSHA256 = strings.Repeat("b", 64)
			case "escape":
				artifact.Path = "../validator.sbc"
			case "missing":
				artifact.Path = "absent.sbc"
			}
			if _, err := loadCompiledValidator(filepath.Join(dir, "manifest.json"), artifact, source); err == nil {
				t.Fatal("accepted mutated artifact")
			}
		})
	}
}
