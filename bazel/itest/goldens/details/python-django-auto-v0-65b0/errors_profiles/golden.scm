(define-library (realworld detail python-django-auto-v0-65b0 errors_profiles)
  (export expected-trace-shapes)
  (import (scheme base) (otel trace-shape))
  (begin
(define expected-trace-shapes
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "DELETE api/profiles/<username>/follow")) (http-status 401))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "DELETE api/profiles/<username>/follow")) (http-status 404)
          (children (unordered
            (repeat 6 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/profiles/<username>")) (http-status 404)
          (children (unordered
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/profiles/<username>/follow")) (http-status 401))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/profiles/<username>/follow")) (http-status 404)
          (children (unordered
            (repeat 6 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/users")) (http-status 201)
          (children (unordered
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent)))
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))))
  ))
