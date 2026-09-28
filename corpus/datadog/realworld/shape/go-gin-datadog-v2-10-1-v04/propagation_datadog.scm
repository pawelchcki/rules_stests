; The native Datadog traces of the propagation_datadog scenario, reviewed for go-gin-datadog-v2-10-1-v04.
; Builders: corpus/datadog/shape/gin.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 propagation_datadog)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape gin))
  (begin

(define scenario-shape
  (traces gin-app
    (trace
      (gin-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "11276220234964099125" "67667974448284343" 1 "b3f7d21c9e6a4805"))
        (gorm-query "SELECT * FROM `tag_models` WHERE `tag_models`.`deleted_at` IS NULL")))
    (trace
      (gin-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "11803532876627986230" "67667974448284343" 1 "4bf92f3577b34da6"))
        (gorm-query "SELECT * FROM `tag_models` WHERE `tag_models`.`deleted_at` IS NULL")))
    (trace
      (gin-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "9965072336285547154" "67667974448284343" 1 "8c1e0a5b6d2f4739"))
        (gorm-query "SELECT * FROM `tag_models` WHERE `tag_models`.`deleted_at` IS NULL")))
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
