(define-library (datadog proofs intake)
  (export intake-proof-rules)
  (import (scheme base))
  (begin
; What reaches the agent: request headers, chunk counts, and decodable spans.
(define intake-proof-rules
  '(("datadog.intake.headers-and-counts" (assertion request/headers-and-counts) (evidence wire-sufficient))
    ("datadog.intake.library-headers" (assertion request/library-headers) (evidence wire-sufficient))
    ("datadog.intake.semantic-validity" (assertion capture/semantic-valid) (evidence wire-sufficient))
    ("datadog.intake.chunk-coherence" (assertion capture/chunk-coherence) (evidence wire-sufficient))))
  ))
