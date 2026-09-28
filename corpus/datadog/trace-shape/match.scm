(define-library (datadog trace-shape match)
  (export datadog-validate-trace-shapes trace-shape-difference)
  (import (scheme base) (datadog capture base))
  (begin

; Exact comparison of a reviewed shape with the sink's `trace-shapes` datum.
;
; Every span field, tag, metric, native field name, edge, and multiplicity has
; to agree. Only order is ignored: traces, sibling spans, tags, metrics, and
; native field names are compared as multisets. Equality modulo order is an
; equivalence, so greedily pairing equal elements is exact.

(define scalar-fields '(name resource service type parent-kind error parent-id trace-id trace-id-high))

(define (remove-first item values)
  (cond ((null? values) '())
        ((eq? (car values) item) (cdr values))
        (else (cons (car values) (remove-first item (cdr values))))))
(define (find-first predicate values)
  (cond ((null? values) #f)
        ((predicate (car values)) (car values))
        (else (find-first predicate (cdr values)))))

; Tag maps and native field lists have unique entries, so equal length plus
; containment is set equality.
(define (same-set? expected actual)
  (and (= (length expected) (length actual))
       (every (lambda (entry) (member entry actual)) expected)))

(define (same-multiset? same? expected actual)
  (and (= (length expected) (length actual))
       (let loop ((expected expected) (actual actual))
         (or (null? expected)
             (let ((match (find-first (lambda (candidate) (same? (car expected) candidate)) actual)))
               (and match (loop (cdr expected) (remove-first match actual))))))))

(define (same-span? expected actual)
  (and (every (lambda (key) (equal? (field key expected) (field key actual))) scalar-fields)
       (same-set? (items expected 'native-fields) (items actual 'native-fields))
       (same-set? (items expected 'meta) (items actual 'meta))
       (same-set? (items expected 'metrics) (items actual 'metrics))
       (same-multiset? same-span? (items expected 'children) (items actual 'children))))

(define (same-trace? expected actual) (same-multiset? same-span? expected actual))

; Groups become one entry per trace so repeated traces can be written either
; as `(repeat n ...)` or one after another.
(define (expand-groups groups)
  (let loop ((groups (if (list? groups) groups '())) (result '()))
    (if (null? groups)
        (reverse result)
        (let repeat ((count (field 'count (car groups))) (result result))
          (if (and (integer? count) (> count 0))
              (repeat (- count 1) (cons (items (car groups) 'roots) result))
              (loop (cdr groups) result))))))

;; Explanations ----------------------------------------------------------------

(define (text value) (if (string? value) value "?"))
(define (shorten value)
  (let ((value (text value)))
    (if (> (string-length value) 72) (string-append (substring value 0 69) "...") value)))
(define (describe span)
  (string-append (text (field 'name span)) " " (shorten (field 'resource span))))
(define (show value)
  (cond ((string? value) (string-append "\"" value "\""))
        ((number? value) (number->string value))
        ((not value) "absent")
        ((symbol? value) (symbol->string value))
        (else "a structured value")))

(define (entry-difference kind expected actual)
  (let ((missing (find-first (lambda (entry) (not (member entry actual))) expected))
        (extra (find-first (lambda (entry) (not (member entry expected))) actual)))
    (cond ((and missing (assoc (car missing) actual))
           (string-append kind " " (text (car missing)) " expected " (show (cadr missing))
                          " but was " (show (cadr (assoc (car missing) actual)))))
          (missing (string-append "missing " kind " " (text (car missing)) " " (show (cadr missing))))
          (extra (string-append "unexpected " kind " " (text (car extra)) " " (show (cadr extra))))
          (else #f))))

(define (field-difference expected actual)
  (let ((key (find-first (lambda (key) (not (equal? (field key expected) (field key actual))))
                         scalar-fields)))
    (if key
        (string-append (symbol->string key) " expected " (show (field key expected))
                       " but was " (show (field key actual)))
        (let ((fields-expected (items expected 'native-fields))
              (fields-actual (items actual 'native-fields)))
          (cond ((not (same-set? fields-expected fields-actual))
                 (let ((missing (find-first (lambda (name) (not (member name fields-actual))) fields-expected))
                       (extra (find-first (lambda (name) (not (member name fields-expected))) fields-actual)))
                   (if missing
                       (string-append "native field " (text missing) " is not encoded")
                       (string-append "native field " (text extra) " is encoded unexpectedly"))))
                ((entry-difference "tag" (items expected 'meta) (items actual 'meta)))
                ((entry-difference "metric" (items expected 'metrics) (items actual 'metrics)))
                (else #f))))))

(define (similar? expected actual)
  (and (equal? (field 'name expected) (field 'name actual))
       (equal? (field 'resource expected) (field 'resource actual))))

; Pairs equal children, then explains the first unpaired one.
(define (children-difference expected actual path)
  (let loop ((pending expected) (actual actual) (unmatched '()))
    (if (pair? pending)
        (let ((match (find-first (lambda (candidate) (same-span? (car pending) candidate)) actual)))
          (if match
              (loop (cdr pending) (remove-first match actual) unmatched)
              (loop (cdr pending) actual (cons (car pending) unmatched))))
        (let ((unmatched (reverse unmatched)))
          (cond ((pair? unmatched)
                 (let ((nearest (or (find-first (lambda (candidate) (similar? (car unmatched) candidate)) actual)
                                    (find-first (lambda (candidate) (equal? (field 'name (car unmatched)) (field 'name candidate))) actual))))
                   (if nearest
                       (span-difference (car unmatched) nearest path)
                       (string-append path " > " (describe (car unmatched)) ": child span is missing"))))
                ((pair? actual)
                 (string-append path " > " (describe (car actual)) ": unexpected child span"))
                (else #f))))))

(define (span-difference expected actual path)
  (let ((here (string-append path (if (string=? path "") "" " > ") (describe expected))))
    (let ((local (field-difference expected actual)))
      (if local
          (string-append here ": " local)
          (children-difference (items expected 'children) (items actual 'children) here)))))

(define (trace-description roots)
  (if (pair? roots) (describe (car roots)) "empty trace"))

(define (trace-difference expected actual)
  (cond ((and (pair? expected) (pair? actual) (null? (cdr expected)) (null? (cdr actual)))
         (span-difference (car expected) (car actual) ""))
        (else (children-difference expected actual "trace"))))

; #f when the shapes agree, otherwise a description of the first difference.
(define (trace-shape-difference expected-groups actual-groups)
  (let loop ((pending (expand-groups expected-groups))
             (actual (expand-groups actual-groups))
             (unmatched '()))
    (if (pair? pending)
        (let ((match (find-first (lambda (candidate) (same-trace? (car pending) candidate)) actual)))
          (if match
              (loop (cdr pending) (remove-first match actual) unmatched)
              (loop (cdr pending) actual (cons (car pending) unmatched))))
        (let ((unmatched (reverse unmatched)))
          (cond ((pair? unmatched)
                 (let ((nearest (find-first
                                  (lambda (candidate)
                                    (and (pair? candidate) (similar? (car (car unmatched)) (car candidate))))
                                  actual)))
                   (string-append
                     "Datadog trace shape differs from the reviewed scenario shape: "
                     (number->string (length unmatched)) " expected trace(s) unmatched, "
                     (number->string (length actual)) " observed trace(s) unexplained; "
                     (if nearest
                         (string-append "first difference at " (trace-difference (car unmatched) nearest))
                         (string-append "no observed trace resembles " (trace-description (car unmatched)))))))
                ((pair? actual)
                 (string-append "Datadog trace shape differs from the reviewed scenario shape: unexpected trace "
                                (trace-description (car actual))))
                (else #f))))))

(define (datadog-validate-trace-shapes expected capture)
  (let ((actual (field 'trace-shapes capture)))
    (check (list? actual) "Datadog capture has no native trace topology")
    (let ((difference (trace-shape-difference expected actual)))
      (check (not difference) (or difference "")))))
  ))
