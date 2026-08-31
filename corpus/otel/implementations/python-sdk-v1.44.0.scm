(define-library (otel implementation python-sdk-v1.44.0)
  (export python-sdk-v1.44
          python-trace-api python-resource-api python-meter-api
          python-meter-sdk python-instrument-api python-aggregation-api
          python-logger-api)
  (import (scheme base))
  (begin
(define python-sdk-v1.44 '(python-sdk "1.44.0"))
(define python-trace-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/trace/__init__.py")
(define python-resource-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/resources/__init__.py")
(define python-meter-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/metrics/_internal/__init__.py")
(define python-meter-sdk "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/metrics/_internal/__init__.py")
(define python-instrument-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/metrics/_internal/instrument.py")
(define python-aggregation-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-sdk/src/opentelemetry/sdk/metrics/_internal/aggregation.py")
(define python-logger-api "https://github.com/open-telemetry/opentelemetry-python/blob/53a5a40c9604583c501bcf13970a635f00e62df4/opentelemetry-api/src/opentelemetry/_logs/_internal/__init__.py")
  ))
