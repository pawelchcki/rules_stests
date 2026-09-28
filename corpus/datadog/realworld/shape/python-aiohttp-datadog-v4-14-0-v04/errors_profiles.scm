; The native Datadog traces of the errors_profiles scenario, reviewed for python-aiohttp-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 errors_profiles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.4")
    (trace
      (aiohttp-request "GET" "/api/profiles/{username}" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (trace
      (aiohttp-request "DELETE" "/api/profiles/{username}/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")))
    (trace
      (aiohttp-request "DELETE" "/api/profiles/{username}/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (trace
      (aiohttp-request "POST" "/api/profiles/{username}/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")))
    (trace
      (aiohttp-request "POST" "/api/profiles/{username}/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (trace
      (aiohttp-request "POST" "/api/users" 201
        (url "/api/users")
        (sqlalchemy "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))))
  ))
