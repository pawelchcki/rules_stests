(define-library (otel proofs exporters)
  (export exporters-proof-rules)
  (import (scheme base))
  (begin
(define exporters-proof-rules
  '(("exporters.otlp.otlp-http-binary-protobuf-exporter" (assertion exporter/binary-protobuf-request) (evidence wire-sufficient))))
  ))
