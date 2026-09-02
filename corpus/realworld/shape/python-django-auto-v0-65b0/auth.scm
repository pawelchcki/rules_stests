(define-library (realworld shape python-django-auto-v0-65b0 auth)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (repeat 8 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/user")) (http-status 200)
            (children (unordered
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent))
              (repeat 5 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/users")) (http-status 201)
          (children (unordered
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent)))
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/users/login")) (http-status 200)
          (children (unordered
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent))
            (repeat 3 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (repeat 10 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "PUT api/user")) (http-status 200)
            (children (unordered
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent))
              (repeat 6 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "UPDATE")) (http-status 'absent))))))))))
  ))
