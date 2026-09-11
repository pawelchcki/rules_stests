(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v04 pagination)
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
            (resource "DELETE /api/articles/{slug}")
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
                ("http.route" "/api/articles/{slug}")
                ("http.status_code" "204")
                ("http.url" "http://<endpoint>/api/articles/pagination-1-rules-stests-<workload>")
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
                  (resource "DELETE FROM articles WHERE articles.id = ?")
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
                  (resource "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
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
            (resource "DELETE /api/articles/{slug}")
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
                ("http.route" "/api/articles/{slug}")
                ("http.status_code" "204")
                ("http.url" "http://<endpoint>/api/articles/pagination-2-rules-stests-<workload>")
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
                  (resource "DELETE FROM articles WHERE articles.id = ?")
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
                  (resource "SELECT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles \nWHERE articles.slug = ?")
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
            (resource "GET /api/articles")
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
                ("http.route" "/api/articles")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/articles?author=page_rules_stests_<workload>&limit=1")
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
                  (resource "SELECT DISTINCT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
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
                  (resource "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
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
                  (resource "SELECT count(*) AS count_1 \nFROM (SELECT DISTINCT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ?) AS anon_1")
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
                  (resource "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
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
            (resource "GET /api/articles")
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
                ("http.route" "/api/articles")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/articles?author=page_rules_stests_<workload>&limit=1&offset=1")
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
                  (resource "SELECT DISTINCT articles.id, articles.author_id, articles.slug, articles.title, articles.description, articles.body, articles.created_at, articles.updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ? ORDER BY articles.id DESC\n LIMIT ? OFFSET ?")
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
                  (resource "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
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
                  (resource "SELECT count(*) AS count_1 \nFROM (SELECT DISTINCT articles.id AS id, articles.author_id AS author_id, articles.slug AS slug, articles.title AS title, articles.description AS description, articles.body AS body, articles.created_at AS created_at, articles.updated_at AS updated_at \nFROM articles JOIN users ON users.id = articles.author_id \nWHERE users.username = ?) AS anon_1")
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
                  (resource "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
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
                    ()))))))))
    (
      (count 2)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "aiohttp.request")
            (type "web")
            (resource "POST /api/articles")
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
                ("http.route" "/api/articles")
                ("http.status_code" "201")
                ("http.url" "http://<endpoint>/api/articles")
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
                  (resource "INSERT INTO articles (author_id, slug, title, description, body, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)")
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
                  (resource "SELECT article_tags.tag \nFROM article_tags \nWHERE article_tags.article_id = ? ORDER BY article_tags.position")
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
                  (resource "SELECT articles.id \nFROM articles \nWHERE articles.slug = ?")
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
                  (resource "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ? AND favorites.user_id = ?")
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
                  (resource "SELECT count(*) AS count_1 \nFROM favorites \nWHERE favorites.article_id = ?")
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
                  (resource "SELECT count(*) AS count_1 \nFROM follows \nWHERE follows.follower_id = ? AND follows.followed_id = ?")
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
