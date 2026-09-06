(define-library (realworld shape python-aiohttp-auto-v0-65b0 unicode)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.aiohttp_server") (kind 'server) (status 'unset) (name (exact "GET /api/profiles/{username}")) (http-status 404)
          (children (unordered
            (span (scope "opentelemetry.instrumentation.sqlalchemy") (kind 'client) (status 'unset) (name (prefix-suffix "SELECT /" "realworld.sqlite3")) (http-status 'absent))
            (span (scope "opentelemetry.instrumentation.sqlalchemy") (kind 'client) (status 'unset) (name (exact "connect")) (http-status 'absent)))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))
  ))
