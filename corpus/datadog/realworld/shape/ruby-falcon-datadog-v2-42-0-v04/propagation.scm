; The native Datadog traces of the propagation scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 propagation)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (trace
      (sinatra-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"))
        (route
          (sequel "SELECT `name` FROM `tags` ORDER BY `id`"
            first-finished))))
    (trace
      (sinatra-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-8c1e0a5b6d2f47398a4b0c7e1d5f3a92-00f067aa0ba902b7-01"))
        (route
          (sequel "SELECT `name` FROM `tags` ORDER BY `id`"
            first-finished))))
    (trace
      (sinatra-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-b3f7d21c9e6a48059c7d2e8f4a1b6035-00f067aa0ba902b7-01"))
        (route
          (sequel "SELECT `name` FROM `tags` ORDER BY `id`"
            first-finished))))
    (trace
      (sinatra-request "POST" "/api/users" 201
        (url "/api/users")
        (route
          (sequel "INSERT INTO `users` (`username`, `email`, `password_digest`, `created_at`, `updated_at`) VALUES (:username, :email, :password_digest, :created_at, :updated_at)")
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
          (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))))
  ))
