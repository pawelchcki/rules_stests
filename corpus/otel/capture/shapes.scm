(define-library (otel capture shapes)
  (export capture-shapes capture-shape-known? assert-capture-shape)
  (import (scheme base) (scheme write) (otel contract-error))
  (begin

; Capture shapes describe executable facts present in decoded OTLP.  They are
; deliberately independent of specification feature IDs: several language API
; features can be proved by the same wire fact.

(define (field key object)
  (let ((entry (and (pair? object) (assq key object))))
    (and entry (pair? (cdr entry)) (cadr entry))))

(define (items capture key)
  (let ((value (field key capture))) (if (list? value) value '())))

(define (every predicate values)
  (or (null? values)
      (and (predicate (car values)) (every predicate (cdr values)))))

(define (some predicate values)
  (and (pair? values)
       (or (predicate (car values)) (some predicate (cdr values)))))

(define (nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))

(define (tagged? tag value)
  (and (pair? value) (eq? (car value) tag) (pair? (cdr value))))

(define (attribute attributes key)
  (let ((entry (and (pair? attributes) (assoc key attributes))))
    (and entry (pair? (cdr entry)) (cadr entry))))

(define (metric-type? capture type)
  (some (lambda (metric) (eq? (field 'data-type metric) type))
        (items capture 'metrics)))

(define (sum-type? capture monotonic)
  (some (lambda (metric)
          (and (eq? (field 'data-type metric) 'sum)
               (eq? (field 'monotonic metric) monotonic)))
        (items capture 'metrics)))

(define exception-keys
  '("exception.type" "exception.message" "exception.stacktrace" "exception.escaped"))

(define (exception-event? event)
  (let ((attributes (field 'attributes event)))
    (and (string=? (field 'name event) "exception")
         (= (length attributes) 4)
         (every (lambda (key) (attribute attributes key)) exception-keys)
         (tagged? 'string (attribute attributes "exception.type"))
         (tagged? 'string (attribute attributes "exception.message"))
         (tagged? 'long-string (attribute attributes "exception.stacktrace"))
         (tagged? 'string (attribute attributes "exception.escaped")))))

(define (exception-events capture)
  (let span-loop ((spans (items capture 'spans)) (result '()))
    (if (null? spans)
        result
        (let event-loop ((events (field 'events (car spans))) (result result))
          (if (null? events)
              (span-loop (cdr spans) result)
              (event-loop (cdr events)
                          (if (exception-event? (car events))
                              (cons (car events) result)
                              result)))))))

(define (capture-shape name predicate) (list name predicate))

(define (attribute-shape? capture tag)
  (some (lambda (span)
          (some (lambda (entry) (tagged? tag (cadr entry)))
                (field 'attributes span)))
        (items capture 'spans)))

(define (go-resource-shape? capture require-schema?)
  (some (lambda (resource)
          (let ((runtime (attribute (field 'attributes resource) "process.runtime.name")))
            (and (tagged? 'string runtime)
                 (string=? (cadr runtime) "go")
                 (or (not require-schema?)
                     (nonempty-string? (field 'schema-url resource))))))
        (items capture 'resources)))

; One table is both the registry and the executable dispatch.  Go tooling reads
; the capture-shape heads, while Scheme calls the paired predicates via assq.
(define capture-shapes
  (list
    (capture-shape 'span/present
      (lambda (capture) (pair? (items capture 'spans))))
    (capture-shape 'span/root-present
      (lambda (capture)
        (some (lambda (span)
                (and (eq? (field 'parent-class span) 'root)
                     (string=? (field 'parent-span-id span) "")))
              (items capture 'spans))))
    (capture-shape 'span/parent-valid-present
      (lambda (capture)
        (some (lambda (span)
                (and (memq (field 'parent-class span) '(child external))
                     (nonempty-string? (field 'parent-span-id span))
                     (eq? (field 'parent-valid span) #t)))
              (items capture 'spans))))
    (capture-shape 'span/all-completed
      (lambda (capture)
        (let ((spans (items capture 'spans)))
          (and (pair? spans)
               (every (lambda (span)
                        (and (> (field 'start span) 0)
                             (>= (field 'end span) (field 'start span))))
                      spans)))))
    (capture-shape 'span/string-attribute-present
      (lambda (capture) (attribute-shape? capture 'string)))
    (capture-shape 'span/int64-attribute-present
      (lambda (capture) (attribute-shape? capture 'integer)))
    (capture-shape 'span/exception-events-complete
      (lambda (capture) (= (length (exception-events capture)) 2)))
    (capture-shape 'trace/scope-associated
      (lambda (capture)
        (let ((spans (items capture 'spans)) (scopes (items capture 'scopes)))
          (and (pair? spans)
               (every (lambda (span)
                        (some (lambda (scope)
                                (string=? (field 'scope span) (field 'name scope)))
                              scopes))
                      spans)))))
    (capture-shape 'trace/schema-url-present
      (lambda (capture)
        (some (lambda (scope) (nonempty-string? (field 'schema-url scope)))
              (items capture 'scopes))))
    (capture-shape 'metric/scope-associated
      (lambda (capture)
        (let ((metrics (items capture 'metrics)))
          (and (pair? metrics)
               (every (lambda (metric) (nonempty-string? (field 'scope metric))) metrics)))))
    (capture-shape 'metric/scope-version-schema-present
      (lambda (capture)
        (some (lambda (metric)
                (and (nonempty-string? (field 'scope metric))
                     (nonempty-string? (field 'scope-version metric))
                     (nonempty-string? (field 'schema-url metric))))
              (items capture 'metrics))))
    (capture-shape 'metric/monotonic-sum-present
      (lambda (capture) (sum-type? capture #t)))
    (capture-shape 'metric/nonmonotonic-sum-present
      (lambda (capture) (sum-type? capture #f)))
    (capture-shape 'metric/histogram-present
      (lambda (capture) (metric-type? capture 'histogram)))
    (capture-shape 'metric/gauge-present
      (lambda (capture) (metric-type? capture 'gauge)))
    (capture-shape 'metric/names-valid
      (lambda (capture)
        (let ((metrics (items capture 'metrics)))
          (and (pair? metrics)
               (every (lambda (metric) (nonempty-string? (field 'name metric))) metrics)))))
    (capture-shape 'metric/kinds-valid
      (lambda (capture)
        (let ((metrics (items capture 'metrics)))
          (and (pair? metrics)
               (every (lambda (metric)
                        (and (memq (field 'data-type metric)
                                   '(gauge sum histogram exponential-histogram summary)) #t))
                      metrics)))))
    (capture-shape 'metric/units-valid
      (lambda (capture)
        (let ((metrics (items capture 'metrics)))
          (and (pair? metrics) (every (lambda (metric) (string? (field 'unit metric))) metrics)))))
    (capture-shape 'metric/descriptions-valid
      (lambda (capture)
        (let ((metrics (items capture 'metrics)))
          (and (pair? metrics) (every (lambda (metric) (string? (field 'description metric))) metrics)))))
    (capture-shape 'metric/resource-associated
      (lambda (capture)
        (and (pair? (items capture 'metrics))
             (some (lambda (resource) (eq? (field 'signal resource) 'metrics))
                   (items capture 'resources)))))
    (capture-shape 'log/scope-associated
      (lambda (capture)
        (some (lambda (log) (nonempty-string? (field 'scope log))) (items capture 'logs))))
    (capture-shape 'log/record-present
      (lambda (capture) (pair? (items capture 'logs))))
    (capture-shape 'log/otlp-http-request-present
      (lambda (capture)
        (some (lambda (request)
                (and (eq? (field 'signal request) 'logs)
                     (string=? (field 'method request) "POST")
                     (string=? (field 'path request) "/v1/logs")))
              (items capture 'requests))))
    (capture-shape 'resource/attributes-present
      (lambda (capture)
        (let ((resources (items capture 'resources)))
          (and (pair? resources)
               (every (lambda (resource) (pair? (field 'attributes resource))) resources)))))
    (capture-shape 'resource/go-detector-present
      (lambda (capture) (go-resource-shape? capture #f)))
    (capture-shape 'resource/schema-url-present
      (lambda (capture) (go-resource-shape? capture #t)))
    (capture-shape 'exporter/binary-protobuf-request
      (lambda (capture)
        (let ((requests (items capture 'requests)))
          (and (pair? requests)
               (every (lambda (request)
                        (member (field 'content-type request)
                                '("application/x-protobuf" "application/protobuf")))
                      requests)))))))

(define (capture-shape-known? shape) (and (assq shape capture-shapes) #t))

(define (shape-satisfied? shape capture)
  (let ((entry (assq shape capture-shapes)))
    (and entry ((cadr entry) capture))))

(define (capture-error feature shape)
  (let ((message (string-append "feature " feature ": assertion "
                                (symbol->string shape) " failed")))
    (contract-error message)))

(define (assert-capture-shape feature shape capture)
  (if (shape-satisfied? shape capture) #t (capture-error feature shape)))
  ))
