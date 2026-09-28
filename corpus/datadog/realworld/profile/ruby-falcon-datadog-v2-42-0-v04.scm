(define-library (datadog realworld profile ruby-falcon-datadog-v2-42-0-v04)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation ruby-v2.42.0))
  (begin
(define profile
  (realworld-profile
    (id 'ruby-falcon-datadog-v2-42-0-v04)
    (display-name "Ruby Sinatra on Falcon (Datadog 2.42.0, v0.4)")
    (language 'ruby)
    (tracer-version "2.42.0")
    (framework "sinatra")
    (family 'datadog)
    (wire-version "v0.4")
    (application "falcon")
    (shape-namespace "datadog.realworld.shape.ruby-falcon-datadog-v2-42-0-v04")
    (implementation (compose ddtrace-ruby-v2.42.0))
    (service-name "falcon-datadog")
    (signals 'traces)
    ; Intake requests
    (all (observed request/headers-and-counts request/library-headers capture/semantic-valid
                   capture/chunk-coherence))
    ; Span structure and identifiers
    (all (observed span/native-fields span/ids-valid span/completed span/root-present
                   span/trace-id-128))
    ; Service identity
    ; Not claimed: span/version-scoped. Sequel spans report under "sqlite" but carry version.
    (all (observed span/service-present span/base-service span/unified-service-tags
                   span/process-identity))
    ; Sampling
    (all (observed span/sampling-priority span/decision-maker span/rule-keep))
    ; HTTP server spans
    ; Not claimed: span/http-absolute-url. Rack records the path in http.url and the origin in http.base_url
    ; (system-tests Test_Meta: bug APMAPI-922).
    (all (observed span/http-classification span/http-server-tags span/http-route-template))
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
