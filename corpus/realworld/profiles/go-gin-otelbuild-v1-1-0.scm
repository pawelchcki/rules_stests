(define-library (realworld profile go-gin-otelbuild-v1-1-0)
  (export profile)
  (import (scheme base)
          (otel profile)
          (otel profile go-otelbuild-v0)
          (otel implementation go-compile-v1.1.0)
          (otel implementation go-runtime-v0.70.0)
          (otel standard traces) (otel standard metrics)
          (otel standard resource) (otel standard exporters)
          (realworld contract))
  (begin

; Exact profile for the gothinkster Gin RealWorld application built with
; opentelemetry-go-compile-instrumentation v1.1.0.
(define implementation-profile 'go-gin-otelbuild-v1-1-0)

; The HTTP server instrumentation follows the current semantic conventions and
; leaves 4xx responses unset, so no span in this profile carries a status
; message.
(define expected-error-status-message-policy 'empty)

; This build exports no logs, so the log policy is never consulted. It is
; declared for symmetry with the profiles that do.
(define expected-log-policy '(#f #f #f #f any))

(define expected-resource-attributes
  (go-service-resource-attributes "gin-otel"))

(define expected-scopes
  (list
    ; `url.query` is present only on requests that carry a query string, so it
    ; is permitted but not required.
    (go-http-scope
      'http
      '("client.address" "http.request.method" "http.response.status_code" "http.route" "network.peer.address" "network.peer.port" "network.protocol.version" "server.address" "server.port" "url.path" "url.scheme" "user_agent.original")
      '("client.address" "http.request.method" "http.response.status_code" "http.route" "network.peer.address" "network.peer.port" "network.protocol.version" "server.address" "server.port" "url.path" "url.query" "url.scheme" "user_agent.original")
      '(("http.request.method" (one-of "DELETE" "GET" "POST" "PUT"))
        ("network.protocol.version" (exact "1.1"))
        ("server.address" (exact "127.0.0.1"))
        ("url.scheme" (exact "http")))
      '("http.response.status_code" "network.peer.port" "server.port"))
    go-database-sql-scope))

(define expected-metric-scopes (list go-runtime-metrics-scope))
(define expected-metric-descriptors go-runtime-metric-descriptors)
(define expected-metric-aggregation go-metric-aggregation)
(define expected-metric-point-schemas go-runtime-metric-point-schemas)

; The tool's log/slog support only correlates trace IDs into the application's
; own logger; it installs no OTLP log exporter, so this build emits no logs.
(define expected-log-scopes '())

(define (event-policy-for scenario) '(empty 0))
(define server-scope 'http)

; Gin reports its own route template as `http.route`, and the HTTP server
; instrumentation names spans `<METHOD> <route>`. Gin writes path parameters as
; `:name`, and names the comment identifier `id` where the portable contract
; calls it `comment_id`.
(define (split-slash value)
  (let loop ((characters (string->list value)) (segment '()) (segments '()))
    (cond
      ((null? characters)
       (reverse (cons (list->string (reverse segment)) segments)))
      ((char=? (car characters) #\/)
       (loop (cdr characters) '() (cons (list->string (reverse segment)) segments)))
      (else
       (loop (cdr characters) (cons (car characters) segment) segments)))))

(define (join-slash segments)
  (if (null? (cdr segments))
      (car segments)
      (string-append (car segments) "/" (join-slash (cdr segments)))))

(define (brace-parameter segment)
  (let ((width (string-length segment)))
    (and (>= width 2)
         (char=? (string-ref segment 0) #\{)
         (char=? (string-ref segment (- width 1)) #\})
         (substring segment 1 (- width 1)))))

(define (gin-parameter name)
  (if (string=? name "comment_id") "id" name))

(define (gin-route canonical-route)
  (join-slash
    (map (lambda (segment)
           (let ((parameter (brace-parameter segment)))
             (if parameter
                 (string-append ":" (gin-parameter parameter))
                 segment)))
         (split-slash canonical-route))))

(define (render-server-span-name method canonical-route)
  (string-append method " " (gin-route canonical-route)))

(define profile
  (realworld-profile
    (id 'go-gin-otelbuild-v1-1-0)
    (display-name "Go Gin (otelbuild v1.1.0)")
    (language 'go)
    (framework "Gin")
    (implementation (compose go-compile-v1.1 go-runtime-v0.70))
    (service-name "gin-otel")
    (signals 'traces 'metrics)
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
    (all (observed exporter/otlp-http-binary-protobuf))
    (all (corroborated (sources go-compile-release) tracer/get))
    (all (corroborated (sources go-compile-release) tracer/scope-associated))
    (all (corroborated (sources go-compile-release) span/create))
    (all (corroborated (sources go-compile-release) resource/create-from-attributes))
    (all (corroborated (sources go-runtime-source) meter/get))
    (all (corroborated (sources go-runtime-source) meter/scope-associated))
    (all (corroborated (sources go-runtime-source) metric/async-counter))
    (all (corroborated (sources go-runtime-source) metric/async-up-down-counter))
    (all (corroborated (sources go-runtime-source) metric/instrument-name))
    (all (corroborated (sources go-runtime-source) metric/instrument-kind))
    (all (corroborated (sources go-runtime-source) metric/instrument-unit))
    (all (corroborated (sources go-runtime-source) metric/instrument-description))
    (all (corroborated (sources go-runtime-source) metric/sum-aggregation))
    (all (corroborated (sources go-compile-release) resource/detector-interface))
    (all (corroborated (sources go-compile-release) resource/detector-schema-url))))

  ))
