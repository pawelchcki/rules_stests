(define-library (datadog proofs service)
  (export service-proof-rules)
  (import (scheme base))
  (begin
; Which service and process a span reports, and its unified service tags.
(define service-proof-rules
  '(("datadog.traces.service-identity" (assertion span/service-present) (evidence wire-sufficient))
    ("datadog.service.base-service" (assertion span/base-service) (evidence wire-sufficient))
    ("datadog.service.unified-service-tags" (assertion span/unified-service-tags) (evidence wire-sufficient))
    ("datadog.service.version-scoped" (assertion span/version-scoped) (evidence wire-sufficient))
    ("datadog.service.process-identity" (assertion span/process-identity) (evidence wire-sufficient))))
  ))
