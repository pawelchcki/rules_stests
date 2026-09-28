(define-library (datadog capture intake)
  (export headers-and-counts? library-headers? semantic-valid? chunk-coherence?)
  (import (scheme base) (datadog capture base))
  (begin

; What reaches the agent's /v0.4/traces and /v0.5/traces intake.

(define (request-valid? request)
  (and (member (field 'method request) '("POST" "PUT"))
       (member (field 'wire-version request) '("v0.4" "v0.5"))
       (equal? (field 'path request) (string-append "/" (field 'wire-version request) "/traces"))
       (equal? (field 'content-type request) "application/msgpack")
       (every (lambda (key) (= (header-count request key) 1))
              '("datadog-meta-lang" "datadog-meta-tracer-version" "x-datadog-trace-count"))
       (nonempty-string? (header-value request "datadog-meta-lang"))
       (nonempty-string? (header-value request "datadog-meta-tracer-version"))
       (decimal? (field 'trace-count request))
       (equal? (header-value request "x-datadog-trace-count") (field 'trace-count request))
       (equal? (field 'trace-count request) (number->string (field 'chunk-count request)))
       (> (field 'span-count request) 0)))
(define (headers-and-counts? capture)
  (and (pair? (items capture 'requests)) (every request-valid? (items capture 'requests))))

; The library identity headers system-tests requires on every non-empty trace
; request (tests/test_data_integrity.py, Test_TraceHeaders).
(define library-header-names
  '("datadog-meta-lang" "datadog-meta-lang-interpreter" "datadog-meta-lang-version"
    "datadog-meta-tracer-version"))
(define (library-headers? capture)
  (and (pair? (items capture 'requests))
       (every (lambda (request)
                (every (lambda (key)
                         (and (= (header-count request key) 1)
                              (nonempty-string? (header-value request key))))
                       library-header-names))
              (items capture 'requests))))

(define (semantic-valid? capture) (eq? (field 'semantic-valid capture) #t))

; Every span of a chunk belongs to the chunk's trace: the agent reads a chunk
; as one trace (system-tests Test_TraceHeaders.test_traces_coherence).
(define (chunk-coherence? capture)
  (let loop ((spans (items capture 'spans)) (chunk #f) (trace-id #f))
    (cond ((null? spans) (pair? (items capture 'spans)))
          ((equal? (field 'chunk-index (car spans)) chunk)
           (and (equal? (field 'trace-id (car spans)) trace-id)
                (loop (cdr spans) chunk trace-id)))
          (else (loop (cdr spans) (field 'chunk-index (car spans)) (field 'trace-id (car spans)))))))
  ))
