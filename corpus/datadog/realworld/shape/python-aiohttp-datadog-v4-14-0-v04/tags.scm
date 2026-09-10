(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 tags)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape))
  (begin
(define scenario-shape
  '(
    (
      (count 1)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "DELETE /api/articles/{slug}")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "DELETE")
                ("http.route" "/api/articles/{slug}")
                ("http.status_code" "204")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              (
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "DELETE FROM articles WHERE articles.id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "GET /api/tags")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "/api/tags")
                ("http.status_code" "200")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              (
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT DISTINCT article_tags.tag \nFROM article_tags ORDER BY article_tags.tag")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/articles")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "/api/articles")
                ("http.status_code" "201")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              (
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "INSERT INTO article_tags (article_id, tag, position) VALUES (?, ?, ?)")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "INSERT INTO articles (author_id, slug, title, description, body, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT articles.id \nFROM articles \nWHERE articles.slug = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/users")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "/api/users")
                ("http.status_code" "201")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              (
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))
                (
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sqlalchemy")
                      ("span.kind" "client")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    ()))))))))))
  ))
