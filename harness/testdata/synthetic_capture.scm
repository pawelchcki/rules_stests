; Positive fixture for every proof rule in the corpus: the sink probe asserts
; that each rule's capture shape holds here, and that a targeted mutation of
; this text makes the shape fail. Field spellings mirror the decoder in
; harness/otel_sink/validation.rs.
((requests (
  ((signal traces) (received-unix-nano 1) (method "POST") (path "/v1/traces") (content-type "application/x-protobuf") (content-encoding "identity") (headers (("host" "127.0.0.1:4318") ("user-agent" "OTel-OTLP-Exporter-Python/1.44.0"))))
  ((signal metrics) (received-unix-nano 2) (method "POST") (path "/v1/metrics") (content-type "application/x-protobuf") (content-encoding "identity") (headers (("host" "127.0.0.1:4318") ("User-Agent" "OTel-OTLP-Exporter-Python/1.44.0"))))
  ((signal metrics) (received-unix-nano 3) (method "POST") (path "/v1/metrics") (content-type "application/x-protobuf") (content-encoding "identity") (headers (("host" "127.0.0.1:4318") ("user-agent" "OTel-OTLP-Exporter-Python/1.44.0"))))
  ((signal logs) (received-unix-nano 4) (method "POST") (path "/v1/logs") (content-type "application/x-protobuf") (content-encoding "identity") (headers (("host" "127.0.0.1:4318") ("user-agent" "OTel-OTLP-Exporter-Python/1.44.0"))))))
 (resources (
  ((signal metrics) (attributes (("process.runtime.name" (string "go")) ("service.name" (string "synthetic-service")))) (schema-url "https://opentelemetry.io/schemas/1.43.0"))))
 (scopes (
  ((name "trace.scope") (schema-url "https://opentelemetry.io/schemas/1.11.0"))))
 (spans (
  ((scope "trace.scope") (trace-id "1111111111111111111111111111111a") (span-id "222222222222222a")
   (parent-span-id "") (parent-class root) (parent-valid #t) (trace-state "") (name "GET /api/articles/:slug") (kind 2)
   (start 1) (end 4) (attributes (("string.key" (string "value")) ("integer.key" (integer 7)) ("unicode.key" (string "ünïcødé"))))
   (events (
    ((name "exception") (time 2) (attributes (("exception.type" (string "ValueError")) ("exception.message" (string "bad")) ("exception.stacktrace" (long-string 300)) ("exception.escaped" (string "False")))))
    ((name "exception") (time 3) (attributes (("exception.type" (string "KeyError")) ("exception.message" (string "missing")) ("exception.stacktrace" (long-string 400)) ("exception.escaped" (string "True")))))))
   (status-code 2) (status-message "boom") (flags 257))
  ((scope "trace.scope") (trace-id "1111111111111111111111111111111a") (span-id "333333333333333a")
   (parent-span-id "1111111111111111") (parent-class child) (parent-valid #t) (trace-state "") (name "SELECT articles") (kind 3)
   (start 2) (end 3) (attributes (("string.key" (string "child")) ("integer.key" (integer 8)))) (events ())
   (status-code 0) (status-message "") (flags 256))
  ((scope "trace.scope") (trace-id "5555555555555555555555555555555a") (span-id "666666666666666a")
   (parent-span-id "00f067aa0ba902b7") (parent-class external) (parent-valid #t) (trace-state "") (name "GET /api/tags") (kind 2)
   (start 5) (end 6) (attributes ()) (events ())
   (status-code 0) (status-message "") (flags 769))
  ((scope "trace.scope") (trace-id "7777777777777777777777777777777a") (span-id "888888888888888a")
   (parent-span-id "") (parent-class root) (parent-valid #t) (trace-state "") (name "GET /api/tags") (kind 2)
   (start 7) (end 8) (attributes (("capped.key" (string "kept")) ("capped.other" (string "kept")) ("capped.third" (string "kept")))) (events ())
   (dropped-attributes 4) (status-code 0) (status-message "") (flags 257))))
 (metrics (
  ((scope "meter.scope") (scope-version "1.2.3") (schema-url "https://opentelemetry.io/schemas/1.11.0") (name "counter") (description "counter description") (unit "{item}") (data-type sum) (aggregation-temporality delta) (data-points 2) (exemplars 2) (exemplars-with-trace-context 2) (exemplars-with-time 2) (points-with-start 2) (points-start-le-time 2) (monotonic #t))
  ((scope "meter.scope") (scope-version "1.2.3") (schema-url "https://opentelemetry.io/schemas/1.11.0") (name "updown") (description "updown description") (unit "{item}") (data-type sum) (aggregation-temporality cumulative) (data-points 1) (exemplars 0) (exemplars-with-trace-context 0) (exemplars-with-time 0) (points-with-start 1) (points-start-le-time 1) (monotonic #f))
  ((scope "meter.scope") (scope-version "1.2.3") (schema-url "https://opentelemetry.io/schemas/1.11.0") (name "histogram") (description "histogram description") (unit "ms") (data-type histogram) (aggregation-temporality delta) (data-points 1) (exemplars 1) (exemplars-with-trace-context 1) (exemplars-with-time 1) (points-with-start 1) (points-start-le-time 1) (monotonic absent))
  ((scope "meter.scope") (scope-version "1.2.3") (schema-url "https://opentelemetry.io/schemas/1.11.0") (name "gauge") (description "gauge description") (unit "1") (data-type gauge) (aggregation-temporality absent) (data-points 1) (exemplars 0) (exemplars-with-trace-context 0) (exemplars-with-time 0) (points-with-start 0) (points-start-le-time 0) (monotonic absent))))
 (logs (
  ((scope "logger.scope") (schema-url "https://opentelemetry.io/schemas/1.11.0")))))
