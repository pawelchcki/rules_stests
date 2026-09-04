(define-library (otel proofs resource)
  (export resource-proof-rules)
  (import (scheme base))
  (begin
(define resource-proof-rules
  '(("resource.create-from-attributes" (assertion resource/attributes-present) (evidence requires-immutable-source))
    ("resource.retrieve-attributes" (assertion resource/attributes-present) (evidence requires-immutable-source))
    ("resource.resource-detector-interface-mechanism" (assertion resource/go-detector-present) (evidence requires-immutable-source))
    ("resource.resource-detectors-populate-schema-url" (assertion resource/schema-url-present) (evidence requires-immutable-source))))
  ))
