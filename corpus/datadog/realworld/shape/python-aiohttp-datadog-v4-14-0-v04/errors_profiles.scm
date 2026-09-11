(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 errors_profiles)
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
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "aiohttp.request")
            (type "web")
            (resource "DELETE /api/profiles/{username}/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "aiohttp")
                ("env" "test")
                ("http.method" "DELETE")
                ("http.route" "/api/profiles/{username}/follow")
                ("http.status_code" "401")
                ("http.url" "http://<endpoint>/api/profiles/unknown-user-rules_stests_<workload>/follow")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              ())))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "aiohttp.request")
            (type "web")
            (resource "DELETE /api/profiles/{username}/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "aiohttp")
                ("env" "test")
                ("http.method" "DELETE")
                ("http.route" "/api/profiles/{username}/follow")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/profiles/unknown-user-rules_stests_<workload>/follow")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "aiohttp.request")
            (type "web")
            (resource "GET /api/profiles/{username}")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "aiohttp")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "/api/profiles/{username}")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/profiles/unknown-user-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/profiles/{username}/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "aiohttp")
                ("env" "test")
                ("http.method" "POST")
                ("http.route" "/api/profiles/{username}/follow")
                ("http.status_code" "401")
                ("http.url" "http://<endpoint>/api/profiles/unknown-user-rules_stests_<workload>/follow")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              ())))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/profiles/{username}/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "aiohttp")
                ("env" "test")
                ("http.method" "POST")
                ("http.route" "/api/profiles/{username}/follow")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/profiles/unknown-user-rules_stests_<workload>/follow")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id AS users_id, users.username AS users_username, users.email AS users_email, users.password_hash AS users_password_hash, users.bio AS users_bio, users.image AS users_image \nFROM users \nWHERE users.id = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/users")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "aiohttp")
                ("env" "test")
                ("http.method" "POST")
                ("http.route" "/api/users")
                ("http.status_code" "201")
                ("http.url" "http://<endpoint>/api/users")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("version" "1")))
            (metrics
              (
                ("_dd.limit_psr" 1.0)
                ("_dd.measured" 1.0)
                ("_dd.rule_psr" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 2.0)
                ("process_id" "<process-id>")))
            (children
              (
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "INSERT INTO users (username, email, password_hash, bio, image) VALUES (?, ?, ?, ?, ?)")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)
                      ("db.row_count" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.email = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))
                (
                  (native-fields
                    ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                  (service "sqlite")
                  (name "sqlite.query")
                  (type "sql")
                  (resource "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.base_service" "<service>")
                      ("_dd.svc_src" "sqlalchemy")
                      ("component" "sqlalchemy")
                      ("env" "test")
                      ("span.kind" "client")
                      ("sql.db" "<fixture>/realworld.sqlite3")
                      ("version" "1")))
                  (metrics
                    (
                      ("_dd.measured" 1.0)
                      ("_dd.top_level" 1.0)))
                  (children
                    ()))))))))))
  ))
