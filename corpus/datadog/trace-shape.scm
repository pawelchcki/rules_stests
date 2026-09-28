(define-library (datadog trace-shape)
  (export traces trace repeat times
          span tag untag metric unmetric service span-type raised mark bundle
          own-clauses child-spans clause-value span-name span-resource
          continues traceparent datadog-headers
          caller-style caller-priority caller-header
          tracer app-service)
  (import (scheme base))
  (begin

; The vocabulary reviewed Datadog shapes are written in.
;
; A scenario shape lists the traces one scenario produces:
;
;   (traces (django-app "v0.4")
;     (trace (django-request "GET" "api/tags" 200 ...
;              (sqlite "SELECT ...")))
;     (repeat 3 (trace ...)))
;
; Spans are written with integration builders (see corpus/datadog/shape/),
; which are themselves ordinary `span` calls with the integration's fixed
; tags.  Everything a tracer adds on its own - sampling decisions on the trace
; root, `_dd.top_level` on service-entry spans, `_dd.base_service` on spans
; reported under an integration service, process identity, and which native
; fields the wire encoding writes - is derived here from the `tracer` the
; shape names, so each rule is stated once instead of on every span.
;
; `traces` evaluates to the same canonical datum the sink reports under
; `trace-shapes`; (datadog trace-shape match) compares the two exactly,
; ignoring only the order of traces, siblings, tags, and native fields.

; The sink reports the service of each trace's HTTP server span as this
; placeholder, so shapes are independent of the configured service name.
(define app-service "<service>")

;; Clauses -------------------------------------------------------------------

; Later clauses override earlier ones, so a builder's defaults can be adjusted
; by the clauses a shape passes to it.
(define (tag key value) (list 'tag key value))
(define (untag key) (list 'untag key))
(define (metric key value) (list 'metric key value))
(define (unmetric key) (list 'unmetric key))
(define (service name) (list 'service name))
(define (span-type value) (list 'type value))
; A recorded exception: error 1 plus type, message, and a stack trace. The
; tracer decides which tag holds the stack; the sink checks the stack itself
; and reports it as "<validated-stack>".
(define (raised type message) (list 'raised type message))
; A tracer-specific positional fact the sink cannot derive from the tree (for
; example which span finished first). The tracer maps it to tags.
(define (mark name) (list 'mark name))
(define (bundle . clauses) (cons 'bundle clauses))
; `count` identical sibling spans.
(define (times count value) (apply bundle (make-list count value)))

(define (flatten-clauses clauses)
  (let loop ((clauses clauses) (result '()))
    (cond ((null? clauses) (reverse result))
          ((not (car clauses)) (loop (cdr clauses) result))
          ((eq? (car (car clauses)) 'bundle)
           (loop (cdr clauses) (append (reverse (flatten-clauses (cdr (car clauses)))) result)))
          (else (loop (cdr clauses) (cons (car clauses) result))))))

;; Spans ---------------------------------------------------------------------

; Child spans are passed as clauses too; their order does not matter.
(define (span name resource . clauses)
  (list 'span-node name resource (flatten-clauses clauses)))
(define (span-node? value) (and (pair? value) (eq? (car value) 'span-node)))
; Builders that place children somewhere other than directly below the span
; they build separate the two kinds of clauses first.
(define (own-clauses clauses)
  (let loop ((clauses (flatten-clauses clauses)) (result '()))
    (cond ((null? clauses) (reverse result))
          ((span-node? (car clauses)) (loop (cdr clauses) result))
          (else (loop (cdr clauses) (cons (car clauses) result))))))
(define (child-spans clauses)
  (let loop ((clauses (flatten-clauses clauses)) (result '()))
    (cond ((null? clauses) (reverse result))
          ((span-node? (car clauses)) (loop (cdr clauses) (cons (car clauses) result)))
          (else (loop (cdr clauses) result)))))
(define (span-name node) (list-ref node 1))
(define (span-resource node) (list-ref node 2))
(define (node-clauses node) (list-ref node 3))

;; Distributed tracing callers -------------------------------------------------

; A root span that continues a trace started by an upstream caller. The caller
; is described by the propagation headers it sent.
(define (continues caller) caller)
(define (caller-style caller) (list-ref caller 1))
(define (caller-trace-id caller) (list-ref caller 2))
(define (caller-parent-id caller) (list-ref caller 3))
(define (caller-trace-id-high caller) (list-ref caller 4))
(define (caller-priority caller) (list-ref caller 5))
(define (caller-header caller) (list-ref caller 6))

; W3C `traceparent: 00-<trace-id>-<parent-id>-<flags>`. Datadog stores the
; low 64 trace-id bits and the parent id as unsigned decimals and the high 64
; bits in `_dd.p.tid`; a sampled flag becomes sampling priority 1 (auto keep).
(define (traceparent header)
  (list 'caller 'w3c
        (hex->decimal (string-copy header 19 35))
        (hex->decimal (string-copy header 36 52))
        (string-copy header 3 19)
        (if (string=? (string-copy header 53 55) "01") 1 0)
        header))
; `x-datadog-trace-id`, `x-datadog-parent-id`, `x-datadog-sampling-priority`,
; and the `_dd.p.tid` member of `x-datadog-tags`.
(define (datadog-headers trace-id parent-id priority trace-id-high)
  (list 'caller 'datadog trace-id parent-id trace-id-high priority #f))

; Unsigned 64-bit identifiers exceed the VM's fixnums, so convert through a
; little-endian list of decimal digits.
(define (hex-digit character)
  (let ((code (char->integer character)))
    (cond ((and (>= code 48) (<= code 57)) (- code 48))
          ((and (>= code 97) (<= code 102)) (- code 87))
          ((and (>= code 65) (<= code 70)) (- code 55))
          (else (error "invalid hexadecimal digit" character)))))
(define (digits-times-add digits factor addend)
  (let loop ((digits digits) (carry addend) (result '()))
    (if (null? digits)
        (if (= carry 0) (reverse result)
            (loop '() (quotient carry 10) (cons (remainder carry 10) result)))
        (let ((value (+ (* (car digits) factor) carry)))
          (loop (cdr digits) (quotient value 10) (cons (remainder value 10) result))))))
(define (hex->decimal text)
  (let loop ((index 0) (digits '(0)))
    (if (= index (string-length text))
        (let render ((digits (reverse digits)) (result '()))
          (cond ((and (pair? digits) (= (car digits) 0) (pair? (cdr digits)) (null? result))
                 (render (cdr digits) result))
                ((null? digits) (list->string (reverse result)))
                (else (render (cdr digits) (cons (integer->char (+ 48 (car digits))) result)))))
        (loop (+ index 1) (digits-times-add digits 16 (hex-digit (string-ref text index)))))))

;; Traces --------------------------------------------------------------------

(define (trace . roots) (list 'trace 1 roots))
(define (repeat count value)
  (if (and (pair? value) (eq? (car value) 'trace))
      (list 'trace (* count (cadr value)) (list-ref value 2))
      (error "repeat expects a trace" value)))

;; Tracers -------------------------------------------------------------------

; A tracer states what the tracer library adds to spans on its own:
;   exception-stack   the tag holding a recorded exception's stack
;   native-fields     (lambda (kind error type meta metrics) field-names):
;                     which native span fields the wire encoding writes
;   trace-root        (lambda (caller) clauses) for each trace's root span;
;                     caller is #f when the tracer made the sampling decision
;   every-span        (lambda (caller) clauses) for every span of the trace
;   service-entry     clauses for spans that enter a service (roots and spans
;                     whose service differs from their parent's)
;   marks             ((mark clause ...) ...) for tracer-specific marks
(define (tracer . entries) entries)
(define (tracer-field tracer key)
  (let ((entry (assq key tracer)))
    (if entry (cadr entry) (error "tracer lacks" key))))

;; Evaluation to the canonical datum -----------------------------------------

(define (assoc-remove key entries)
  (let loop ((entries entries) (result '()))
    (cond ((null? entries) (reverse result))
          ((equal? (car (car entries)) key) (loop (cdr entries) result))
          (else (loop (cdr entries) (cons (car entries) result))))))
(define (assoc-set key value entries)
  (append (assoc-remove key entries) (list (list key value))))

(define (clause-value clauses kind default)
  (let loop ((clauses clauses) (value default))
    (cond ((null? clauses) value)
          ((eq? (car (car clauses)) kind) (loop (cdr clauses) (cadr (car clauses))))
          (else (loop (cdr clauses) value)))))
(define (node-caller node)
  (let loop ((clauses (node-clauses node)))
    (cond ((null? clauses) #f)
          ((eq? (car (car clauses)) 'caller) (car clauses))
          (else (loop (cdr clauses))))))
(define (node-marks node)
  (let loop ((clauses (node-clauses node)) (result '()))
    (cond ((null? clauses) (reverse result))
          ((eq? (car (car clauses)) 'mark) (loop (cdr clauses) (cons (cadr (car clauses)) result)))
          (else (loop (cdr clauses) result)))))

; Applies clauses in order to (error meta metrics type).
(define (apply-clauses tracer clauses state)
  (let loop ((clauses clauses) (err (list-ref state 0)) (meta (list-ref state 1))
             (metrics (list-ref state 2)) (type (list-ref state 3)))
    (if (null? clauses)
        (list err meta metrics type)
        (let* ((clause (car clauses)) (kind (car clause)) (rest (cdr clauses)))
          (case kind
            ((tag) (loop rest err (assoc-set (cadr clause) (list-ref clause 2) meta) metrics type))
            ((untag) (loop rest err (assoc-remove (cadr clause) meta) metrics type))
            ((metric) (loop rest err meta (assoc-set (cadr clause) (list-ref clause 2) metrics) type))
            ((unmetric) (loop rest err meta (assoc-remove (cadr clause) metrics) type))
            ((type) (loop rest err meta metrics (cadr clause)))
            ((raised)
             (loop rest 1
                   (assoc-set (tracer-field tracer 'exception-stack) "<validated-stack>"
                     (assoc-set "error.message" (list-ref clause 2)
                       (assoc-set "error.type" (cadr clause) meta)))
                   metrics type))
            (else (loop rest err meta metrics type)))))))

(define (mark-clauses tracer marks)
  (let loop ((marks marks) (result '()))
    (if (null? marks)
        result
        (let ((entry (assq (car marks) (tracer-field tracer 'marks))))
          (if entry
              (loop (cdr marks) (append result (cdr entry)))
              (error "tracer does not define mark" (car marks)))))))

(define (evaluate-span tracer node parent-service caller)
  (let* ((clauses (node-clauses node))
         (root? (not parent-service))
         (own-service (clause-value clauses 'service app-service))
         (entry? (or root? (not (equal? own-service parent-service))))
         (derived
           (append (flatten-clauses ((tracer-field tracer 'every-span) caller))
                   (if root? (flatten-clauses ((tracer-field tracer 'trace-root) caller)) '())
                   (if entry? (flatten-clauses (tracer-field tracer 'service-entry)) '())
                   (if (equal? own-service app-service) '()
                       (list (tag "_dd.base_service" app-service)))
                   (flatten-clauses (mark-clauses tracer (node-marks node)))))
         (state (apply-clauses tracer (append derived clauses) (list 0 '() '() "")))
         (err (list-ref state 0)) (meta (list-ref state 1))
         (metrics (list-ref state 2)) (type (list-ref state 3))
         (kind (cond ((not root?) "child") (caller "remote") (else "root")))
         (children
           (let loop ((clauses clauses) (result '()))
             (cond ((null? clauses) (reverse result))
                   ((span-node? (car clauses))
                    (loop (cdr clauses)
                          (cons (evaluate-span tracer (car clauses) own-service caller) result)))
                   (else (loop (cdr clauses) result))))))
    (append
      (list (list 'native-fields ((tracer-field tracer 'native-fields) kind err type meta metrics))
            (list 'service own-service)
            (list 'name (span-name node))
            (list 'type type)
            (list 'resource (span-resource node))
            (list 'parent-kind kind))
      (if (and root? caller)
          (list (list 'parent-id (caller-parent-id caller))
                (list 'trace-id (caller-trace-id caller))
                (list 'trace-id-high (caller-trace-id-high caller)))
          '())
      (list (list 'error err)
            (list 'meta meta)
            (list 'metrics metrics)
            (list 'children children)))))

(define (evaluate-trace tracer roots)
  (map (lambda (root) (evaluate-span tracer root #f (node-caller root))) roots))

; The canonical `trace-shapes` datum: ((count n) (roots (span ...))) groups.
(define (traces tracer . items)
  (map (lambda (item)
         (if (and (pair? item) (eq? (car item) 'trace))
             (list (list 'count (cadr item))
                   (list 'roots (evaluate-trace tracer (list-ref item 2))))
             (error "traces expects trace or repeat forms" item)))
       items))
  ))
