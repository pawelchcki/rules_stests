(define-library (otel profile)
  (export realworld-profile id display-name language framework implementation compose service-name signals
          all scenario observed corroborated sources
          validate-profile)
  (import (scheme base) (scheme write) (otel declarations) (otel record)
          (otel validation) (otel trace-shape match)
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
(define (sources . values) values)
(define (observed . features) (list 'observed features '()))
(define (corroborated source-list . features)
  (list 'corroborated features source-list))
(define (all proof) (list 'claim 'all proof))
(define (scenario name proof) (list 'claim (list name) proof))
(define (realworld-profile . clauses) (cons 'realworld-profile clauses))

(define (profile-field profile key)
  (record-field profile key))

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
    (if (and (eq? (cadr (assq 'evidence (cdr rule))) 'requires-immutable-source)
             (or (not (eq? basis 'corroborated)) (null? evidence)))
        (error "feature requires immutable source" feature) #t)
    (let ((shape (cadr (assq 'assertion (cdr rule)))))
      (assert-capture-shape feature shape capture)
      (emit-proof feature shape basis))))

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
                         (record-field contract 'server-scope)
                         (record-field contract 'server-span-name)))

(define (validate-capture-contract contract scenario-name capture mode)
  (let ((event-policy ((record-field contract 'event-policy) scenario-name))
        (buckets (span-buckets contract scenario-name)))
    (otel-validate-capture contract event-policy buckets capture mode)))

(define (validate-profile profile scenario-name capture validation-mode)
  (validate-capture-contract (profile-field profile 'capture-contract)
                             scenario-name capture
                             (if (and (pair? validation-mode)
                                      (eq? (car validation-mode) 'exact))
                                 'exact
                                 'contract))
  (validate-proofs profile scenario-name capture)
  (if (and (pair? validation-mode) (eq? (car validation-mode) 'exact))
      (otel-validate-trace-shapes (cdr validation-mode) capture)
      #t))
  ))
