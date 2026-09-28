; The native Datadog traces of the errors_articles scenario, reviewed for python-aiohttp-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 errors_articles)
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
      (aiohttp-request "POST" "/api/articles" 201
        (url "/api/articles")
        (sqlalchemy "INSERT INTO articles (author_id, slug, title, description, body, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (times 2
          (sqlalchemy "SELECT articles.id \nFROM articles \nWHERE articles.slug = ?"))
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "POST" "/api/articles" 401
        (url "/api/articles")))
    (repeat 3
      (trace
        (aiohttp-request "POST" "/api/articles" 422
          (url "/api/articles")
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "GET" "/api/articles/feed" 401
        (url "/api/articles/feed")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 204
        (url "/api/articles/dup-title-rules-stests-<workload>")
        (sqlalchemy "DELETE FROM articles WHERE articles.id = ?"
          (rows 1))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 204
        (url "/api/articles/dup-title-rules-stests-<workload>-2")
        (sqlalchemy "DELETE FROM articles WHERE articles.id = ?"
          (rows 1))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 401
        (url "/api/articles/some-slug")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "GET" "/api/articles/{slug}" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")))
    (trace
      (aiohttp-request "PUT" "/api/articles/{slug}" 401
        (url "/api/articles/some-slug")))
    (repeat 2
      (trace
        (aiohttp-request "PUT" "/api/articles/{slug}" 404
          (url "/api/articles/unknown-slug-rules_stests_<workload>")
          (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}/favorite" 401
        (url "/api/articles/some-slug/favorite")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}/favorite" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/favorite")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "POST" "/api/articles/{slug}/favorite" 401
        (url "/api/articles/some-slug/favorite")))
    (trace
      (aiohttp-request "POST" "/api/articles/{slug}/favorite" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/favorite")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "POST" "/api/users" 201
        (url "/api/users")
        (sqlalchemy "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))))
  ))
