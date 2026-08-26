(define-library (realworld profile python-aiohttp-auto-v0-65b0)
  (export implementation-profile
          expected-resource-attributes
          expected-resource-schema-url
          expected-scopes
          expected-metric-scopes
          expected-metric-descriptors
          expected-metric-aggregation
          expected-metric-point-schemas
          expected-log-scopes
          expected-log-policy
          expected-span-flags
          expected-trace-state
          expected-error-status-message-policy
          event-policy-for
          server-scope
          render-server-span-name)
  (import (scheme base)
          (otel profile python-auto-v0-65b0)
          (realworld contract))
  (begin

; Exact profile for OpenTelemetry Python auto-instrumentation 0.65b0 on aiohttp.
(define implementation-profile 'python-aiohttp-auto-v0-65b0)
(define expected-error-status-message-policy 'empty)

(define expected-resource-attributes
  (python-service-resource-attributes "aiohttp-otel"))

(define expected-scopes
  (list
    python-sqlite-scope
    python-sqlalchemy-scope
    (python-http-scope
      'http
      "opentelemetry.instrumentation.aiohttp_server"
      '("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.target" "http.url" "http.user_agent" "net.host.name" "net.host.port")
      '(("http.scheme" (exact "http")) ("net.host.name" (exact "127.0.0.1")))
      '("net.host.port" "http.status_code"))))

(define expected-metric-scopes
  (list
    (list "opentelemetry.instrumentation.aiohttp_server" "0.65b0" python-schema-url)
    '("opentelemetry.instrumentation.asyncio" "0.65b0" "")
    (list "opentelemetry.instrumentation.sqlalchemy" "0.65b0" python-schema-url)
    python-system-metrics-scope))

(define expected-metric-descriptors
  (append
    '(("opentelemetry.instrumentation.aiohttp_server" "http.server.active_requests" "Number of active HTTP server requests." "{request}" sum ())
      ("opentelemetry.instrumentation.aiohttp_server" "http.server.duration" "Measures the duration of inbound HTTP requests." "ms" histogram ())
      ("opentelemetry.instrumentation.asyncio" "asyncio.process.created" "Number of asyncio process" "{process}" sum ())
      ("opentelemetry.instrumentation.asyncio" "asyncio.process.duration" "Duration of asyncio process" "s" histogram ())
      ("opentelemetry.instrumentation.sqlalchemy" "db.client.connections.usage" "The number of connections that are currently in state described by the state attribute." "connections" sum ()))
    python-system-metric-descriptors))

(define expected-metric-aggregation
  (list (car python-metric-aggregation)
        (cons "asyncio.process.created" (cadr python-metric-aggregation))))

(define expected-metric-point-schemas
  (append
    '(("http.server.active_requests"
       ("http.flavor" "http.host" "http.method" "http.scheme" "http.server_name")
       (("http.flavor" (exact "1.1")) ("http.host" (exact "127.0.0.1")) ("http.method" (one-of "DELETE" "GET" "POST" "PUT")) ("http.scheme" (exact "http")) ("http.server_name" (loopback-port))))
      ("http.server.duration"
       ("http.flavor" "http.host" "http.method" "http.scheme" "http.server_name" "http.status_code" "net.host.name" "net.host.port")
       (("http.flavor" (exact "1.1")) ("http.host" (exact "127.0.0.1")) ("http.method" (one-of "DELETE" "GET" "POST" "PUT")) ("http.scheme" (exact "http")) ("http.server_name" (loopback-port)) ("http.status_code" (http-status)) ("net.host.name" (exact "127.0.0.1")) ("net.host.port" (positive-integer))))
      ("asyncio.process.created" ("name" "state" "type") (("name" (nonempty)) ("state" (exact "finished")) ("type" (exact "coroutine"))))
      ("asyncio.process.duration" ("name" "state" "type") (("name" (nonempty)) ("state" (exact "finished")) ("type" (exact "coroutine"))))
      ("db.client.connections.usage" ("pool.name" "state") (("pool.name" (nonempty)) ("state" (one-of "idle" "used")))))
    python-system-metric-point-schemas))

(define expected-log-scopes (list python-logging-scope))

(define (event-policy-for scenario) '(empty 0))
(define server-scope 'http)

(define (render-server-span-name method canonical-route)
  (string-append method " " canonical-route))

  ))
