; The native Datadog traces of the errors_authorization scenario, reviewed for python-aiohttp-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 errors_authorization)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.4")
    (trace
      (aiohttp-request "POST" "/api/articles" 201
        (url "/api/articles")
        (sqlalchemy "INSERT INTO articles (author_id, slug, title, description, body, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT articles.id \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 204
        (url "/api/articles/authz-article-rules-stests-<workload>")
        (sqlalchemy "DELETE FROM articles WHERE articles.id = ?"
          (rows 1))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 403
        (url "/api/articles/authz-article-rules-stests-<workload>")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "PUT" "/api/articles/{slug}" 403
        (url "/api/articles/authz-article-rules-stests-<workload>")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "GET" "/api/articles/{slug}/comments" 200
        (url "/api/articles/authz-article-rules-stests-<workload>/comments")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT comments.id, comments.article_id, comments.author_id, comments.body, comments.created_at, comments.updated_at \nFROM comments \nWHERE comments.article_id = ? ORDER BY comments.id")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "POST" "/api/articles/{slug}/comments" 201
        (url "/api/articles/authz-article-rules-stests-<workload>/comments")
        (sqlalchemy "INSERT INTO comments (article_id, author_id, body, created_at, updated_at) VALUES (?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}/comments/{comment_id}" 403
        (url "/api/articles/authz-article-rules-stests-<workload>/comments/1")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT comments.id, comments.article_id, comments.author_id, comments.body, comments.created_at, comments.updated_at \nFROM comments \nWHERE comments.id = ? AND comments.article_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (repeat 2
      (trace
        (aiohttp-request "POST" "/api/users" 201
          (url "/api/users")
          (sqlalchemy "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)"
            (rows 1))
          (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
          (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?"))))))
  ))
