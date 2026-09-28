(define-library (datadog capture coverage)
  (export field-policy-coverage?)
  (import (scheme base) (datadog capture base))
  (begin

; The sink classifies every native field as exact, normalized (a placeholder
; such as "<endpoint>"), or runtime-validated (ids, timings, stacks). A
; capture with any unclassified field cannot serve as parity evidence.
(define (field-policy-coverage? capture)
  (let ((coverage (field 'coverage capture)))
    (and (= (field 'policy-schema coverage) 1)
         (> (field 'http-spans coverage) 0)
         (> (+ (field 'exact-fields coverage)
               (field 'normalized-fields coverage)
               (field 'runtime-validated-fields coverage)) 0)
         (= (field 'unclassified-fields coverage) 0))))
  ))
