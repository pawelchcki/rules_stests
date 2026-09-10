(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v05 unicode)
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
            (resource "GET /api/profiles/{username}")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "aiohttp")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "/api/profiles/{username}")
                ("http.status_code" "404")))
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
                    ()))))))))))
  ))
