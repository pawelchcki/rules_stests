(define-library (datadog realworld profile python-django-datadog-v4-14-0-v05)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation python-v4.14.0))
  (begin
(define profile
  (realworld-profile
    (id 'python-django-datadog-v4-14-0-v05)
    (display-name "Python django (Datadog 4.14.0, v0.5)")
    (language 'python)
    (framework "django")
    (family 'datadog)
    (wire-version "v0.5")
    (application "django")
    (shape-namespace "datadog.realworld.shape.python-django-datadog-v4-14-0-v05")
    (implementation (compose ddtrace-python-v4.14.0))
    (service-name "django-datadog")
    (signals 'traces)
    (all (observed span/native-fields span/ids-valid span/completed span/database-children
                   span/root-present span/http-classification span/exception-metadata
                   span/service-present request/headers-and-counts capture/semantic-valid))
    (scenario 'propagation (observed span/tracecontext-parent))
    (scenario 'propagation_datadog (observed span/datadog-parent))))
  ))
