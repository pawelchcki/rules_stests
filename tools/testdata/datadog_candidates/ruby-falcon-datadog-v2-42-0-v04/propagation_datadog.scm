(define-library (datadog realworld shape ruby-falcon-datadog-v2-42-0-v04 propagation_datadog)
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
            (resource "GET /api/tags")
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
                  (name "sinatra.request")
                  (type "web")
                  (resource "GET /api/tags")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sinatra")
                      ("env" "test")
                      ("http.method" "GET")
                      ("http.response.headers.content-type" "application/json; charset=utf-8")
                      ("http.status_code" "200")
                      ("http.url" "/api/tags")
                      ("operation" "request")
                      ("sinatra.route.path" "/api/tags")
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
                        (name "sinatra.route")
                        (type "web")
                        (resource "GET /api/tags")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "sinatra")
                            ("env" "test")
                            ("operation" "route")
                            ("sinatra.app.name" "RealWorld::App")
                            ("sinatra.route.path" "/api/tags")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sequel.query")
                              (type "sql")
                              (resource "SELECT `name` FROM `tags` ORDER BY `id`")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "sequel")
                                  ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:server,entrypoint.basedir:bin,entrypoint.type:script,svc.user:true")
                                  ("component" "sequel")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("db.system" "sqlite")
                                  ("env" "test")
                                  ("operation" "query")
                                  ("sequel.db.name" "<fixture>/realworld.sqlite3")
                                  ("sequel.db.vendor" "sqlite")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                (
                                  ("_dd.top_level" 1.0)))
                              (children
                                ()))))))))))))))
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
            (resource "GET /api/tags")
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
                  (name "sinatra.request")
                  (type "web")
                  (resource "GET /api/tags")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sinatra")
                      ("env" "test")
                      ("http.method" "GET")
                      ("http.response.headers.content-type" "application/json; charset=utf-8")
                      ("http.status_code" "200")
                      ("http.url" "/api/tags")
                      ("operation" "request")
                      ("sinatra.route.path" "/api/tags")
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
                        (name "sinatra.route")
                        (type "web")
                        (resource "GET /api/tags")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "sinatra")
                            ("env" "test")
                            ("operation" "route")
                            ("sinatra.app.name" "RealWorld::App")
                            ("sinatra.route.path" "/api/tags")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sequel.query")
                              (type "sql")
                              (resource "SELECT `name` FROM `tags` ORDER BY `id`")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "sequel")
                                  ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:server,entrypoint.basedir:bin,entrypoint.type:script,svc.user:true")
                                  ("component" "sequel")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("db.system" "sqlite")
                                  ("env" "test")
                                  ("operation" "query")
                                  ("sequel.db.name" "<fixture>/realworld.sqlite3")
                                  ("sequel.db.vendor" "sqlite")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                (
                                  ("_dd.top_level" 1.0)))
                              (children
                                ()))))))))))))))
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
            (resource "GET /api/tags")
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
                  (name "sinatra.request")
                  (type "web")
                  (resource "GET /api/tags")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sinatra")
                      ("env" "test")
                      ("http.method" "GET")
                      ("http.response.headers.content-type" "application/json; charset=utf-8")
                      ("http.status_code" "200")
                      ("http.url" "/api/tags")
                      ("operation" "request")
                      ("sinatra.route.path" "/api/tags")
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
                        (name "sinatra.route")
                        (type "web")
                        (resource "GET /api/tags")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "sinatra")
                            ("env" "test")
                            ("operation" "route")
                            ("sinatra.app.name" "RealWorld::App")
                            ("sinatra.route.path" "/api/tags")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sequel.query")
                              (type "sql")
                              (resource "SELECT `name` FROM `tags` ORDER BY `id`")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "sequel")
                                  ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:server,entrypoint.basedir:bin,entrypoint.type:script,svc.user:true")
                                  ("component" "sequel")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("db.system" "sqlite")
                                  ("env" "test")
                                  ("operation" "query")
                                  ("sequel.db.name" "<fixture>/realworld.sqlite3")
                                  ("sequel.db.vendor" "sqlite")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                (
                                  ("_dd.top_level" 1.0)))
                              (children
                                ()))))))))))))))
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
            (resource "POST /api/users")
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
                  (name "sinatra.request")
                  (type "web")
                  (resource "POST /api/users")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "sinatra")
                      ("env" "test")
                      ("http.method" "POST")
                      ("http.response.headers.content-type" "application/json; charset=utf-8")
                      ("http.status_code" "201")
                      ("http.url" "/api/users")
                      ("operation" "request")
                      ("sinatra.route.path" "/api/users")
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
                        (name "sinatra.route")
                        (type "web")
                        (resource "POST /api/users")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "sinatra")
                            ("env" "test")
                            ("operation" "route")
                            ("sinatra.app.name" "RealWorld::App")
                            ("sinatra.route.path" "/api/users")
                            ("version" "1")))
                        (metrics
                          (
                            ("_dd.measured" 1.0)))
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "error" "meta" "meta_struct" "metrics" "name" "parent_id" "resource" "service" "span_id" "span_links" "start" "trace_id" "type" ))
                              (service "sqlite")
                              (name "sequel.query")
                              (type "sql")
                              (resource "INSERT INTO `users` (`username`, `email`, `password_digest`, `created_at`, `updated_at`) VALUES (:username, :email, :password_digest, :created_at, :updated_at)")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "sequel")
                                  ("component" "sequel")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("db.system" "sqlite")
                                  ("env" "test")
                                  ("operation" "query")
                                  ("sequel.db.name" "<fixture>/realworld.sqlite3")
                                  ("sequel.db.vendor" "sqlite")
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
                              (name "sequel.query")
                              (type "sql")
                              (resource "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "sequel")
                                  ("component" "sequel")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("db.system" "sqlite")
                                  ("env" "test")
                                  ("operation" "query")
                                  ("sequel.db.name" "<fixture>/realworld.sqlite3")
                                  ("sequel.db.vendor" "sqlite")
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
                              (name "sequel.query")
                              (type "sql")
                              (resource "SELECT 1 FROM `users` WHERE (`email` = :email) LIMIT 1")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "sequel")
                                  ("component" "sequel")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("db.system" "sqlite")
                                  ("env" "test")
                                  ("operation" "query")
                                  ("sequel.db.name" "<fixture>/realworld.sqlite3")
                                  ("sequel.db.vendor" "sqlite")
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
                              (name "sequel.query")
                              (type "sql")
                              (resource "SELECT 1 FROM `users` WHERE (`username` = :username) LIMIT 1")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.base_service" "<service>")
                                  ("_dd.svc_src" "sequel")
                                  ("_dd.tags.process" "entrypoint.workdir:main,entrypoint.name:server,entrypoint.basedir:bin,entrypoint.type:script,svc.user:true")
                                  ("component" "sequel")
                                  ("db.instance" "<fixture>/realworld.sqlite3")
                                  ("db.system" "sqlite")
                                  ("env" "test")
                                  ("operation" "query")
                                  ("sequel.db.name" "<fixture>/realworld.sqlite3")
                                  ("sequel.db.vendor" "sqlite")
                                  ("span.kind" "client")
                                  ("version" "1")))
                              (metrics
                                (
                                  ("_dd.top_level" 1.0)))
                              (children
                                ()))))))))))))))))
  ))
