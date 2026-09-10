package main

import (
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/pawelchcki/rules_stests/report"
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

func TestLoadReportManifestDerivesLegacyInputs(t *testing.T) {
	path := filepath.Join(t.TempDir(), "manifest.json")
	manifest := `[
  {"id":"go-profile","repository":"rules_stests","spec":"corpus/realworld/profile/go-profile.scm","plan":"bazel-out/go.proof-plan.json","scenarios":["articles","tags"],"shapes":{"tags":"external/rules_stests+/corpus/realworld/shape/go-profile/tags.scm","articles":"external/rules_stests+/corpus/realworld/shape/go-profile/articles.scm"},"shapeSources":{"tags":"corpus/realworld/shape/go-profile/tags.scm","articles":"corpus/realworld/shape/go-profile/articles.scm"}},
  {"id":"python-profile","repository":"","spec":"profile/python-profile.scm","plan":"bazel-out/python.proof-plan.json","scenarios":["articles","auth","tags"],"shapes":{"tags":"shape/python-profile/tags.scm"},"shapeSources":{"tags":"shape/python-profile/tags.scm"}},
  {"id":"contract-profile","repository":"","spec":"profile/contract-profile.scm","plan":"bazel-out/contract.proof-plan.json","scenarios":["comments"],"shapes":{},"shapeSources":{},"unavailable":true}
]`
	if err := os.WriteFile(path, []byte(manifest), 0o644); err != nil {
		t.Fatal(err)
	}
	profiles, scenarios, plans, shapes, profileScenarios, unavailableProfiles, err := loadReportManifest(path, "https://example.test/consumer/", "https://example.test/corpus/")
	if err != nil {
		t.Fatal(err)
	}
	if got := strings.Join(profiles, ","); got != "go-profile,python-profile,contract-profile" {
		t.Fatalf("profiles = %q", got)
	}
	if got := strings.Join(scenarios, ","); got != "articles,auth,comments,tags" {
		t.Fatalf("scenarios = %q", got)
	}
	if got := strings.Join(profileScenarios["go-profile"], ","); got != "articles,tags" {
		t.Fatalf("go-profile scenarios = %q", got)
	}
	if got := strings.Join(profileScenarios["contract-profile"], ","); got != "comments" {
		t.Fatalf("contract-profile scenarios = %q", got)
	}
	if !unavailableProfiles["contract-profile"] || unavailableProfiles["go-profile"] {
		t.Fatalf("unexpected unavailable profiles: %#v", unavailableProfiles)
	}
	if got := strings.Join(plans, "\n"); !strings.Contains(got, "go-profile,bazel-out/go.proof-plan.json,https://example.test/corpus/corpus/realworld/profile/go-profile.scm") || !strings.Contains(got, "python-profile,bazel-out/python.proof-plan.json,https://example.test/consumer/profile/python-profile.scm") {
		t.Fatalf("plans = %q", got)
	}
	if got := strings.Join(shapes, "\n"); !strings.Contains(got, "go-profile,articles,external/rules_stests+/corpus/realworld/shape/go-profile/articles.scm,https://example.test/corpus/corpus/realworld/shape/go-profile/articles.scm") {
		t.Fatalf("shapes = %q", got)
	}
	if _, _, _, _, _, _, err := loadReportManifest(path, "", "https://example.test/corpus"); err == nil || !strings.Contains(err.Error(), "source-root") {
		t.Fatalf("missing source root was accepted: %v", err)
	}
	if _, _, _, _, _, _, err := loadReportManifest(path, "https://example.test/consumer", ""); err == nil || !strings.Contains(err.Error(), "corpus-source-root") {
		t.Fatalf("missing corpus source root was accepted: %v", err)
	}
	unsupportedPath := filepath.Join(t.TempDir(), "manifest.json")
	unsupported := strings.Replace(manifest, `"repository":"rules_stests"`, `"repository":"third_party+"`, 1)
	if err := os.WriteFile(unsupportedPath, []byte(unsupported), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, _, _, _, _, _, err := loadReportManifest(unsupportedPath, "https://example.test/consumer", "https://example.test/corpus"); err == nil || !strings.Contains(err.Error(), "unsupported external repository") {
		t.Fatalf("unsupported external repository was accepted: %v", err)
	}
}

func TestValidateUnavailableProfilesRequiresAnExplicitManifestDeclaration(t *testing.T) {
	if err := validateUnavailableProfiles([]string{"go"}, []string{"ruby"}, map[string]bool{"ruby": true}); err != nil {
		t.Fatalf("declared unavailable profile was rejected: %v", err)
	}
	if err := validateUnavailableProfiles([]string{"go"}, []string{"ruby"}, nil); err == nil || !strings.Contains(err.Error(), "declare it unavailable") {
		t.Fatalf("undeclared missing profile was accepted: %v", err)
	}
	if err := validateUnavailableProfiles([]string{"go"}, nil, map[string]bool{"go": true}); err == nil || !strings.Contains(err.Error(), "produced receipts") {
		t.Fatalf("stale unavailable declaration was accepted: %v", err)
	}
}

func TestExecutionPathResolvesManifestArtifactsFromExecRoot(t *testing.T) {
	root := filepath.Join("tmp", "execroot")
	if got, want := executionPath(root, "external/rules_stests+/shape.scm"), filepath.Join(root, "external/rules_stests+/shape.scm"); got != want {
		t.Fatalf("execution path = %q, want %q", got, want)
	}
	absolute := filepath.Join(string(filepath.Separator), "tmp", "shape.scm")
	if got := executionPath(root, absolute); got != absolute {
		t.Fatalf("absolute execution path = %q", got)
	}
}

func TestLegacyCoverageWithholdsClaimsWithoutReceipts(t *testing.T) {
	proof := report.ProofPlanProof{FeatureID: "traces.span.end", Basis: "observed", Assertion: "span/all-completed"}
	plans := map[string]report.PlanArtifact{
		"exercised":   {Plan: report.NormalizedProfilePlan{Profile: "exercised", Proofs: []report.ProofPlanProof{proof}}},
		"unexercised": {Plan: report.NormalizedProfilePlan{Profile: "unexercised", Proofs: []report.ProofPlanProof{proof}}},
	}
	receipts := []report.ValidationReceipt{{Profile: "exercised", Scenario: "articles", Outcome: "verified"}}
	coverages := coveragesForInvocation(plans, receipts, []string{"exercised", "unexercised"}, []string{"articles"}, nil)
	if len(coverages) != 2 || len(coverages[0].Claims) != 1 || len(coverages[1].Claims) != 0 {
		t.Fatalf("legacy coverage trusted a plan without receipts: %#v", coverages)
	}
}

// Exercise the actual assembly boundary, including digest validation and the
// embedded JSON, for both manifest membership and the legacy Cartesian suite.
func TestRunRendersDeclaredMembershipAndReceiptOutcomes(t *testing.T) {
	for _, limited := range []bool{false, true} {
		t.Run(fmt.Sprintf("limited=%t", limited), func(t *testing.T) {
			root := t.TempDir()
			write := func(name string, data []byte) string {
				path := filepath.Join(root, name)
				if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
					t.Fatal(err)
				}
				if err := os.WriteFile(path, data, 0o644); err != nil {
					t.Fatal(err)
				}
				return path
			}
			marshal := func(v any) []byte {
				b, err := json.Marshal(v)
				if err != nil {
					t.Fatal(err)
				}
				return b
			}
			digest := func(b []byte) string { return fmt.Sprintf("%x", sha256.Sum256(b)) }
			revision := strings.Repeat("a", 40)
			matrix := []byte("## Traces\n| Feature | Go | Python | Ruby |\n| --- | --- | --- | --- |\n| End | + | + | + |\n")
			metadata := report.CatalogMetadata{SchemaVersion: 1, Source: report.CatalogSource{Revision: revision, URL: "https://example.test/matrix", RawURL: "https://example.test/raw", SHA256: digest(matrix)}, MaturitySource: "https://example.test/maturity", Maturity: map[string]report.SignalMaturity{}}
			for _, language := range []string{"go", "python", "ruby"} {
				metadata.Maturity[language] = report.SignalMaturity{Traces: "stable", Metrics: "stable", Logs: "stable"}
			}
			var specs []string
			var uris []map[string]string
			for _, profile := range []string{"go", "python"} {
				plan := report.NormalizedProfilePlan{SchemaVersion: 1, Profile: profile, DisplayName: profile, Language: profile, Framework: "fixture", Implementations: []string{"fixture@1"}, Proofs: []report.ProofPlanProof{{FeatureID: "traces.end", Basis: "observed", Assertion: "span/all-completed"}}}
				planBytes := marshal(plan)
				planPath := write(profile+".plan.json", planBytes)
				specs = append(specs, profile+","+planPath+",https://example.test/plan")
				// Go is explicitly unavailable, with a plan but no receipts.
				if profile == "go" {
					continue
				}
				for _, scenario := range []string{"case", "failure"} {
					capture := []byte("capture " + scenario)
					r := report.ValidationReceipt{SchemaVersion: 1, Revision: revision, Profile: profile, Scenario: scenario, ProofPlanSHA256: digest(planBytes), CaptureSHA256: digest(capture), ValidationMode: "contract", Outcome: "verified", Proofs: []report.ReceiptProof{{FeatureID: "traces.end", Assertion: "span/all-completed", Basis: "observed", Result: "pass"}}}
					if scenario == "failure" {
						r.Outcome, r.XFailReason, r.Proofs = "xfail", "fixture", nil
					}
					for name, contents := range map[string][]byte{scenario + ".json": marshal(r), scenario + ".capture.json": capture} {
						uris = append(uris, map[string]string{"uri": "file://" + write("receipts/"+profile+"/"+name, contents)})
					}
				}
			}
			bep := marshal(map[string]any{"optionsParsed": map[string]any{"cmdLine": []string{"--nocache_test_results"}}, "outputs": uris})
			var membership map[string][]string
			if limited {
				membership = map[string][]string{"go": {"case"}, "python": {"case", "failure"}}
			}
			out := filepath.Join(root, "report.html")
			if err := run(write("matrix.md", matrix), write("metadata.json", marshal(metadata)), out, "go,python", "case,failure", revision, write("bep.json", bep), "", membership, map[string]bool{"go": true}, specs, nil); err != nil {
				t.Fatal(err)
			}
			html, err := os.ReadFile(out)
			if err != nil {
				t.Fatal(err)
			}
			_, embedded, ok := strings.Cut(string(html), `id="report-data">`)
			if !ok {
				t.Fatal("missing embedded report")
			}
			embedded, _, _ = strings.Cut(embedded, "</script>")
			compressed, err := base64.StdEncoding.DecodeString(embedded)
			if err != nil {
				t.Fatal(err)
			}
			reader, err := gzip.NewReader(bytes.NewReader(compressed))
			if err != nil {
				t.Fatal(err)
			}
			decoded, err := io.ReadAll(reader)
			if err != nil {
				t.Fatal(err)
			}
			if err := reader.Close(); err != nil {
				t.Fatal(err)
			}
			var model report.ReportModel
			if err := json.Unmarshal(decoded, &model); err != nil {
				t.Fatal(err)
			}
			for _, cell := range model.Coverage {
				want := !(limited && cell.Profile == "go" && cell.Scenario == "failure")
				if cell.Declared != want {
					t.Fatalf("coverage membership = %#v", cell)
				}
			}
			if got := model.Verification["traces.end"]["python"]; got.State != "verified" || strings.Join(got.Scenarios, ",") != "case" {
				t.Fatalf("xfail counted as proof: %#v", got)
			}
			if model.Verification["traces.end"]["go"].State != "not_exercised" {
				t.Fatal("plan without receipts verified")
			}
			if len(model.Receipts) != 2 || model.Receipts[1].Outcome != "xfail" {
				t.Fatalf("missing run results: %#v", model.Receipts)
			}
			if len(model.PlannedChecks) != 2 || model.PlannedChecks[1].Passed != 1 || model.PlannedChecks[1].ExpectedFailure != 1 {
				t.Fatalf("missing planned checks or mixed outcomes: %+v", model.PlannedChecks)
			}
			wantedUnrun := 2
			if limited {
				wantedUnrun = 1
			}
			if model.PlannedChecks[0].NoResult != wantedUnrun {
				t.Fatal("unavailable profile lost declared check scope")
			}
			if len(model.Captures) != 2 || len(model.Captures[0].Diagnostics) == 0 {
				t.Fatal("unreadable capture should remain a comparison diagnostic")
			}
			// Integrity failure must stop assembly before readability diagnostics.
			write("receipts/python/case.capture.json", []byte("tampered"))
			if err := run(filepath.Join(root, "matrix.md"), filepath.Join(root, "metadata.json"), out, "go,python", "case,failure", revision, filepath.Join(root, "bep.json"), "", membership, map[string]bool{"go": true}, specs, nil); err == nil || !strings.Contains(err.Error(), "capture digest mismatch") {
				t.Fatalf("capture corruption passed trust boundary: %v", err)
			}
			if strings.Contains(string(html), "<script src=") || strings.Contains(string(html), "<link rel=") {
				t.Fatal("report has external assets")
			}
		})
	}
}
