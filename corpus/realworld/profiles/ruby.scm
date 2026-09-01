(define-library (otel profile ruby-auto-v0-1-0)
  (export ruby-service-resource-attributes ruby-rack-scope ruby-rails-scope
          ruby-active-record-scope expected-span-flags expected-trace-state
          expected-resource-schema-url)
  (import (scheme base))
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

(define expected-span-flags '(257))
(define expected-trace-state "")
(define expected-resource-schema-url "")

(define ruby-http-attributes
  '("client.address" "code.function" "code.namespace" "error.type"
    "http.request.method" "http.response.status_code"
    "http.route" "network.peer.address" "network.peer.port"
    "network.protocol.name" "network.protocol.version" "server.address"
    "server.port" "url.path" "url.query" "url.scheme" "user_agent.original"))

(define ruby-rack-scope
  (list 'rack "OpenTelemetry::Instrumentation::Rack" "0.30.0"
        '("http.request.method" "http.response.status_code" "http.route")
        ruby-http-attributes
        '(("http.request.method" (one-of "DELETE" "GET" "POST" "PUT"))
          ("url.scheme" (exact "http")))
        '("http.response.status_code") ""))

(define ruby-rails-scope
  '(rails "OpenTelemetry::Instrumentation::Rails" "0.40.0"
    ()
    ("code.function" "code.namespace")
    () () ""))

(define ruby-active-record-scope
  '(active-record "OpenTelemetry::Instrumentation::ActiveRecord" "0.13.0"
    ()
    ("code.function" "code.namespace" "db.collection.name" "db.namespace"
     "db.operation.name" "db.query.summary"
     "db.query.text" "db.system" "db.system.name" "server.address" "server.port")
    () () ""))
  ))
