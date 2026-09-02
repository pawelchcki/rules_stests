(define-library (otel implementation ruby-auto-v0.1.0)
  (export ruby-auto-v0.1 rules-stests-ruby-auto-patch-v1 ruby-auto-release)
  (import (scheme base))
  (begin
(define ruby-auto-v0.1 '(ruby-auto-instrumentation "0.1.0"))
(define rules-stests-ruby-auto-patch-v1 '(rules-stests-ruby-auto-patch "1"))
(define ruby-auto-release "https://github.com/open-telemetry/opentelemetry-ruby-instrumentation/tree/5e1c2b7c5b30877f957ae555029275114b23a14d")
  ))
