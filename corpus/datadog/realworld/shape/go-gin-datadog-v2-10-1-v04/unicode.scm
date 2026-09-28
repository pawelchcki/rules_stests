; The native Datadog traces of the unicode scenario, reviewed for go-gin-datadog-v2-10-1-v04.
; Builders: corpus/datadog/shape/gin.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 unicode)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape gin))
  (begin

(define scenario-shape
  (traces gin-app
    (trace
      (gin-request "GET" "/api/profiles/:username" 404
        (url "/api/profiles/%C3%BCn%C3%AFc%C3%B8de_rules_stests_<workload>")
        (user-agent "rules-stests/ünïcødé")
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))))))
  ))
