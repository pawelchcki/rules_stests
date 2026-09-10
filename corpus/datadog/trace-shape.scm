(define-library (datadog trace-shape)
  (export datadog-validate-trace-shapes)
  (import (scheme base) (datadog capture shapes))
  (begin
; The native sink canonicalizes unordered trees and groups equal roots. Exact
; equality preserves every selected native field, edge, and multiplicity.
(define (datadog-validate-trace-shapes expected capture)
  (check (equal? expected (field 'trace-shapes capture))
         "Datadog native trace topology differs from reviewed scenario shape"))
  ))
