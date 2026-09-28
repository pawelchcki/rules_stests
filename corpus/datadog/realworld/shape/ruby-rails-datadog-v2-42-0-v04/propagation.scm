; The native Datadog traces of the propagation scenario, reviewed for ruby-rails-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/rails.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 propagation)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape rails))
  (begin

(define scenario-shape
  (traces rails-app
    (trace
      (rack-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"))
        (action-controller "TagsController" "index"
          (active-record "SELECT \"tags\".\"name\" FROM \"tags\" ORDER BY \"tags\".\"id\" ASC"
            first-finished))))
    (trace
      (rack-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-8c1e0a5b6d2f47398a4b0c7e1d5f3a92-00f067aa0ba902b7-01"))
        (action-controller "TagsController" "index"
          (active-record "SELECT \"tags\".\"name\" FROM \"tags\" ORDER BY \"tags\".\"id\" ASC"
            first-finished))))
    (trace
      (rack-request "GET" "/api/tags" 200
        (url "/api/tags")
        (continues (traceparent "00-b3f7d21c9e6a48059c7d2e8f4a1b6035-00f067aa0ba902b7-01"))
        (action-controller "TagsController" "index"
          (active-record "SELECT \"tags\".\"name\" FROM \"tags\" ORDER BY \"tags\".\"id\" ASC"
            first-finished))))
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
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n")))))))
  ))
