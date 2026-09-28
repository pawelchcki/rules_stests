(define-library (datadog proofs traces)
  (export traces-proof-rules)
  (import (scheme base))
  (begin
; Span structure, identifiers, and completion.
(define traces-proof-rules
  '(("datadog.traces.native-fields" (assertion span/native-fields) (evidence wire-sufficient))
    ("datadog.traces.unsigned-identifiers" (assertion span/ids-valid) (evidence wire-sufficient))
    ("datadog.traces.completed" (assertion span/completed) (evidence wire-sufficient))
    ("datadog.traces.root-span" (assertion span/root-present) (evidence wire-sufficient))
    ("datadog.traces.128-bit-trace-ids" (assertion span/trace-id-128) (evidence wire-sufficient))))
  ))
