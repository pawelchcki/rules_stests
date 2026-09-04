(define-library (otel proofs)
  (export proof-rule proof-rules)
  (import (scheme base)
          (otel proofs traces)
          (otel proofs metrics)
          (otel proofs logs)
          (otel proofs resource)
          (otel proofs exporters)
          (otel proofs environment))
  (begin

; Runtime facade over the signal-specific, language-neutral proof tables.
(define proof-rules
  (append traces-proof-rules metrics-proof-rules logs-proof-rules
          resource-proof-rules exporters-proof-rules environment-proof-rules))

(define (find-proof-rule feature-id rules)
  (if (null? rules)
      #f
      (if (string=? feature-id (car (car rules)))
          (car rules)
          (find-proof-rule feature-id (cdr rules)))))

(define (proof-rule feature-id)
  (find-proof-rule feature-id proof-rules))
  ))
