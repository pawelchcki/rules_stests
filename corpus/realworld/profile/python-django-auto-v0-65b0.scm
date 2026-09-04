(define-library (realworld profile python-django-auto-v0-65b0)
  (export profile)
  (import (scheme base)
          (otel profile)
          (otel declarations)
          (otel runtime python-auto-v0-65b0)
          (otel implementation python-sdk-v1.44.0)
          (otel implementation python-auto-v0.65b0)
          (otel implementation django-v0.65b0)
          (otel standard traces) (otel standard metrics)
          (otel standard logs) (otel standard resource) (otel standard exporters)
          (otel standard environment-variables)
          (realworld contract) (realworld route))
  (begin

; Exact profile for OpenTelemetry Python auto-instrumentation 0.65b0 on Django.
(define implementation-profile 'python-django-auto-v0-65b0)
(define expected-error-status-message-policy 'nonempty)
; Require severity, enrichment attributes, timestamps, a body, and unnamed logs.
(define expected-log-policy
  (log-policy (severity 'required) (attributes 'required)
              (timestamps 'required) (body 'required) (event-name 'unnamed)))

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
    (metric-scope (instrumentation "opentelemetry.instrumentation.django")
                  (version "0.65b0") (schema-url python-schema-url))
    python-system-metrics-scope))

(define expected-metric-descriptors
  (append
    (list
      (metric-descriptor (instrumentation "opentelemetry.instrumentation.django") (metric "http.server.active_requests") (description "Number of active HTTP server requests.") (unit "{request}") (data-type 'sum) (metadata))
      (metric-descriptor (instrumentation "opentelemetry.instrumentation.django") (metric "http.server.duration") (description "Measures the duration of inbound HTTP requests.") (unit "ms") (data-type 'histogram) (metadata)))
    python-system-metric-descriptors))

(define expected-metric-aggregation python-metric-aggregation)

(define expected-metric-point-schemas
  (append
    (list
      (point-schema (metric "http.server.active_requests")
        (attribute-keys "http.flavor" "http.host" "http.method" "http.scheme" "http.server_name")
        (value-rules '("http.flavor" (exact "1.1")) '("http.host" (loopback-port)) '("http.method" (one-of "DELETE" "GET" "POST" "PUT")) '("http.scheme" (exact "http")) '("http.server_name" (one-of "localhost.localdomain" "localhost"))))
      (point-schema (metric "http.server.duration")
        (attribute-keys "http.flavor" "http.host" "http.method" "http.scheme" "http.server_name" "http.status_code" "http.target" "net.host.name" "net.host.port")
        (value-rules '("http.flavor" (exact "1.1")) '("http.host" (loopback-port)) '("http.method" (one-of "DELETE" "GET" "POST" "PUT")) '("http.scheme" (exact "http")) '("http.server_name" (one-of "localhost.localdomain" "localhost")) '("http.status_code" (http-status)) '("http.target" (nonempty)) '("net.host.name" (loopback-port)) '("net.host.port" (positive-integer)))))
    python-system-metric-point-schemas))

(define expected-log-scopes
  (list
    (log-scope (instrumentation "django.request") (version "") (schema-url "") (presence 'optional))
    python-logging-scope))

(define (event-policy-for scenario)
  (event-policy (mode 'exception-on-error)
                (occurrences (if (eq? scenario 'errors_auth) 2 0))))
(define server-scope-alias 'django)

(define (render-server-span-name method canonical-route)
  (string-append method
                 " "
                 (angle-bracket-route
                   (strip-leading-slash canonical-route))))

(define profile
  (realworld-profile
    (id 'python-django-auto-v0-65b0)
    (display-name "Python Django (auto 0.65b0)")
    (language 'python)
    (framework "Django")
    (implementation (compose python-sdk-v1.44 python-auto-v0.65b0
                             python-system-metrics-v0.65b0 django-v0.65b0))
    (service-name "django-otel")
    (signals 'traces 'metrics 'logs)
    (capture-contract
      python-runtime-contract
      (resource-attributes expected-resource-attributes)
      (apply span-scopes expected-scopes)
      (apply metric-scopes expected-metric-scopes)
      (apply metric-descriptors expected-metric-descriptors)
      expected-metric-aggregation
      (apply metric-point-schemas expected-metric-point-schemas)
      (apply log-scopes expected-log-scopes)
      expected-log-policy
      (event-policy event-policy-for)
      (error-status-message expected-error-status-message-policy)
      (server-scope server-scope-alias)
      (server-span-name render-server-span-name))
    (all (observed span/create-root))
    (all (observed span/end))
    (all (observed span/string-attribute))
    (all (observed span/int64-attribute))
    (all (observed metric/resource-associated))
    (all (observed logger/emit))
    (all (observed log/otlp-http-exporter))
    (all (observed exporter/otlp-http-binary-protobuf))
    (all (observed span/set-attribute))
    (all (observed span-context/is-valid))
    (all (observed span-context/w3c-conformant))
    (all (observed meter/resource-configurable))
    (all (observed metric/instrument-name-syntax))
    (all (observed metric/instrument-unit-syntax))
    (all (observed metric/instrument-description-syntax))
    (all (observed exporter/otlp-user-agent))
    (all (observed environment-variables/otel-service-name))
    (all (observed environment-variables/otel-exporter-otlp))
    (all (observed environment-variables/otel-traces-exporter))
    (all (observed environment-variables/otel-metrics-exporter))
    (all (observed environment-variables/otel-logs-exporter))
    (all (observed environment-variables/otel-metric-export-interval))
    (all (corroborated (sources django-instrumentation) tracer/get))
    (all (corroborated (sources python-trace-api) tracer/get-with-schema-url))
    (all (corroborated (sources python-trace-api) tracer/scope-associated))
    (all (corroborated (sources python-trace-api) span/create))
    (all (corroborated (sources python-trace-api) span/create-with-active-parent))
    (all (corroborated (sources python-trace-api) span/create-with-context-parent))
    (scenario 'errors_auth (observed span/set-status))
    (scenario 'errors_auth
      (corroborated (sources python-trace-api django-exception-middleware) span/add-event))
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
    (all (corroborated (sources python-logger-api) logger/get))
    (all (corroborated (sources python-trace-api) tracer-provider/create))
    (all (corroborated (sources python-trace-api) sampling/id-generator))
    (scenario 'articles (corroborated (sources django-instrumentation) span/update-name))
    (all (corroborated (sources python-resource-api) resource/retrieve-attributes))
    (all (corroborated (sources python-trace-api) exporter/otlp-traces-schema-url))
    (all (corroborated (sources python-meter-sdk) exporter/otlp-metrics-schema-url))
    (all (corroborated (sources python-instrument-api) metric/gauge))
    (all (corroborated (sources python-aggregation-api) metric/default-aggregation))
    (all (corroborated (sources python-logger-api) log/batch-processor))))

  ))
