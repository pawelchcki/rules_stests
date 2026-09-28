(define-library (datadog realworld profile go-gin-datadog-v2-10-1-v04)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation go-v2.10.1))
  (begin
(define profile
  (realworld-profile
    (id 'go-gin-datadog-v2-10-1-v04)
    (display-name "Go Gin (Datadog 2.10.1, v0.4)")
    (language 'go)
    (tracer-version "v2.10.1")
    (framework "gin")
    (family 'datadog)
    (wire-version "v0.4")
    (application "gin")
    (shape-namespace "datadog.realworld.shape.go-gin-datadog-v2-10-1-v04")
    (implementation (compose ddtrace-go-v2.10.1))
    (service-name "gin-datadog")
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
    ; Not claimed: span/database-client. GORM operation spans carry no span.kind (the database/sql spans do).
    ; Not claimed: span/database-system. GORM operation spans carry no db.system (the database/sql spans do).
    (all (observed span/database-children))
    ; Errors
    (all (observed span/exception-metadata span/errors-explained))
    ; Evidence quality
    (all (observed capture/field-policy-coverage))
    ; Propagation: each scenario's three callers continue their traces and
    ; keep the caller's sampling priority.
    (scenario 'propagation (observed span/tracecontext-parent span/tracecontext-sampling))
    (scenario 'propagation_datadog (observed span/datadog-parent span/datadog-sampling))))
  ))
