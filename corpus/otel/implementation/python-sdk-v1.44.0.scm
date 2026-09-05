(define-library (otel implementation python-sdk-v1.44.0)
  (export python-sdk-v1.44
          python-trace-api python-trace-sdk python-status-api python-attributes-api
          python-resource-api python-meter-api
          python-meter-sdk python-instrument-api python-aggregation-api
          python-exemplar-filter python-metric-reader
          python-logger-api python-propagation-api)
  (import (scheme base))
  (begin
(define python-sdk-v1.44 '(python-sdk "1.44.0"))
(define python-trace-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/trace/__init__.py")
; StatusCode, which enumerates UNSET, OK and ERROR, and Span.set_status.
(define python-status-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/trace/status.py")
; Attribute key and value validation, which accepts any non-empty string key.
(define python-attributes-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/attributes/__init__.py")
; SpanLimits, which reads OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT and applies the cap.
(define python-trace-sdk "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/trace/__init__.py")
; TraceBasedExemplarFilter, the filter that ties an exemplar to a sampled span.
(define python-exemplar-filter "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/metrics/_internal/exemplar/exemplar_filter.py")
; MetricReader, which maps a preferred temporality onto each instrument kind.
(define python-metric-reader "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/metrics/_internal/export/__init__.py")
(define python-resource-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/resources/__init__.py")
(define python-meter-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/metrics/_internal/__init__.py")
(define python-meter-sdk "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/metrics/_internal/__init__.py")
(define python-instrument-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/metrics/_internal/instrument.py")
(define python-aggregation-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/metrics/_internal/aggregation.py")
(define python-logger-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/_logs/_internal/__init__.py")
(define python-propagation-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/propagate/__init__.py")
  ))
