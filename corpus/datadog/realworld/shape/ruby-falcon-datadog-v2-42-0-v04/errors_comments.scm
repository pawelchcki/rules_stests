; The native Datadog traces of the errors_comments scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 errors_comments)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
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
          (sequel "SELECT count(*) AS 'count' FROM `favorites` WHERE (`article_id` = :article) LIMIT 1"))))
    (trace
      (sinatra-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/err-comment-art-rules_stests_<workload>")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `articles` WHERE (`id` = :id)")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"))))
    (trace
      (sinatra-request "GET" "/api/articles/:slug/comments" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/comments")
        (route
          (failure "{:article=>[\"not found\"]}")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/articles/:slug/comments" 401
        (url "/api/articles/some-slug/comments")
        (route
          (failure "{:token=>[\"is missing\"]}")
          first-finished)))
    (trace
      (sinatra-request "POST" "/api/articles/:slug/comments" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/comments")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:article=>[\"not found\"]}")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"))))
    (trace
      (sinatra-request "POST" "/api/articles/:slug/comments" 422
        (url "/api/articles/err-comment-art-rules_stests_<workload>/comments")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:body=>[\"can't be blank\"]}")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1"))))
    (trace
      (sinatra-request "DELETE" "/api/articles/:slug/comments/:comment_id" 401
        (url "/api/articles/some-slug/comments/1")
        (route
          (failure "{:token=>[\"is missing\"]}")
          first-finished)))
    (trace
      (sinatra-request "DELETE" "/api/articles/:slug/comments/:comment_id" 404
        (url "/api/articles/err-comment-art-rules_stests_<workload>/comments/99999")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:comment=>[\"not found\"]}")
          (sequel "SELECT * FROM `articles` WHERE (`slug` = :slug) LIMIT 1")
          (sequel "SELECT * FROM `comments` WHERE ((`article_id` = :article) AND (`id` = :id)) LIMIT 1"))))
    (trace
      (sinatra-request "DELETE" "/api/articles/:slug/comments/:comment_id" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/comments/99999")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:article=>[\"not found\"]}")
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
