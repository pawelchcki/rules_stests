(define-library (otel capture shapes)
  (export capture-shape-known? assert-capture-shape)
  (import (scheme base) (scheme write))
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

(define known-shapes
  '(span/present span/root-present span/parent-valid-present span/all-completed
    span/string-attribute-present span/int64-attribute-present
    span/exception-events-complete trace/scope-associated trace/schema-url-present
    metric/scope-associated metric/scope-version-schema-present
    metric/monotonic-sum-present metric/nonmonotonic-sum-present
    metric/histogram-present metric/gauge-present metric/names-valid
    metric/kinds-valid metric/units-valid metric/descriptions-valid
    metric/resource-associated log/scope-associated log/record-present
    log/otlp-http-request-present resource/attributes-present
    resource/go-detector-present resource/schema-url-present
    exporter/binary-protobuf-request))

(define (capture-shape-known? shape) (and (memq shape known-shapes) #t))

(define (shape-satisfied? shape capture)
  (let ((spans (items capture 'spans))
        (metrics (items capture 'metrics))
        (logs (items capture 'logs))
        (resources (items capture 'resources))
        (scopes (items capture 'scopes))
        (requests (items capture 'requests)))
    (case shape
      ((span/present) (pair? spans))
      ((span/root-present)
       (some (lambda (span)
               (and (eq? (field 'parent-class span) 'root)
                    (string=? (field 'parent-span-id span) ""))) spans))
      ((span/parent-valid-present)
       (some (lambda (span)
               (and (memq (field 'parent-class span) '(child external))
                    (nonempty-string? (field 'parent-span-id span))
                    (eq? (field 'parent-valid span) #t))) spans))
      ((span/all-completed)
       (and (pair? spans)
            (every (lambda (span)
                     (and (> (field 'start span) 0)
                          (>= (field 'end span) (field 'start span)))) spans)))
      ((span/string-attribute-present span/int64-attribute-present)
       (let ((tag (if (eq? shape 'span/string-attribute-present) 'string 'integer)))
         (some (lambda (span)
                 (some (lambda (entry) (tagged? tag (cadr entry)))
                       (field 'attributes span))) spans)))
      ((span/exception-events-complete) (= (length (exception-events capture)) 2))
      ((trace/scope-associated)
       (and (pair? spans)
            (every (lambda (span)
                     (some (lambda (scope)
                             (string=? (field 'scope span) (field 'name scope)))
                           scopes)) spans)))
      ((trace/schema-url-present)
       (some (lambda (scope) (nonempty-string? (field 'schema-url scope))) scopes))
      ((metric/scope-associated)
       (and (pair? metrics)
            (every (lambda (metric) (nonempty-string? (field 'scope metric))) metrics)))
      ((metric/scope-version-schema-present)
       (some (lambda (metric)
               (and (nonempty-string? (field 'scope metric))
                    (nonempty-string? (field 'scope-version metric))
                    (nonempty-string? (field 'schema-url metric)))) metrics))
      ((metric/monotonic-sum-present) (sum-type? capture #t))
      ((metric/nonmonotonic-sum-present) (sum-type? capture #f))
      ((metric/histogram-present) (metric-type? capture 'histogram))
      ((metric/gauge-present) (metric-type? capture 'gauge))
      ((metric/names-valid)
       (and (pair? metrics)
            (every (lambda (metric) (nonempty-string? (field 'name metric))) metrics)))
      ((metric/kinds-valid)
       (and (pair? metrics)
            (every (lambda (metric)
                     (and (memq (field 'data-type metric)
                                '(gauge sum histogram exponential-histogram summary)) #t))
                   metrics)))
      ((metric/units-valid metric/descriptions-valid)
       (let ((key (if (eq? shape 'metric/units-valid) 'unit 'description)))
         (and (pair? metrics)
              (every (lambda (metric) (string? (field key metric))) metrics))))
      ((metric/resource-associated)
       (and (pair? metrics)
            (some (lambda (resource) (eq? (field 'signal resource) 'metrics)) resources)))
      ((log/scope-associated)
       (some (lambda (log) (nonempty-string? (field 'scope log))) logs))
      ((log/record-present) (pair? logs))
      ((log/otlp-http-request-present)
       (some (lambda (request)
               (and (eq? (field 'signal request) 'logs)
                    (string=? (field 'method request) "POST")
                    (string=? (field 'path request) "/v1/logs"))) requests))
      ((resource/attributes-present)
       (and (pair? resources)
            (every (lambda (resource) (pair? (field 'attributes resource))) resources)))
      ((resource/go-detector-present resource/schema-url-present)
       (some (lambda (resource)
               (let ((runtime (attribute (field 'attributes resource) "process.runtime.name")))
                 (and (tagged? 'string runtime)
                      (string=? (cadr runtime) "go")
                      (or (eq? shape 'resource/go-detector-present)
                          (nonempty-string? (field 'schema-url resource)))))) resources))
      ((exporter/binary-protobuf-request)
       (and (pair? requests)
            (every (lambda (request)
                     (member (field 'content-type request)
                             '("application/x-protobuf" "application/protobuf")))
                   requests)))
      (else #f))))

(define (capture-error feature shape)
  (let ((message (string-append "feature " feature ": assertion "
                                (symbol->string shape) " failed")))
    (display "[[OTLP-CONTRACT-V1:" (current-error-port))
    (display (string-length message) (current-error-port))
    (display "]]" (current-error-port))
    (display message (current-error-port))
    (error "OTLP contract sentinel")))

(define (assert-capture-shape feature shape capture)
  (if (shape-satisfied? shape capture) #t (capture-error feature shape)))
  ))
