; The native Datadog traces of the errors_profiles scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 errors_profiles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (trace
      (sinatra-request "GET" "/api/profiles/:username" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>")
        (route
          (failure "{:profile=>[\"not found\"]}")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "DELETE" "/api/profiles/:username/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (route
          (failure "{:token=>[\"is missing\"]}")
          first-finished)))
    (trace
      (sinatra-request "DELETE" "/api/profiles/:username/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:profile=>[\"not found\"]}")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1"))))
    (trace
      (sinatra-request "POST" "/api/profiles/:username/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (route
          (failure "{:token=>[\"is missing\"]}")
          first-finished)))
    (trace
      (sinatra-request "POST" "/api/profiles/:username/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (failure "{:profile=>[\"not found\"]}")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1"))))
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
