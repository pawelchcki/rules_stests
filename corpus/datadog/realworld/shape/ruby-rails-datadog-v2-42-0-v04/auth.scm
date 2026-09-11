(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 auth)
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
            (resource "UsersController#login")
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
                ("http.route" "/api/users/login")
                ("http.status_code" "200")
                ("http.url" "/api/users/login")
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
                  (resource "UsersController#login")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "login")
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
                        (resource "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"email\" = ? LIMIT ?")
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
      (count 8)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "UsersController#show")
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
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "/api/user")
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
                  (resource "UsersController#show")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "show")
                      ("rails.route.controller" "UsersController")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("rails.db.runtime" "<duration-ms>")
                      ("rails.view.runtime" "<duration-ms>")))
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
            (resource "UsersController#update")
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
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "/api/user")
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
                  (resource "UsersController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
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
                        (resource "PRAGMA index_info('index_users_on_email')")
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
                        (resource "PRAGMA index_info('index_users_on_username')")
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
                        (resource "PRAGMA index_list(\"users\")")
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
                        (resource "SELECT sql\nFROM sqlite_master\nWHERE name = 'index_users_on_email' AND type = 'index'\nUNION ALL\nSELECT sql\nFROM sqlite_temp_master\nWHERE name = 'index_users_on_email' AND type = 'index'\n")
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
                        (resource "SELECT sql\nFROM sqlite_master\nWHERE name = 'index_users_on_username' AND type = 'index'\nUNION ALL\nSELECT sql\nFROM sqlite_temp_master\nWHERE name = 'index_users_on_username' AND type = 'index'\n")
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
                        (resource "UPDATE \"users\" SET \"bio\" = ?, \"updated_at\" = ? WHERE \"users\".\"id\" = ?")
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
            (resource "UsersController#update")
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
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "/api/user")
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
                  (resource "UsersController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
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
                        (resource "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"email\" = ? AND \"users\".\"id\" != ? LIMIT ?")
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
                        (resource "SELECT 1 AS one FROM \"users\" WHERE \"users\".\"username\" = ? AND \"users\".\"id\" != ? LIMIT ?")
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
                        (resource "UPDATE \"users\" SET \"username\" = ?, \"email\" = ?, \"updated_at\" = ? WHERE \"users\".\"id\" = ?")
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
      (count 4)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "UsersController#update")
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
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "/api/user")
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
                  (resource "UsersController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
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
                        (resource "UPDATE \"users\" SET \"bio\" = ?, \"updated_at\" = ? WHERE \"users\".\"id\" = ?")
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
      (count 4)
      (roots
        (
          (
            (native-fields
              ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
            (service "<service>")
            (name "rack.request")
            (type "web")
            (resource "UsersController#update")
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
                ("http.route" "/api/user")
                ("http.status_code" "200")
                ("http.url" "/api/user")
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
                  (resource "UsersController#update")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "update")
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
                        (resource "UPDATE \"users\" SET \"image\" = ?, \"updated_at\" = ? WHERE \"users\".\"id\" = ?")
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
                    ()))))))))))
  ))
