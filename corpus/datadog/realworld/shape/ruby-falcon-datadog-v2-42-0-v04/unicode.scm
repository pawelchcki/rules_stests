; The native Datadog traces of the unicode scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 unicode)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (trace
      (sinatra-request "GET" "/api/profiles/:username" 404
        (url "/api/profiles/%C3%BCn%C3%AFc%C3%B8de_rules_stests_<workload>") (user-agent "")
        (route
          (failure "{:profile=>[\"not found\"]}")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))))
  ))
