(define-library (otel proofs environment)
  (export environment-proof-rules)
  (import (scheme base))
  (begin

; Environment-variable features are proved indirectly: the suite sets the
; variable and the wire shows the effect the variable is defined to have.
(define environment-proof-rules
  '(("environment-variables.otel-service-name" (assertion resource/service-name-configured) (evidence wire-sufficient))
    ("environment-variables.otel-exporter-otlp" (assertion exporter/binary-protobuf-request) (evidence wire-sufficient))
    ("environment-variables.otel-traces-exporter" (assertion request/traces-present) (evidence wire-sufficient))
    ("environment-variables.otel-metrics-exporter" (assertion request/metrics-present) (evidence wire-sufficient))
    ("environment-variables.otel-logs-exporter" (assertion request/logs-present) (evidence wire-sufficient))
    ("environment-variables.otel-exporter-otlp-metrics-temporality-preference" (assertion metric/delta-temporality) (evidence wire-sufficient))
    ("environment-variables.otel-span-attribute-count-limit" (assertion span/attribute-limit-enforced) (evidence wire-sufficient))
    ("environment-variables.otel-metric-export-interval" (assertion request/metric-exports-repeated) (evidence wire-sufficient))))
  ))
