(define-library (telemetry contract-error)
  (export telemetry-contract-error telemetry-check)
  (import (scheme base) (scheme write))
  (begin
; The family chooses the wire marker and sentinel. Keeping emission in one
; place preserves framing and byte-for-byte legacy OTLP diagnostics.
(define (telemetry-contract-error marker sentinel message)
  (display "[[" (current-error-port))
  (display marker (current-error-port))
  (display ":" (current-error-port))
  (display (string-length message) (current-error-port))
  (display "]]" (current-error-port))
  (display message (current-error-port))
  (error sentinel))
(define (telemetry-check condition marker sentinel message)
  (if condition #t (telemetry-contract-error marker sentinel message)))
  ))
