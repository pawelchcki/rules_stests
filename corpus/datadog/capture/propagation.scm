(define-library (datadog capture propagation)
  (export propagated? caller-sampling-kept?)
  (import (scheme base) (datadog capture base))
  (begin

; The propagation scenarios (corpus/realworld/hurl/propagation*.hurl) send
; three requests from the same upstream parent span, each continuing its own
; 128-bit trace, either as W3C `traceparent` or as Datadog headers:
;   trace id (low 64 bits, decimal)  high 64 bits in _dd.p.tid
(define propagated-parent "67667974448284343")
(define propagated-ids
  '(("11803532876627986230" "4bf92f3577b34da6")
    ("9965072336285547154" "8c1e0a5b6d2f4739")
    ("11276220234964099125" "b3f7d21c9e6a4805")))

(define (continues-caller? span id)
  (and (web-span? span)
       (equal? (field 'trace-id span) (car id))
       (equal? (field 'parent-id span) propagated-parent)
       (equal? (tag span "_dd.p.tid") (cadr id))))

; Each caller's trace is continued by a server span parented to the caller.
(define (propagated? capture)
  (every (lambda (id) (some (lambda (span) (continues-caller? span id)) (items capture 'spans)))
         propagated-ids))

; Every caller marks its trace sampled (traceparent flags 01,
; x-datadog-sampling-priority 1). The continued traces keep priority 1 and
; the tracer adds no sampling decision of its own: no rule or limiter rate and
; no rule decision maker.
(define (caller-sampling-kept? capture)
  (every (lambda (id)
           (let ((spans (filter (lambda (span) (continues-caller? span id)) (items capture 'spans))))
             (and (pair? spans)
                  (every (lambda (span)
                           (and (eqv? (metric span "_sampling_priority_v1") 1)
                                (not (metric span "_dd.rule_psr"))
                                (not (metric span "_dd.limit_psr"))
                                (not (equal? (tag span "_dd.p.dm") "-3"))))
                         spans))))
         propagated-ids))
  ))
