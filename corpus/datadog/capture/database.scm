(define-library (datadog capture database)
  (export database-children? client-spans? database-system?)
  (import (scheme base) (datadog capture base))
  (begin

; Database spans.

; SQL operations stay in the request's trace even when an asynchronous driver
; dispatches work to another thread: following native parent ids, every
; database span reaches the HTTP server span.
(define (source-http-ancestor? span spans)
  ; Source-only diagnostic captures predate the sink's indexed ancestry field.
  ; Resolve only a unique parent, carrying any known high bits along the walk.
  (let walk ((current span) (high (tag span "_dd.p.tid")) (remaining (length spans)))
    (let ((parents
            (let find ((rest spans) (result '()))
              (if (null? rest) result
                  (let* ((candidate (car rest))
                         (candidate-high (tag candidate "_dd.p.tid")))
                    (find (cdr rest)
                      (if (and (equal? (field 'trace-id current) (field 'trace-id candidate))
                               (equal? (field 'parent-id current) (field 'span-id candidate))
                               (or (not high) (not candidate-high) (equal? high candidate-high)))
                          (cons candidate result) result)))))))
      (and (> remaining 0) (pair? parents) (null? (cdr parents))
           (let ((parent (car parents)))
             (or (web-span? parent)
                 (walk parent (or high (tag parent "_dd.p.tid")) (- remaining 1))))))))
(define (database-children? capture)
  (let ((spans (items capture 'spans)))
    (and (some database-span? spans)
         (every (lambda (span)
                  (or (not (database-span? span))
                      (if (assq 'http-ancestor span)
                          (eq? (field 'http-ancestor span) #t)
                          (source-http-ancestor? span spans))))
                spans))))

; Database spans describe calls from the application to a database server
; (system-tests integrations/test_db_integrations_sql.py).
(define (database-spans capture) (filter database-span? (items capture 'spans)))
(define (client-spans? capture)
  (and (pair? (database-spans capture))
       (every (lambda (span) (equal? (tag span "span.kind") "client")) (database-spans capture))))
(define (database-system? capture)
  (and (pair? (database-spans capture))
       (every (lambda (span) (nonempty-string? (tag span "db.system"))) (database-spans capture))))
  ))
