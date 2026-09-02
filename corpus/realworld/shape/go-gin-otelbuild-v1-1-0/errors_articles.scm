(define-library (realworld shape go-gin-otelbuild-v1-1-0 errors_articles)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (repeat 7 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "COMMIT")) (http-status 'absent)))))
    (repeat 13 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent)))))
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "ROLLBACK")) (http-status 'absent)))))
    (repeat 55 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))
    (repeat 10 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "START")) (http-status 'absent)))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/database/sql") (kind 'client) (status 'unset) (name (exact "UPDATE")) (http-status 'absent)))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug")) (http-status 204)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug")) (http-status 401))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug")) (http-status 404))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug/favorite")) (http-status 401))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "DELETE /api/articles/:slug/favorite")) (http-status 404))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "GET /api/articles/:slug")) (http-status 404))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "GET /api/articles/feed")) (http-status 401))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/articles")) (http-status 201)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/articles")) (http-status 401))))
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/articles")) (http-status 422)))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/articles/:slug/favorite")) (http-status 401))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/articles/:slug/favorite")) (http-status 404))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 201))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "PUT /api/articles/:slug")) (http-status 401))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "go.opentelemetry.io/otelc/instrumentation/net/http") (kind 'server) (status 'unset) (name (exact "PUT /api/articles/:slug")) (http-status 404)))))))
  ))
