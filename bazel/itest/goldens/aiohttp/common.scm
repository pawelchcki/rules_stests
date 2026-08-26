(define-library (realworld profile python-aiohttp-auto-v0-65b0)
  (export implementation-profile
          expected-resource-attributes
          expected-scopes
          event-policy
          server-scope
          render-server-span-name)
  (import (scheme base)
          (otel profile python-auto-v0-65b0)
          (realworld contract))
  (begin

; Exact profile for OpenTelemetry Python auto-instrumentation 0.65b0 on aiohttp.
(define implementation-profile 'python-aiohttp-auto-v0-65b0)

(define expected-resource-attributes
  (python-service-resource-attributes "aiohttp-otel"))

(define expected-scopes
  (list
    python-sqlite-scope
    '(sqlalchemy
      "opentelemetry.instrumentation.sqlalchemy"
      "0.65b0"
      ("db.name" "db.system")
      ("db.name" "db.system" "db.operation" "db.statement")
      (("db.system" (exact "sqlite")))
      ())
    '(http
      "opentelemetry.instrumentation.aiohttp_server"
      "0.65b0"
      ("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.target" "http.url" "http.user_agent" "net.host.name" "net.host.port")
      ("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.target" "http.url" "http.user_agent" "net.host.name" "net.host.port")
      (("http.scheme" (exact "http")) ("net.host.name" (exact "127.0.0.1")))
      ("net.host.port" "http.status_code"))))

(define event-policy 'empty)
(define server-scope 'http)

(define (render-server-span-name method canonical-route)
  (string-append method " " canonical-route))
  ))
