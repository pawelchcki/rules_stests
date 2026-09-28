; The native Datadog traces of the articles scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 articles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (trace
      (sinatra-request "GET" "/api/articles" 200
        (url "/api/articles")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "SELECT * FROM `articles` ORDER BY `created_at` DESC, `id` DESC LIMIT 20 OFFSET 0")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `articles` LIMIT 1")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (repeat 2
      (trace
        (sinatra-request "GET" "/api/articles" 200
          (url "/api/articles")
          (route
            (sequel "SELECT * FROM `articles` ORDER BY `created_at` DESC, `id` DESC LIMIT 20 OFFSET 0"
              first-finished)
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
            (sequel "SELECT count(*) AS 'count' FROM `articles` LIMIT 1")
            (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1")))))
    (trace
      (sinatra-request "GET" "/api/articles" 200
        (url "/api/articles?author")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "SELECT * FROM `articles` WHERE (`user_id` IN (SELECT `id` FROM `users` WHERE (`username` = :author))) ORDER BY `created_at` DESC, `id` DESC LIMIT 20 OFFSET 0")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `articles` WHERE (`user_id` IN (SELECT `id` FROM `users` WHERE (`username` = :author))) LIMIT 1")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (trace
      (sinatra-request "GET" "/api/articles" 200
        (url "/api/articles?author")
        (route
          (sequel "SELECT * FROM `articles` WHERE (`user_id` IN (SELECT `id` FROM `users` WHERE (`username` = :author))) ORDER BY `created_at` DESC, `id` DESC LIMIT 20 OFFSET 0"
            first-finished)
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `articles` WHERE (`user_id` IN (SELECT `id` FROM `users` WHERE (`username` = :author))) LIMIT 1")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (trace
      (sinatra-request "GET" "/api/articles" 200
        (url "/api/articles?tag")
        (route
          (sequel "SELECT * FROM `articles` WHERE (`id` IN (SELECT `article_id` FROM `article_tags` WHERE (`tag_id` IN (SELECT `id` FROM `tags` WHERE (`name` = :tag))))) ORDER BY `created_at` DESC, `id` DESC LIMIT 20 OFFSET 0"
            first-finished)
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `articles` WHERE (`id` IN (SELECT `article_id` FROM `article_tags` WHERE (`tag_id` IN (SELECT `id` FROM `tags` WHERE (`name` = :tag))))) LIMIT 1")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (trace
      (sinatra-request "POST" "/api/articles" 201
        (url "/api/articles")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `article_tags` WHERE (`article_id` = :article)")
          (times 2
            (sequel "INSERT INTO `article_tags` (`article_id`, `tag_id`) VALUES (:article_id, :tag_id)"))
          (sequel "INSERT INTO `articles` (`user_id`, `slug`, `title`, `description`, `body`, `created_at`, `updated_at`) VALUES (:user_id, :slug, :title, :description, :body, :created_at, :updated_at)")
          (times 2
            (sequel "INSERT OR IGNORE INTO `tags` (`name`) VALUES (:name)"))
          (sequel "SELECT * FROM `articles` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `articles` WHERE (`slug` = :slug) LIMIT 1")
          (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
          (times 2
            (sequel "SELECT `id` FROM `tags` WHERE (`name` = :name) LIMIT 1"))
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (trace
      (sinatra-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/test-article-rules_stests_<workload>")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `articles` WHERE (`id` = :id)")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"))))
    (repeat 3
      (trace
        (sinatra-request "GET" "/api/articles/:slug" 200
          (url "/api/articles/test-article-rules_stests_<workload>")
          (route
            (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"
              first-finished)
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
            (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1")))))
    (trace
      (sinatra-request "GET" "/api/articles/:slug" 404
        (url "/api/articles/test-article-rules_stests_<workload>")
        (route
          (failure "{:article=>[\"not found\"]}")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "PUT" "/api/articles/:slug" 200
        (url "/api/articles/test-article-rules_stests_<workload>")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `article_tags` WHERE (`article_id` = :article)")
          (sequel "SELECT * FROM `articles` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
          (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1")
          (sequel "UPDATE `articles` SET `title` = :title, `description` = :description, `body` = :body, `updated_at` = :updated_at WHERE (`id` = :id)"))))
    (repeat 2
      (trace
        (sinatra-request "PUT" "/api/articles/:slug" 200
          (url "/api/articles/test-article-rules_stests_<workload>")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (sequel "SELECT * FROM `articles` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1")
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT 1 FROM `favorites` WHERE ((`article_id` = :article) AND (`user_id` = :user)) LIMIT 1")
            (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")
            (sequel "SELECT `name` FROM `tags` WHERE (`id` IN (SELECT `tag_id` FROM `article_tags` WHERE (`article_id` = :article))) ORDER BY `id`")
            (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1")
            (sequel "UPDATE `articles` SET `title` = :title, `description` = :description, `body` = :body, `updated_at` = :updated_at WHERE (`id` = :id)")))))
    (trace
      (sinatra-request "PUT" "/api/articles/:slug" 422
        (url "/api/articles/test-article-rules_stests_<workload>")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:tagList=>[\"must be an array\"]}")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"))))
    (trace
      (sinatra-request "POST" "/api/users" 201
        (url "/api/users")
        (route
          (sequel "INSERT INTO `users` (`username`, `email`, `password_digest`, `created_at`, `updated_at`) VALUES (:username, :email, :password_digest, :created_at, :updated_at)")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))))
  ))
