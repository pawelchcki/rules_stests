(define-library (otel record)
  (export record-kind record-field record-field/default record-has?)
  (import (scheme base))
  (begin

(define (record-kind record)
  (and (pair? record) (car record)))

(define (record-entry record key)
  (and (pair? record) (assq key (cdr record))))

(define (record-has? record key)
  (and (record-entry record key) #t))

(define (record-field record key)
  (let ((entry (record-entry record key)))
    (if entry
        (if (or (and (eq? (record-kind record) 'capture-contract)
                     (memq key '(metric-aggregation log-policy)))
                (and (eq? (record-kind record) 'realworld-profile)
                     (eq? key 'capture-contract)))
            entry
            (cadr entry))
        (error "record field is missing" (record-kind record) key))))

(define (record-field/default record key default)
  (let ((entry (record-entry record key)))
    (if entry (cadr entry) default)))
  ))
