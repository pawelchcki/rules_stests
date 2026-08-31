(define-library (realworld shape go-gin-otelbuild-v1-1-0 errors_authorization)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (repeat 9 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "COMMIT")) (http-status 'absent)))))
    (repeat 18 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent)))))
    (repeat 63 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))
    (repeat 9 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "START")) (http-status 'absent)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "UPDATE")) (http-status 'absent))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug")) (http-status 204))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug")) (http-status 403))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug/comments/:id")) (http-status 403))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "GET /api/articles/:slug/comments")) (http-status 200))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/articles")) (http-status 201))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/articles/:slug/comments")) (http-status 201))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 201)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "PUT /api/articles/:slug")) (http-status 403))))))
  ))
