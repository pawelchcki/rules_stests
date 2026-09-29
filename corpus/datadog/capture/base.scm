(define-library (datadog capture base)
  (export field items every some count filter present? all-spans check
          nonempty-string? decimal? nonzero-decimal? uint64? metric-number?
          string-prefix? lowercase-hex? hex-string? tag metric header-value header-count
          web-span? database-span? controller-span? http-client-span?
          set-server-operation! root-span? trace-root?)
  (import (scheme base) (scheme char) (telemetry contract-error))
  (begin

; Readers for the decoded capture the sink hands to validators. Every Datadog
; integer arrives as a decimal string: the VM's fixnums would otherwise round
; unsigned IDs and nanosecond timestamps before a check inspects them.

(define (field key object)
  (let ((entry (and (pair? object) (assq key object))))
    (and entry (pair? (cdr entry)) (cadr entry))))
(define (items object key)
  (let ((value (field key object))) (if (list? value) value '())))
(define (every predicate values)
  (or (null? values) (and (predicate (car values)) (every predicate (cdr values)))))
(define (some predicate values)
  (and (pair? values) (or (predicate (car values)) (some predicate (cdr values)))))
(define (count predicate values)
  (let loop ((values values) (result 0))
    (if (null? values) result
        (loop (cdr values) (if (predicate (car values)) (+ result 1) result)))))
(define (filter predicate values)
  (let loop ((values values) (result '()))
    (cond ((null? values) (reverse result))
          ((predicate (car values)) (loop (cdr values) (cons (car values) result)))
          (else (loop (cdr values) result)))))
(define (present? value) value)
; A nonempty capture whose every span satisfies predicate.
(define (all-spans capture predicate)
  (and (pair? (items capture 'spans)) (every predicate (items capture 'spans))))

(define (check condition message)
  (telemetry-check condition "DATADOG-CONTRACT-V2" "Datadog contract sentinel" message))

(define (nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))
(define (decimal? value)
  (and (nonempty-string? value)
       (or (= (string-length value) 1) (not (char=? (string-ref value 0) #\0)))
       (every (lambda (c) (and (char>=? c #\0) (char<=? c #\9))) (string->list value))))
(define (nonzero-decimal? value) (and (decimal? value) (not (string=? value "0"))))
(define (uint64? value)
  (and (decimal? value)
       (or (< (string-length value) 20)
           (and (= (string-length value) 20)
                (not (string<? "18446744073709551615" value))))))
(define (metric-number? value)
  (or (number? value) (decimal? value)
      (and (nonempty-string? value) (> (string-length value) 1)
           (char=? (string-ref value 0) #\-)
           (decimal? (substring value 1 (string-length value))))))
(define (string-prefix? prefix value)
  (and (string? value) (<= (string-length prefix) (string-length value))
       (string=? prefix (substring value 0 (string-length prefix)))))
(define (lowercase-hex? value length)
  (and (string? value) (= (string-length value) length)
       (every (lambda (c) (or (and (char>=? c #\0) (char<=? c #\9))
                              (and (char>=? c #\a) (char<=? c #\f))))
              (string->list value))))

(define (hex-string? value length)
  (and (string? value) (= (string-length value) length)
       (every (lambda (c) (or (char-numeric? c) (memv (char-downcase c) '(#\a #\b #\c #\d #\e #\f))))
              (string->list value))))

; Span `meta` (string tags) and `metrics` (numeric tags).
(define (tag span key)
  (let ((entry (assoc key (items span 'meta)))) (and entry (cadr entry))))
(define (metric span key)
  (let ((entry (assoc key (items span 'metrics)))) (and entry (cadr entry))))

; Intake request headers are case-insensitive.
(define (header-value request key)
  (let loop ((headers (items request 'headers)))
    (cond ((null? headers) #f)
          ((string=? (string-downcase (caar headers)) key) (cadr (car headers)))
          (else (loop (cdr headers))))))
(define (header-count request key)
  (count (lambda (header) (string=? (string-downcase (car header)) key))
         (items request 'headers)))

; The HTTP server span each RealWorld request produces.
(define selected-server-operation #f)
(define (set-server-operation! operation) (set! selected-server-operation operation))
(define (web-span? span)
  (and (if selected-server-operation
           (equal? (field 'name span) selected-server-operation)
           (member (field 'name span) '("aiohttp.request" "django.request" "rack.request" "gin.request" "http.request")))
       (equal? (field 'type span) "web")))
(define (controller-span? span)
  (and (equal? (field 'name span) "rails.action_controller")
       (equal? (field 'type span) "web")
       (nonempty-string? (field 'resource span))
       (nonempty-string? (tag span "rails.route.action"))
       (nonempty-string? (tag span "rails.route.controller"))))
(define (http-client-span? span)
  (and (equal? (field 'name span) "http.request")
       (equal? (field 'type span) "http")
       (equal? (tag span "span.kind") "client")
       (nonempty-string? (tag span "http.method"))
       (nonempty-string? (tag span "http.url"))))
; dd-trace-py emits sqlite.connection.commit without the "sql" type, so name
; classification is part of the database inventory.
(define (database-span? span)
  (or (equal? (field 'type span) "sql")
      (string-prefix? "sqlite." (field 'name span))))
; A span with no parent at all, or whose parent lives in an upstream caller.
(define (root-span? span) (equal? (field 'parent-id span) "0"))
(define (trace-root? span) (member (field 'parent-kind span) '("root" "remote")))
  ))
