; The native Datadog traces of the profiles scenario, reviewed for go-gin-datadog-v2-10-1-v04.
; Builders: corpus/datadog/shape/gin.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 profiles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape gin))
  (begin

(define scenario-shape
  (traces gin-app
    (repeat 2
      (trace
        (gin-request "GET" "/api/profiles/:username" 200
          (url "/api/profiles/celeb_rules_stests_<workload>")
          (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
            (raised "*errors.errorString" "record not found"))
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"))))
    (trace
      (gin-request "GET" "/api/profiles/:username" 200
        (url "/api/profiles/celeb_rules_stests_<workload>")
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")))
    (trace
      (gin-request "DELETE" "/api/profiles/:username/follow" 200
        (url "/api/profiles/celeb_rules_stests_<workload>/follow")
        (gorm-delete "DELETE FROM `follow_models` WHERE following_id = ? AND followed_by_id = ?")
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")
        (database-sql "Begin")
        (database-sql "Commit")))
    (trace
      (gin-request "POST" "/api/profiles/:username/follow" 200
        (url "/api/profiles/celeb_rules_stests_<workload>/follow")
        (gorm-create "INSERT INTO `follow_models` (`created_at`,`updated_at`,`deleted_at`,`following_id`,`followed_by_id`) VALUES (?,?,?,?,?) ON CONFLICT (`following_id`,`followed_by_id`) DO NOTHING RETURNING `id`")
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1")
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1")
        (database-sql "Begin")
        (database-sql "Commit")))
    (repeat 2
      (trace
        (gin-request "POST" "/api/users" 201
          (url "/api/users")
          (gorm-create "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`) VALUES (?,?,?,?,?) RETURNING `id`"
            (database-sql "Commit"))
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`email` = ? ORDER BY `user_models`.`id` LIMIT 1"
            (raised "*errors.errorString" "record not found"))
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`username` = ? ORDER BY `user_models`.`id` LIMIT 1"
            (raised "*errors.errorString" "record not found"))
          (database-sql "Begin"))))))
  ))
