(define-library (otel contract-error)
  (export contract-error check)
  (import (scheme base) (telemetry contract-error))
  (begin
(define (contract-error message)
  (telemetry-contract-error "OTLP-CONTRACT-V1" "OTLP contract sentinel" message))
(define (check condition message) (if condition #t (contract-error message)))
  ))
