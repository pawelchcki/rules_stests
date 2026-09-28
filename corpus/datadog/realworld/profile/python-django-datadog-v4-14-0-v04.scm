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
    ; Intake requests
    (all (observed request/headers-and-counts request/library-headers capture/semantic-valid
                   capture/chunk-coherence))
    ; Span structure and identifiers
    (all (observed span/native-fields span/ids-valid span/completed span/root-present
                   span/trace-id-128))
    ; Service identity
    (all (observed span/service-present span/base-service span/unified-service-tags
                   span/version-scoped span/process-identity))
    ; Sampling
    (all (observed span/sampling-priority span/decision-maker span/rule-keep))
    ; HTTP server spans
    (all (observed span/http-classification span/http-server-tags span/http-absolute-url
                   span/http-route-template))
    ; Database spans
    (all (observed span/database-children span/database-client span/database-system))
    ; Errors
    (all (observed span/exception-metadata span/errors-explained))
    ; Evidence quality
    (all (observed capture/field-policy-coverage))
    ; Propagation: each scenario's three callers continue their traces and
    ; keep the caller's sampling priority.
    (scenario 'propagation (observed span/tracecontext-parent span/tracecontext-sampling))
    (scenario 'propagation_datadog (observed span/datadog-parent span/datadog-sampling))))
  ))
