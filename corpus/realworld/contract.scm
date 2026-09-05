(define-library (realworld contract)
  (export http-contract-buckets)
  (import (scheme base) (otel declarations))
  (begin

(define (http-contract-bucket observation server-scope render-server-span-name)
  (let ((count (list-ref observation 0))
        (method (list-ref observation 1))
        (route (list-ref observation 2))
        (response-status (list-ref observation 3))
        ; A scenario that sends its own traceparent declares the parent class its
        ; server spans must carry; every other scenario starts its own trace.
        (parent-class (if (> (length observation) 4) (list-ref observation 4) 'root)))
    (span-bucket
      (bucket-count count)
      (scope server-scope)
      (kind 'server)
      (status 'unset)
      (name (exact (render-server-span-name method route)))
      (parent parent-class)
      (http-status response-status))))

(define (http-contract-buckets observations server-scope render-server-span-name)
  (map (lambda (observation)
         (http-contract-bucket observation server-scope render-server-span-name))
       observations))
  ))
