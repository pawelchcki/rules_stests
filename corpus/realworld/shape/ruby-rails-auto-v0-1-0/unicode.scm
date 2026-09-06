(define-library (realworld shape ruby-rails-auto-v0-1-0 unicode)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "GET /api/profiles/:username")) (http-status 404)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent)))))))))
  ))
