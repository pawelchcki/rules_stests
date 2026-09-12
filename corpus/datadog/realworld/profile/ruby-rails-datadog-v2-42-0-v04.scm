(define-library (datadog realworld profile ruby-rails-datadog-v2-42-0-v04)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation ruby-v2.42.0))
  (begin
(define profile
  (realworld-profile
    (id 'ruby-rails-datadog-v2-42-0-v04)
    (display-name "Ruby Rails (Datadog 2.42.0, v0.4)")
    (language 'ruby)
    (tracer-version "2.42.0")
    (framework "rails")
    (family 'datadog)
    (wire-version "v0.4")
    (application "rails")
    (shape-namespace "datadog.realworld.shape.ruby-rails-datadog-v2-42-0-v04")
    (implementation (compose ddtrace-ruby-v2.42.0))
    (service-name "rails-datadog")
    (signals 'traces)
    (all (observed span/native-fields span/ids-valid span/completed span/database-children
                   span/root-present span/http-classification span/exception-metadata
                   span/service-present request/headers-and-counts capture/semantic-valid
                   capture/field-policy-coverage))))
  ))
