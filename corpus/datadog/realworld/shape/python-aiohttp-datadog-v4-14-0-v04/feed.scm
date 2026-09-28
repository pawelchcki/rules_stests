; The native Datadog traces of the feed scenario, reviewed for python-aiohttp-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 feed)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.4")
    (repeat 2
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
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ?) AS anon_1")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed")
        (times 2
          (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position"))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ?) AS anon_1")
        (times 2
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?"))
        (times 2
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?"))
        (times 2
          (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?"))
        (times 3
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed?limit=1")
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ?) AS anon_1")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (times 2
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "GET" "/api/articles/feed" 200
        (url "/api/articles/feed?limit=1&offset=1")
        (sqlalchemy "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM (SELECT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN follows ON follows.followed_id = articles.author_id \nWHERE follows.follower_id = ?) AS anon_1")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (times 2
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 204
        (url "/api/articles/feed-article-1-rules-stests-<workload>")
        (sqlalchemy "DELETE FROM articles WHERE articles.id = ?"
          (rows 1))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/articles/{slug}" 204
        (url "/api/articles/feed-article-2-rules-stests-<workload>")
        (sqlalchemy "DELETE FROM articles WHERE articles.id = ?"
          (rows 1))
        (sqlalchemy "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/profiles/{username}/follow" 200
        (url "/api/profiles/feedc_rules_stests_<workload>/follow")
        (sqlalchemy "DELETE FROM follows WHERE follows.follower_id = ? AND follows.followed_id = ?"
          (rows 1))
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (trace
      (aiohttp-request "POST" "/api/profiles/{username}/follow" 200
        (url "/api/profiles/feedc_rules_stests_<workload>/follow")
        (sqlalchemy "INSERT INTO follows (follower_id, followed_id) VALUES (?, ?) ON CONFLICT DO NOTHING"
          (rows 1))
        (sqlalchemy "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (repeat 2
      (trace
        (aiohttp-request "POST" "/api/users" 201
          (url "/api/users")
          (sqlalchemy "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)"
            (rows 1))
          (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
          (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?"))))))
  ))
