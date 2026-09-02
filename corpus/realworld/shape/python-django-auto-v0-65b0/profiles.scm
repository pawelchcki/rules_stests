(define-library (realworld shape python-django-auto-v0-65b0 profiles)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "DELETE api/profiles/<username>/follow")) (http-status 200)
          (children (unordered
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "DELETE")) (http-status 'absent))
            (repeat 11 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/profiles/<username>")) (http-status 200)
          (children (unordered
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/profiles/<username>")) (http-status 200)
            (children (unordered
              (repeat 8 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/profiles/<username>/follow")) (http-status 200)
          (children (unordered
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent))
            (repeat 11 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/users")) (http-status 201)
            (children (unordered
              (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent)))
              (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))))
  ))
