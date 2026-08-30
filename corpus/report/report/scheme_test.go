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

func TestParseGoldenRejectsMissingDefinition(t *testing.T) {
	if _, err := ParseGolden("p", "s", "broken.scm", "(define x 1)"); err == nil || !strings.Contains(err.Error(), "missing expected-trace-shapes") {
		t.Fatalf("expected missing definition error, got %v", err)
	}
}
