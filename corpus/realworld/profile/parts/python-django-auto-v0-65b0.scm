(define-library (realworld profile parts python-django-auto-v0-65b0)
  (export implementation-profile
          expected-error-status-message-policy expected-log-policy
          expected-resource-attributes expected-scopes
          expected-metric-scopes expected-metric-descriptors
          expected-metric-aggregation expected-metric-point-schemas
          expected-log-scopes event-policy-for server-scope-alias
          render-server-span-name)
  (import (scheme base)
          (otel declarations)
          (otel runtime python-auto-v0-65b0)
          (realworld route))
  (begin

; Everything the Django profile and its environment-variable variants share.
; A variant re-states only the contract clause its variable changes, so the two
; profiles cannot drift apart in any respect the variable does not govern.
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

  ))
