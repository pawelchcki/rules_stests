(define-library (otel implementation ruby-sdk-v1.11.0)
  (export ruby-sdk-v1.11 ruby-trace-api ruby-resource-api ruby-logger-api
          ruby-propagation-api ruby-textmap-api
          ruby-global-propagation-api ruby-composite-propagator)
  (import (scheme base))
  (begin
(define ruby-sdk-v1.11 '(ruby-sdk "1.11.0"))
(define ruby-trace-api "https://github.com/open-telemetry/opentelemetry-ruby/blob/0b94ef6086facf3c7ad584485bb3825b0ab90e39/api/lib/opentelemetry/trace.rb")
(define ruby-resource-api "https://github.com/open-telemetry/opentelemetry-ruby/blob/0b94ef6086facf3c7ad584485bb3825b0ab90e39/sdk/lib/opentelemetry/sdk/resources/resource.rb")
(define ruby-logger-api "https://github.com/open-telemetry/opentelemetry-ruby/blob/0b94ef6086facf3c7ad584485bb3825b0ab90e39/logs_api/lib/opentelemetry/logs.rb")
(define ruby-propagation-api "https://github.com/open-telemetry/opentelemetry-ruby/blob/0b94ef6086facf3c7ad584485bb3825b0ab90e39/api/lib/opentelemetry/trace/propagation/trace_context.rb")
(define ruby-textmap-api "https://github.com/open-telemetry/opentelemetry-ruby/blob/0b94ef6086facf3c7ad584485bb3825b0ab90e39/api/lib/opentelemetry/context/propagation/text_map_propagator.rb")
(define ruby-global-propagation-api "https://github.com/open-telemetry/opentelemetry-ruby/blob/0b94ef6086facf3c7ad584485bb3825b0ab90e39/api/lib/opentelemetry.rb")
(define ruby-composite-propagator "https://github.com/open-telemetry/opentelemetry-ruby/blob/0b94ef6086facf3c7ad584485bb3825b0ab90e39/api/lib/opentelemetry/context/propagation/composite_text_map_propagator.rb")
  ))
