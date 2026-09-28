; The native Datadog traces of the feed scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 feed)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (repeat 2
      (trace
        (sinatra-request "POST" "/api/articles" 201
          (url "/api/articles")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (sequel "DELETE FROM `article_tags` WHERE (`article_id` = :article)")
            (sequel "INSERT INTO `articles` (`user_id`, `slug`, `title`, `description`, `body`, `created_at`, `updated_at`) VALUES (:user_id, :slug, :title, :description, :body, :created_at, :updated_at)")
            (sequel "SELECT * FROM `articles` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT 1 FROM `articles` WHERE (`slug` = :slug) LIMIT 1")
            (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
            (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
            (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
            (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1")))))
    (trace
      (sinatra-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/feed-article-1-rules_stests_<workload>")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `articles` WHERE (`id` = :id)")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"))))
    (trace
      (sinatra-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/feed-article-2-rules_stests_<workload>")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `articles` WHERE (`id` = :id)")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"))))
    (trace
      (sinatra-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "SELECT * FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) ORDER BY `created_at` DESC, `id` DESC LIMIT 20 OFFSET 0")
          (sequel "SELECT count(*) AS 'count' FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) LIMIT 1"))))
    (trace
      (sinatra-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "SELECT * FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) ORDER BY `created_at` DESC, `id` DESC LIMIT 20 OFFSET 0")
          (times 2
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"))
          (times 2
            (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1"))
          (times 2
            (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1"))
          (times 2
            (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`"))
          (sequel "SELECT count(*) AS 'count' FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) LIMIT 1")
          (times 2
            (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1")))))
    (trace
      (sinatra-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed?limit")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "SELECT * FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) ORDER BY `created_at` DESC, `id` DESC LIMIT 1 OFFSET 0")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) LIMIT 1")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (trace
      (sinatra-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed?limit&offset")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "SELECT * FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) ORDER BY `created_at` DESC, `id` DESC LIMIT 1 OFFSET 1")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `articles` WHERE (`user_id` IN (SELECT `followed_id` FROM `follows` WHERE (`follower_id` = :follower))) LIMIT 1")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (trace
      (sinatra-request "DELETE" "/api/profiles/:username/follow" 200
        (url "/api/profiles/feedc_rules_stests_<workload>/follow")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed))")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1"))))
    (trace
      (sinatra-request "POST" "/api/profiles/:username/follow" 200
        (url "/api/profiles/feedc_rules_stests_<workload>/follow")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "INSERT OR IGNORE INTO `follows` (`follower_id`, `followed_id`) VALUES (:follower_id, :followed_id)")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1"))))
    (repeat 2
      (trace
        (sinatra-request "POST" "/api/users" 201
          (url "/api/users")
          (route
            (sequel "INSERT INTO `users` (`username`, `email`, `password_digest`, `created_at`, `updated_at`) VALUES (:username, :email, :password_digest, :created_at, :updated_at)")
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
              first-finished)))))))
  ))
