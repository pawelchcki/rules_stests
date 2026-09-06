(define-library (realworld shape go-gin-otelbuild-v1-1-0 propagation)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "COMMIT")) (http-status 'absent))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent))))
    (repeat 5 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "START")) (http-status 'absent))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 201))))
    (repeat 3 (trace (coverage 'partial)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "GET /api/tags")) (http-status 200)))))))
  ))
