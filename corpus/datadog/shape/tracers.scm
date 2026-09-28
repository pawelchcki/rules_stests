(define-library (datadog shape tracers)
  (export dd-trace-py dd-trace-rb dd-trace-go service-version first-finished)
  (import (scheme base) (datadog trace-shape))
  (begin

; What each tracer library adds to spans on its own, under the fixture
; configuration from `datadog_env` (rules/realworld_app.bzl):
;
;   DD_ENV=test DD_VERSION=1
;   DD_TRACE_SAMPLING_RULES=[{"sample_rate":1.0}] DD_TRACE_RATE_LIMIT=-1
;   DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED=true DD_PROFILING_ENABLED=false
;
; Integration builders (aiohttp.scm, django.scm, rails.scm, gin.scm) state
; only what their integration records; see (datadog trace-shape) for how these
; tracer rules are applied.

;; Unified service tagging ------------------------------------------------------

; Every tracer applies DD_ENV to every span. DD_VERSION is applied per
; integration, so builders state it with `service-version`.
(define deployment-env (tag "env" "test"))
(define service-version (tag "version" "1"))

;; Sampling ----------------------------------------------------------------------

; The configured sampling rule keeps every trace the tracer starts: priority 2
; (user keep), rule and limiter rates of 1, knuth sampling rate 1, and decision
; maker -3 ("sampling rule").
(define kept-by-sampling-rule
  (bundle (tag "_dd.p.dm" "-3") (tag "_dd.p.ksr" "1")
          (metric "_dd.rule_psr" 1) (metric "_dd.limit_psr" 1)))
; A continued trace keeps its caller's sampling priority instead.
(define (sampling-priority caller)
  (metric "_sampling_priority_v1" (if caller (caller-priority caller) 2)))
(define (sampling-decision caller)
  (if caller #f kept-by-sampling-rule))

;; Process identity --------------------------------------------------------------

(define (process-identity language)
  (bundle (tag "language" language)
          (tag "runtime-id" "<runtime-id>")
          (metric "process_id" "<process-id>")))
; The high 64 bits of every generated 128-bit trace id.
(define trace-id-high (tag "_dd.p.tid" "<trace-id-high>"))

;; Native field encodings --------------------------------------------------------

; v0.5 encodes each span as a fixed 12-element array.
(define v0.5-fields
  '("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service"
    "span_id" "start" "trace_id" "type"))
(define (fixed-fields . extra)
  (let ((names (append v0.5-fields extra)))
    (lambda (kind error type meta metrics) names)))
; dd-trace-py's v0.4 encoder writes a map and leaves out zero/empty values:
; error 0, the parent id of a root, an empty type, and empty tag maps.
(define (python-v0.4-fields kind error type meta metrics)
  (append '("duration" "name" "resource" "service" "span_id" "start" "trace_id")
          (if (null? meta) '() '("meta"))
          (if (null? metrics) '() '("metrics"))
          (if (= error 0) '() '("error"))
          (if (equal? kind "root") '() '("parent_id"))
          (if (equal? type "") '() '("type"))))

;; dd-trace-py -------------------------------------------------------------------

; Trace-level tags go on the trace's root span. A W3C caller's traceparent is
; kept as a tag; a caller that sent Datadog headers has its `_dd.p.tid` copied
; to every span of the trace.
(define (dd-trace-py wire process-tags)
  (tracer
    (list 'exception-stack "error.stack")
    (list 'native-fields (if (equal? wire "v0.4") python-v0.4-fields (fixed-fields)))
    (list 'trace-root
          (lambda (caller)
            (list trace-id-high (tag "_dd.tags.process" process-tags)
                  (process-identity "python") (metric "_dd.tracer_kr" 1)
                  (sampling-priority caller) (sampling-decision caller)
                  (and caller (eq? (caller-style caller) 'w3c)
                       (tag "traceparent" (caller-header caller))))))
    (list 'every-span
          (lambda (caller)
            (list deployment-env
                  (and caller (eq? (caller-style caller) 'datadog) trace-id-high))))
    (list 'service-entry (list (metric "_dd.top_level" 1)))
    (list 'marks '())))

;; dd-trace-rb -------------------------------------------------------------------

; dd-trace-rb writes process tags on the first span of each serialized chunk,
; which is the first span of the trace to finish. A W3C caller without a
; Datadog tracestate member is recorded with decision maker -0 and a zero
; `_dd.parent_id`.
(define first-finished (mark 'first-finished))
(define (dd-trace-rb process-tags)
  (tracer
    (list 'exception-stack "error.stack")
    (list 'native-fields (fixed-fields "meta_struct" "span_links"))
    (list 'trace-root
          (lambda (caller)
            (list trace-id-high (process-identity "ruby")
                  (metric "_dd.profiling.enabled" 0)
                  (sampling-priority caller) (sampling-decision caller)
                  (and caller (eq? (caller-style caller) 'w3c)
                       (bundle (tag "_dd.p.dm" "-0")
                               (tag "_dd.parent_id" "0000000000000000"))))))
    (list 'every-span (lambda (caller) (list deployment-env)))
    (list 'service-entry (list (metric "_dd.top_level" 1)))
    (list 'marks (list (list 'first-finished (tag "_dd.tags.process" process-tags))))))

;; dd-trace-go -------------------------------------------------------------------

; dd-trace-go stamps process identity and the sampling priority on every span,
; and records the span attribute schema on service-entry spans.
(define (dd-trace-go process-tags)
  (tracer
    (list 'exception-stack "error.handling_stack")
    (list 'native-fields (fixed-fields "meta_struct"))
    (list 'trace-root
          (lambda (caller)
            (list trace-id-high (tag "_dd.tags.process" process-tags)
                  (metric "_dd.profiling.enabled" 0) (sampling-decision caller))))
    (list 'every-span
          (lambda (caller)
            (list deployment-env (process-identity "go") (sampling-priority caller))))
    (list 'service-entry
          (list (metric "_dd.top_level" 1) (metric "_dd.trace_span_attribute_schema" 0)))
    (list 'marks '())))
  ))
