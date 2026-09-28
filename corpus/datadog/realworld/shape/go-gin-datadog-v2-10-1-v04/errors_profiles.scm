; The native Datadog traces of the errors_profiles scenario, reviewed for go-gin-datadog-v2-10-1-v04.
; Builders: corpus/datadog/shape/gin.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 errors_profiles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape gin))
  (begin

(define scenario-shape
  (traces gin-app
    (trace
      (gin-request "GET" "/api/profiles/:username" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>")
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))))
    (trace
      (gin-request "DELETE" "/api/profiles/:username/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")))
    (trace
      (gin-request "DELETE" "/api/profiles/:username/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))))
    (trace
      (gin-request "POST" "/api/profiles/:username/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")))
    (trace
      (gin-request "POST" "/api/profiles/:username/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))))
    (trace
      (gin-request "POST" "/api/users" 201
        (url "/api/users")
        (gorm-create "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`) VALUES (?,?,?,?,?) RETURNING `id`"
          (database-sql "Commit"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (database-sql "Begin")))))
  ))
