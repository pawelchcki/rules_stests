(define-library (otel proofs logs)
  (export logs-proof-rules)
  (import (scheme base))
  (begin
(define logs-proof-rules
  '(("logs.loggerprovider-get-logger" log/scope-associated requires-immutable-source)
    ("logs.logger-emit-logrecord" log/record-present wire-sufficient)
    ("logs.otlp-http-exporter" log/otlp-http-request-present wire-sufficient)))
  ))
