(define-library (realworld detail python-django-auto-v0-65b0 feed)
  (export expected-trace-shapes)
  (import (scheme base) (otel trace-shape))
  (begin
(define expected-trace-shapes
  (traces
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "DELETE api/articles/<slug>")) (http-status 204)
            (children (unordered
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
              (repeat 4 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "DELETE")) (http-status 'absent)))
              (repeat 12 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "DELETE api/profiles/<username>/follow")) (http-status 200)
          (children (unordered
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "DELETE")) (http-status 'absent))
            (repeat 11 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/articles/feed")) (http-status 200)
            (children (unordered
              (repeat 14 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/articles/feed")) (http-status 200)
          (children (unordered
            (repeat 20 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/articles/feed")) (http-status 200)
          (children (unordered
            (repeat 8 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/articles")) (http-status 201)
            (children (unordered
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent))
              (repeat 15 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
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
