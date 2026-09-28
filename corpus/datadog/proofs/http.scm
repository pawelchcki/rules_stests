(define-library (datadog proofs http)
  (export http-proof-rules)
  (import (scheme base))
  (begin
; HTTP server spans.
(define http-proof-rules
  '(("datadog.traces.http-classification" (assertion span/http-classification) (evidence wire-sufficient))
    ("datadog.http.server-tags" (assertion span/http-server-tags) (evidence wire-sufficient))
    ("datadog.http.absolute-url" (assertion span/http-absolute-url) (evidence wire-sufficient))
    ("datadog.http.route-template" (assertion span/http-route-template) (evidence wire-sufficient))))
  ))
