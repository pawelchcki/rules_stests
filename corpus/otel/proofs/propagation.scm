(define-library (otel proofs propagation)
  (export propagation-proof-rules)
  (import (scheme base))
  (begin

; A server span whose parent arrived in a request header is the observable end
; of the whole extraction path: the globally registered composite propagator
; selected the W3C TraceContext propagator, which read `traceparent` through the
; carrier getter and turned it into a remote parent span context.
(define propagation-proof-rules
  '(("context-propagation.tracecontext-propagator" (assertion span/external-parent-present) (evidence wire-sufficient))
    ("context-propagation.textmappropagator" (assertion span/external-parent-present) (evidence requires-immutable-source))
    ("context-propagation.fields" (assertion span/external-parent-present) (evidence requires-immutable-source))
    ("context-propagation.getter-argument" (assertion span/external-parent-present) (evidence requires-immutable-source))
    ("context-propagation.global-propagator" (assertion span/external-parent-present) (evidence requires-immutable-source))
    ("context-propagation.composite-propagator" (assertion span/external-parent-present) (evidence requires-immutable-source))))
  ))
