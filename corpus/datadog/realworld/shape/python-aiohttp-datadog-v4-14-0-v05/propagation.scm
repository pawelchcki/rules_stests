; The native Datadog traces of the propagation scenario, reviewed for python-aiohttp-datadog-v4-14-0-v05.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v05 propagation)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.5")
    (trace
      (aiohttp-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"))
        (sqlalchemy "SELECT DISTINCT article_tags.tag \nFROM article_tags ORDER BY article_tags.tag")))
    (trace
      (aiohttp-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-8c1e0a5b6d2f47398a4b0c7e1d5f3a92-00f067aa0ba902b7-01"))
        (sqlalchemy "SELECT DISTINCT article_tags.tag \nFROM article_tags ORDER BY article_tags.tag")))
    (trace
      (aiohttp-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-b3f7d21c9e6a48059c7d2e8f4a1b6035-00f067aa0ba902b7-01"))
        (sqlalchemy "SELECT DISTINCT article_tags.tag \nFROM article_tags ORDER BY article_tags.tag")))
    (trace
      (aiohttp-request "POST" "/api/users" 201
        (url "/api/users")
        (sqlalchemy "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))))
  ))
