(define-library (datadog capture sampling)
  (export sampling-priority? decision-maker? rule-keep?)
  (import (scheme base) (scheme char) (datadog capture base))
  (begin

; Sampling decisions as the agent reads them (system-tests
; parametric/test_sampling_span_tags.py, test_sampling_rates.py).

(define sampling-rate-metrics '("_dd.rule_psr" "_dd.limit_psr" "_dd.agent_psr"))
(define (priority span) (metric span "_sampling_priority_v1"))

; Every trace root carries a sampling priority from -1 (user reject) to 2
; (user keep); spans of one chunk never disagree about it; the rates behind a
; decision appear only on trace roots.
(define (chunk-priorities-agree? spans)
  (let loop ((spans spans) (chunk #f) (known #f))
    (if (null? spans)
        #t
        (let* ((span (car spans))
               (current (if (equal? (field 'chunk-index span) chunk) known #f))
               (value (priority span)))
          (and (or (not value) (not current) (equal? value current))
               (loop (cdr spans) (field 'chunk-index span) (or value current)))))))
(define (sampling-priority? capture)
  (let ((spans (items capture 'spans)))
    (and (pair? spans)
         (every (lambda (span) (memv (priority span) '(-1 0 1 2))) (filter trace-root? spans))
         (chunk-priorities-agree? spans)
         (every (lambda (span)
                  (or (trace-root? span)
                      (not (some (lambda (key) (metric span key)) sampling-rate-metrics))))
                spans))))

; `_dd.p.dm` names the mechanism behind a decision as "-<number>". It travels
; with the trace, so only a trace root or the first span of a chunk carries
; it, and every trace the tracer started itself records one.
(define (decision-maker-value? value)
  (and (string? value) (> (string-length value) 1)
       (char=? (string-ref value 0) #\-)
       (every char-numeric? (string->list (substring value 1 (string-length value))))))
(define (decision-maker? capture)
  (let loop ((spans (items capture 'spans)) (chunk #f) (ok (pair? (items capture 'spans))))
    (if (or (not ok) (null? spans))
        ok
        (let* ((span (car spans))
               (first-in-chunk (not (equal? (field 'chunk-index span) chunk)))
               (value (tag span "_dd.p.dm")))
          (loop (cdr spans) (field 'chunk-index span)
                (and (or (not value)
                         (and (decision-maker-value? value) (or first-in-chunk (trace-root? span))))
                     (or (not (equal? (field 'parent-kind span) "root")) value)))))))

; The fixtures configure DD_TRACE_SAMPLING_RULES=[{"sample_rate":1.0}] and
; DD_TRACE_RATE_LIMIT=-1, so every trace the tracer starts is kept by that
; rule: user keep (2), rule rate 1, limiter rate 1, and decision maker -3.
(define (rule-keep? capture)
  (let ((roots (filter (lambda (span) (equal? (field 'parent-kind span) "root"))
                       (items capture 'spans))))
    (and (pair? roots)
         (every (lambda (span)
                  (and (eqv? (priority span) 2)
                       (eqv? (metric span "_dd.rule_psr") 1)
                       (eqv? (metric span "_dd.limit_psr") 1)
                       (equal? (tag span "_dd.p.dm") "-3")))
                roots))))
  ))
