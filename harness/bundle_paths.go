package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func resolveDirectory(value string) (string, error) {
	candidates := []string{value}
	if runfiles := os.Getenv("RUNFILES_DIR"); runfiles != "" {
		candidates = append(candidates, filepath.Join(runfiles, value))
	}
	if testSrcdir := os.Getenv("TEST_SRCDIR"); testSrcdir != "" {
		candidates = append(candidates, filepath.Join(testSrcdir, value))
	}
	if executable, err := os.Executable(); err == nil {
		candidates = append(candidates, filepath.Join(executable+".runfiles", value))
	}
	for _, candidate := range candidates {
		if info, err := os.Stat(candidate); err == nil && info.IsDir() {
			return filepath.Abs(candidate)
		}
	}
	return "", fmt.Errorf("directory %q is not present in runfiles", value)
}

func safePath(root, name string) (string, error) {
	clean := filepath.Clean(filepath.FromSlash(name))
	if clean == "." || filepath.IsAbs(clean) || clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("unsafe layer path %q", name)
	}
	path := filepath.Join(root, clean)
	relative, err := filepath.Rel(root, path)
	if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("layer path escapes root: %q", name)
	}
	return path, nil
}
