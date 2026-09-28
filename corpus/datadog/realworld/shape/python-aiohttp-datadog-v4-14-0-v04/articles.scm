; The native Datadog traces of the articles scenario, reviewed for python-aiohttp-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 articles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.4")
    (trace
      (aiohttp-request "GET" "/api/articles" 200
        (url "/api/articles")
        (sqlalchemy "SELECT DISTINCT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT DISTINCT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles) AS anon_1")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (repeat 2
      (trace
        (aiohttp-request "GET" "/api/articles" 200
          (url "/api/articles")
          (sqlalchemy "SELECT DISTINCT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
          (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT DISTINCT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles) AS anon_1")
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "GET" "/api/articles" 200
        (url "/api/articles?author=art_rules_stests_<workload>")
        (sqlalchemy "SELECT DISTINCT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT DISTINCT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ?) AS anon_1")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "GET" "/api/articles" 200
        (url "/api/articles?author=art_rules_stests_<workload>")
        (sqlalchemy "SELECT DISTINCT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT DISTINCT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ?) AS anon_1")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "GET" "/api/articles" 200
        (url "/api/articles?tag=d_rules_stests_<workload>")
        (sqlalchemy "SELECT DISTINCT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN article_tags ON article_tags.article_id = articles.id \nWHERE article_tags.tag = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT DISTINCT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN article_tags ON article_tags.article_id = articles.id \nWHERE article_tags.tag = ?) AS anon_1")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "POST" "/api/articles" 201
        (url "/api/articles")
        (sqlalchemy "INSERT INTO article_tags (article_id, tag, position) VALUES (?, ?, ?)"
          (rows 2))
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
        (url "/api/articles/test-article-rules-stests-<workload>")
        (sqlalchemy "DELETE FROM articles WHERE articles.id = ?"
          (rows 1))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (repeat 3
      (trace
        (aiohttp-request "GET" "/api/articles/{slug}" 200
          (url "/api/articles/test-article-rules-stests-<workload>")
          (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
          (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "GET" "/api/articles/{slug}" 404
        (url "/api/articles/test-article-rules-stests-<workload>")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")))
    (trace
      (aiohttp-request "PUT" "/api/articles/{slug}" 200
        (url "/api/articles/test-article-rules-stests-<workload>")
        (sqlalchemy "DELETE FROM article_tags WHERE article_tags.article_id = ?"
          (rows 2))
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
        (sqlalchemy "UPDATE articles SET updated_at=? WHERE articles.id = ?"
          (rows 1))))
    (repeat 2
      (trace
        (aiohttp-request "PUT" "/api/articles/{slug}" 200
          (url "/api/articles/test-article-rules-stests-<workload>")
          (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
          (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
          (sqlalchemy "UPDATE articles SET body=?, updated_at=? WHERE articles.id = ?"
            (rows 1)))))
    (trace
      (aiohttp-request "PUT" "/api/articles/{slug}" 422
        (url "/api/articles/test-article-rules-stests-<workload>")
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
