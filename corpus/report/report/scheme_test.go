package report

import (
	"strings"
	"testing"
)

const sampleGolden = `(define-library (realworld detail sample case)
  (export expected-trace-shapes)
  (import (scheme base))
  (begin
    (define expected-trace-shapes
      (traces
        (repeat 2 (trace (coverage 'complete)
          (unordered
            (span (scope "server") (kind 'server) (status 'unset)
              (name (exact "GET /items")) (http-status 200)
              (children (unordered
                (repeat 3 (span (scope "db") (kind 'client) (status 'error)
                  (name (prefix-suffix "SELECT " "items")) (http-status 'absent)))))))))))
  ))`

func TestParseGoldenAggregatesRepeatedTrees(t *testing.T) {
	golden, err := ParseGolden("profile", "case", "source", sampleGolden)
	if err != nil {
		t.Fatal(err)
	}
	if golden.TraceCount != 2 || golden.SpanCount != 8 {
		t.Fatalf("got %d traces, %d spans", golden.TraceCount, golden.SpanCount)
	}
	if !golden.ExactCounts {
		t.Fatal("repeat-only golden should have exact counts")
	}
	if golden.Scopes["server"] != 2 || golden.Scopes["db"] != 6 {
		t.Fatalf("unexpected scopes %#v", golden.Scopes)
	}
	if golden.Statuses["unset"] != 2 || golden.Statuses["error"] != 6 {
		t.Fatalf("unexpected statuses %#v", golden.Statuses)
	}
	child := golden.Traces[0].Roots[0].Span.Children[0]
	if child.Count != 3 || !strings.Contains(child.Span.Name, "SELECT") {
		t.Fatalf("unexpected child %#v", child)
	}
}

func TestParseGoldenSupportsAllCardinalityWrappers(t *testing.T) {
	input := `(define expected-trace-shapes
  (traces
    (optional (trace (coverage 'complete)
      (unordered (optional (span (scope "server") (kind 'server) (status 'unset) (name "optional"))))))
    (between 2 4 (trace (coverage 'complete)
      (unordered (between 1 3 (span (scope "server") (kind 'server) (status 'unset) (name "between"))))))
    (one-of
      (trace (coverage 'complete) (unordered (span (scope "a") (kind 'server) (status 'unset) (name "a"))))
      (repeat 2 (trace (coverage 'complete) (unordered (span (scope "b") (kind 'server) (status 'unset) (name "b"))))))))`
	golden, err := ParseGolden("profile", "case", "source", input)
	if err != nil {
		t.Fatal(err)
	}
	if golden.ExactCounts {
		t.Fatal("variable cardinalities must not be reported as exact counts")
	}
	if len(golden.Traces) != 3 || golden.Traces[0].Cardinality != "optional" {
		t.Fatalf("unexpected optional trace %#v", golden.Traces)
	}
	if golden.Traces[1].MinCount != 2 || golden.Traces[1].MaxCount != 4 {
		t.Fatalf("unexpected between trace %#v", golden.Traces[1])
	}
	if len(golden.Traces[2].Alternatives) != 2 {
		t.Fatalf("unexpected one-of trace %#v", golden.Traces[2])
	}
	if golden.Traces[0].Roots[0].Cardinality != "optional" || golden.Traces[1].Roots[0].MaxCount != 3 {
		t.Fatalf("span cardinalities were not preserved: %#v %#v", golden.Traces[0].Roots[0], golden.Traces[1].Roots[0])
	}
}

func TestParseGoldenAcceptsZeroRepeat(t *testing.T) {
	input := `(define expected-trace-shapes
  (traces (repeat 0 (trace (coverage 'complete)
    (unordered (span (scope "server") (kind 'server) (status 'unset) (name "unused")))))))`
	golden, err := ParseGolden("profile", "case", "source", input)
	if err != nil {
		t.Fatal(err)
	}
	if !golden.ExactCounts || golden.TraceCount != 0 || golden.SpanCount != 0 {
		t.Fatalf("unexpected zero-repeat counts %#v", golden)
	}
}

func TestParseGoldenPreservesPartialSpanMatchers(t *testing.T) {
	input := `(define expected-trace-shapes
  (traces (trace (coverage 'complete)
    (unordered (span (name "request"))))))`
	golden, err := ParseGolden("profile", "case", "source", input)
	if err != nil {
		t.Fatal(err)
	}
	span := golden.Traces[0].Roots[0].Span
	if span.Name != "request" || span.Scope != "" || span.Kind != "" || span.Status != "" || span.HTTPStatus != "" {
		t.Fatalf("omitted matchers should remain unconstrained: %#v", span)
	}
	if !golden.ExactCounts || golden.SpanCount != 1 || len(golden.Scopes) != 0 || len(golden.Statuses) != 0 {
		t.Fatalf("unexpected partial matcher aggregates: %#v", golden)
	}
}

func TestParseGoldenRejectsMissingDefinition(t *testing.T) {
	if _, err := ParseGolden("p", "s", "broken.scm", "(define x 1)"); err == nil || !strings.Contains(err.Error(), "missing expected-trace-shapes") {
		t.Fatalf("expected missing definition error, got %v", err)
	}
}
