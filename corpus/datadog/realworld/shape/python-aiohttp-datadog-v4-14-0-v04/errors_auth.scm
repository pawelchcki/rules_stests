; The native Datadog traces of the errors_auth scenario, reviewed for python-aiohttp-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 errors_auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.4")
    (trace
      (aiohttp-request "GET" "/api/user" 401
        (url "/api/user")))
    (repeat 2
      (trace
        (aiohttp-request "PUT" "/api/user" 200
          (url "/api/user")
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
          (sqlalchemy "UPDATE users SET password_hash=? WHERE users.id = ?"
            (rows 1)))))
    (trace
      (aiohttp-request "PUT" "/api/user" 401
        (url "/api/user")))
    (repeat 7
      (trace
        (aiohttp-request "PUT" "/api/user" 422
          (url "/api/user")
          (sqlalchemy "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?"))))
    (trace
      (aiohttp-request "POST" "/api/users" 201
        (url "/api/users")
        (sqlalchemy "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)"
          (rows 1))
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (trace
      (aiohttp-request "POST" "/api/users" 409
        (url "/api/users")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (trace
      (aiohttp-request "POST" "/api/users" 409
        (url "/api/users")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))
    (repeat 3
      (trace
        (aiohttp-request "POST" "/api/users" 422
          (url "/api/users"))))
    (trace
      (aiohttp-request "POST" "/api/users/login" 401
        (url "/api/users/login")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")))
    (repeat 2
      (trace
        (aiohttp-request "POST" "/api/users/login" 422
          (url "/api/users/login"))))))
  ))
