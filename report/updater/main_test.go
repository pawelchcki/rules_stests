package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestReadMatrixAcceptsSizeLimit(t *testing.T) {
	want := bytes.Repeat([]byte("x"), maxMatrixBytes)
	got, err := readMatrix(bytes.NewReader(want))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, want) {
		t.Fatal("matrix changed while reading")
	}
}

func TestReadMatrixRejectsOversizeDownload(t *testing.T) {
	_, err := readMatrix(bytes.NewReader(bytes.Repeat([]byte("x"), maxMatrixBytes+1)))
	if err == nil || !strings.Contains(err.Error(), "exceeds") {
		t.Fatalf("expected oversize error, got %v", err)
	}
}

func TestAtomicWritePairRestoresFirstFile(t *testing.T) {
	directory := t.TempDir()
	matrixPath := filepath.Join(directory, "matrix.md")
	if err := os.WriteFile(matrixPath, []byte("old matrix"), 0o644); err != nil {
		t.Fatal(err)
	}
	metadataPath := filepath.Join(directory, "metadata.json")
	if err := os.Mkdir(metadataPath, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := atomicWritePair(matrixPath, []byte("new matrix"), metadataPath, []byte("new metadata")); err == nil {
		t.Fatal("expected metadata replacement to fail")
	}
	matrix, err := os.ReadFile(matrixPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(matrix) != "old matrix" {
		t.Fatalf("matrix was not restored: %q", matrix)
	}
}
