; The native Datadog traces of the profiles scenario, reviewed for ruby-rails-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/rails.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 profiles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape rails))
  (begin

(define scenario-shape
  (traces rails-app
    (trace
      (rack-request "GET" "/api/profiles/:username" 200
        (url "/api/profiles/celeb_rules_stests_<workload>")
        (action-controller "ProfilesController" "show"
          (instantiate "User" 1)
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
            first-finished))))
    (trace
      (rack-request "GET" "/api/profiles/:username" 200
        (url "/api/profiles/celeb_rules_stests_<workload>")
        (instantiate "User" 1)
        (action-controller "ProfilesController" "show"
          (instantiate "User" 1)
          (active-record "PRAGMA table_xinfo(\"follows\")")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'follows'\n"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "GET" "/api/profiles/:username" 200
        (url "/api/profiles/celeb_rules_stests_<workload>")
        (instantiate "User" 1)
        (action-controller "ProfilesController" "show"
          (instantiate "User" 1)
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "DELETE" "/api/profiles/:username/follow" 200
        (url "/api/profiles/celeb_rules_stests_<workload>/follow")
        (instantiate "User" 1)
        (action-controller "ProfilesController" "unfollow"
          (instantiate "User" 1)
          (active-record "DELETE FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ?")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "POST" "/api/profiles/:username/follow" 200
        (url "/api/profiles/celeb_rules_stests_<workload>/follow")
        (instantiate "User" 1)
        (action-controller "ProfilesController" "follow"
          (instantiate "User" 1)
          (active-record "COMMIT TRANSACTION")
          (active-record "INSERT INTO \"follows\" (\"follower_id\", \"followed_id\") VALUES (?, ?) RETURNING \"id\"")
          (active-record "PRAGMA table_xinfo(\"follows\")"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT \"follows\".* FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"followed_id\" = ? AND \"follows\".\"follower_id\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'follows'\n"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "POST" "/api/users" 201
        (url "/api/users")
        (action-controller "UsersController" "create"
          (active-record "COMMIT TRANSACTION")
          (active-record "INSERT INTO \"users\" (\"username\", \"email\", \"password_digest\", \"bio\", \"image\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
          (active-record "PRAGMA table_xinfo(\"users\")"
            first-finished)
          (active-record "PRAGMA table_xinfo(\"users\")")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT name FROM pragma_table_list WHERE schema <> 'temp' AND name NOT IN ('sqlite_sequence', 'sqlite_schema') AND type IN ('table','view')")
          (times 2
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n")))))
    (trace
      (rack-request "POST" "/api/users" 201
        (url "/api/users")
        (action-controller "UsersController" "create"
          (active-record "COMMIT TRANSACTION")
          (active-record "INSERT INTO \"users\" (\"username\", \"email\", \"password_digest\", \"bio\", \"image\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"
              first-finished)))))))
  ))
