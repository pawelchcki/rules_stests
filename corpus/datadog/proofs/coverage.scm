(define-library (datadog proofs coverage)
  (export coverage-proof-rules)
  (import (scheme base))
  (begin
; Whether a capture can serve as parity evidence at all.
(define coverage-proof-rules
  '(("datadog.coverage.field-policies" (assertion capture/field-policy-coverage) (evidence wire-sufficient))))
  ))
