(define-library (datadog proofs errors)
  (export errors-proof-rules)
  (import (scheme base))
  (begin
; Error flags and recorded exceptions.
(define errors-proof-rules
  '(("datadog.traces.exception-metadata" (assertion span/exception-metadata) (evidence wire-sufficient))
    ("datadog.errors.explained" (assertion span/errors-explained) (evidence wire-sufficient))))
  ))
