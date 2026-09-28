; The native Datadog traces of the propagation_datadog scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 propagation_datadog)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (trace
      (sinatra-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "11276220234964099125" "67667974448284343" 1 "b3f7d21c9e6a4805"))
        (route
          (sequel "SELECT `name` FROM `tags` ORDER BY `id`"
            first-finished))))
    (trace
      (sinatra-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "11803532876627986230" "67667974448284343" 1 "4bf92f3577b34da6"))
        (route
          (sequel "SELECT `name` FROM `tags` ORDER BY `id`"
            first-finished))))
    (trace
      (sinatra-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (datadog-headers "9965072336285547154" "67667974448284343" 1 "8c1e0a5b6d2f4739"))
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
