(define-library (datadog capture shapes)
  (export capture-shapes assert-capture-shape
          field items every some tag metric header-value web-span? database-span?
          check decimal? nonempty-string?)
  (import (scheme base)
          (datadog capture base)
          (datadog capture intake)
          (datadog capture traces)
          (datadog capture service)
          (datadog capture sampling)
          (datadog capture propagation)
          (datadog capture http)
          (datadog capture database)
          (datadog capture errors)
          (datadog capture coverage))
  (begin

; Every executable assertion a Datadog proof rule can name, by theme. Each
; predicate receives the decoded capture and lives in the theme's library.
(define (capture-shape name predicate) (list name predicate))
(define capture-shapes
  (list
    ; Intake requests
    (capture-shape 'request/headers-and-counts headers-and-counts?)
    (capture-shape 'request/library-headers library-headers?)
    (capture-shape 'capture/semantic-valid semantic-valid?)
    (capture-shape 'capture/chunk-coherence chunk-coherence?)
    ; Span structure and identifiers
    (capture-shape 'span/native-fields native-fields?)
    (capture-shape 'span/ids-valid ids-valid?)
    (capture-shape 'span/completed completed?)
    (capture-shape 'span/root-present root-present?)
    (capture-shape 'span/trace-id-128 trace-id-128?)
    ; Service identity
    (capture-shape 'span/service-present service-present?)
    (capture-shape 'span/base-service base-service?)
    (capture-shape 'span/unified-service-tags unified-service-tags?)
    (capture-shape 'span/version-scoped version-scoped?)
    (capture-shape 'span/process-identity process-identity?)
    ; Sampling
    (capture-shape 'span/sampling-priority sampling-priority?)
    (capture-shape 'span/decision-maker decision-maker?)
    (capture-shape 'span/rule-keep rule-keep?)
    ; Propagation
    (capture-shape 'span/tracecontext-parent propagated?)
    (capture-shape 'span/datadog-parent propagated?)
    (capture-shape 'span/caller-sampling-kept caller-sampling-kept?)
    ; HTTP server spans
    (capture-shape 'span/http-classification http-classification?)
    (capture-shape 'span/http-server-tags server-tags?)
    (capture-shape 'span/http-absolute-url absolute-url?)
    (capture-shape 'span/http-route-template route-matches-url?)
    ; Database spans
    (capture-shape 'span/database-children database-children?)
    (capture-shape 'span/database-client client-spans?)
    (capture-shape 'span/database-system database-system?)
    ; Errors
    (capture-shape 'span/exception-metadata exception-metadata?)
    (capture-shape 'span/errors-explained errors-explained?)
    ; Evidence quality
    (capture-shape 'capture/field-policy-coverage field-policy-coverage?)))

(define (assert-capture-shape feature shape capture)
  (let ((entry (assq shape capture-shapes)))
    (check (and entry ((cadr entry) capture))
           (string-append "feature " feature ": assertion " (symbol->string shape) " failed"))))
  ))
