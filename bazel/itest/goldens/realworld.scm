(define-library (realworld contract)
  (export angle-bracket-route
          http-contract-buckets)
  (import (scheme base) (scheme char))
  (begin

; A portable RealWorld request observation is:
; (count method canonical-route http-status)
;
; Implementation profiles supply server-scope and render-server-span-name.
; This keeps the workload contract language-neutral while still checking each
; instrumentation implementation's exact span naming convention.

(define (angle-bracket-route route)
  (list->string
    (map (lambda (character)
           (cond ((char=? character #\{) #\<)
                 ((char=? character #\}) #\>)
                 (else character)))
         (string->list route))))

(define (http-contract-bucket observation server-scope render-server-span-name)
  (let ((count (list-ref observation 0))
        (method (list-ref observation 1))
        (route (list-ref observation 2))
        (status (list-ref observation 3)))
    (list count
          server-scope
          'server
          'unset
          (list 'exact (render-server-span-name method route))
          'root
          status)))

(define (http-contract-buckets observations server-scope render-server-span-name)
  (map (lambda (observation)
         (http-contract-bucket observation server-scope render-server-span-name))
       observations))
  ))
