(define-library (datadog realworld profile example-django-datadog-v4-14-0)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation python-v4.14.0))
  (begin
    (define profile
      (realworld-profile
        (id 'example-django-datadog-v4-14-0)
        (display-name "Consumer Django (Datadog 4.14.0, v0.5)")
        (language 'python)
        (tracer-version "4.14.0")
        (framework "django")
        (family 'datadog)
        (wire-version "v0.5")
        (application "django")
        (shape-namespace "datadog.realworld.shape.example-django-datadog-v4-14-0")
        (implementation (compose ddtrace-python-v4.14.0))
        (service-name "example-django-datadog")
        (signals 'traces)
        (all (observed span/native-fields span/ids-valid span/completed span/database-children
                       span/root-present span/http-classification span/exception-metadata
                       span/service-present request/headers-and-counts capture/semantic-valid
                       capture/field-policy-coverage))
        (scenario 'propagation (observed span/tracecontext-parent))
        (scenario 'propagation_datadog (observed span/datadog-parent))))))
