package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"sort"

	"github.com/pawelchcki/rules_stests/report"
)

func main() {
	language := flag.String("language", "", "lab language")
	output := flag.String("out", "", "plan output path")
	flag.Parse()
	claims, ok := labClaims[*language]
	if !ok || *output == "" {
		fmt.Fprintln(os.Stderr, "known --language and --out are required")
		os.Exit(2)
	}
	plan := report.NormalizedProfilePlan{
		SchemaVersion: 1,
		Profile:       *language + "-telemetry-lab",
		DisplayName:   *language + " standalone telemetry lab",
		Language:      *language,
		Framework:     "standalone",
		ServiceName:   *language + "-telemetry-lab",
		Sources:       map[string]string{},
	}
	switch *language {
	case "go":
		plan.Signals = []string{"traces", "metrics"}
		plan.Implementations = []string{"OpenTelemetry Go SDK 1.44.0"}
	case "python":
		plan.Signals = []string{"traces", "metrics", "logs"}
		plan.Implementations = []string{"OpenTelemetry Python SDK 1.44.0", "auto-instrumentation 0.65b0"}
	case "ruby":
		plan.Signals = []string{"traces"}
		plan.Implementations = []string{"OpenTelemetry Ruby SDK 1.11.0", "auto-instrumentation 0.1.0"}
	}
	appendProofs := func(scenario string, ids []string) {
		for _, id := range ids {
			plan.Proofs = append(plan.Proofs, report.ProofPlanProof{
				FeatureID:      id,
				Assertion:      "telemetry-lab/" + id,
				Basis:          "observed",
				EvidencePolicy: "lab-capture-and-response",
				Scenarios:      []string{scenario},
			})
		}
	}
	appendProofs("base", claims)
	if *language == "python" {
		scenarios := make([]string, 0, len(labVariantClaims))
		for scenario := range labVariantClaims {
			scenarios = append(scenarios, scenario)
		}
		sort.Strings(scenarios)
		for _, scenario := range scenarios {
			appendProofs(scenario, labVariantClaims[scenario])
		}
	}
	encoded, err := json.MarshalIndent(plan, "", "  ")
	if err != nil {
		panic(err)
	}
	if err := os.WriteFile(*output, append(encoded, '\n'), 0o644); err != nil {
		panic(err)
	}
}
