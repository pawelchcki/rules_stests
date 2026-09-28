; The native Datadog traces of the propagation_datadog scenario, reviewed for python-aiohttp-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 propagation_datadog)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.4")
    (trace
      (aiohttp-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "11276220234964099125" "67667974448284343" 1 "b3f7d21c9e6a4805"))
        (sqlalchemy "SELECT DISTINCT article_tags.tag \nFROM article_tags ORDER BY article_tags.tag")))
    (trace
      (aiohttp-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "11803532876627986230" "67667974448284343" 1 "4bf92f3577b34da6"))
        (sqlalchemy "SELECT DISTINCT article_tags.tag \nFROM article_tags ORDER BY article_tags.tag")))
    (trace
      (aiohttp-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "9965072336285547154" "67667974448284343" 1 "8c1e0a5b6d2f4739"))
        (sqlalchemy "SELECT DISTINCT article_tags.tag \nFROM article_tags ORDER BY article_tags.tag")))
    (trace
      (aiohttp-request "POST" "/api/users" 201
        (url "/api/users")
        (sqlalchemy "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))))
  ))
