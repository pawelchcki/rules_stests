(define-library (realworld shape ruby-rails-auto-v0-1-0 errors_profiles)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "DELETE /api/profiles/:username/follow")) (http-status 'absent))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "DELETE /api/profiles/:username/follow")) (http-status 'absent)
          (children (unordered
            (repeat 2 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "GET /api/profiles/:username")) (http-status 'absent)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent)))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/profiles/:username/follow")) (http-status 'absent))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/profiles/:username/follow")) (http-status 'absent)
          (children (unordered
            (repeat 2 (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User query")) (http-status 'absent))))))))
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 'absent)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User#save")) (http-status 'absent)))))))))
  ))
