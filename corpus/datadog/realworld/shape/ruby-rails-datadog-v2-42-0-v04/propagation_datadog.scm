(define-library (datadog realworld shape ruby-rails-datadog-v2-42-0-v04 propagation_datadog)
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
            (resource "TagsController#index")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "11276220234964099125")
            (trace-id-high "b3f7d21c9e6a4805")
            (error 0)
            (meta
              (
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/tags")
                ("http.status_code" "200")
                ("http.url" "/api/tags")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 1.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "TagsController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "TagsController")
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
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" ORDER BY \"tags\".\"id\" ASC")
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
            (resource "TagsController#index")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "11803532876627986230")
            (trace-id-high "4bf92f3577b34da6")
            (error 0)
            (meta
              (
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/tags")
                ("http.status_code" "200")
                ("http.url" "/api/tags")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 1.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "TagsController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "TagsController")
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
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" ORDER BY \"tags\".\"id\" ASC")
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
            (resource "TagsController#index")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "9965072336285547154")
            (trace-id-high "8c1e0a5b6d2f4739")
            (error 0)
            (meta
              (
                ("_dd.p.tid" "<trace-id-high>")
                ("component" "rack")
                ("env" "test")
                ("http.base_url" "http://<endpoint>")
                ("http.method" "GET")
                ("http.response.headers.content-type" "application/json; charset=utf-8")
                ("http.response.headers.x-request-id" "<request-id>")
                ("http.route" "/api/tags")
                ("http.status_code" "200")
                ("http.url" "/api/tags")
                ("http.useragent" "hurl/8.0.1")
                ("language" "ruby")
                ("operation" "request")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_dd.profiling.enabled" 0.0)
                ("_dd.top_level" 1.0)
                ("_sampling_priority_v1" 1.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                  (service "<service>")
                  (name "rails.action_controller")
                  (type "web")
                  (resource "TagsController#index")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "action_pack")
                      ("env" "test")
                      ("operation" "controller")
                      ("rails.route.action" "index")
                      ("rails.route.controller" "TagsController")
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
                        (resource "SELECT \"tags\".\"name\" FROM \"tags\" ORDER BY \"tags\".\"id\" ASC")
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
