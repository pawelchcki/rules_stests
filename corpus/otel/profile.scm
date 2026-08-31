(define-library (otel profile)
  (export realworld-profile id display-name language framework implementation compose service-name signals
          capture-contract all scenario observed corroborated sources
          validate-profile)
  (import (scheme base) (scheme write)
          (otel validation) (otel trace-shape)
          (otel capture shapes) (otel proofs)
          (realworld contract) (realworld scenarios))
  (begin

(define (id value) (list 'id value))
(define (display-name value) (list 'display-name value))
(define (language value) (list 'language value))
(define (framework value) (list 'framework value))
(define (implementation value) (list 'implementation value))
(define (compose . values) (cons 'composition values))
(define (service-name value) (list 'service-name value))
(define (signals . values) (list 'signals values))
(define (capture-contract value) (list 'capture-contract value))
(define (sources . values) values)
(define (observed . features) (list 'observed features '()))
(define (corroborated source-list . features)
  (list 'corroborated features source-list))
(define (all proof) (list 'claim 'all proof))
(define (scenario name proof) (list 'claim (list name) proof))
(define (realworld-profile . clauses) (cons 'realworld-profile clauses))

(define (profile-field profile key)
  (let loop ((clauses (cdr profile)))
    (cond ((null? clauses) (error "profile field is missing" key))
          ((and (pair? (car clauses)) (eq? (car (car clauses)) key))
           (cadr (car clauses)))
          (else (loop (cdr clauses))))))

(define (claim? clause) (and (pair? clause) (eq? (car clause) 'claim)))
(define (claim-applies? claim scenario-name)
  (let ((scope (cadr claim)))
    (or (eq? scope 'all) (memq scenario-name scope))))

(define (emit-proof feature shape basis)
  (display "[[OTLP-PROOF-V1|")
  (display feature)
  (display "|")
  (display shape)
  (display "|")
  (display basis)
  (display "]]\n"))

(define (validate-feature feature basis evidence capture)
  (let ((rule (proof-rule feature)))
    (if (not rule) (error "feature has no proof rule" feature) #t)
    (if (and (eq? (list-ref rule 2) 'requires-immutable-source)
             (or (not (eq? basis 'corroborated)) (null? evidence)))
        (error "feature requires immutable source" feature) #t)
    (assert-capture-shape feature (cadr rule) capture)
    (emit-proof feature (cadr rule) basis)))

(define (validate-claim claim scenario-name capture)
  (if (not (claim-applies? claim scenario-name))
      #t
      (let* ((proof (car (cddr claim)))
             (basis (car proof))
             (features (cadr proof))
             (evidence (car (cddr proof))))
        (let loop ((features features))
          (if (null? features)
              #t
              (begin
                (validate-feature (car features) basis evidence capture)
                (loop (cdr features))))))))

(define (validate-proofs profile scenario-name capture)
  (let loop ((clauses (cdr profile)))
    (if (null? clauses)
        #t
        (begin
          (if (claim? (car clauses))
              (validate-claim (car clauses) scenario-name capture) #t)
          (loop (cdr clauses))))))

(define (span-buckets contract scenario-name)
  (http-contract-buckets (expected-http-requests-for scenario-name)
                         (list-ref contract 13)
                         (list-ref contract 14)))

(define (validate-capture-contract contract scenario-name capture exact?)
  (let ((event-policy ((list-ref contract 9) scenario-name))
        (buckets (span-buckets contract scenario-name)))
    (if exact?
        (otel-validate-exact
          (list-ref contract 0) (list-ref contract 1) (list-ref contract 2)
          (list-ref contract 3) (list-ref contract 4) (list-ref contract 5)
          (list-ref contract 6) (list-ref contract 7) (list-ref contract 8)
          event-policy (list-ref contract 10) (list-ref contract 11)
          (list-ref contract 12) buckets capture)
        (otel-validate-contract
          (list-ref contract 0) (list-ref contract 1) (list-ref contract 2)
          (list-ref contract 3) (list-ref contract 7) event-policy buckets capture))))

(define (validate-profile profile scenario-name capture validation-mode)
  (validate-capture-contract (profile-field profile 'capture-contract)
                             scenario-name capture
                             (and (pair? validation-mode)
                                  (eq? (car validation-mode) 'exact)))
  (validate-proofs profile scenario-name capture)
  (if (and (pair? validation-mode) (eq? (car validation-mode) 'exact))
      (otel-validate-trace-shapes (cdr validation-mode) capture)
      #t))
  ))
