package main

import (
	"flag"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/pawelchcki/rules_stests/corpus/report"
)

type repeatedFlag []string

func (values *repeatedFlag) String() string         { return strings.Join(*values, ",") }
func (values *repeatedFlag) Set(value string) error { *values = append(*values, value); return nil }

func main() {
	var matrixPath, metadataPath, outputPath, profileList, scenarioList string
	var manifestPaths, goldenSpecs, evidenceRefs repeatedFlag
	flag.StringVar(&matrixPath, "matrix", "", "checked-in compliance matrix")
	flag.StringVar(&metadataPath, "metadata", "", "catalog metadata JSON")
	flag.StringVar(&outputPath, "out", "", "output HTML")
	flag.StringVar(&profileList, "profiles", "", "comma-separated REALWORLD_PROFILES")
	flag.StringVar(&scenarioList, "scenarios", "", "comma-separated RealWorld scenarios")
	flag.Var(&manifestPaths, "manifest", "implementation manifest JSON (repeatable)")
	flag.Var(&goldenSpecs, "golden", "profile,scenario,path,source URL (repeatable)")
	flag.Var(&evidenceRefs, "evidence-ref", "valid repository evidence path (repeatable)")
	flag.Parse()
	if err := run(matrixPath, metadataPath, outputPath, profileList, scenarioList, manifestPaths, goldenSpecs, evidenceRefs); err != nil {
		fmt.Fprintln(os.Stderr, "feature parity report:", err)
		os.Exit(1)
	}
}

func run(matrixPath, metadataPath, outputPath, profileList, scenarioList string, manifestPaths, goldenSpecs, evidenceRefs []string) error {
	if matrixPath == "" || metadataPath == "" || outputPath == "" {
		return fmt.Errorf("--matrix, --metadata, and --out are required")
	}
	matrix, err := os.ReadFile(matrixPath)
	if err != nil {
		return err
	}
	metadataBytes, err := os.ReadFile(metadataPath)
	if err != nil {
		return err
	}
	metadata, err := report.DecodeMetadata(metadataBytes)
	if err != nil {
		return err
	}
	if err := report.VerifyMatrixDigest(matrix, metadata.Source.SHA256); err != nil {
		return err
	}
	features, err := report.ImportMatrix(string(matrix), metadata.Source)
	if err != nil {
		return err
	}
	var manifests []report.Manifest
	for _, path := range manifestPaths {
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		manifest, err := report.DecodeManifest(data)
		if err != nil {
			return fmt.Errorf("%s: %w", path, err)
		}
		manifests = append(manifests, manifest)
	}
	var goldens []report.Golden
	for _, spec := range goldenSpecs {
		parts := strings.SplitN(spec, ",", 4)
		if len(parts) != 4 {
			return fmt.Errorf("invalid --golden %q", spec)
		}
		data, err := os.ReadFile(parts[2])
		if err != nil {
			return err
		}
		golden, err := report.ParseGolden(parts[0], parts[1], parts[3], string(data))
		if err != nil {
			return err
		}
		goldens = append(goldens, golden)
	}
	sort.Slice(goldens, func(i, j int) bool {
		if goldens[i].Scenario != goldens[j].Scenario {
			return goldens[i].Scenario < goldens[j].Scenario
		}
		return goldens[i].Profile < goldens[j].Profile
	})
	evidence := map[string]bool{}
	for _, path := range evidenceRefs {
		evidence[path] = true
	}
	model, err := report.BuildModel(metadata, features, manifests, goldens, commaList(profileList), commaList(scenarioList), evidence)
	if err != nil {
		return err
	}
	html, err := report.RenderHTML(model)
	if err != nil {
		return err
	}
	if err := os.WriteFile(outputPath, html, 0o644); err != nil {
		return err
	}
	return nil
}

func commaList(value string) []string {
	if value == "" {
		return nil
	}
	return strings.Split(value, ",")
}
