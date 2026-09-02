(define-library (otel implementation rails-v0.40.0)
  (export rails-v0.40 rack-v0.30 active-record-v0.13 rails-instrumentation
          rack-instrumentation active-record-instrumentation)
  (import (scheme base))
  (begin
(define rails-v0.40 '(rails-instrumentation "0.40.0"))
(define rack-v0.30 '(rack-instrumentation "0.30.0"))
(define active-record-v0.13 '(active-record-instrumentation "0.13.0"))
(define rails-instrumentation "https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/cbe92a6f207d9509d79af0c5015ad215de2ef6d0/instrumentation/rails/lib/opentelemetry/instrumentation/rails/instrumentation.rb")
(define rack-instrumentation "https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/cbe92a6f207d9509d79af0c5015ad215de2ef6d0/instrumentation/rack/lib/opentelemetry/instrumentation/rack/instrumentation.rb")
(define active-record-instrumentation "https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/b4b99994ddf7f6cf5faaebdd597ee730aab1ae91/instrumentation/active_record/lib/opentelemetry/instrumentation/active_record/instrumentation.rb")
  ))
