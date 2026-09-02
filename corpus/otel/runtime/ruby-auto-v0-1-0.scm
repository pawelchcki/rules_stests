(define-library (otel runtime ruby-auto-v0-1-0)
  (export ruby-service-resource-attributes ruby-rack-scope ruby-rails-scope
          ruby-active-record-scope ruby-runtime-contract)
  (import (scheme base) (otel declarations))
  (begin

(define ruby-resource-attributes
  '(("telemetry.sdk.language" (exact "ruby"))
    ("telemetry.sdk.name" (exact "opentelemetry"))
    ("telemetry.sdk.version" (exact "1.11.0"))
    ("telemetry.distro.name" (exact "opentelemetry-ruby-instrumentation"))
    ("telemetry.distro.version" (exact "0.1.0"))
    ("process.pid" (positive-integer))
    ("process.command" (nonempty))
    ("process.runtime.name" (exact "ruby"))
    ("process.runtime.version" (exact "3.3.12"))
    ("process.runtime.description" (nonempty))))

(define (ruby-service-resource-attributes service-name)
  (append ruby-resource-attributes
          (list (list "service.name" (list 'exact service-name)))))

(define ruby-runtime-contract
  (list (span-flags '(257))
        (trace-state "")
        (resource-schema-url "")))

(define ruby-http-attributes
  '("client.address" "code.function" "code.namespace" "error.type"
    "http.request.method" "http.response.status_code"
    "http.route" "network.peer.address" "network.peer.port"
    "network.protocol.name" "network.protocol.version" "server.address"
    "server.port" "url.path" "url.query" "url.scheme" "user_agent.original"))

(define ruby-rack-scope
  (span-scope
    (alias 'rack)
    (instrumentation "OpenTelemetry::Instrumentation::Rack")
    (version "0.30.0")
    (required-keys "http.request.method" "http.response.status_code" "http.route")
    (apply allowed-keys ruby-http-attributes)
    (string-rules
      '("http.request.method" (one-of "DELETE" "GET" "POST" "PUT"))
      '("url.scheme" (exact "http")))
    (integer-keys "http.response.status_code")
    (schema-url "")))

(define ruby-rails-scope
  (span-scope
    (alias 'rails)
    (instrumentation "OpenTelemetry::Instrumentation::Rails")
    (version "0.40.0")
    (required-keys)
    (allowed-keys "code.function" "code.namespace")
    (string-rules)
    (integer-keys)
    (schema-url "")))

(define ruby-active-record-scope
  (span-scope
    (alias 'active-record)
    (instrumentation "OpenTelemetry::Instrumentation::ActiveRecord")
    (version "0.13.0")
    (required-keys)
    (allowed-keys "code.function" "code.namespace" "db.collection.name" "db.namespace"
                  "db.operation.name" "db.query.summary" "db.query.text" "db.system"
                  "db.system.name" "server.address" "server.port")
    (string-rules)
    (integer-keys)
    (schema-url "")))
  ))
