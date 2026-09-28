; The native Datadog traces of the errors_articles scenario, reviewed for ruby-rails-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/rails.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 errors_articles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape rails))
  (begin

(define scenario-shape
  (traces rails-app
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
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
          (active-record "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'article_tags'\n")
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
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
          (active-record "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
          (active-record "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "POST" "/api/articles" 422
        (url "/api/articles")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "create"
          without-runtimes
          (active-record "PRAGMA table_xinfo(\"articles\")"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "ROLLBACK TRANSACTION")
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
            cached)
          (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'articles'\n"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (repeat 2
      (trace
        (rack-request "POST" "/api/articles" 422
          (url "/api/articles")
          (instantiate "User" 1)
          (action-controller "ArticlesController" "create"
            without-runtimes
            (active-record "ROLLBACK TRANSACTION")
            (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
              cached)
            (active-record "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"
              (active-record "BEGIN immediate TRANSACTION")))
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
            first-finished))))
    (trace
      (rack-request "POST" "/api/articles" 401
        (url "/api/articles")
        first-finished))
    (trace
      (rack-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/dup-title-rules_stests_<workload>")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "destroy"
          without-runtimes
          (instantiate "Article" 1)
          (instantiate "User" 1)
          (active-record "COMMIT TRANSACTION")
          (active-record "DELETE FROM \"articles\" WHERE \"articles\".\"id\" = ?")
          (active-record "PRAGMA table_xinfo(\"article_tags\")")
          (active-record "PRAGMA table_xinfo(\"comments\")")
          (active-record "PRAGMA table_xinfo(\"comments\")"
            (active-record "BEGIN immediate TRANSACTION"))
          (active-record "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
          (active-record "SELECT \"comments\".* FROM \"comments\" WHERE \"comments\".\"article_id\" = ?")
          (active-record "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'article_tags'\n")
          (times 2
            (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'comments'\n")))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "DELETE" "/api/articles/:slug" 204
        (url "/api/articles/dup-title-rules_stests_<workload>")
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
      (rack-request "DELETE" "/api/articles/:slug" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "destroy"
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "DELETE" "/api/articles/:slug" 401
        (url "/api/articles/some-slug")
        first-finished))
    (trace
      (rack-request "GET" "/api/articles/:slug" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>")
        (action-controller "ArticlesController" "show"
          (active-record "PRAGMA table_xinfo(\"articles\")"
            first-finished)
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'articles'\n"))))
    (repeat 2
      (trace
        (rack-request "PUT" "/api/articles/:slug" 404
          (url "/api/articles/unknown-slug-rules_stests_<workload>")
          (instantiate "User" 1)
          (action-controller "ArticlesController" "update"
            (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"))
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
            first-finished))))
    (trace
      (rack-request "PUT" "/api/articles/:slug" 401
        (url "/api/articles/some-slug")
        first-finished))
    (trace
      (rack-request "DELETE" "/api/articles/:slug/favorite" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/favorite")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "unfavorite"
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "DELETE" "/api/articles/:slug/favorite" 401
        (url "/api/articles/some-slug/favorite")
        first-finished))
    (trace
      (rack-request "POST" "/api/articles/:slug/favorite" 404
        (url "/api/articles/unknown-slug-rules_stests_<workload>/favorite")
        (instantiate "User" 1)
        (action-controller "ArticlesController" "favorite"
          (active-record "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?"))
        (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?"
          first-finished)))
    (trace
      (rack-request "POST" "/api/articles/:slug/favorite" 401
        (url "/api/articles/some-slug/favorite")
        first-finished))
    (trace
      (rack-request "GET" "/api/articles/feed" 401
        (url "/api/articles/feed")
        first-finished))
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
