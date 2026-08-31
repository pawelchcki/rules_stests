package report

import (
	"flag"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func testSource() CatalogSource {
	return CatalogSource{Revision: strings.Repeat("a", 40), URL: "https://example.test/matrix", RawURL: "https://example.test/raw", SHA256: strings.Repeat("0", 64)}
}

func TestImportMatrix(t *testing.T) {
	matrix := `## Traces
| Feature | Optional | Go | Python |
| --- | --- | --- | --- |
| [Span](specification/trace/api.md#span) | Optional | Go | Python |
| Create root span | | + | - |
| A [linked](specification/linked.md) claim with code | X | N/A | |

## Environment Variables
| Feature | Go | Python |
| --- | --- | --- |
| OTEL_SDK_DISABLED | - | + |
`
	features, err := ImportMatrix(matrix, testSource())
	if err != nil {
		t.Fatal(err)
	}
	if len(features) != 3 {
		t.Fatalf("got %d features", len(features))
	}
	if features[0].ID != "traces.span.create-root-span" {
		t.Fatalf("unexpected ID %q", features[0].ID)
	}
	if features[0].Support["go"] != "supported" || features[0].Support["python"] != "unsupported" {
		t.Fatalf("unexpected support: %#v", features[0].Support)
	}
	if features[1].Support["go"] != "n/a" || features[1].Support["python"] != "unknown" {
		t.Fatalf("unexpected support: %#v", features[1].Support)
	}
	if features[1].Name != "A linked claim with code" {
		t.Fatalf("markdown was not normalized: %q", features[1].Name)
	}
	if cleanMarkdown("A `code` value") != "A code value" {
		t.Fatal("inline code was not normalized")
	}
	if features[0].Source != "https://example.test/matrix#L5" {
		t.Fatalf("feature source does not identify its pinned row: %s", features[0].Source)
	}
}

func TestImportMatrixRejectsDuplicateFeatureIDs(t *testing.T) {
	matrix := `## Traces
| Feature | Go | Python |
| --- | --- | --- |
| Same name | + | + |
| Same name | + | + |
`
	if _, err := ImportMatrix(matrix, testSource()); err == nil || !strings.Contains(err.Error(), "duplicate feature id") {
		t.Fatalf("expected duplicate error, got %v", err)
	}
}

func TestImportMatrixPreservesEscapedPipes(t *testing.T) {
	matrix := `## Traces
| Feature | Optional | Go | Python |
| --- | --- | --- | --- |
| Emit A \| B | | + | - |
`
	features, err := ImportMatrix(matrix, testSource())
	if err != nil {
		t.Fatal(err)
	}
	if len(features) != 1 || features[0].Name != "Emit A | B" {
		t.Fatalf("escaped pipe changed the feature cell: %#v", features)
	}
	if features[0].Support["go"] != "supported" || features[0].Support["python"] != "unsupported" {
		t.Fatalf("escaped pipe shifted support columns: %#v", features[0].Support)
	}
}

func TestCheckedInCatalogImportsEveryCategory(t *testing.T) {
	args := flag.Args()
	if len(args) < 2 {
		t.Fatalf("expected catalog and matrix runfiles, got %q", args)
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
	metadata, err := DecodeMetadata(metadataBytes)
	if err != nil {
		t.Fatal(err)
	}
	if err := VerifyMatrixDigest(matrix, metadata.Source.SHA256); err != nil {
		t.Fatal(err)
	}
	features, err := ImportMatrix(string(matrix), metadata.Source)
	if err != nil {
		t.Fatal(err)
	}
	categories := map[string]bool{}
	for _, feature := range features {
		categories[feature.Category] = true
	}
	if len(features) != 326 || len(categories) != 12 {
		t.Fatalf("checked-in catalog changed unexpectedly: %d features, %d categories", len(features), len(categories))
	}
}
