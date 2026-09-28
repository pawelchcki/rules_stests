; The native Datadog traces of the pagination scenario, reviewed for ruby-rails-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/rails.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 pagination)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape rails))
  (begin

(define scenario-shape
  (traces rails-app
    (trace
      (rack-request "GET" "/api/articles" 200
        (url "/api/articles?author&limit")
        (action-controller "ArticlesController" "index"
          (instantiate "Article" 1)
          (instantiate "User" 1)
          (active-record "PRAGMA table_xinfo(\"article_tags\")")
          (active-record "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
          (active-record "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
          (active-record "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT COUNT(DISTINCT \"articles\".\"id\") FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?)"
            first-finished)
          (active-record "SELECT DISTINCT \"articles\".* FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?) ORDER BY \"articles\".\"created_at\" DESC, \"articles\".\"id\" DESC LIMIT ? OFFSET ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'article_tags'\n"))))
    (trace
      (rack-request "GET" "/api/articles" 200
        (url "/api/articles?author&limit&offset")
        (action-controller "ArticlesController" "index"
          (instantiate "Article" 1)
          (instantiate "User" 1)
          (active-record "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
          (active-record "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
          (active-record "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT COUNT(DISTINCT \"articles\".\"id\") FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?)"
            first-finished)
          (active-record "SELECT DISTINCT \"articles\".* FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?) ORDER BY \"articles\".\"created_at\" DESC, \"articles\".\"id\" DESC LIMIT ? OFFSET ?"))))
    (trace
      (rack-request "POST" "/api/articles" 201
        (url "/api/articles")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "create"
          (instantiate "Article" 1)
          (instantiate "User" 1)
          (active-record "COMMIT TRANSACTION")
          (active-record "INSERT INTO \"articles\" (\"user_id\", \"slug\", \"title\", \"description\", \"body\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
          (active-record "PRAGMA table_xinfo(\"article_tags\")")
          (active-record "PRAGMA table_xinfo(\"articles\")")
          (active-record "PRAGMA table_xinfo(\"articles\")"
            (active-record "BEGIN immediate TRANSACTION"))
          (times 2
            (active-record "PRAGMA table_xinfo(\"favorites\")"))
          (active-record "PRAGMA table_xinfo(\"follows\")")
          (active-record "PRAGMA table_xinfo(\"tags\")")
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"id\" = ? LIMIT ?")
          (active-record "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
          (active-record "SELECT \"tags\".* FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ?")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
            cached)
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
          (active-record "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'article_tags'\n")
          (times 2
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'articles'\n"))
          (times 2
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'favorites'\n"))
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'follows'\n")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'tags'\n"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "POST" "/api/articles" 201
        (url "/api/articles")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "create"
          (instantiate "Article" 1)
          (instantiate "User" 1)
          (active-record "COMMIT TRANSACTION")
          (active-record "INSERT INTO \"articles\" (\"user_id\", \"slug\", \"title\", \"description\", \"body\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"id\" = ? LIMIT ?")
          (active-record "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
          (active-record "SELECT \"tags\".* FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ?")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
            cached)
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
          (active-record "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/pagination-1-rules_stests_<workload>")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "destroy"
          without-runtimes
          (instantiate "Article" 1)
          (instantiate "User" 1)
          (active-record "COMMIT TRANSACTION")
          (active-record "DELETE FROM \"articles\" WHERE \"articles\".\"id\" = ?")
          (active-record "PRAGMA table_xinfo(\"comments\")")
          (active-record "PRAGMA table_xinfo(\"comments\")"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
          (active-record "SELECT \"comments\".* FROM \"comments\" WHERE \"comments\".\"article_id\" = ?")
          (active-record "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
          (times 2
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'comments'\n")))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/pagination-2-rules_stests_<workload>")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "destroy"
          without-runtimes
          (instantiate "Article" 1)
          (instantiate "User" 1)
          (active-record "COMMIT TRANSACTION")
          (active-record "DELETE FROM \"articles\" WHERE \"articles\".\"id\" = ?")
          (active-record "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
          (active-record "SELECT \"comments\".* FROM \"comments\" WHERE \"comments\".\"article_id\" = ?"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?"))
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
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n")))))))
  ))
