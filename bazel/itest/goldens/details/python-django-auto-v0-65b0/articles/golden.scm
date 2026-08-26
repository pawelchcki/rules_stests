(define-library (realworld detail python-django-auto-v0-65b0 articles)
  (export expected-trace-shapes)
  (import (scheme base) (otel trace-shape))
  (begin
(define expected-trace-shapes
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "DELETE api/articles/<slug>")) (http-status 204)
          (children (unordered
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
            (repeat 4 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "DELETE")) (http-status 'absent)))
            (repeat 12 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/articles")) (http-status 200)
            (children (unordered
              (repeat 7 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/articles")) (http-status 200)
            (children (unordered
              (repeat 8 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
    (repeat 3 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/articles/<slug>")) (http-status 200)
            (children (unordered
              (repeat 6 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "GET api/articles/<slug>")) (http-status 404)
          (children (unordered
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/articles")) (http-status 201)
          (children (unordered
            (repeat 3 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent)))
            (repeat 4 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent)))
            (repeat 24 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "POST api/users")) (http-status 201)
          (children (unordered
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "INSERT")) (http-status 'absent)))
            (repeat 2 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "PUT api/articles/<slug>")) (http-status 200)
          (children (unordered
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "DELETE")) (http-status 'absent))
            (repeat 18 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))
            (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "UPDATE")) (http-status 'absent)))))))
    (repeat 2 (trace (coverage 'complete)
        (unordered
          (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "PUT api/articles/<slug>")) (http-status 200)
            (children (unordered
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "BEGIN")) (http-status 'absent))
              (repeat 15 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent)))
              (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "UPDATE")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "opentelemetry.instrumentation.django") (kind 'server) (status 'unset) (name (exact "PUT api/articles/<slug>")) (http-status 422)
          (children (unordered
            (repeat 4 (span (scope "opentelemetry.instrumentation.sqlite3") (kind 'client) (status 'unset) (name (exact "SELECT")) (http-status 'absent))))))))))
  ))
