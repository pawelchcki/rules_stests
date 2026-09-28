(define-library (datadog proofs propagation)
  (export propagation-proof-rules)
  (import (scheme base))
  (begin
; Continuing a caller's trace from W3C or Datadog headers.
(define propagation-proof-rules
  '(("datadog.propagation.tracecontext" (assertion span/tracecontext-parent) (evidence wire-sufficient))
    ("datadog.propagation.datadog" (assertion span/datadog-parent) (evidence wire-sufficient))
    ("datadog.propagation.tracecontext-sampling" (assertion span/caller-sampling-kept) (evidence wire-sufficient))
    ("datadog.propagation.datadog-sampling" (assertion span/caller-sampling-kept) (evidence wire-sufficient))))
  ))
