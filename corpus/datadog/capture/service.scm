(define-library (datadog capture service)
  (export service-present? base-service? unified-service-tags? version-scoped? process-identity?)
  (import (scheme base) (datadog capture base))
  (begin

; Service identity: which service a span reports under, the unified service
; tags, and the process that produced it.

(define (service-present? capture)
  (all-spans capture (lambda (span) (nonempty-string? (field 'service span)))))

; The configured service is the one each trace's HTTP server span reports.
; A trace is its low 64-bit id plus the high bits in `_dd.p.tid`, which every
; span of a chunk shares but only some carry; two traces may share a low id.
(define (chunk-high-bits spans)
  (map (lambda (span) (list (field 'chunk-index span) (tag span "_dd.p.tid")))
       (filter (lambda (span) (and (field 'chunk-index span) (tag span "_dd.p.tid"))) spans)))
(define (high-bits chunks span)
  (or (tag span "_dd.p.tid")
      (let ((entry (and (field 'chunk-index span) (assoc (field 'chunk-index span) chunks))))
        (and entry (cadr entry)))))
(define (trace-services spans chunks)
  (map (lambda (span) (list (field 'trace-id span) (high-bits chunks span) (field 'service span)))
       (filter web-span? spans)))
; The configured service of span's trace: #f outside every server span's
; trace, and 'ambiguous when traces sharing its low id report different
; services and its high bits cannot tell them apart.
(define (trace-service services chunks span)
  (let* ((high (high-bits chunks span))
         (matching
           (filter (lambda (entry)
                     (and (equal? (car entry) (field 'trace-id span))
                          (or (not high) (not (cadr entry)) (equal? high (cadr entry)))))
                   services)))
    (cond ((null? matching) #f)
          ((every (lambda (entry) (equal? (list-ref entry 2) (list-ref (car matching) 2))) matching)
           (list-ref (car matching) 2))
          (else 'ambiguous))))
(define (for-spans-with-service capture predicate)
  (let* ((spans (items capture 'spans))
         (chunks (chunk-high-bits spans))
         (services (trace-services spans chunks)))
    (and (pair? services)
         (every (lambda (span)
                  (let ((configured (trace-service services chunks span)))
                    (cond ((not configured) #t)
                          ((eq? configured 'ambiguous) #f)
                          (else (predicate span configured)))))
                spans))))

; A span reported under another service (an integration's own service name)
; names the configured service in `_dd.base_service`; spans of the configured
; service do not (system-tests Test_TracerBaseService, Test_BaseService_SqlSpan).
(define (base-service? capture)
  (for-spans-with-service capture
    (lambda (span configured)
      (if (equal? (field 'service span) configured)
          (not (tag span "_dd.base_service"))
          (equal? (tag span "_dd.base_service") configured)))))

; DD_ENV and DD_VERSION: each trace root carries one environment, and every
; span of the configured service carries one version.
(define (single-value? values)
  (and (pair? values) (every nonempty-string? values)
       (every (lambda (value) (equal? value (car values))) values)))
(define (unified-service-tags? capture)
  (let ((spans (items capture 'spans)))
    (and (every (lambda (span) (tag span "env")) (filter trace-root? spans))
         (single-value? (filter present? (map (lambda (span) (tag span "env")) spans)))
         (for-spans-with-service capture
           (lambda (span configured)
             (or (not (equal? (field 'service span) configured)) (tag span "version"))))
         (single-value? (filter present? (map (lambda (span) (tag span "version")) spans))))))
; DD_VERSION describes the configured service only, so spans reported under
; another service carry no version (system-tests Test_Config_UnifiedServiceTagging).
(define (version-scoped? capture)
  (for-spans-with-service capture
    (lambda (span configured)
      (or (equal? (field 'service span) configured) (not (tag span "version"))))))

; Each trace root names the process that produced it: its language, runtime
; id, and process id (system-tests Test_Meta, Test_MetricsStandardTags). One
; application process serves a scenario, so every span that repeats these
; agrees with the roots.
; The sink accepts a runtime id as 32 hex digits or a hyphenated UUID.
(define (runtime-id? value)
  (or (hex-string? value 32)
      (and (string? value) (= (string-length value) 36)
           (let loop ((index 0))
             (or (= index 36)
                 (and (if (memv index '(8 13 18 23))
                          (char=? (string-ref value index) #\-)
                          (hex-string? (string (string-ref value index)) 1))
                      (loop (+ index 1))))))))
; The sink hands a process id over as a number or, past the VM's exact
; integers, a decimal string; either way it is a positive integer. (The VM
; reads numbers as integers, so it cannot see a fractional id.)
(define (process-id? value)
  (or (nonzero-decimal? value) (and (number? value) (integer? value) (>= value 1))))
(define (process-identity? capture)
  (let* ((spans (items capture 'spans))
         (roots (filter trace-root? spans)))
    (and (pair? roots)
         (every (lambda (span)
                  (and (nonempty-string? (tag span "language"))
                       (runtime-id? (tag span "runtime-id"))
                       (process-id? (metric span "process_id"))))
                roots)
         (single-value? (filter present? (map (lambda (span) (tag span "language")) spans)))
         (single-value? (filter present? (map (lambda (span) (tag span "runtime-id")) spans)))
         (let ((process-ids (filter present? (map (lambda (span) (metric span "process_id")) spans))))
           (every (lambda (value) (equal? value (car process-ids))) process-ids)))))
  ))
