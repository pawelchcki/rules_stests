; The native Datadog traces of the favorites scenario, reviewed for go-gin-datadog-v2-10-1-v04.
; Builders: corpus/datadog/shape/gin.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape go-gin-datadog-v2-10-1-v04 favorites)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape gin))
  (begin

(define scenario-shape
  (traces gin-app
    (trace
      (gin-request "GET" "/api/articles" 200
        (url "/api/articles?favorited=fav_rules_stests_<workload>")
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"
          (database-sql "Commit"))
        (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
        (gorm-query "SELECT * FROM `favorite_models` WHERE (favorite_id IN (?) AND favorite_by_id = ?) AND `favorite_models`.`deleted_at` IS NULL")
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
        (gorm-query "SELECT COUNT(DISTINCT(`article_models`.`id`)) FROM `article_models` JOIN favorite_models AS favorites ON favorites.favorite_id = article_models.id AND favorites.deleted_at IS NULL JOIN article_user_models AS favoriters ON favoriters.id = favorites.favorite_by_id AND favoriters.deleted_at IS NULL JOIN user_models AS favoriter_users ON favoriter_users.id = favoriters.user_model_id WHERE favoriter_users.username = ? AND `article_models`.`deleted_at` IS NULL"
          (gorm-query "SELECT DISTINCT article_models.* FROM `article_models` JOIN favorite_models AS favorites ON favorites.favorite_id = article_models.id AND favorites.deleted_at IS NULL JOIN article_user_models AS favoriters ON favoriters.id = favorites.favorite_by_id AND favoriters.deleted_at IS NULL JOIN user_models AS favoriter_users ON favoriter_users.id = favoriters.user_model_id WHERE favoriter_users.username = ? AND `article_models`.`deleted_at` IS NULL ORDER BY article_models.created_at DESC, article_models.id DESC LIMIT 20"
            (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
            (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
              (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?"))))
        (gorm-query "SELECT favorite_id, COUNT(*) as count FROM `favorite_models` WHERE favorite_id IN (?) AND `favorite_models`.`deleted_at` IS NULL GROUP BY `favorite_id`")
        (times 2
          (database-sql "Begin"))
        (database-sql "Commit")))
    (trace
      (gin-request "GET" "/api/articles" 200
        (url "/api/articles?favorited=fav_rules_stests_<workload>")
        (gorm-query "SELECT COUNT(DISTINCT(`article_models`.`id`)) FROM `article_models` JOIN favorite_models AS favorites ON favorites.favorite_id = article_models.id AND favorites.deleted_at IS NULL JOIN article_user_models AS favoriters ON favoriters.id = favorites.favorite_by_id AND favoriters.deleted_at IS NULL JOIN user_models AS favoriter_users ON favoriter_users.id = favoriters.user_model_id WHERE favoriter_users.username = ? AND `article_models`.`deleted_at` IS NULL"
          (gorm-query "SELECT DISTINCT article_models.* FROM `article_models` JOIN favorite_models AS favorites ON favorites.favorite_id = article_models.id AND favorites.deleted_at IS NULL JOIN article_user_models AS favoriters ON favoriters.id = favorites.favorite_by_id AND favoriters.deleted_at IS NULL JOIN user_models AS favoriter_users ON favoriter_users.id = favoriters.user_model_id WHERE favoriter_users.username = ? AND `article_models`.`deleted_at` IS NULL ORDER BY article_models.created_at DESC, article_models.id DESC LIMIT 20"
            (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
            (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
              (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?"))))
        (gorm-query "SELECT favorite_id, COUNT(*) as count FROM `favorite_models` WHERE favorite_id IN (?) AND `favorite_models`.`deleted_at` IS NULL GROUP BY `favorite_id`")
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
      (gin-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/favorite-article-rules_stests_<workload>")
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
      (gin-request "GET" "/api/articles/:slug" 200
        (url "/api/articles/favorite-article-rules_stests_<workload>")
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"
          (database-sql "Commit"))
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")))
        (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
        (gorm-query "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
        (gorm-query "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
        (database-sql "Begin")))
    (trace
      (gin-request "GET" "/api/articles/:slug" 200
        (url "/api/articles/favorite-article-rules_stests_<workload>")
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"
          (database-sql "Commit"))
        (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
          (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
            (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?")))
        (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1")
        (gorm-query "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1")
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1")
        (gorm-query "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
        (database-sql "Begin")))
    (trace
      (gin-request "DELETE" "/api/articles/:slug/favorite" 200
        (url "/api/articles/favorite-article-rules_stests_<workload>/favorite")
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"
          (database-sql "Commit"))
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
        (gorm-delete "DELETE FROM `favorite_models` WHERE favorite_id = ? AND favorite_by_id = ?")
        (times 2
          (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
            (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
            (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
              (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?"))))
        (times 2
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
        (times 2
          (database-sql "Begin"))
        (database-sql "Commit")))
    (trace
      (gin-request "POST" "/api/articles/:slug/favorite" 200
        (url "/api/articles/favorite-article-rules_stests_<workload>/favorite")
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`"
          (database-sql "Commit"))
        (gorm-create "INSERT INTO `article_user_models` (`created_at`,`updated_at`,`deleted_at`,`user_model_id`) VALUES (?,?,?,?) ON CONFLICT (`user_model_id`) DO NOTHING RETURNING `id`")
        (gorm-create "INSERT INTO `favorite_models` (`created_at`,`updated_at`,`deleted_at`,`favorite_id`,`favorite_by_id`) VALUES (?,?,?,?,?) ON CONFLICT (`favorite_id`,`favorite_by_id`) DO NOTHING RETURNING `id`")
        (times 2
          (gorm-query "SELECT * FROM `article_models` WHERE `article_models`.`slug` = ? AND `article_models`.`deleted_at` IS NULL ORDER BY `article_models`.`id` LIMIT 1"
            (gorm-query "SELECT * FROM `article_tags` WHERE `article_tags`.`article_model_id` = ?")
            (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`id` = ? AND `article_user_models`.`deleted_at` IS NULL"
              (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ?"))))
        (times 2
          (gorm-query "SELECT * FROM `article_user_models` WHERE `article_user_models`.`user_model_id` = ? AND `article_user_models`.`deleted_at` IS NULL ORDER BY `article_user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT * FROM `favorite_models` WHERE (`favorite_models`.`favorite_id` = ? AND `favorite_models`.`favorite_by_id` = ?) AND `favorite_models`.`deleted_at` IS NULL ORDER BY `favorite_models`.`id` LIMIT 1")
        (gorm-query "SELECT * FROM `follow_models` WHERE (`follow_models`.`following_id` = ? AND `follow_models`.`followed_by_id` = ?) AND `follow_models`.`deleted_at` IS NULL ORDER BY `follow_models`.`id` LIMIT 1"
          (raised "*errors.errorString" "record not found"))
        (times 2
          (gorm-query "SELECT * FROM `user_models` WHERE `user_models`.`id` = ? ORDER BY `user_models`.`id` LIMIT 1"))
        (gorm-query "SELECT count(*) FROM `favorite_models` WHERE `favorite_models`.`favorite_id` = ? AND `favorite_models`.`deleted_at` IS NULL")
        (times 2
          (database-sql "Begin"))
        (database-sql "Commit")))
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
