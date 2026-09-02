package main

import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/pawelchcki/rules_stests/report"
)

type repeatedFlag []string

func (values *repeatedFlag) String() string         { return strings.Join(*values, ",") }
func (values *repeatedFlag) Set(value string) error { *values = append(*values, value); return nil }

func main() {
	var matrixPath, metadataPath, outputPath, profileList, scenarioList, revision, bepPath, manifestPath, sourceRoot, corpusSourceRoot, executionRoot string
	var planSpecs, shapeSpecs repeatedFlag
	flag.StringVar(&matrixPath, "matrix", "", "checked-in compliance matrix")
	flag.StringVar(&metadataPath, "metadata", "", "catalog metadata JSON")
	flag.StringVar(&outputPath, "out", "", "assembled report HTML")
	flag.StringVar(&profileList, "profiles", "", "comma-separated profiles")
	flag.StringVar(&scenarioList, "scenarios", "", "comma-separated scenarios")
	flag.StringVar(&revision, "revision", "", "current 40-character repository revision")
	flag.StringVar(&bepPath, "bep", "", "JSON build-event file from the uncached profile run")
	flag.StringVar(&manifestPath, "manifest", "", "corpus report manifest JSON")
	flag.StringVar(&sourceRoot, "source-root", "", "repository source URL prefix for manifest evidence")
	flag.StringVar(&corpusSourceRoot, "corpus-source-root", "", "pinned rules_stests source URL prefix for external manifest evidence")
	flag.StringVar(&executionRoot, "execution-root", "", "Bazel execution root for manifest artifact paths")
	flag.Var(&planSpecs, "plan", "profile,path,source URL (repeatable)")
	flag.Var(&shapeSpecs, "shape", "profile,scenario,path,source URL (repeatable)")
	flag.Parse()
	var profileScenarios map[string][]string
	if manifestPath != "" {
		profiles, scenarios, plans, shapes, memberships, err := loadReportManifest(manifestPath, sourceRoot, corpusSourceRoot)
		if err != nil {
			fmt.Fprintln(os.Stderr, "assemble feature report:", err)
			os.Exit(1)
		}
		profileList, scenarioList = strings.Join(profiles, ","), strings.Join(scenarios, ",")
		planSpecs, shapeSpecs = append(planSpecs, plans...), append(shapeSpecs, shapes...)
		profileScenarios = memberships
	}
	if err := run(matrixPath, metadataPath, outputPath, profileList, scenarioList, revision, bepPath, executionRoot, profileScenarios, planSpecs, shapeSpecs); err != nil {
		fmt.Fprintln(os.Stderr, "assemble feature report:", err)
		os.Exit(1)
	}
}

type reportManifestEntry struct {
	ID           string            `json:"id"`
	Repository   string            `json:"repository"`
	Spec         string            `json:"spec"`
	Plan         string            `json:"plan"`
	Scenarios    []string          `json:"scenarios"`
	Shapes       map[string]string `json:"shapes"`
	ShapeSources map[string]string `json:"shapeSources"`
}

func loadReportManifest(path, sourceRoot, corpusSourceRoot string) ([]string, []string, []string, []string, map[string][]string, error) {
	if sourceRoot == "" {
		return nil, nil, nil, nil, nil, fmt.Errorf("--source-root is required with --manifest")
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, nil, nil, nil, nil, err
	}
	var entries []reportManifestEntry
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&entries); err != nil {
		return nil, nil, nil, nil, nil, fmt.Errorf("decode report manifest: %w", err)
	}
	root := strings.TrimSuffix(sourceRoot, "/")
	corpusRoot := strings.TrimSuffix(corpusSourceRoot, "/")
	profiles, plans, shapes := make([]string, 0, len(entries)), make([]string, 0, len(entries)), []string{}
	scenarioSet, profileSet := map[string]bool{}, map[string]bool{}
	profileScenarios := make(map[string][]string, len(entries))
	for _, entry := range entries {
		if entry.ID == "" || entry.Spec == "" || entry.Plan == "" || profileSet[entry.ID] {
			return nil, nil, nil, nil, nil, fmt.Errorf("invalid or duplicate manifest profile %q", entry.ID)
		}
		profileSet[entry.ID] = true
		profiles = append(profiles, entry.ID)
		evidenceRoot := root
		if entry.Repository != "" {
			if entry.Repository != "rules_stests" {
				return nil, nil, nil, nil, nil, fmt.Errorf("profile %q uses unsupported external repository %q", entry.ID, entry.Repository)
			}
			if corpusRoot == "" {
				return nil, nil, nil, nil, nil, fmt.Errorf("--corpus-source-root is required for profile %q from repository %q", entry.ID, entry.Repository)
			}
			evidenceRoot = corpusRoot
		}
		plans = append(plans, strings.Join([]string{entry.ID, entry.Plan, evidenceRoot + "/" + filepath.ToSlash(entry.Spec)}, ","))
		declaredScenarios := map[string]bool{}
		for _, scenario := range entry.Scenarios {
			if scenario == "" {
				return nil, nil, nil, nil, nil, fmt.Errorf("profile %q has an empty scenario", entry.ID)
			}
			declaredScenarios[scenario] = true
			scenarioSet[scenario] = true
		}
		if len(declaredScenarios) == 0 {
			return nil, nil, nil, nil, nil, fmt.Errorf("profile %q has no declared scenarios", entry.ID)
		}
		profileScenarios[entry.ID] = make([]string, 0, len(declaredScenarios))
		for scenario := range declaredScenarios {
			profileScenarios[entry.ID] = append(profileScenarios[entry.ID], scenario)
		}
		sort.Strings(profileScenarios[entry.ID])
		scenarios := make([]string, 0, len(entry.Shapes))
		for scenario := range entry.Shapes {
			scenarios = append(scenarios, scenario)
			if !declaredScenarios[scenario] {
				return nil, nil, nil, nil, nil, fmt.Errorf("profile %q shape has undeclared scenario %q", entry.ID, scenario)
			}
			if entry.ShapeSources[scenario] == "" {
				return nil, nil, nil, nil, nil, fmt.Errorf("profile %q shape %q has no evidence source", entry.ID, scenario)
			}
		}
		for scenario := range entry.ShapeSources {
			if entry.Shapes[scenario] == "" {
				return nil, nil, nil, nil, nil, fmt.Errorf("profile %q has evidence for unknown shape %q", entry.ID, scenario)
			}
		}
		sort.Strings(scenarios)
		for _, scenario := range scenarios {
			shapePath := filepath.ToSlash(entry.Shapes[scenario])
			shapeSource := filepath.ToSlash(entry.ShapeSources[scenario])
			shapes = append(shapes, strings.Join([]string{entry.ID, scenario, shapePath, evidenceRoot + "/" + shapeSource}, ","))
		}
	}
	scenarios := make([]string, 0, len(scenarioSet))
	for scenario := range scenarioSet {
		scenarios = append(scenarios, scenario)
	}
	sort.Strings(scenarios)
	return profiles, scenarios, plans, shapes, profileScenarios, nil
}

func run(matrixPath, metadataPath, outputPath, profileList, scenarioList, revision, bepPath, executionRoot string, profileScenarios map[string][]string, planSpecs, shapeSpecs []string) error {
	if matrixPath == "" || metadataPath == "" || outputPath == "" || bepPath == "" {
		return fmt.Errorf("--matrix, --metadata, --out, and --bep are required")
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
	profiles, scenarios := commaList(profileList), commaList(scenarioList)

	plans := map[string]report.PlanArtifact{}
	evidencePaths := map[string]bool{}
	for _, spec := range planSpecs {
		parts := strings.SplitN(spec, ",", 3)
		if len(parts) != 3 {
			return fmt.Errorf("invalid --plan %q", spec)
		}
		readPath := executionPath(executionRoot, parts[1])
		data, readErr := os.ReadFile(readPath)
		if readErr != nil {
			return readErr
		}
		var plan report.NormalizedProfilePlan
		decoder := json.NewDecoder(bytes.NewReader(data))
		decoder.DisallowUnknownFields()
		if decodeErr := decoder.Decode(&plan); decodeErr != nil {
			return fmt.Errorf("%s: %w", parts[1], decodeErr)
		}
		if plan.SchemaVersion != 1 || plan.Profile != parts[0] {
			return fmt.Errorf("%s: normalized profile identity mismatch", parts[1])
		}
		if _, exists := plans[parts[0]]; exists {
			return fmt.Errorf("duplicate plan for %s", parts[0])
		}
		path := filepath.ToSlash(parts[1])
		evidencePaths[path] = true
		plans[parts[0]] = report.PlanArtifact{Plan: plan, Bytes: data, Source: report.Evidence{Label: "normalized proof plan", Href: parts[2], Path: path}}
	}

	shapeBytes := map[string][]byte{}
	var shapes []report.ScenarioShape
	for _, spec := range shapeSpecs {
		parts := strings.SplitN(spec, ",", 4)
		if len(parts) != 4 {
			return fmt.Errorf("invalid --shape %q", spec)
		}
		readPath := executionPath(executionRoot, parts[2])
		data, readErr := os.ReadFile(readPath)
		if readErr != nil {
			return readErr
		}
		key := parts[0] + "\x00" + parts[1]
		if _, exists := shapeBytes[key]; exists {
			return fmt.Errorf("duplicate shape %s/%s", parts[0], parts[1])
		}
		shapeBytes[key] = data
		shape, parseErr := report.ParseScenarioShape(parts[0], parts[1], parts[3], string(data))
		if parseErr != nil {
			return parseErr
		}
		shapes = append(shapes, shape)
	}
	receiptData, captures, err := collectBEP(bepPath)
	if err != nil {
		return err
	}
	receipts := make([]report.ValidationReceipt, 0, len(receiptData))
	for name, data := range receiptData {
		receipt, decodeErr := report.DecodeReceipt(data)
		if decodeErr != nil {
			return fmt.Errorf("%s: %w", name, decodeErr)
		}
		receipts = append(receipts, receipt)
	}
	var validationErr error
	if profileScenarios == nil {
		validationErr = report.ValidateReceiptSet(revision, profiles, scenarios, plans, shapeBytes, captures, receipts)
	} else {
		validationErr = report.ValidateReceiptSetForProfiles(revision, profiles, profileScenarios, plans, shapeBytes, captures, receipts)
	}
	if validationErr != nil {
		return validationErr
	}

	manifests := make([]report.Manifest, 0, len(profiles))
	for _, profile := range profiles {
		artifact := plans[profile]
		manifests = append(manifests, report.Manifest{SchemaVersion: 1, Profile: profile, DisplayName: artifact.Plan.DisplayName, Language: artifact.Plan.Language, Framework: artifact.Plan.Framework, InstrumentationVersion: strings.Join(artifact.Plan.Implementations, " + "), Version: report.FormatInstrumentationVersion(artifact.Plan.Implementations), ShortLabel: report.FormatProfileLabel(artifact.Plan.Language, artifact.Plan.Framework, artifact.Plan.Implementations), ProfileEvidence: []report.Evidence{artifact.Source}, BaseCoverage: "contract_only", DefaultVerification: "not_exercised"})
	}
	coverages := report.CoveragesFromPlans(plans, receipts)
	var model report.ReportModel
	if profileScenarios == nil {
		model, err = report.BuildModel(metadata, features, manifests, shapes, profiles, scenarios, evidencePaths, coverages...)
	} else {
		model, err = report.BuildModelForProfiles(metadata, features, manifests, shapes, profiles, scenarios, profileScenarios, evidencePaths, coverages...)
	}
	if err != nil {
		return err
	}
	sort.Slice(receipts, func(i, j int) bool {
		if receipts[i].Profile != receipts[j].Profile {
			return receipts[i].Profile < receipts[j].Profile
		}
		return receipts[i].Scenario < receipts[j].Scenario
	})
	model.Receipts = receipts
	html, err := report.RenderHTML(model)
	if err != nil {
		return err
	}
	return os.WriteFile(outputPath, html, 0o644)
}

func executionPath(root, path string) string {
	if root == "" || filepath.IsAbs(path) {
		return path
	}
	return filepath.Join(root, path)
}

func collectBEP(path string) (map[string][]byte, map[string][]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, nil, err
	}
	var files []string
	uncached := false
	decoder := json.NewDecoder(bytes.NewReader(data))
	for decoder.More() {
		var event any
		if err := decoder.Decode(&event); err != nil {
			return nil, nil, err
		}
		uncached = uncached || eventDisablesTestCache(event)
		collectURIs(event, &files)
	}
	if !uncached {
		return nil, nil, fmt.Errorf("build event file does not prove --nocache_test_results")
	}
	receipts, captures := map[string][]byte{}, map[string][]byte{}
	seenFiles := map[string]bool{}
	for _, path := range files {
		if seenFiles[path] {
			continue
		}
		seenFiles[path] = true
		if strings.HasSuffix(path, ".zip") {
			archive, openErr := zip.OpenReader(path)
			if openErr != nil {
				continue
			}
			for _, file := range archive.File {
				contents, readErr := readZip(file)
				if readErr != nil {
					archive.Close()
					return nil, nil, readErr
				}
				if err := addArtifact(file.Name, contents, receipts, captures); err != nil {
					archive.Close()
					return nil, nil, err
				}
			}
			archive.Close()
		} else if contents, readErr := os.ReadFile(path); readErr == nil {
			if err := addArtifact(path, contents, receipts, captures); err != nil {
				return nil, nil, err
			}
		}
	}
	return receipts, captures, nil
}

func eventDisablesTestCache(value any) bool {
	event, ok := value.(map[string]any)
	if !ok {
		return false
	}
	options, ok := event["optionsParsed"].(map[string]any)
	if !ok {
		return false
	}
	values, _ := options["cmdLine"].([]any)
	for _, value := range values {
		option, _ := value.(string)
		if option == "--nocache_test_results" || option == "--cache_test_results=0" || option == "--cache_test_results=false" {
			return true
		}
	}
	return false
}

func collectURIs(value any, out *[]string) {
	switch value := value.(type) {
	case map[string]any:
		for key, child := range value {
			if key == "uri" {
				if text, ok := child.(string); ok && strings.HasPrefix(text, "file://") {
					if parsed, err := url.Parse(text); err == nil {
						*out = append(*out, parsed.Path)
					}
				}
			}
			collectURIs(child, out)
		}
	case []any:
		for _, child := range value {
			collectURIs(child, out)
		}
	}
}

func readZip(file *zip.File) ([]byte, error) {
	reader, err := file.Open()
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	return io.ReadAll(reader)
}
func addArtifact(name string, data []byte, receipts, captures map[string][]byte) error {
	name = filepath.ToSlash(name)
	marker := "/receipts/"
	index := strings.Index("/"+name, marker)
	if index < 0 {
		return nil
	}
	relative := ("/" + name)[index+len(marker):]
	if strings.HasSuffix(relative, ".capture.json") {
		key := strings.TrimSuffix(relative, ".capture.json")
		normalized := strings.Replace(key, "/", "\x00", 1)
		if _, exists := captures[normalized]; exists {
			return fmt.Errorf("duplicate capture artifact %s", key)
		}
		captures[normalized] = data
		return nil
	}
	if strings.HasSuffix(relative, ".json") {
		key := strings.TrimSuffix(relative, ".json")
		if _, exists := receipts[key]; exists {
			return fmt.Errorf("duplicate receipt artifact %s", key)
		}
		receipts[key] = data
	}
	return nil
}

func commaList(value string) []string {
	if value == "" {
		return nil
	}
	result := strings.Split(value, ",")
	sort.Strings(result)
	return result
}
