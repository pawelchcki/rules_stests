(define-library (otel proofs resource)
  (export resource-proof-rules)
  (import (scheme base))
  (begin
(define resource-proof-rules
  '(("resource.create-from-attributes" resource/attributes-present requires-immutable-source)
    ("resource.resource-detector-interface-mechanism" resource/go-detector-present requires-immutable-source)
    ("resource.resource-detectors-populate-schema-url" resource/schema-url-present requires-immutable-source)))
  ))
