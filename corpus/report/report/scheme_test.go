package report

import (
	"strings"
	"testing"
)

const sampleScenarioShape = `(define-library (realworld shape sample case)
  (export scenario-shape)
  (import (scheme base))
  (begin
    (define scenario-shape
      (traces
        (repeat 2 (trace (coverage 'complete)
          (unordered
            (span (scope "server") (kind 'server) (status 'unset)
              (name (exact "GET /items")) (http-status 200)
              (children (unordered
                (repeat 3 (span (scope "db") (kind 'client) (status 'error)
                  (name (prefix-suffix "SELECT " "items")) (http-status 'absent)))))))))))
  ))`

func TestParseScenarioShapeAggregatesRepeatedTrees(t *testing.T) {
	shape, err := ParseScenarioShape("profile", "case", "source", sampleScenarioShape)
	if err != nil {
		t.Fatal(err)
	}
	if shape.TraceCount != 2 || shape.SpanCount != 8 {
		t.Fatalf("got %d traces, %d spans", shape.TraceCount, shape.SpanCount)
	}
	if !shape.ExactCounts {
		t.Fatal("repeat-only shape should have exact counts")
	}
	if shape.Scopes["server"] != 2 || shape.Scopes["db"] != 6 {
		t.Fatalf("unexpected scopes %#v", shape.Scopes)
	}
	if shape.Statuses["unset"] != 2 || shape.Statuses["error"] != 6 {
		t.Fatalf("unexpected statuses %#v", shape.Statuses)
	}
	child := shape.Traces[0].Roots[0].Span.Children[0]
	if child.Count != 3 || !strings.Contains(child.Span.Name, "SELECT") {
		t.Fatalf("unexpected child %#v", child)
	}
}

func TestParseScenarioShapeSupportsAllCardinalityWrappers(t *testing.T) {
	input := `(define scenario-shape
  (traces
    (optional (trace (coverage 'complete)
      (unordered (optional (span (scope "server") (kind 'server) (status 'unset) (name "optional"))))))
    (between 2 4 (trace (coverage 'complete)
      (unordered (between 1 3 (span (scope "server") (kind 'server) (status 'unset) (name "between"))))))
    (one-of
      (trace (coverage 'complete) (unordered (span (scope "a") (kind 'server) (status 'unset) (name "a"))))
      (repeat 2 (trace (coverage 'complete) (unordered (span (scope "b") (kind 'server) (status 'unset) (name "b"))))))))`
	shape, err := ParseScenarioShape("profile", "case", "source", input)
	if err != nil {
		t.Fatal(err)
	}
	if shape.ExactCounts {
		t.Fatal("variable cardinalities must not be reported as exact counts")
	}
	if len(shape.Traces) != 3 || shape.Traces[0].Cardinality != "optional" {
		t.Fatalf("unexpected optional trace %#v", shape.Traces)
	}
	if shape.Traces[1].MinCount != 2 || shape.Traces[1].MaxCount != 4 {
		t.Fatalf("unexpected between trace %#v", shape.Traces[1])
	}
	if len(shape.Traces[2].Alternatives) != 2 {
		t.Fatalf("unexpected one-of trace %#v", shape.Traces[2])
	}
	if shape.Traces[0].Roots[0].Cardinality != "optional" || shape.Traces[1].Roots[0].MaxCount != 3 {
		t.Fatalf("span cardinalities were not preserved: %#v %#v", shape.Traces[0].Roots[0], shape.Traces[1].Roots[0])
	}
}

func TestParseScenarioShapeAcceptsZeroRepeat(t *testing.T) {
	input := `(define scenario-shape
  (traces (repeat 0 (trace (coverage 'complete)
    (unordered (span (scope "server") (kind 'server) (status 'unset) (name "unused")))))))`
	shape, err := ParseScenarioShape("profile", "case", "source", input)
	if err != nil {
		t.Fatal(err)
	}
	if !shape.ExactCounts || shape.TraceCount != 0 || shape.SpanCount != 0 {
		t.Fatalf("unexpected zero-repeat counts %#v", shape)
	}
}

func TestParseScenarioShapePreservesPartialSpanMatchers(t *testing.T) {
	input := `(define scenario-shape
  (traces (trace (coverage 'complete)
	(unordered (span (name (one-of (exact "GET /a") (exact "GET /b"))))))))`
	shape, err := ParseScenarioShape("profile", "case", "source", input)
	if err != nil {
		t.Fatal(err)
	}
	span := shape.Traces[0].Roots[0].Span
	if span.Name != "one of: GET /a | GET /b" || span.Scope != "" || span.Kind != "" || span.Status != "" || span.HTTPStatus != "" {
		t.Fatalf("omitted matchers should remain unconstrained: %#v", span)
	}
	if !shape.ExactCounts || shape.SpanCount != 1 || len(shape.Scopes) != 0 || len(shape.Statuses) != 0 {
		t.Fatalf("unexpected partial matcher aggregates: %#v", shape)
	}
}

func TestParseScenarioShapeRejectsMissingDefinition(t *testing.T) {
	if _, err := ParseScenarioShape("p", "s", "broken.scm", "(define x 1)"); err == nil || !strings.Contains(err.Error(), "missing scenario-shape") {
		t.Fatalf("expected missing definition error, got %v", err)
	}
}
