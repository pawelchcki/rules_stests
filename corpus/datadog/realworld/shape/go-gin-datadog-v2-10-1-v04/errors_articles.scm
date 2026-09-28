; The native Datadog traces of the errors_articles scenario, reviewed for go-gin-datadog-v2-10-1-v04.
; Builders: corpus/datadog/shape/gin.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 errors_articles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape gin))
  (begin

(define scenario-shape
  (traces gin-app
    (trace
      (gin-request "POST" "/api/articles" 201
        (url "/api/articles")
        (gorm-create "INSERT INTO `article_models` (`created_at`,`updated_at`,`deleted_at`,`slug`,`title`,`description`,`body`,`author_id`) VALUES (?,?,?,?,?,?,?,?) RETURNING `id`")
        (times 2
          (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"))
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`,`id`) VALUES (?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
        (gorm-create "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`,`id`) VALUES (?,?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? ORDER BY `article_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
        (database-sql "Begin")
        (database-sql "Commit")))
    (trace
      (gin-request "POST" "/api/articles" 201
        (url "/api/articles")
        (gorm-create "INSERT INTO `article_models` (`created_at`,`updated_at`,`deleted_at`,`slug`,`title`,`description`,`body`,`author_id`) VALUES (?,?,?,?,?,?,?,?) RETURNING `id`")
        (times 2
          (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"))
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`,`id`) VALUES (?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
        (gorm-create "INSERT INTO `user_models` (`username`,`email`,`bio`,`image`,`password`,`id`) VALUES (?,?,?,?,?,?) ON CONFLICT DO NOTHING RETURNING `id`")
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? ORDER BY `article_models`.`id` LIMIT 1")
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? ORDER BY `article_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
        (database-sql "Begin")
        (database-sql "Commit")))
    (trace
      (gin-request "POST" "/api/articles" 401
        (url "/api/articles")))
    (repeat 3
      (trace
        (gin-request "POST" "/api/articles" 422
          (url "/api/articles")
          (times 2
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
          (database-sql "Begin")
          (database-sql "Rollback"))))
    (trace
      (gin-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/dup-title-rules_stests_<workload>")
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"
          (database-sql "Commit"))
        (gorm-delete "UPDATE `article_models` SET `deleted_at`=? WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL"
          (database-sql "Commit"))
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")))
        (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (times 2
          (database-sql "Begin"))))
    (trace
      (gin-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/dup-title-rules_stests_<workload>-2")
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"
          (database-sql "Commit"))
        (gorm-delete "UPDATE `article_models` SET `deleted_at`=? WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL"
          (database-sql "Commit"))
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")))
        (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (times 2
          (database-sql "Begin"))))
    (trace
      (gin-request "DELETE" "/api/articles/:slug" 401
        (url "/api/articles/some-slug")))
    (trace
      (gin-request "DELETE" "/api/articles/:slug" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>")
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))))
    (trace
      (gin-request "GET" "/api/articles/:slug" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>")
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))))
    (trace
      (gin-request "PUT" "/api/articles/:slug" 401
        (url "/api/articles/some-slug")))
    (repeat 2
      (trace
        (gin-request "PUT" "/api/articles/:slug" 404
          (url "/api/articles/unknown-slug-rules_stests_<workload>")
          (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
            (raised "*errors.errorString" "record not found"))
          (times 2
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")))))
    (trace
      (gin-request "DELETE" "/api/articles/:slug/favorite" 401
        (url "/api/articles/some-slug/favorite")))
    (trace
      (gin-request "DELETE" "/api/articles/:slug/favorite" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/favorite")
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))))
    (trace
      (gin-request "POST" "/api/articles/:slug/favorite" 401
        (url "/api/articles/some-slug/favorite")))
    (trace
      (gin-request "POST" "/api/articles/:slug/favorite" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/favorite")
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))))
    (trace
      (gin-request "GET" "/api/articles/feed" 401
        (url "/api/articles/feed")))
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
