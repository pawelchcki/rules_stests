; The native Datadog traces of the errors_auth scenario, reviewed for ruby-rails-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/rails.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 errors_auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape rails))
  (begin

(define scenario-shape
  (traces rails-app
    (trace
      (rack-request "GET" "/api/user" 401
        (url "/api/user")
        first-finished))
    (trace
      (rack-request "PUT" "/api/user" 401
        (url "/api/user")
        first-finished))
    (repeat 2
      (trace
        (rack-request "PUT" "/api/user" 200
          (url "/api/user")
          (instantiate "User" 1)
          (action-controller "UsersController" "update"
            (active-record "COMMIT TRANSACTION")
            (active-record "UPDATE \"users\" SET \"password_digest\" = ?, \"updated_at\" = ? WHERE \"users\".\"id\" = ?"
              (active-record "BEGIN immediate TRANSACTION")))
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
            first-finished))))
    (trace
      (rack-request "PUT" "/api/user" 422
        (url "/api/user")
        (instantiate "User" 1)
        (action-controller "UsersController" "update"
          (active-record "PRAGMA index_info('index_users_on_email')")
          (active-record "PRAGMA index_info('index_users_on_username')")
          (active-record "PRAGMA index_list(\"users\")"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "ROLLBACK TRANSACTION")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? AND \"users\".\"id\" != ? LIMIT ?")
          (active-record "SELECT sql\nFROM sqlite_master\nWHERE name = 'index_users_on_email' AND type = 'index'\nUNION ALL\nSELECT sql\nFROM sqlite_temp_master\nWHERE name = 'index_users_on_email' AND type = 'index'\n")
          (active-record "SELECT sql\nFROM sqlite_master\nWHERE name = 'index_users_on_username' AND type = 'index'\nUNION ALL\nSELECT sql\nFROM sqlite_temp_master\nWHERE name = 'index_users_on_username' AND type = 'index'\n"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "PUT" "/api/user" 422
        (url "/api/user")
        (instantiate "User" 1)
        (action-controller "UsersController" "update"
          (active-record "ROLLBACK TRANSACTION")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" IS NULL AND \"users\".\"id\" != ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION")))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "PUT" "/api/user" 422
        (url "/api/user")
        (instantiate "User" 1)
        (action-controller "UsersController" "update"
          (active-record "ROLLBACK TRANSACTION")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? AND \"users\".\"id\" != ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION")))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "PUT" "/api/user" 422
        (url "/api/user")
        (instantiate "User" 1)
        (action-controller "UsersController" "update"
          (active-record "ROLLBACK TRANSACTION")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" IS NULL AND \"users\".\"id\" != ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION")))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (repeat 3
      (trace
        (rack-request "PUT" "/api/user" 422
          (url "/api/user")
          (instantiate "User" 1)
          (action-controller "UsersController" "update")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
            first-finished))))
    (trace
      (rack-request "POST" "/api/users" 201
        (url "/api/users")
        (action-controller "UsersController" "create"
          (active-record "COMMIT TRANSACTION")
          (active-record "INSERT INTO \"users\" (\"username\", \"email\", \"password_digest\", \"bio\", \"image\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"
              first-finished)))))
    (repeat 2
      (trace
        (rack-request "POST" "/api/users" 409
          (url "/api/users")
          (action-controller "UsersController" "create"
            (active-record "ROLLBACK TRANSACTION")
            (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
            (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
              (active-record "BEGIN immediate TRANSACTION"
                first-finished))))))
    (trace
      (rack-request "POST" "/api/users" 422
        (url "/api/users")
        (action-controller "UsersController" "create"
          (active-record "PRAGMA table_xinfo(\"users\")"
            first-finished)
          (active-record "PRAGMA table_xinfo(\"users\")")
          (active-record "ROLLBACK TRANSACTION")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT name FROM pragma_table_list WHERE schema <> 'temp' AND name NOT IN ('sqlite_sequence', 'sqlite_schema') AND type IN ('table','view')")
          (times 2
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n")))))
    (repeat 2
      (trace
        (rack-request "POST" "/api/users" 422
          (url "/api/users")
          (action-controller "UsersController" "create"
            (active-record "ROLLBACK TRANSACTION")
            (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
            (active-record "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?"
              (active-record "BEGIN immediate TRANSACTION"
                first-finished))))))
    (trace
      (rack-request "POST" "/api/users/login" 401
        (url "/api/users/login")
        (action-controller "UsersController" "login"
          (instantiate "User" 1)
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?"
            first-finished))))
    (repeat 2
      (trace
        (rack-request "POST" "/api/users/login" 422
          (url "/api/users/login")
          (action-controller "UsersController" "login"
            first-finished))))))
  ))
