(define-library (datadog realworld profile python-django-datadog-v4-14-0-v04)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation python-v4.14.0))
  (begin
(define profile
  (realworld-profile
    (id 'python-django-datadog-v4-14-0-v04)
    (display-name "Python django (Datadog 4.14.0, v0.4)")
    (language 'python)
    (tracer-version "4.14.0")
    (framework "django")
    (family 'datadog)
    (wire-version "v0.4")
    (application "django")
    (shape-namespace "datadog.realworld.shape.python-django-datadog-v4-14-0-v04")
    (implementation (compose ddtrace-python-v4.14.0))
    (service-name "django-datadog")
    (signals 'traces)
    (all (observed span/native-fields span/ids-valid span/completed span/database-children
                   span/root-present span/http-classification span/exception-metadata
                   span/service-present request/headers-and-counts capture/semantic-valid
                   capture/field-policy-coverage))))
  ))
