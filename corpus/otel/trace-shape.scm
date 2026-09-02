(define-library (otel trace-shape)
  (export traces trace span children unordered
          repeat between optional one-of
          coverage scope kind status name http-status
          exact prefix-suffix)
  (import (scheme base))
  (begin

(define (traces . values) (cons 'traces values))
(define (trace . values) (cons 'trace values))
(define (span . values) (cons 'span values))
(define (children value) (list 'children value))
(define (unordered . values) (cons 'unordered values))
(define (repeat count value) (list 'repeat count value))
(define (between minimum maximum value) (list 'between minimum maximum value))
(define (optional value) (list 'optional value))
(define (one-of . values) (cons 'one-of values))
(define (coverage value) (list 'coverage value))
(define (scope value) (list 'scope value))
(define (kind value) (list 'kind value))
(define (status value) (list 'status value))
(define (name value) (list 'name value))
(define (http-status value) (list 'http-status value))
(define (exact value) (list 'exact value))
(define (prefix-suffix prefix suffix) (list 'prefix-suffix prefix suffix))
  ))
