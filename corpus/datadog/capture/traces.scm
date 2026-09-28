(define-library (datadog capture traces)
  (export native-fields? ids-valid? completed? root-present? trace-id-128?
          rails-controller-children? http-client?)
  (import (scheme base) (datadog capture base))
  (begin

; Span structure, identifiers, and completion.

(define (native-fields? capture)
  (all-spans capture
    (lambda (span)
      (and (every (lambda (key) (nonempty-string? (field key span))) '(name service resource))
           (string? (field 'type span))
           (memv (field 'error span) '(0 1))
           (every (lambda (entry) (and (string? (car entry)) (string? (cadr entry)))) (items span 'meta))
           (every (lambda (entry) (and (string? (car entry)) (metric-number? (cadr entry)))) (items span 'metrics))))))

; Unsigned 64-bit decimal identifiers; trace and span ids are nonzero.
(define (ids-valid? capture)
  (all-spans capture
    (lambda (span)
      (and (every (lambda (key) (uint64? (field key span))) '(trace-id span-id parent-id))
           (nonzero-decimal? (field 'trace-id span))
           (nonzero-decimal? (field 'span-id span))
           (eq? (field 'ids-valid span) #t)))))

(define (completed? capture)
  (all-spans capture
    (lambda (span)
      (and (nonzero-decimal? (field 'start span)) (decimal? (field 'duration span))
           (eq? (field 'completed span) #t)))))

(define (root-present? capture) (some root-span? (items capture 'spans)))

; Rails normally contributes a Rack span and a controller child for each
; handled request. Authentication before-actions may deliberately halt with a
; 401 before ActionController::Metal#process_action starts.
(define (span-high-bits spans span)
  (or (tag span "_dd.p.tid")
      (let ((chunk (field 'chunk-index span)))
        (and chunk
             (let ((tagged (filter (lambda (candidate)
                                     (and (equal? (field 'chunk-index candidate) chunk)
                                          (tag candidate "_dd.p.tid")))
                                   spans)))
               (and (pair? tagged) (tag (car tagged) "_dd.p.tid")))))))
(define (rails-controller-children? capture)
  (let ((spans (items capture 'spans)))
    (and (some controller-span? spans)
         (every
           (lambda (server)
             (or (not (web-span? server))
                 (some (lambda (span)
                         (and (controller-span? span)
                              (equal? (field 'trace-id span) (field 'trace-id server))
                              (equal? (span-high-bits spans span) (span-high-bits spans server))
                              (equal? (field 'parent-id span) (field 'span-id server))))
                       spans)
                 (equal? (tag server "http.status_code") "401")))
           spans))))

(define (http-client? capture)
  (some http-client-span? (items capture 'spans)))

; 128-bit trace ids (system-tests parametric/test_128_bit_traceids.py). Each
; trace root carries the high 64 bits in `_dd.p.tid` as 16 lowercase hex
; digits; a chunk never mixes two values. Ids the tracer generated itself put
; a Unix timestamp in the top 32 bits and zeros in the next 32.
(define (hex-value text)
  (let loop ((index 0) (value 0))
    (if (= index (string-length text))
        value
        (loop (+ index 1)
              (+ (* value 16)
                 (let ((code (char->integer (string-ref text index))))
                   (if (<= code 57) (- code 48) (- code 87))))))))
(define (generated-high-bits? high)
  (and (string=? (substring high 8 16) "00000000")
       ; 1678573964 is 0x640CFD8C, the bound system-tests uses (March 2023).
       (> (hex-value (substring high 0 8)) 1678573964)))
(define (trace-id-high-valid? span)
  (let ((high (tag span "_dd.p.tid")))
    (and (lowercase-hex? high 16)
         (not (string=? high "0000000000000000"))
         (or (not (equal? (field 'parent-kind span) "root")) (generated-high-bits? high)))))
(define (chunk-high-bits-agree? spans)
  (let loop ((spans spans) (chunk #f) (high #f))
    (if (null? spans)
        #t
        (let* ((span (car spans))
               (same-chunk (equal? (field 'chunk-index span) chunk))
               (known (if same-chunk high #f))
               (value (tag span "_dd.p.tid")))
          (and (or (not value) (not known) (string=? value known))
               (loop (cdr spans) (field 'chunk-index span) (or value known)))))))
(define (trace-id-128? capture)
  (let ((roots (filter trace-root? (items capture 'spans))))
    (and (pair? roots)
         (every trace-id-high-valid? roots)
         (chunk-high-bits-agree? (items capture 'spans)))))
  ))
