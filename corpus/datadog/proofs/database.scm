(define-library (datadog proofs database)
  (export database-proof-rules)
  (import (scheme base))
  (begin
; Database spans.
(define database-proof-rules
  '(("datadog.traces.database-children" (assertion span/database-children) (evidence wire-sufficient))
    ("datadog.database.client-spans" (assertion span/database-client) (evidence wire-sufficient))
    ("datadog.database.system" (assertion span/database-system) (evidence wire-sufficient))))
  ))
