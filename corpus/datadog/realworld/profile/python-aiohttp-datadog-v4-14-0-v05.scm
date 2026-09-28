(define-library (datadog realworld profile python-aiohttp-datadog-v4-14-0-v05)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation python-v4.14.0))
  (begin
(define profile
  (realworld-profile
    (id 'python-aiohttp-datadog-v4-14-0-v05)
    (display-name "Python aiohttp (Datadog 4.14.0, v0.5)")
    (language 'python)
    (tracer-version "4.14.0")
    (framework "aiohttp")
    (family 'datadog)
    (wire-version "v0.5")
    (application "aiohttp")
    (shape-namespace "datadog.realworld.shape.python-aiohttp-datadog-v4-14-0-v05")
    (implementation (compose ddtrace-python-v4.14.0))
    (service-name "aiohttp-datadog")
    (signals 'traces)
    ; Intake requests
    (all (observed request/headers-and-counts request/library-headers capture/semantic-valid
                   capture/chunk-coherence))
    ; Span structure and identifiers
    (all (observed span/native-fields span/ids-valid span/completed span/root-present
                   span/trace-id-128))
    ; Service identity
    ; Not claimed: span/version-scoped. SQLAlchemy spans report under "sqlite" but carry version.
    (all (observed span/service-present span/base-service span/unified-service-tags
                   span/process-identity))
    ; Sampling
    (all (observed span/sampling-priority span/decision-maker span/rule-keep))
    ; HTTP server spans
    (all (observed span/http-classification span/http-server-tags span/http-absolute-url
                   span/http-route-template))
    ; Database spans
    ; Not claimed: span/database-system. SQLAlchemy spans name the database in sql.db, not db.system.
    (all (observed span/database-children span/database-client))
    ; Errors
    (all (observed span/exception-metadata span/errors-explained))
    ; Evidence quality
    (all (observed capture/field-policy-coverage))
    ; Propagation: each scenario's three callers continue their traces and
    ; keep the caller's sampling priority.
    (scenario 'propagation (observed span/tracecontext-parent span/tracecontext-sampling))
    (scenario 'propagation_datadog (observed span/datadog-parent span/datadog-sampling))))
  ))
