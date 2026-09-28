; The native Datadog traces of the profiles scenario, reviewed for ruby-falcon-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/falcon.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 profiles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape falcon))
  (begin

(define scenario-shape
  (traces falcon-app
    (repeat 2
      (trace
        (sinatra-request "GET" "/api/profiles/:username" 200
          (url "/api/profiles/celeb_rules_stests_<workload>")
          (before-filter
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
              first-finished))
          (route
            (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1")
            (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1")))))
    (trace
      (sinatra-request "GET" "/api/profiles/:username" 200
        (url "/api/profiles/celeb_rules_stests_<workload>")
        (route
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1"
            first-finished))))
    (trace
      (sinatra-request "DELETE" "/api/profiles/:username/follow" 200
        (url "/api/profiles/celeb_rules_stests_<workload>/follow")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "DELETE FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed))")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1"))))
    (trace
      (sinatra-request "POST" "/api/profiles/:username/follow" 200
        (url "/api/profiles/celeb_rules_stests_<workload>/follow")
        (before-filter
          (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1"
            first-finished))
        (route
          (sequel "INSERT OR IGNORE INTO `follows` (`follower_id`, `followed_id`) VALUES (:follower_id, :followed_id)")
          (sequel "SELECT * FROM `users` WHERE (`username` = :username) LIMIT 1")
          (sequel "SELECT 1 FROM `follows` WHERE ((`follower_id` = :follower) AND (`followed_id` = :followed)) LIMIT 1"))))
    (repeat 2
      (trace
        (sinatra-request "POST" "/api/users" 201
          (url "/api/users")
          (route
            (sequel "INSERT INTO `users` (`username`, `email`, `password_digest`, `created_at`, `updated_at`) VALUES (:username, :email, :password_digest, :created_at, :updated_at)")
            (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
            (sequel "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1"
              first-finished)))))))
  ))
