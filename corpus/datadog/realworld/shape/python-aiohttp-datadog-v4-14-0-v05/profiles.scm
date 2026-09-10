(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v05 profiles)
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
            (resource "DELETE /api/profiles/{username}/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "DELETE")
                ("http.route" "/api/profiles/{username}/follow")
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
                  (resource "DELETE FROM follows WHERE follows.follower_id = ? AND follows.followed_id = ?")
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
                    ()))))))))
    (
      (count 2)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "GET /api/profiles/{username}")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "/api/profiles/{username}")
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
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "GET /api/profiles/{username}")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "/api/profiles/{username}")
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
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/profiles/{username}/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "/api/profiles/{username}/follow")
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
                  (resource "INSERT INTO follows (follower_id, followed_id) VALUES (?, ?) ON CONFLICT DO NOTHING")
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
                    ()))))))))
    (
      (count 2)
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
