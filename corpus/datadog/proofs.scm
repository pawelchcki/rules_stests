(define-library (datadog proofs)
  (export proof-rule proof-rules)
  (import (scheme base)
          (datadog proofs intake)
          (datadog proofs traces)
          (datadog proofs service)
          (datadog proofs sampling)
          (datadog proofs propagation)
          (datadog proofs http)
          (datadog proofs database)
          (datadog proofs errors)
          (datadog proofs coverage))
  (begin
; Every Datadog feature and the capture assertion that proves it, by theme.
(define proof-rules
  (append intake-proof-rules traces-proof-rules service-proof-rules
          sampling-proof-rules propagation-proof-rules http-proof-rules
          database-proof-rules errors-proof-rules coverage-proof-rules))
(define (proof-rule feature) (assoc feature proof-rules))
  ))
