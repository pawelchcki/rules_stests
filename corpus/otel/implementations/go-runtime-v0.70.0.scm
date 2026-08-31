(define-library (otel implementation go-runtime-v0.70.0)
  (export go-runtime-v0.70 go-runtime-source)
  (import (scheme base))
  (begin
(define go-runtime-v0.70 '(go-runtime-instrumentation "0.70.0"))
(define go-runtime-source "https://github.com/open-telemetry/opentelemetry-go-contrib/blob/c8a87a60ba1b3374fd16df11fc3eeae6c41abbc9/instrumentation/runtime/runtime.go")
  ))
