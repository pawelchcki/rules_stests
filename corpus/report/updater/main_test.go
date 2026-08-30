package main

import (
	"bytes"
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
