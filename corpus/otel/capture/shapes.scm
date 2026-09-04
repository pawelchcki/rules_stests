(define-library (otel capture shapes)
  (export capture-shapes capture-shape-known? assert-capture-shape)
  (import (scheme base) (scheme char) (scheme write)
          (otel identifiers) (otel contract-error))
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

(define (string-prefix? prefix value)
  (and (string? value)
       (>= (string-length value) (string-length prefix))
       (string=? (substring value 0 (string-length prefix)) prefix)))

(define (ascii-upper? character) (and (char>=? character #\A) (char<=? character #\Z)))
(define (ascii-lower? character) (and (char>=? character #\a) (char<=? character #\z)))
(define (ascii-letter? character) (or (ascii-upper? character) (ascii-lower? character)))
(define (ascii-digit? character) (and (char>=? character #\0) (char<=? character #\9)))

(define (ascii-printable? value limit)
  (and (string? value)
       (<= (string-length value) limit)
       (let loop ((index 0))
         (or (= index (string-length value))
             (let ((code (char->integer (string-ref value index))))
               (and (>= code 32) (<= code 126) (loop (+ index 1))))))))

(define (string-index value wanted)
  (let loop ((index 0))
    (cond ((= index (string-length value)) #f)
          ((char=? (string-ref value index) wanted) index)
          (else (loop (+ index 1))))))

; https://opentelemetry.io/docs/specs/otel/metrics/api/#instrument-name-syntax
(define (metric-name-conformant? name)
  (and (string? name)
       (> (string-length name) 0)
       (<= (string-length name) 255)
       (ascii-letter? (string-ref name 0))
       (let loop ((index 1))
         (or (= index (string-length name))
             (and (let ((character (string-ref name index)))
                    (or (ascii-letter? character)
                        (ascii-digit? character)
                        (memv character '(#\_ #\. #\- #\/))))
                  (loop (+ index 1)))))))

(define (every-metric? capture predicate)
  (let ((metrics (items capture 'metrics)))
    (and (pair? metrics) (every predicate metrics))))

(define (every-span? capture predicate)
  (let ((spans (items capture 'spans)))
    (and (pair? spans) (every predicate spans))))

(define (span-ids-valid? span)
  (and (valid-hex? (field 'trace-id span) 32)
       (valid-hex? (field 'span-id span) 16)))

; The OTLP `flags` field carries the W3C trace-flags byte in its low octet; the
; remaining bits are the OTLP parent-is-remote encoding, not W3C flags.
(define (w3c-span? span)
  (let ((parent (field 'parent-span-id span))
        (flags (field 'flags span)))
    (and (span-ids-valid? span)
         (or (string=? parent "") (valid-hex? parent 16))
         (valid-trace-state? (field 'trace-state span))
         (integer? flags)
         (memq (modulo flags 256) '(0 1))
         #t)))

; Server spans are renamed from the transport-level default to `<METHOD> <route>`
; once routing resolves; a parameter marker proves the low-cardinality template
; rather than the concrete request target.
(define (server-route-name? name)
  (and (string? name)
       (let ((space (string-index name #\space)))
         (and space
              (> space 0)
              (let loop ((index 0))
                (or (= index space)
                    (and (ascii-upper? (string-ref name index)) (loop (+ index 1)))))
              (let loop ((index (+ space 1)))
                (and (< index (string-length name))
                     (or (and (memv (string-ref name index) '(#\: #\{ #\<)) #t)
                         (loop (+ index 1)))))))))

(define (requests-for capture signal)
  (let loop ((requests (items capture 'requests)) (count 0))
    (if (null? requests)
        count
        (loop (cdr requests)
              (if (eq? (field 'signal (car requests)) signal) (+ count 1) count)))))

(define (header-value request name)
  (let loop ((headers (field 'headers request)))
    (cond ((not (pair? headers)) #f)
          ((and (pair? (car headers))
                (string=? (string-downcase (car (car headers))) name))
           (cadr (car headers)))
          (else (loop (cdr headers))))))

(define (resource-schema-url? capture signal)
  (some (lambda (resource)
          (and (eq? (field 'signal resource) signal)
               (nonempty-string? (field 'schema-url resource))))
        (items capture 'resources)))

(define (scope-schema-url? capture key)
  (some (lambda (item) (nonempty-string? (field 'schema-url item)))
        (items capture key)))

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
    (capture-shape 'span/attributes-present
      (lambda (capture)
        (some (lambda (span) (pair? (field 'attributes span))) (items capture 'spans))))
    (capture-shape 'span/ids-valid
      (lambda (capture) (every-span? capture span-ids-valid?)))
    (capture-shape 'span/w3c-trace-context-valid
      (lambda (capture) (every-span? capture w3c-span?)))
    (capture-shape 'span/server-name-is-route
      (lambda (capture)
        (some (lambda (span)
                (and (eqv? (field 'kind span) 2)
                     (server-route-name? (field 'name span))))
              (items capture 'spans))))
    (capture-shape 'span/status-error-present
      (lambda (capture)
        (and (every-span? capture
                          (lambda (span) (and (memv (field 'status-code span) '(0 1 2)) #t)))
             (some (lambda (span) (eqv? (field 'status-code span) 2))
                   (items capture 'spans)))))
    (capture-shape 'span/events-present
      (lambda (capture)
        (some (lambda (span) (pair? (field 'events span))) (items capture 'spans))))
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
    (capture-shape 'metric/default-aggregations
      (lambda (capture)
        (every-metric? capture
                       (lambda (metric)
                         (and (memq (field 'data-type metric) '(sum gauge histogram)) #t)))))
    (capture-shape 'metric/names-conform
      (lambda (capture)
        (every-metric? capture (lambda (metric) (metric-name-conformant? (field 'name metric))))))
    (capture-shape 'metric/units-conform
      (lambda (capture)
        (every-metric? capture (lambda (metric) (ascii-printable? (field 'unit metric) 63)))))
    (capture-shape 'metric/descriptions-conform
      (lambda (capture)
        (every-metric? capture
                       (lambda (metric)
                         (let ((description (field 'description metric)))
                           (and (string? description) (<= (string-length description) 1023)))))))
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
      (lambda (capture)
        (some (lambda (resource) (nonempty-string? (field 'schema-url resource)))
              (items capture 'resources))))
    (capture-shape 'resource/service-name-configured
      (lambda (capture)
        (let ((resources (items capture 'resources)))
          (and (pair? resources)
               (every (lambda (resource)
                        (let ((name (attribute (field 'attributes resource) "service.name")))
                          (and (tagged? 'string name)
                               (nonempty-string? (cadr name))
                               (not (string-prefix? "unknown_service" (cadr name))))))
                      resources)))))
    (capture-shape 'request/traces-present
      (lambda (capture) (> (requests-for capture 'traces) 0)))
    (capture-shape 'request/metrics-present
      (lambda (capture) (> (requests-for capture 'metrics) 0)))
    (capture-shape 'request/logs-present
      (lambda (capture) (> (requests-for capture 'logs) 0)))
    (capture-shape 'request/metric-exports-repeated
      (lambda (capture) (>= (requests-for capture 'metrics) 2)))
    (capture-shape 'exporter/binary-protobuf-request
      (lambda (capture)
        (let ((requests (items capture 'requests)))
          (and (pair? requests)
               (every (lambda (request)
                        (member (field 'content-type request)
                                '("application/x-protobuf" "application/protobuf")))
                      requests)))))
    ; https://opentelemetry.io/docs/specs/otel/protocol/exporter/#user-agent
    (capture-shape 'exporter/otel-user-agent
      (lambda (capture)
        (let ((requests (items capture 'requests)))
          (and (pair? requests)
               (every (lambda (request)
                        (string-prefix? "OTel-OTLP-Exporter-"
                                        (or (header-value request "user-agent") "")))
                      requests)))))
    (capture-shape 'exporter/traces-schema-url-present
      (lambda (capture)
        (or (resource-schema-url? capture 'traces) (scope-schema-url? capture 'scopes))))
    (capture-shape 'exporter/metrics-schema-url-present
      (lambda (capture)
        (or (resource-schema-url? capture 'metrics) (scope-schema-url? capture 'metrics))))
    (capture-shape 'exporter/logs-schema-url-present
      (lambda (capture)
        (or (resource-schema-url? capture 'logs) (scope-schema-url? capture 'logs))))))

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
