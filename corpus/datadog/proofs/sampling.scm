(define-library (datadog proofs sampling)
  (export sampling-proof-rules)
  (import (scheme base))
  (begin
; Sampling priorities and the decisions behind them.
(define sampling-proof-rules
  '(("datadog.sampling.priority" (assertion span/sampling-priority) (evidence wire-sufficient))
    ("datadog.sampling.decision-maker" (assertion span/decision-maker) (evidence wire-sufficient))
    ("datadog.sampling.rule-keep" (assertion span/rule-keep) (evidence wire-sufficient))))
  ))
