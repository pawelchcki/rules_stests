; The native Datadog traces of the unicode scenario, reviewed for ruby-rails-datadog-v2-42-0-v04.
; Builders: corpus/datadog/shape/rails.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 unicode)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape rails))
  (begin

(define scenario-shape
  (traces rails-app
    (trace
      (rack-request "GET" "/api/profiles/:username" 404
        (url "/api/profiles/%C3%BCn%C3%AFc%C3%B8de_rules_stests_<workload>") (user-agent "")
        (action-controller "ProfilesController" "show"
          (active-record "PRAGMA table_xinfo(\"users\")"
            first-finished)
          (active-record "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?")
          (active-record "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n"))))))
  ))
