package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

// Paths are relative to the manifest and supplied as Bazel runfiles. Keeping
// source and bytecode identities separate detects stale compilation artifacts.
type compiledValidator struct {
	Path           string `json:"path"`
	SourceSHA256   string `json:"sourceSha256"`
	CompilerSHA256 string `json:"compilerSha256"`
	BytecodeSHA256 string `json:"bytecodeSha256"`
}

func digestBytes(data []byte) string { return fmt.Sprintf("%x", sha256.Sum256(data)) }

func compileProfile(input, output, directory, compiler string) error {
	data, err := os.ReadFile(input)
	if err != nil {
		return err
	}
	var manifest atomicProfileManifest
	if err = json.Unmarshal(data, &manifest); err != nil {
		return err
	}
	executable, err := os.ReadFile(compiler)
	if err != nil {
		return err
	}
	compiler, err = filepath.Abs(compiler)
	if err != nil {
		return err
	}
	if err = os.MkdirAll(directory, 0755); err != nil {
		return err
	}
	scratch, err := os.MkdirTemp("", "scheme-compile-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(scratch)
	manifest.CompiledValidators = map[string]compiledValidator{}
	for _, scenario := range manifest.Scenarios {
		profile, err := loadAtomicProfile(input, scenario, "validate")
		if err != nil {
			return err
		}
		source, err := readSchemeBundle(profile.Libraries, profile.Imports, profile.Program, scenario, profile.ValidationMode)
		if err != nil {
			return err
		}
		sourcePath := filepath.Join(scratch, scenario+".scm")
		if err = os.WriteFile(sourcePath, source, 0600); err != nil {
			return err
		}
		path := filepath.Join(directory, scenario+".sbc")
		start := time.Now()
		if result, err := exec.Command(compiler, "--compile", sourcePath, "--output", path).CombinedOutput(); err != nil {
			return fmt.Errorf("compile %s/%s: %w: %s", profile.ID, scenario, err, result)
		}
		fmt.Fprintf(os.Stderr, "compile %s/%s: %d ms\n", profile.ID, scenario, time.Since(start).Milliseconds())
		bytecode, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(filepath.Dir(output), path)
		if err != nil {
			return err
		}
		manifest.CompiledValidators[scenario] = compiledValidator{Path: relative, SourceSHA256: digestBytes(source), CompilerSHA256: digestBytes(executable), BytecodeSHA256: digestBytes(bytecode)}
	}
	data, err = json.Marshal(manifest)
	if err != nil {
		return err
	}
	return os.WriteFile(output, append(data, '\n'), 0644)
}

func loadCompiledValidator(manifestPath string, artifact compiledValidator, source []byte) ([]byte, error) {
	if artifact.Path == "" || filepath.IsAbs(artifact.Path) || !filepath.IsLocal(artifact.Path) ||
		!sha256Digest.MatchString(artifact.CompilerSHA256) || artifact.SourceSHA256 != digestBytes(source) || !sha256Digest.MatchString(artifact.BytecodeSHA256) {
		return nil, fmt.Errorf("compiled validator source/compiler identity mismatch")
	}
	bytecode, err := os.ReadFile(filepath.Join(filepath.Dir(manifestPath), artifact.Path))
	if err != nil {
		return nil, err
	}
	if len(bytecode) == 0 || digestBytes(bytecode) != artifact.BytecodeSHA256 {
		return nil, fmt.Errorf("compiled validator bytecode digest mismatch")
	}
	return bytecode, nil
}
