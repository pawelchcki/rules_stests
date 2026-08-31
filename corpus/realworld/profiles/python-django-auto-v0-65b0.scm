(define-library (realworld profile python-django-auto-v0-65b0)
  (export profile)
  (import (scheme base)
          (otel profile)
          (otel profile python-auto-v0-65b0)
          (otel implementation python-sdk-v1.44.0)
          (otel implementation python-auto-v0.65b0)
          (otel implementation django-v0.65b0)
          (otel standard traces) (otel standard metrics)
          (otel standard logs) (otel standard resource) (otel standard exporters)
          (realworld contract))
  (begin

; Exact profile for OpenTelemetry Python auto-instrumentation 0.65b0 on Django.
(define implementation-profile 'python-django-auto-v0-65b0)
(define expected-error-status-message-policy 'nonempty)
; Require severity, enrichment attributes, timestamps, a body, and unnamed logs.
(define expected-log-policy '(#t #t #t #t unnamed))

(define expected-resource-attributes
  (python-service-resource-attributes "django-otel"))

(define expected-scopes
  (list
    python-sqlite-scope
    (python-http-scope
      'django
      "opentelemetry.instrumentation.django"
      '("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.url" "http.user_agent" "net.host.name" "net.host.port" "net.peer.ip")
      '(("http.scheme" (exact "http")) ("net.host.name" (loopback-port)) ("net.peer.ip" (exact "127.0.0.1")))
      '("net.host.port" "http.status_code"))))

(define expected-metric-scopes
  (list
    (list "opentelemetry.instrumentation.django" "0.65b0" python-schema-url)
    python-system-metrics-scope))

(define expected-metric-descriptors
  (append
    '(("opentelemetry.instrumentation.django" "http.server.active_requests" "Number of active HTTP server requests." "{request}" sum ())
      ("opentelemetry.instrumentation.django" "http.server.duration" "Measures the duration of inbound HTTP requests." "ms" histogram ()))
    python-system-metric-descriptors))

(define expected-metric-aggregation python-metric-aggregation)

(define expected-metric-point-schemas
  (append
    '(("http.server.active_requests"
       ("http.flavor" "http.host" "http.method" "http.scheme" "http.server_name")
       (("http.flavor" (exact "1.1")) ("http.host" (loopback-port)) ("http.method" (one-of "DELETE" "GET" "POST" "PUT")) ("http.scheme" (exact "http")) ("http.server_name" (one-of "localhost.localdomain" "localhost"))))
      ("http.server.duration"
       ("http.flavor" "http.host" "http.method" "http.scheme" "http.server_name" "http.status_code" "http.target" "net.host.name" "net.host.port")
       (("http.flavor" (exact "1.1")) ("http.host" (loopback-port)) ("http.method" (one-of "DELETE" "GET" "POST" "PUT")) ("http.scheme" (exact "http")) ("http.server_name" (one-of "localhost.localdomain" "localhost")) ("http.status_code" (http-status)) ("http.target" (nonempty)) ("net.host.name" (loopback-port)) ("net.host.port" (positive-integer)))))
    python-system-metric-point-schemas))

(define expected-log-scopes
  (list
    '("django.request" "" "" #f)
    python-logging-scope))

(define (event-policy-for scenario)
  (list 'exception-on-error
        (if (eq? scenario 'errors_auth) 2 0)))
(define server-scope 'django)

(define (render-server-span-name method canonical-route)
  (string-append method
                 " "
                 (angle-bracket-route
                   (substring canonical-route 1 (string-length canonical-route)))))

(define profile
  (realworld-profile
    (id 'python-django-auto-v0-65b0)
    (implementation (compose python-sdk-v1.44 python-auto-v0.65b0
                             python-system-metrics-v0.65b0 django-v0.65b0))
    (service-name "django-otel")
    (signals 'traces 'metrics 'logs)
    (capture-contract
      (list expected-resource-attributes expected-resource-schema-url expected-scopes
            expected-metric-scopes expected-metric-descriptors expected-metric-aggregation
            expected-metric-point-schemas expected-log-scopes expected-log-policy
            event-policy-for expected-span-flags expected-trace-state
            expected-error-status-message-policy server-scope render-server-span-name))
    (all (observed span/create-root))
    (all (observed span/end))
    (all (observed span/string-attribute))
    (all (observed span/int64-attribute))
    (all (observed metric/resource-associated))
    (all (observed logger/emit))
    (all (observed log/otlp-http-exporter))
    (all (observed exporter/otlp-http-binary-protobuf))
    (all (corroborated (sources django-instrumentation) tracer/get))
    (all (corroborated (sources python-trace-api) tracer/get-with-schema-url))
    (all (corroborated (sources python-trace-api) tracer/scope-associated))
    (all (corroborated (sources python-trace-api) span/create))
    (all (corroborated (sources python-trace-api) span/create-with-active-parent))
    (all (corroborated (sources python-trace-api) span/create-with-context-parent))
    (scenario 'errors_auth
      (corroborated (sources python-trace-api django-exception-middleware)
                    span/record-exception
                    span/record-exception-with-parameters))
    (all (corroborated (sources python-resource-api) resource/create-from-attributes))
    (all (corroborated (sources python-meter-api) meter/get))
    (all (corroborated (sources python-meter-api) meter/get-with-version-schema))
    (all (corroborated (sources python-meter-sdk) meter/scope-associated))
    (all (corroborated (sources python-instrument-api) metric/async-counter))
    (all (corroborated (sources python-instrument-api) metric/histogram))
    (all (corroborated (sources python-instrument-api) metric/async-gauge))
    (all (corroborated (sources python-instrument-api) metric/up-down-counter))
    (all (corroborated (sources python-instrument-api) metric/instrument-name))
    (all (corroborated (sources python-instrument-api) metric/instrument-kind))
    (all (corroborated (sources python-instrument-api) metric/instrument-unit))
    (all (corroborated (sources python-instrument-api) metric/instrument-description))
    (all (corroborated (sources python-aggregation-api) metric/sum-aggregation))
    (all (corroborated (sources python-aggregation-api) metric/last-value-aggregation))
    (all (corroborated (sources python-aggregation-api) metric/explicit-bucket-histogram-aggregation))
    (all (corroborated (sources python-logger-api) logger/get))))

  ))
