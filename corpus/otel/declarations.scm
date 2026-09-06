(define-library (otel declarations)
  (export
    exact alias instrumentation version required-keys allowed-keys string-rules integer-keys schema-url presence
    metric description unit data-type metadata attribute-keys value-rules temporality monotonic-sums
    severity attributes timestamps body event-name mode occurrences bucket-count scope kind status name parent http-status
    span-flags trace-state resource-schema-url resource-attributes span-scopes metric-scopes metric-descriptors
    metric-point-schemas log-scopes error-status-message server-scope server-span-name
    attribute-limits
    span-scope metric-scope log-scope metric-descriptor point-schema metric-aggregation log-policy event-policy span-bucket
    capture-contract)
  (import (scheme base) (otel record))
  (begin

(define (exact value) (list 'exact value))
(define (alias value) (list 'alias value))
(define (instrumentation value) (list 'instrumentation value))
(define (version value) (list 'version value))
(define (required-keys . values) (list 'required-keys values))
(define (allowed-keys . values) (list 'allowed-keys values))
(define (string-rules . values) (list 'string-rules values))
(define (integer-keys . values) (list 'integer-keys values))
(define (schema-url value) (list 'schema-url value))
(define (presence value) (list 'presence value))
(define (metric value) (list 'metric value))
(define (description value) (list 'description value))
(define (unit value) (list 'unit value))
(define (data-type value) (list 'data-type value))
(define (metadata . values) (list 'metadata values))
(define (attribute-keys . values) (list 'attribute-keys values))
(define (value-rules . values) (list 'value-rules values))
(define (temporality value) (list 'temporality value))
(define (monotonic-sums . values) (list 'monotonic-sums values))
(define (severity value) (list 'severity value))
(define (attributes value) (list 'attributes value))
(define (timestamps value) (list 'timestamps value))
(define (body value) (list 'body value))
(define (event-name value) (list 'event-name value))
(define (mode value) (list 'mode value))
(define (occurrences value) (list 'occurrences value))
(define (bucket-count value) (list 'bucket-count value))
(define (scope value) (list 'scope value))
(define (kind value) (list 'kind value))
(define (status value) (list 'status value))
(define (name value) (list 'name value))
(define (parent value) (list 'parent value))
(define (http-status value) (list 'http-status value))

(define (span-flags value) (list 'span-flags value))
(define (trace-state value) (list 'trace-state value))
(define (resource-schema-url value) (list 'resource-schema-url value))
(define (resource-attributes value) (list 'resource-attributes value))
(define (span-scopes . values) (list 'span-scopes values))
(define (metric-scopes . values) (list 'metric-scopes values))
(define (metric-descriptors . values) (list 'metric-descriptors values))
(define (metric-point-schemas . values) (list 'metric-point-schemas values))
(define (log-scopes . values) (list 'log-scopes values))
; 'complete means every declared attribute reaches the wire. 'enforced means a
; span attribute limit is in force, so a span may report dropped attributes and
; carry only some of the declared keys. Whichever keys do arrive are still held
; to every rule the contract states about them.
(define (attribute-limits value) (list 'attribute-limits value))
(define (error-status-message value) (list 'error-status-message value))
(define (server-scope value) (list 'server-scope value))
(define (server-span-name value) (list 'server-span-name value))

(define (span-scope . clauses) (cons 'span-scope clauses))
(define (metric-scope . clauses) (cons 'metric-scope clauses))
(define (log-scope . clauses)
  (let ((record (cons 'log-scope clauses)))
    (if (record-has? record 'presence)
        record
        (append record (list (presence 'required))))))
(define (metric-descriptor . clauses) (cons 'metric-descriptor clauses))
(define (point-schema . clauses) (cons 'point-schema clauses))
(define (metric-aggregation . clauses) (cons 'metric-aggregation clauses))
(define (log-policy . clauses) (cons 'log-policy clauses))
(define (event-policy . clauses) (cons 'event-policy clauses))
(define (span-bucket . clauses) (cons 'span-bucket clauses))

(define (capture-contract . clauses)
  (let flatten ((remaining clauses) (result '()))
    (if (null? remaining)
        (cons 'capture-contract (reverse result))
        (let ((clause (car remaining)))
          (if (and (pair? clause) (pair? (car clause)))
              (flatten (append clause (cdr remaining)) result)
              (flatten (cdr remaining) (cons clause result)))))))
  ))
