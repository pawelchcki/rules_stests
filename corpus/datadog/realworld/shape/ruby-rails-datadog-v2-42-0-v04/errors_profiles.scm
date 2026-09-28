; The native Datadog traces of the errors_profiles scenario, reviewed for ruby-rails-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/rails.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 errors_profiles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape rails))
  (begin

(define scenario-shape
  (traces rails-app
    (trace
      (rack-request "GET" "/api/profiles/:username" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>")
        (action-controller "ProfilesController" "show"
          (active-record "PRAGMA table_xinfo(\"users\")"
            first-finished)
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n"))))
    (trace
      (rack-request "DELETE" "/api/profiles/:username/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        first-finished))
    (trace
      (rack-request "DELETE" "/api/profiles/:username/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (instantiate "User" 1)
        (action-controller "ProfilesController" "unfollow"
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "POST" "/api/profiles/:username/follow" 401
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        first-finished))
    (trace
      (rack-request "POST" "/api/profiles/:username/follow" 404
        (url "/api/profiles/unknown-user-rules_stests_<workload>/follow")
        (instantiate "User" 1)
        (action-controller "ProfilesController" "follow"
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "POST" "/api/users" 201
        (url "/api/users")
        (action-controller "UsersController" "create"
          (active-record "COMMIT TRANSACTION")
          (active-record "INSERT INTO \"users\" (\"username\", \"email\", \"password_digest\", \"bio\", \"image\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
          (active-record "PRAGMA table_xinfo(\"users\")")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT name FROM pragma_table_list WHERE schema <> 'temp' AND name NOT IN ('sqlite_sequence', 'sqlite_schema') AND type IN ('table','view')"
            first-finished)
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n"))))))
  ))
