package report

import "sort"

// PlannedCheck describes authored checks, independently of accepted verification.
type PlannedCheck struct {
	Profile         string           `json:"profile"`
	FeatureID       string           `json:"featureId"`
	Assertion       string           `json:"assertion"`
	Basis           string           `json:"basis"`
	Evidence        []Evidence       `json:"evidence"`
	Executions      []CheckExecution `json:"executions"`
	Passed          int              `json:"passed"`
	ExpectedFailure int              `json:"expectedFailure"`
	NoResult        int              `json:"noResult"`
}
type CheckExecution struct {
	Scenario string `json:"scenario"`
	Outcome  string `json:"outcome"`
	Reason   string `json:"reason,omitempty"`
}

// AddReportProjections must be called after receipt integrity validation. It
// never writes Verification: a planned check or a parity difference is no proof.
func AddReportProjections(model *ReportModel, plans map[string]PlanArtifact, captures map[string][]byte) {
	receipts := map[string]ValidationReceipt{}
	for _, r := range model.Receipts {
		receipts[r.Profile+"\x00"+r.Scenario] = r
	}
	for _, m := range model.Manifests {
		artifact := plans[m.Profile]
		for _, proof := range artifact.Plan.Proofs {
			check := PlannedCheck{Profile: m.Profile, FeatureID: proof.FeatureID, Assertion: proof.Assertion, Basis: proof.Basis, Evidence: []Evidence{artifact.Source}}
			for _, source := range proof.Sources {
				check.Evidence = append(check.Evidence, Evidence{Label: source, Href: artifact.Plan.Sources[source]})
			}
			for _, cell := range model.Coverage {
				if cell.Profile != m.Profile || !cell.Declared || (len(proof.Scenarios) > 0 && !stringSliceContains(proof.Scenarios, cell.Scenario)) {
					continue
				}
				execution := CheckExecution{Scenario: cell.Scenario, Outcome: "missing"}
				r := receipts[m.Profile+"\x00"+cell.Scenario]
				if r.Outcome == "xfail" {
					execution.Outcome, execution.Reason = "xfail", r.XFailReason
					check.ExpectedFailure++
				} else {
					for _, p := range r.Proofs {
						if p.FeatureID == proof.FeatureID && p.Assertion == proof.Assertion && p.Basis == proof.Basis && p.Result == "pass" && r.Outcome == "verified" {
							execution.Outcome = "verified"
							break
						}
					}
					if execution.Outcome == "verified" {
						check.Passed++
					} else {
						check.NoResult++
					}
				}
				check.Executions = append(check.Executions, execution)
			}
			model.PlannedChecks = append(model.PlannedChecks, check)
		}
	}
	for _, r := range model.Receipts {
		if raw, ok := captures[r.Profile+"\x00"+r.Scenario]; ok {
			model.Captures = append(model.Captures, DecodeCapture(r, raw))
		}
	}
	sort.Slice(model.Captures, func(i, j int) bool { return model.Captures[i].Key < model.Captures[j].Key })
	for i := range model.Captures {
		for j := i + 1; j < len(model.Captures); j++ {
			l, r := &model.Captures[i], &model.Captures[j]
			if l.Scenario != r.Scenario || len(l.Diagnostics) > 0 || len(r.Diagnostics) > 0 {
				continue
			}
			alignment := AlignShapes(&l.Shape, &r.Shape)
			comparison := CaptureComparison{Left: l.Key, Right: r.Key, Scenario: l.Scenario}
			for _, t := range alignment.Traces {
				trace := CaptureTraceMatch{Left: t.Left, Right: t.Right}
				for _, s := range t.Spans {
					row := CaptureSpanMatch{Depth: s.Depth}
					if s.Left != nil {
						row.Left = s.Left.Occurrences
					}
					if s.Right != nil {
						row.Right = s.Right.Occurrences
					}
					trace.Spans = append(trace.Spans, row)
				}
				comparison.Traces = append(comparison.Traces, trace)
			}
			model.CaptureComparisons = append(model.CaptureComparisons, comparison)
		}
	}
}
