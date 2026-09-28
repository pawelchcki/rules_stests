; The native Datadog traces of the errors_auth scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 errors_auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (trace
      (sinatra-request "GET" "/api/user" 401
        (url "/api/user")
        (route
          (failure "{:token=>[\"is missing\"]}")
          first-finished)))
    (repeat 2
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
            (sequel "UPDATE `users` SET `password_digest` = :password_digest, `updated_at` = :updated_at WHERE (`id` = :id)")))))
    (trace
      (sinatra-request "PUT" "/api/user" 401
        (url "/api/user")
        (route
          (failure "{:token=>[\"is missing\"]}")
          first-finished)))
    (repeat 2
      (trace
        (sinatra-request "PUT" "/api/user" 422
          (url "/api/user")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (failure "{:email=>[\"can't be blank\"]}")
            (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`username` = :username)) LIMIT 1")))))
    (repeat 2
      (trace
        (sinatra-request "PUT" "/api/user" 422
          (url "/api/user")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (failure "{:password=>[\"can't be blank\"]}")))))
    (trace
      (sinatra-request "PUT" "/api/user" 422
        (url "/api/user")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:password=>[\"is too short (minimum is 8 characters)\"]}")
          (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`email` = :email)) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`username` = :username)) LIMIT 1"))))
    (repeat 2
      (trace
        (sinatra-request "PUT" "/api/user" 422
          (url "/api/user")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (failure "{:username=>[\"can't be blank\"]}")
            (sequel "SELECT 1 FROM `users` WHERE ((`id` != :id) AND (`email` = :email)) LIMIT 1")))))
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
      (sinatra-request "POST" "/api/users" 409
        (url "/api/users")
        (route
          (failure "{:email=>[\"has already been taken\"]}")
          (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users" 409
        (url "/api/users")
        (route
          (failure "{:username=>[\"has already been taken\"]}")
          (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users" 422
        (url "/api/users")
        (route
          (failure "{:email=>[\"can't be blank\"]}")
          (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users" 422
        (url "/api/users")
        (route
          (failure "{:password=>[\"can't be blank\", \"is too short (minimum is 8 characters)\"]}")
          (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users" 422
        (url "/api/users")
        (route
          (failure "{:username=>[\"can't be blank\"]}")
          (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users/login" 401
        (url "/api/users/login")
        (route
          (failure "{:credentials=>[\"invalid\"]}")
          (sequel "SELECT * FROM `users` WHERE (`email` = :email) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users/login" 422
        (url "/api/users/login")
        (route
          (failure "{:email=>[\"can't be blank\"]}")
          first-finished)))
    (trace
      (sinatra-request "POST" "/api/users/login" 422
        (url "/api/users/login")
        (route
          (failure "{:password=>[\"can't be blank\"]}")
          first-finished)))))
  ))
