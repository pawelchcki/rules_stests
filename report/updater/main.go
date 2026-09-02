package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"time"

	"github.com/pawelchcki/rules_stests/report"
)

var revisionPattern = regexp.MustCompile(`^[0-9a-f]{40}$`)

const maxMatrixBytes = 4 << 20

func main() {
	var revision, matrixPath, metadataPath string
	flag.StringVar(&revision, "revision", "", "40-character opentelemetry-specification commit")
	flag.StringVar(&matrixPath, "matrix", "report/data/spec-compliance-matrix.md", "matrix snapshot output")
	flag.StringVar(&metadataPath, "metadata", "report/data/catalog.json", "catalog metadata to update")
	flag.Parse()
	if err := update(revision, matrixPath, metadataPath); err != nil {
		fmt.Fprintln(os.Stderr, "update feature catalog:", err)
		os.Exit(1)
	}
}

func update(revision, matrixPath, metadataPath string) error {
	if !revisionPattern.MatchString(revision) {
		return fmt.Errorf("--revision must be a lowercase 40-character commit SHA")
	}
	metadataBytes, err := os.ReadFile(metadataPath)
	if err != nil {
		return err
	}
	metadata, err := report.DecodeMetadata(metadataBytes)
	if err != nil {
		return err
	}
	rawURL := "https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/" + revision + "/spec-compliance-matrix.md"
	client := &http.Client{Timeout: 30 * time.Second}
	response, err := client.Get(rawURL)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("download %s: %s", rawURL, response.Status)
	}
	matrix, err := readMatrix(response.Body)
	if err != nil {
		return err
	}
	digest := sha256.Sum256(matrix)
	metadata.Source = report.CatalogSource{Revision: revision, URL: "https://github.com/open-telemetry/opentelemetry-specification/blob/" + revision + "/spec-compliance-matrix.md", RawURL: rawURL, SHA256: hex.EncodeToString(digest[:])}
	if _, err := report.ImportMatrix(string(matrix), metadata.Source); err != nil {
		return fmt.Errorf("refuse invalid snapshot: %w", err)
	}
	encoded, err := json.MarshalIndent(metadata, "", "  ")
	if err != nil {
		return err
	}
	encoded = append(encoded, '\n')
	if err := atomicWritePair(matrixPath, matrix, metadataPath, encoded); err != nil {
		return err
	}
	fmt.Printf("updated %s to %s (%s)\n", matrixPath, revision, metadata.Source.SHA256)
	return nil
}

func atomicWritePair(firstPath string, firstData []byte, secondPath string, secondData []byte) error {
	originalFirst, err := os.ReadFile(firstPath)
	if err != nil {
		return fmt.Errorf("read original %s: %w", firstPath, err)
	}
	if err := atomicWrite(firstPath, firstData); err != nil {
		return err
	}
	if err := atomicWrite(secondPath, secondData); err != nil {
		if restoreErr := atomicWrite(firstPath, originalFirst); restoreErr != nil {
			return fmt.Errorf("write %s: %v; restore %s: %w", secondPath, err, firstPath, restoreErr)
		}
		return err
	}
	return nil
}

func readMatrix(reader io.Reader) ([]byte, error) {
	matrix, err := io.ReadAll(io.LimitReader(reader, maxMatrixBytes+1))
	if err != nil {
		return nil, err
	}
	if len(matrix) > maxMatrixBytes {
		return nil, fmt.Errorf("matrix download exceeds %d bytes", maxMatrixBytes)
	}
	return matrix, nil
}

func atomicWrite(path string, data []byte) error {
	temporary := path + ".tmp"
	if err := os.WriteFile(temporary, data, 0o644); err != nil {
		return err
	}
	if err := os.Rename(temporary, path); err != nil {
		_ = os.Remove(temporary)
		return err
	}
	return nil
}
