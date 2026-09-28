(define-library (datadog capture errors)
  (export exception-metadata? errors-explained?)
  (import (scheme base) (datadog capture base))
  (begin

; Error flags and exception metadata (system-tests
; parametric/test_parametric_endpoints.py, test_db_integrations_sql.py).

(define exception-keys '("error.type" "error.message" "error.msg" "error.stack" "error.handling_stack"))
(define (exception-message span)
  (or (tag span "error.message") (tag span "error.msg")))

; Once any exception field is present, the exception is complete: the span is
; an error with a type, a message, and a stack. dd-trace-go records where the
; error was handled instead of a raised exception's stack.
(define (exception-complete? span)
  (if (some (lambda (key) (tag span key)) exception-keys)
      (and (equal? (field 'error span) 1)
           (nonempty-string? (tag span "error.type"))
           (string? (exception-message span))
           (or (nonempty-string? (tag span "error.stack"))
               (and (equal? (tag span "language") "go")
                    (nonempty-string? (tag span "error.handling_stack")))))
      #t))
(define (exception-metadata? capture) (all-spans capture exception-complete?))

; Every span flagged as an error says why: it is a server span that answered
; with a 5xx status, or it recorded the exception.
(define (explained? span)
  (or (not (equal? (field 'error span) 1))
      (and (web-span? span)
           (let ((status (tag span "http.status_code")))
             (and (string? status) (not (string<? status "500")))))
      (and (nonempty-string? (tag span "error.type")) (string? (exception-message span)))))
(define (errors-explained? capture) (all-spans capture explained?))
  ))
