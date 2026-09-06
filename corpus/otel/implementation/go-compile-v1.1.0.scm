(define-library (otel implementation go-compile-v1.1.0)
  (export go-compile-v1.1 go-compile-release
          go-propagation-api go-global-propagation-api go-attribute-api)
  (import (scheme base))
  (begin
(define go-compile-v1.1 '(go-compile-instrumentation "1.1.0"))
(define go-compile-release "https://github.com/open-telemetry/opentelemetry-go-compile-instrumentation/tree/449ee08a682586adb177e4402845ed404565879f")
; otelc v1.1.0 links OpenTelemetry Go v1.45.0. This file defines the
; TextMapPropagator carrier, Fields contract, and composite implementation.
(define go-propagation-api "https://github.com/open-telemetry/opentelemetry-go/blob/93a693edeed0e07ce5ebd1dfe67af42d1e2055d8/propagation/propagation.go")
; The process-global TextMapPropagator getter and setter.
(define go-global-propagation-api "https://github.com/open-telemetry/opentelemetry-go/blob/93a693edeed0e07ce5ebd1dfe67af42d1e2055d8/propagation.go")
; Attribute keys are unrestricted Go strings, and String preserves a Go string
; as an attribute value.
(define go-attribute-api "https://github.com/open-telemetry/opentelemetry-go/blob/93a693edeed0e07ce5ebd1dfe67af42d1e2055d8/attribute/key.go")
  ))
