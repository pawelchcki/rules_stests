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
    (all (observed span/native-fields span/ids-valid span/completed span/database-children
                   span/root-present span/http-classification span/exception-metadata
                   span/service-present request/headers-and-counts capture/semantic-valid
                   capture/field-policy-coverage))))
  ))
