; The native Datadog traces of the errors_auth scenario, reviewed for go-gin-datadog-v2-10-1-v04.
; Builders: corpus/datadog/shape/gin.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 errors_auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape gin))
  (begin

(define scenario-shape
  (traces gin-app
    (trace
      (gin-request "GET" "/api/user" 401
        (url "/api/user")))
    (repeat 2
      (trace
        (gin-request "PUT" "/api/user" 200
          (url "/api/user")
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
          (times 2
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")
          (gorm-update "UPDATE `user_models` SET `password`=? WHERE `id` = ?")
          (database-sql "Begin")
          (database-sql "Commit"))))
    (trace
      (gin-request "PUT" "/api/user" 401
        (url "/api/user")))
    (repeat 7
      (trace
        (gin-request "PUT" "/api/user" 422
          (url "/api/user")
          (times 2
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")))))
    (trace
      (gin-request "POST" "/api/users" 201
        (url "/api/users")
        (gorm-create "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`) VALUES (?,?,?,?,?) RETURNING `id`"
          (database-sql "Commit"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (database-sql "Begin")))
    (trace
      (gin-request "POST" "/api/users" 409
        (url "/api/users")
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))))
    (trace
      (gin-request "POST" "/api/users" 409
        (url "/api/users")
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")))
    (repeat 3
      (trace
        (gin-request "POST" "/api/users" 422
          (url "/api/users"))))
    (trace
      (gin-request "POST" "/api/users/login" 401
        (url "/api/users/login")
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1")))
    (repeat 2
      (trace
        (gin-request "POST" "/api/users/login" 422
          (url "/api/users/login"))))))
  ))
