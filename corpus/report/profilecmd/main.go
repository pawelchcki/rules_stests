package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/pawelchcki/rules_stests/corpus/report"
)

type repeated []string

func (values *repeated) String() string         { return fmt.Sprint([]string(*values)) }
func (values *repeated) Set(value string) error { *values = append(*values, value); return nil }

func main() {
	var profilePath, registryPath, captureShapesPath, outputPath, manifestPath, profileID, programPath string
	var implementationPaths, proofRulePaths, libraryPaths, importNames, signals, scenarios, shapeSpecs repeated
	flag.StringVar(&profilePath, "profile", "", "Scheme profile")
	flag.StringVar(&registryPath, "registry", "", "standard registry JSON")
	flag.Var(&proofRulePaths, "proof-rules", "Scheme proof table (repeatable)")
	flag.StringVar(&captureShapesPath, "capture-shapes", "", "Scheme capture-shape registry")
	flag.StringVar(&outputPath, "out", "", "normalized plan output")
	flag.StringVar(&manifestPath, "manifest-out", "", "atomic profile manifest output")
	flag.StringVar(&profileID, "profile-id", "", "profile identity")
	flag.StringVar(&programPath, "program", "", "validation program")
	flag.Var(&implementationPaths, "implementation", "implementation layer (repeatable)")
	flag.Var(&libraryPaths, "library", "Scheme library to embed (repeatable)")
	flag.Var(&importNames, "import", "Scheme library import (repeatable)")
	flag.Var(&signals, "signal", "required signal (repeatable)")
	flag.Var(&scenarios, "scenario", "valid workload scenario (repeatable)")
	flag.Var(&shapeSpecs, "shape", "scenario,path exact shape (repeatable)")
	flag.Parse()
	profile, err := os.ReadFile(profilePath)
	if err != nil {
		fail(err)
	}
	registry, err := os.ReadFile(registryPath)
	if err != nil {
		fail(err)
	}
	var rules []byte
	for _, path := range proofRulePaths {
		contents, readErr := os.ReadFile(path)
		if readErr != nil {
			fail(readErr)
		}
		rules = append(rules, contents...)
		rules = append(rules, '\n')
	}
	captureShapes, err := os.ReadFile(captureShapesPath)
	if err != nil {
		fail(err)
	}
	implementations := make([]string, 0, len(implementationPaths))
	for _, path := range implementationPaths {
		contents, readErr := os.ReadFile(path)
		if readErr != nil {
			fail(readErr)
		}
		implementations = append(implementations, string(contents))
	}
	plan, err := report.CompileNormalizedProfile(string(profile), implementations, registry, rules, captureShapes, scenarios)
	if err != nil {
		fail(err)
	}
	if plan.Profile != profileID {
		fail(fmt.Errorf("profile id %q does not match target id %q", plan.Profile, profileID))
	}
	if !sameStrings(plan.Signals, signals) {
		fail(fmt.Errorf("profile signals %v do not match target signals %v", plan.Signals, []string(signals)))
	}
	encoded, err := json.MarshalIndent(plan, "", "  ")
	if err != nil {
		fail(err)
	}
	encoded = append(encoded, '\n')
	if err := os.WriteFile(outputPath, encoded, 0o644); err != nil {
		fail(err)
	}
	if manifestPath != "" {
		libraries := make([]string, 0, len(libraryPaths))
		for _, path := range libraryPaths {
			contents, readErr := os.ReadFile(path)
			if readErr != nil {
				fail(readErr)
			}
			libraries = append(libraries, string(contents))
		}
		program, readErr := os.ReadFile(programPath)
		if readErr != nil {
			fail(readErr)
		}
		shapes := map[string]string{}
		knownScenarios := map[string]bool{}
		for _, scenario := range scenarios {
			knownScenarios[scenario] = true
		}
		for _, spec := range shapeSpecs {
			parts := strings.SplitN(spec, ",", 2)
			if len(parts) != 2 {
				fail(fmt.Errorf("invalid --shape %q", spec))
			}
			contents, shapeErr := os.ReadFile(parts[1])
			if shapeErr != nil {
				fail(shapeErr)
			}
			if _, exists := shapes[parts[0]]; exists {
				fail(fmt.Errorf("duplicate shape %q", parts[0]))
			}
			if !knownScenarios[parts[0]] {
				fail(fmt.Errorf("shape has unknown scenario %q", parts[0]))
			}
			shapes[parts[0]] = string(contents)
		}
		document := struct {
			SchemaVersion  int               `json:"schemaVersion"`
			Profile        string            `json:"profile"`
			Signals        []string          `json:"signals"`
			ProofPlan      string            `json:"proofPlan"`
			Program        string            `json:"program"`
			Libraries      []string          `json:"libraries"`
			Imports        []string          `json:"imports"`
			ScenarioShapes map[string]string `json:"scenarioShapes"`
		}{1, profileID, signals, string(encoded), string(program), libraries, importNames, shapes}
		manifest, marshalErr := json.Marshal(document)
		if marshalErr != nil {
			fail(marshalErr)
		}
		manifest = append(manifest, '\n')
		if writeErr := os.WriteFile(manifestPath, manifest, 0o644); writeErr != nil {
			fail(writeErr)
		}
	}
}

func sameStrings(left []string, right repeated) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}

func fail(err error) { fmt.Fprintln(os.Stderr, "profile compiler:", err); os.Exit(1) }
