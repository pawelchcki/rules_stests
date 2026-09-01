(define-library (realworld profile ruby-rails-auto-v0-1-0)
  (export profile)
  (import (scheme base)
          (otel profile)
          (otel profile ruby-auto-v0-1-0)
          (otel implementation ruby-sdk-v1.11.0)
          (otel implementation ruby-auto-v0.1.0)
          (otel implementation rails-v0.40.0)
          (otel standard traces) (otel standard logs)
          (otel standard resource) (otel standard exporters)
          (realworld contract))
  (begin

(define implementation-profile 'ruby-rails-auto-v0-1-0)
(define expected-error-status-message-policy 'nonempty)
(define expected-resource-attributes (ruby-service-resource-attributes "rails-otel"))
(define expected-scopes (list ruby-rack-scope ruby-active-record-scope))

; Rails auto-instrumentation does not create request/runtime metrics. Metrics
; are therefore intentionally absent rather than represented by a canary.
(define expected-metric-scopes '())
(define expected-metric-descriptors '())
(define expected-metric-aggregation #f)
(define expected-metric-point-schemas '())

; The repository activation patch routes Rails Logger broadcasts through the
; distribution's logs SDK. The scope is optional per request because not every
; successful request logs, but each Hurl scenario produces request records.
(define expected-log-scopes
  '(("Ruby::Logger" "3.3.12" "" #f)))
(define expected-log-policy '(#t #f #t #t unnamed))

(define (event-policy-for scenario)
  (list 'exception-on-error
        (cond ((eq? scenario 'articles) 1)
              ((eq? scenario 'errors_articles) 6)
              ((eq? scenario 'errors_comments) 2)
              (else 0))))
(define server-scope 'rack)

(define (colon-route canonical-route)
  (list->string
    (let loop ((characters (string->list canonical-route)) (inside #f))
      (if (null? characters)
          '()
          (let ((character (car characters)))
            (cond ((char=? character #\{) (cons #\: (loop (cdr characters) #t)))
                  ((char=? character #\}) (loop (cdr characters) #f))
                  (else (cons character (loop (cdr characters) inside)))))))))

(define (render-server-span-name method canonical-route)
  (string-append method " " (colon-route canonical-route)))

(define profile
  (realworld-profile
    (id 'ruby-rails-auto-v0-1-0)
    (display-name "Ruby Rails (patched auto 0.1.0)")
    (language 'ruby)
    (framework "Rails")
    (implementation (compose ruby-sdk-v1.11 ruby-auto-v0.1 rules-stests-ruby-auto-patch-v1 rails-v0.40 rack-v0.30 active-record-v0.13))
    (service-name "rails-otel")
    (signals 'traces 'logs)
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
    (all (observed logger/emit))
    (all (observed log/otlp-http-exporter))
    (all (observed exporter/otlp-http-binary-protobuf))
    (all (corroborated (sources rails-instrumentation rack-instrumentation) tracer/get))
    (all (corroborated (sources ruby-trace-api) tracer/scope-associated))
    (all (corroborated (sources ruby-trace-api) span/create))
    (all (corroborated (sources ruby-trace-api) span/create-with-active-parent))
    (all (corroborated (sources ruby-trace-api) span/create-with-context-parent))
    (all (corroborated (sources ruby-resource-api) resource/create-from-attributes))
    (all (corroborated (sources ruby-logger-api) logger/get))))
  ))
