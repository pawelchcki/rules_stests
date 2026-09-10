(define-library (datadog realworld profile python-aiohttp-datadog-v4-14-0-v04)
  (export profile)
  (import (scheme base) (datadog profile) (datadog catalog)
          (datadog implementation python-v4.14.0))
  (begin
(define profile
  (realworld-profile
    (id 'python-aiohttp-datadog-v4-14-0-v04)
    (display-name "Python aiohttp (Datadog 4.14.0, v0.4)")
    (language 'python)
    (framework "aiohttp")
    (family 'datadog)
    (wire-version "v0.4")
    (application "aiohttp")
    (shape-namespace "datadog.realworld.shape.python-aiohttp-datadog-v4-14-0-v04")
    (implementation (compose ddtrace-python-v4.14.0))
    (service-name "aiohttp-datadog")
    (signals 'traces)
    (all (observed span/native-fields span/ids-valid span/completed span/database-children
                   span/root-present span/http-classification span/exception-metadata
                   span/service-present request/headers-and-counts capture/semantic-valid))))
  ))
