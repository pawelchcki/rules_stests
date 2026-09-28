; The native Datadog traces of the auth scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (repeat 8
      (trace
        (sinatra-request "GET" "/api/user" 200
          (url "/api/user")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route))))
    (repeat 5
      (trace
        (sinatra-request "PUT" "/api/user" 200
          (url "/api/user")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`email` = :email)) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`username` = :username)) LIMIT 1")
            (sequel "UPDATE `users` SET `bio` = :bio, `updated_at` = :updated_at WHERE (`id` = :id)")))))
    (repeat 4
      (trace
        (sinatra-request "PUT" "/api/user" 200
          (url "/api/user")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`email` = :email)) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`username` = :username)) LIMIT 1")
            (sequel "UPDATE `users` SET `image` = :image, `updated_at` = :updated_at WHERE (`id` = :id)")))))
    (trace
      (sinatra-request "PUT" "/api/user" 200
        (url "/api/user")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`email` = :email)) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`username` = :username)) LIMIT 1")
          (sequel "UPDATE `users` SET `username` = :username, `email` = :email, `updated_at` = :updated_at WHERE (`id` = :id)"))))
    (trace
      (sinatra-request "POST" "/api/users" 201
        (url "/api/users")
        (route
          (sequel "INSERT INTO `users` (`username`, `email`, `password_digest`, `created_at`, `updated_at`) VALUES (:username, :email, :password_digest, :created_at, :updated_at)")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users/login" 200
        (url "/api/users/login")
        (route
          (sequel "SELECT * FROM `users` WHERE (`email` = :email) LIMIT 1"
            first-finished))))))
  ))
