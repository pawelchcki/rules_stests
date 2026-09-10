(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v05 errors_auth)
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
            (resource "GET /api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "/api/user")
                ("http.status_code" "401")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              ())))))
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
                ("http.status_code" "409")))
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
                ("http.status_code" "409")))
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
      (count 3)
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
                ("http.status_code" "422")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              ())))))
    (
      (count 1)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/users/login")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "/api/users/login")
                ("http.status_code" "401")))
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
                    ()))))))))
    (
      (count 2)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/users/login")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "/api/users/login")
                ("http.status_code" "422")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              ())))))
    (
      (count 2)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "PUT /api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "PUT")
                ("http.route" "/api/user")
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
                  (resource "UPDATE users SET password_hash=? WHERE users.id = ?")
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
            (resource "PUT /api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "PUT")
                ("http.route" "/api/user")
                ("http.status_code" "401")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              ())))))
    (
      (count 7)
      (roots
        (
          (
            (service "aiohttp-datadog")
            (name "aiohttp.request")
            (type "web")
            (resource "PUT /api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "PUT")
                ("http.route" "/api/user")
                ("http.status_code" "422")))
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
                    ()))))))))))
  ))
