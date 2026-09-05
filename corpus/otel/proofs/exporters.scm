(define-library (otel proofs exporters)
  (export exporters-proof-rules)
  (import (scheme base))
  (begin
(define exporters-proof-rules
  '(("exporters.otlp.otlp-http-binary-protobuf-exporter" (assertion exporter/binary-protobuf-request) (evidence wire-sufficient))
    ("exporters.otlp.honors-the-user-agent-spec" (assertion exporter/otel-user-agent) (evidence wire-sufficient))
    ("exporters.otlp.schemaurl-in-resourcespans-and-scopespans" (assertion exporter/traces-schema-url-present) (evidence requires-immutable-source))
    ("exporters.otlp.schemaurl-in-resourcemetrics-and-scopemetrics" (assertion exporter/metrics-schema-url-present) (evidence requires-immutable-source))
    ("exporters.otlp.metric-exporter-configurable-temporality-preference" (assertion metric/delta-temporality) (evidence wire-sufficient))
    ("exporters.otlp.schemaurl-in-resourcelogs-and-scopelogs" (assertion exporter/logs-schema-url-present) (evidence requires-immutable-source))))
  ))
