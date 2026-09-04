(define-library (otel proofs logs)
  (export logs-proof-rules)
  (import (scheme base))
  (begin
(define logs-proof-rules
  '(("logs.loggerprovider-get-logger" (assertion log/scope-associated) (evidence requires-immutable-source))
    ("logs.logger-emit-logrecord" (assertion log/record-present) (evidence wire-sufficient))
    ("logs.batchlogrecordprocessor" (assertion log/record-present) (evidence requires-immutable-source))
    ("logs.otlp-http-exporter" (assertion log/otlp-http-request-present) (evidence wire-sufficient))))
  ))
