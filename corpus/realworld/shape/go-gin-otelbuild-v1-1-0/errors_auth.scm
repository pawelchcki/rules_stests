(define-library (realworld shape go-gin-otelbuild-v1-1-0 errors_auth)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "COMMIT")) (http-status 'absent)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent))))
    (repeat 28 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "START")) (http-status 'absent)))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "UPDATE")) (http-status 'absent)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "GET /api/user")) (http-status 401))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 201))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 409)))))
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 422)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users/login")) (http-status 401))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users/login")) (http-status 422)))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "PUT /api/user")) (http-status 200)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "PUT /api/user")) (http-status 401))))
    (repeat 7 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "PUT /api/user")) (http-status 422)))))))
  ))
