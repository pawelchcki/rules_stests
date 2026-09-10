(define-library (datadog realworld profile example-aiohttp-datadog-v4-14-0)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation python-v4.14.0))
  (begin
    (define profile
      (realworld-profile
        (id 'example-aiohttp-datadog-v4-14-0)
        (display-name "Consumer aiohttp (Datadog 4.14.0, v0.5)")
        (language 'python)
        (framework "aiohttp")
        (family 'datadog)
        (wire-version "v0.5")
        (application "aiohttp")
        (shape-namespace "datadog.realworld.shape.example-aiohttp-datadog-v4-14-0")
        (implementation (compose ddtrace-python-v4.14.0))
        (service-name "example-aiohttp-datadog")
        (signals 'traces)
        (all (observed span/native-fields span/ids-valid span/completed
                       span/root-present span/http-classification span/exception-metadata
                       span/service-present request/headers-and-counts capture/semantic-valid))))))
