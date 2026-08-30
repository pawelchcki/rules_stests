(define-library (realworld profile python-django-auto-v0-65b0)
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

; Exact profile for OpenTelemetry Python auto-instrumentation 0.65b0 on Django.
(define implementation-profile 'python-django-auto-v0-65b0)
(define expected-error-status-message-policy 'nonempty)
; Require severity, enrichment attributes, timestamps, a body, unnamed logs,
; and at least one log correlated with a trace and span.
(define expected-log-policy '(#t #t #t #t unnamed #t))

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

  ))
