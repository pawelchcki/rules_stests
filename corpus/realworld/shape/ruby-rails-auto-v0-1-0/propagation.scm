(define-library (realworld shape ruby-rails-auto-v0-1-0 propagation)
  (export scenario-shape)
  (import (scheme base) (otel trace-shape))
  (begin
(define scenario-shape
  (traces
    (trace (coverage 'complete)
      (unordered
        (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "POST /api/users")) (http-status 201)
          (children (unordered
            (span (scope "OpenTelemetry::Instrumentation::ActiveRecord") (kind 'internal) (status 'unset) (name (exact "User#save")) (http-status 'absent)))))))
    (repeat 3 (trace (coverage 'partial)
        (unordered
          (span (scope "OpenTelemetry::Instrumentation::Rack") (kind 'server) (status 'unset) (name (exact "GET /api/tags")) (http-status 200)))))))
  ))
