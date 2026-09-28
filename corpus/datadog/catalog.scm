(define-library (datadog catalog)
  (export
    request/headers-and-counts request/library-headers capture/semantic-valid capture/chunk-coherence
    span/native-fields span/ids-valid span/completed span/root-present
    span/trace-id-128 span/service-present span/base-service span/unified-service-tags
    span/version-scoped span/process-identity span/sampling-priority span/decision-maker
    span/rule-keep span/tracecontext-parent span/datadog-parent span/tracecontext-sampling span/datadog-sampling
    span/http-classification span/http-server-tags span/http-absolute-url span/http-route-template
    span/database-children span/database-client span/database-system span/exception-metadata
    span/errors-explained capture/field-policy-coverage)
  (import (scheme base))
  (begin

; Profile bindings for the Datadog feature ids (features.json), by theme.
; intake
(define request/headers-and-counts "datadog.intake.headers-and-counts")
(define request/library-headers "datadog.intake.library-headers")
(define capture/semantic-valid "datadog.intake.semantic-validity")
(define capture/chunk-coherence "datadog.intake.chunk-coherence")
; traces
(define span/native-fields "datadog.traces.native-fields")
(define span/ids-valid "datadog.traces.unsigned-identifiers")
(define span/completed "datadog.traces.completed")
(define span/root-present "datadog.traces.root-span")
(define span/trace-id-128 "datadog.traces.128-bit-trace-ids")
; service
(define span/service-present "datadog.traces.service-identity")
(define span/base-service "datadog.service.base-service")
(define span/unified-service-tags "datadog.service.unified-service-tags")
(define span/version-scoped "datadog.service.version-scoped")
(define span/process-identity "datadog.service.process-identity")
; sampling
(define span/sampling-priority "datadog.sampling.priority")
(define span/decision-maker "datadog.sampling.decision-maker")
(define span/rule-keep "datadog.sampling.rule-keep")
; propagation
(define span/tracecontext-parent "datadog.propagation.tracecontext")
(define span/datadog-parent "datadog.propagation.datadog")
(define span/tracecontext-sampling "datadog.propagation.tracecontext-sampling")
(define span/datadog-sampling "datadog.propagation.datadog-sampling")
; http
(define span/http-classification "datadog.traces.http-classification")
(define span/http-server-tags "datadog.http.server-tags")
(define span/http-absolute-url "datadog.http.absolute-url")
(define span/http-route-template "datadog.http.route-template")
; database
(define span/database-children "datadog.traces.database-children")
(define span/database-client "datadog.database.client-spans")
(define span/database-system "datadog.database.system")
; errors
(define span/exception-metadata "datadog.traces.exception-metadata")
(define span/errors-explained "datadog.errors.explained")
; coverage
(define capture/field-policy-coverage "datadog.coverage.field-policies")
  ))
