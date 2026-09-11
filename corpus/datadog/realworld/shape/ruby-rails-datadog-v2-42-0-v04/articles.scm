(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 articles)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape))
  (begin
(define scenario-shape
  '(
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#create")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "POST")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles")
                ("http.status_code" "201")
                ("http.url" "/api/articles")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#create")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "create")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "COMMIT TRANSACTION")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "INSERT INTO \"article_tags\" (\"article_id\", \"tag_id\") VALUES (?, ?) RETURNING \"id\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "INSERT INTO \"article_tags\" (\"article_id\", \"tag_id\") VALUES (?, ?) RETURNING \"id\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "INSERT INTO \"articles\" (\"user_id\", \"slug\", \"title\", \"description\", \"body\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "INSERT INTO \"tags\" (\"name\") VALUES (?) RETURNING \"id\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "INSERT INTO \"tags\" (\"name\") VALUES (?) RETURNING \"id\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"article_tags\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"article_tags\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"articles\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "BEGIN immediate TRANSACTION")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ())))))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"articles\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"favorites\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"favorites\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"follows\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"tags\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "SAVEPOINT active_record_1")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ())))))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "RELEASE SAVEPOINT active_record_1")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "RELEASE SAVEPOINT active_record_1")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"article_tags\" WHERE \"article_tags\".\"tag_id\" = ? AND \"article_tags\".\"article_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"article_tags\" WHERE \"article_tags\".\"tag_id\" = ? AND \"article_tags\".\"article_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.cached" "true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"tags\" WHERE \"tags\".\"name\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "SAVEPOINT active_record_1")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ())))))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"tags\" WHERE \"tags\".\"name\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"name\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"name\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'article_tags'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'article_tags'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'articles'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'articles'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'favorites'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'favorites'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'follows'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'tags'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#destroy")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "DELETE")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "204")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#destroy")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "destroy")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "COMMIT TRANSACTION")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "DELETE FROM \"articles\" WHERE \"articles\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"comments\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "BEGIN immediate TRANSACTION")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ())))))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"comments\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"comments\".* FROM \"comments\" WHERE \"comments\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'comments'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'comments'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#index")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles")
                ("http.status_code" "200")
                ("http.url" "/api/articles")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(DISTINCT \"articles\".\"id\") FROM \"articles\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT DISTINCT \"articles\".* FROM \"articles\" ORDER BY \"articles\".\"created_at\" DESC, \"articles\".\"id\" DESC LIMIT ? OFFSET ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 2)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#index")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles")
                ("http.status_code" "200")
                ("http.url" "/api/articles")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(DISTINCT \"articles\".\"id\") FROM \"articles\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT DISTINCT \"articles\".* FROM \"articles\" ORDER BY \"articles\".\"created_at\" DESC, \"articles\".\"id\" DESC LIMIT ? OFFSET ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#index")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles")
                ("http.status_code" "200")
                ("http.url" "/api/articles?author")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(DISTINCT \"articles\".\"id\") FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT DISTINCT \"articles\".* FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?) ORDER BY \"articles\".\"created_at\" DESC, \"articles\".\"id\" DESC LIMIT ? OFFSET ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#index")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles")
                ("http.status_code" "200")
                ("http.url" "/api/articles?author")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(DISTINCT \"articles\".\"id\") FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT DISTINCT \"articles\".* FROM \"articles\" WHERE \"articles\".\"user_id\" IN (SELECT \"users\".\"id\" FROM \"users\" WHERE \"users\".\"username\" = ?) ORDER BY \"articles\".\"created_at\" DESC, \"articles\".\"id\" DESC LIMIT ? OFFSET ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#index")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles")
                ("http.status_code" "200")
                ("http.url" "/api/articles?tag")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(DISTINCT \"articles\".\"id\") FROM \"articles\" WHERE \"articles\".\"id\" IN (SELECT \"article_tags\".\"article_id\" FROM \"article_tags\" WHERE \"article_tags\".\"tag_id\" IN (SELECT \"tags\".\"id\" FROM \"tags\" WHERE \"tags\".\"name\" = ?))")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT DISTINCT \"articles\".* FROM \"articles\" WHERE \"articles\".\"id\" IN (SELECT \"article_tags\".\"article_id\" FROM \"article_tags\" WHERE \"article_tags\".\"tag_id\" IN (SELECT \"tags\".\"id\" FROM \"tags\" WHERE \"tags\".\"name\" = ?)) ORDER BY \"articles\".\"created_at\" DESC, \"articles\".\"id\" DESC LIMIT ? OFFSET ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"favorites\".* FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))))))))
    (
      (count 2)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#show")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "200")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#show")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "show")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#show")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "200")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#show")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "show")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#show")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "404")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#show")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "show")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#update")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "PUT")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "200")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "COMMIT TRANSACTION")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "DELETE FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ? AND \"article_tags\".\"tag_id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "BEGIN immediate TRANSACTION")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ())))))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#update")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "PUT")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "200")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "COMMIT TRANSACTION")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA index_info('index_articles_on_slug')")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA index_info('index_articles_on_user_id')")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA index_info('index_articles_on_user_id_and_created_at')")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA index_list(\"articles\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "BEGIN immediate TRANSACTION")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ())))))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql\nFROM sqlite_master\nWHERE name = 'index_articles_on_slug' AND type = 'index'\nUNION ALL\nSELECT sql\nFROM sqlite_temp_master\nWHERE name = 'index_articles_on_slug' AND type = 'index'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql\nFROM sqlite_master\nWHERE name = 'index_articles_on_user_id' AND type = 'index'\nUNION ALL\nSELECT sql\nFROM sqlite_temp_master\nWHERE name = 'index_articles_on_user_id' AND type = 'index'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql\nFROM sqlite_master\nWHERE name = 'index_articles_on_user_id_and_created_at' AND type = 'index'\nUNION ALL\nSELECT sql\nFROM sqlite_temp_master\nWHERE name = 'index_articles_on_user_id_and_created_at' AND type = 'index'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "UPDATE \"articles\" SET \"body\" = ?, \"updated_at\" = ? WHERE \"articles\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#update")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "PUT")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "200")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "ArticleTag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "ArticleTag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Tag")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Tag")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 2.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "COMMIT TRANSACTION")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ? AND \"favorites\".\"user_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"follows\" WHERE \"follows\".\"follower_id\" = ? AND \"follows\".\"followed_id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT COUNT(*) FROM \"favorites\" WHERE \"favorites\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".* FROM \"tags\" WHERE \"tags\".\"id\" IN (?, ?)")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" INNER JOIN \"article_tags\" ON \"tags\".\"id\" = \"article_tags\".\"tag_id\" WHERE \"article_tags\".\"article_id\" = ? ORDER BY \"tags\".\"id\" ASC")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "UPDATE \"articles\" SET \"body\" = ?, \"updated_at\" = ? WHERE \"articles\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "BEGIN immediate TRANSACTION")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))))))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "ArticlesController#update")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "PUT")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/articles/:slug")
                ("http.status_code" "422")
                ("http.url" "/api/articles/test-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "active_record.instantiation")
                  (type "custom")
                  (resource "User")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("active_record.instantiation.class_name" "User")
                      ("component" "active_record")
                      ("env" "test")
                      ("operation" "instantiation")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("active_record.instantiation.record_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "ArticlesController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
                      ("rails.route.controller" "ArticlesController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "Article")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "Article")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "<service>")
                        (name "active_record.instantiation")
                        (type "custom")
                        (resource "User")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("active_record.instantiation.class_name" "User")
                            ("component" "active_record")
                            ("env" "test")
                            ("operation" "instantiation")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)
                            ("active_record.instantiation.record_count" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"article_tags\".* FROM \"article_tags\" WHERE \"article_tags\".\"article_id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"articles\".* FROM \"articles\" WHERE \"articles\".\"slug\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"id\" = ? LIMIT ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "active_record")
                      ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                      ("active_record.db.name" "<fixture>/realworld.sqlite3")
                      ("active_record.db.vendor" "sqlite")
                      ("component" "active_record")
                      ("db.instance" "<fixture>/realworld.sqlite3")
                      ("env" "test")
                      ("operation" "sql")
                      ("span.kind" "client")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "UsersController#create")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "POST")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/users")
                ("http.status_code" "201")
                ("http.url" "/api/users")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "UsersController#create")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "create")
                      ("rails.route.controller" "UsersController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "COMMIT TRANSACTION")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "INSERT INTO \"users\" (\"username\", \"email\", \"password_digest\", \"bio\", \"image\", \"created_at\", \"updated_at\") VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING \"id\"")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"users\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "PRAGMA table_xinfo(\"users\")")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? LIMIT ?")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sqlite.query")
                              (type "sql")
                              (resource "BEGIN immediate TRANSACTION")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "active_record")
                                  ("active_record.db.name" "<fixture>/realworld.sqlite3")
                                  ("active_record.db.vendor" "sqlite")
                                  ("component" "active_record")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("env" "test")
                                  ("operation" "sql")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ())))))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT name FROM pragma_table_list WHERE schema <> 'temp' AND name NOT IN ('sqlite_sequence', 'sqlite_schema') AND type IN ('table','view')")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                        (service "sqlite")
                        (name "sqlite.query")
                        (type "sql")
                        (resource "SELECT sql FROM\n  (SELECT * FROM sqlite_master UNION ALL\n   SELECT * FROM sqlite_temp_master)\nWHERE type = 'table' AND name = 'users'\n")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.base_service" "<service>")
                            ("_dd.svc_src" "active_record")
                            ("active_record.db.name" "<fixture>/realworld.sqlite3")
                            ("active_record.db.vendor" "sqlite")
                            ("component" "active_record")
                            ("db.instance" "<fixture>/realworld.sqlite3")
                            ("env" "test")
                            ("operation" "sql")
                            ("span.kind" "client")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.top_level" 1.0)))
                        (children
                          ())))))))))))))
  ))
