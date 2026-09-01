(define-library (realworld shape ruby-rails-auto-v0-1-0 auth)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (repeat 8 (trace (coverage 'complete)
        (unordered
          (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "GET /api/user")) (http-status 'absent)
            (children (unordered
              (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 'absent)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User#save")) (http-status 'absent)))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/users/login")) (http-status 'absent)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent)))))))
    (repeat 10 (trace (coverage 'complete)
        (unordered
          (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "PUT /api/user")) (http-status 'absent)
            (children (unordered
              (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent))
              (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User#save")) (http-status 'absent))))))))))
  ))
