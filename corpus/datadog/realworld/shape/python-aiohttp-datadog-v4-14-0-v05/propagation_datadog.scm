(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v05 propagation_datadog)
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
            (resource "GET /api/tags")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "11276220234964099125")
            (trace-id-high "b3f7d21c9e6a4805")
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
                ("_sampling_priority_v1" 1.0)))
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
            (resource "GET /api/tags")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "11803532876627986230")
            (trace-id-high "4bf92f3577b34da6")
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
                ("_sampling_priority_v1" 1.0)))
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
            (resource "GET /api/tags")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "9965072336285547154")
            (trace-id-high "8c1e0a5b6d2f4739")
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
                ("_sampling_priority_v1" 1.0)))
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
