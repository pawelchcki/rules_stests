(define-library (otel implementation django-v0.65b0)
  (export django-v0.65b0 django-instrumentation django-exception-middleware)
  (import (scheme base))
  (begin
(define django-v0.65b0 '(django-instrumentation "0.65b0" "a5470c666947acddc24fd4064ec7c1b169dfe8b6"))
(define django-instrumentation "https://github.com/open-telemetry/opentelemetry-python-contrib/blob/a5470c666947acddc24fd4064ec7c1b169dfe8b6/instrumentation/opentelemetry-instrumentation-django/src/opentelemetry/instrumentation/django/__init__.py")
(define django-exception-middleware "https://github.com/open-telemetry/opentelemetry-python-contrib/blob/a5470c666947acddc24fd4064ec7c1b169dfe8b6/instrumentation/opentelemetry-instrumentation-django/src/opentelemetry/instrumentation/django/middleware/otel_middleware.py")
  ))
