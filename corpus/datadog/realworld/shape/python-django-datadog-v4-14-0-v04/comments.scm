(define-library (datadog realworld shape python-django-datadog-v4-14-0-v04 comments)
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
            (name "django.request")
            (type "web")
            (resource "DELETE api/articles/<slug>")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.id" "1")
                ("django.user.is_authenticated" "True")
                ("django.user.name" "cmt_rules_stests_<workload>")
                ("django.view" "api-1.0.0:retrieve")
                ("env" "test")
                ("http.method" "DELETE")
                ("http.route" "api/articles/<slug>")
                ("http.status_code" "204")
                ("http.url" "http://<endpoint>/api/articles/comment-article-rules_stests_<workload>")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("usr.id" "1")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "BEGIN")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "DELETE FROM \"articles_article\" WHERE \"articles_article\".\"id\" IN (%s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
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
                                                                              (resource "DELETE FROM \"articles_article_favorites\" WHERE \"articles_article_favorites\".\"article_id\" IN (%s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" 0.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "DELETE FROM \"articles_article_tags\" WHERE \"articles_article_tags\".\"article_id\" IN (%s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" 0.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "DELETE FROM \"comments_comment\" WHERE \"comments_comment\".\"article_id\" IN (%s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
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
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.connection.commit")
                                                                              (type "")
                                                                              (resource "sqlite.connection.commit")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.top_level" 1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "DELETE api/articles/<slug>/comments/<comment_id>")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.id" "1")
                ("django.user.is_authenticated" "True")
                ("django.user.name" "cmt_rules_stests_<workload>")
                ("django.view" "api-1.0.0:delete_comment")
                ("env" "test")
                ("http.method" "DELETE")
                ("http.route" "api/articles/<slug>/comments/<comment_id>")
                ("http.status_code" "204")
                ("http.url" "http://<endpoint>/api/articles/comment-article-rules_stests_<workload>/comments/1")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("usr.id" "1")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "DELETE FROM \"comments_comment\" WHERE \"comments_comment\".\"id\" IN (%s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
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
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"comments_comment\".\"id\", \"comments_comment\".\"article_id\", \"comments_comment\".\"author_id\", \"comments_comment\".\"content\", \"comments_comment\".\"created\", \"comments_comment\".\"updated\" FROM \"comments_comment\" WHERE \"comments_comment\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "DELETE api/articles/<slug>/comments/<comment_id>")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.id" "1")
                ("django.user.is_authenticated" "True")
                ("django.user.name" "cmt_rules_stests_<workload>")
                ("django.view" "api-1.0.0:delete_comment")
                ("env" "test")
                ("http.method" "DELETE")
                ("http.route" "api/articles/<slug>/comments/<comment_id>")
                ("http.status_code" "204")
                ("http.url" "http://<endpoint>/api/articles/comment-article-rules_stests_<workload>/comments/2")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("usr.id" "1")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "DELETE FROM \"comments_comment\" WHERE \"comments_comment\".\"id\" IN (%s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
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
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"comments_comment\".\"id\", \"comments_comment\".\"article_id\", \"comments_comment\".\"author_id\", \"comments_comment\".\"content\", \"comments_comment\".\"created\", \"comments_comment\".\"updated\" FROM \"comments_comment\" WHERE \"comments_comment\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "GET api/articles/<slug>/comments")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.id" "1")
                ("django.user.is_authenticated" "True")
                ("django.user.name" "cmt_rules_stests_<workload>")
                ("django.view" "api-1.0.0:list_comments")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/articles/<slug>/comments")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/articles/comment-article-rules_stests_<workload>/comments")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("usr.id" "1")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"comments_comment\".\"id\", \"comments_comment\".\"article_id\", \"comments_comment\".\"author_id\", \"comments_comment\".\"content\", \"comments_comment\".\"created\", \"comments_comment\".\"updated\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE (U1.\"to_user_id\" = %s AND U0.\"id\" = (\"comments_comment\".\"author_id\")) LIMIT 1) AS \"author_following\", \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"comments_comment\" INNER JOIN \"accounts_user\" ON (\"comments_comment\".\"author_id\" = \"accounts_user\".\"id\") WHERE \"comments_comment\".\"article_id\" = %s ORDER BY \"comments_comment\".\"created\" DESC")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 4)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "GET api/articles/<slug>/comments")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.is_authenticated" "False")
                ("django.view" "api-1.0.0:list_comments")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/articles/<slug>/comments")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/articles/comment-article-rules_stests_<workload>/comments")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"comments_comment\".\"id\", \"comments_comment\".\"article_id\", \"comments_comment\".\"author_id\", \"comments_comment\".\"content\", \"comments_comment\".\"created\", \"comments_comment\".\"updated\", %s AS \"author_following\", \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"comments_comment\" INNER JOIN \"accounts_user\" ON (\"comments_comment\".\"author_id\" = \"accounts_user\".\"id\") WHERE \"comments_comment\".\"article_id\" = %s ORDER BY \"comments_comment\".\"created\" DESC")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "POST api/articles")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.id" "1")
                ("django.user.is_authenticated" "True")
                ("django.user.name" "cmt_rules_stests_<workload>")
                ("django.view" "api-1.0.0:list_articles")
                ("env" "test")
                ("http.method" "POST")
                ("http.route" "api/articles")
                ("http.status_code" "201")
                ("http.url" "http://<endpoint>/api/articles")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("usr.id" "1")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "BEGIN")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "INSERT INTO \"articles_article\" (\"author_id\", \"title\", \"summary\", \"content\", \"created\", \"updated\", \"slug\") VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING \"articles_article\".\"id\"")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" 0.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT %s AS \"a\" FROM \"articles_article\" WHERE (\"articles_article\".\"slug\" = %s AND NOT (\"articles_article\".\"id\" IS NULL)) LIMIT 1")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\", COUNT(\"articles_article_favorites\".\"user_id\") AS \"num_favorites\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"id\" = %s GROUP BY \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\" INNER JOIN \"articles_article_tags\" ON (\"articles_tag\".\"id\" = \"articles_article_tags\".\"tag_id\") WHERE \"articles_article_tags\".\"article_id\" = %s")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.connection.commit")
                                                                              (type "")
                                                                              (resource "sqlite.connection.commit")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.top_level" 1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 3)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "POST api/articles/<slug>/comments")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.id" "1")
                ("django.user.is_authenticated" "True")
                ("django.user.name" "cmt_rules_stests_<workload>")
                ("django.view" "api-1.0.0:list_comments")
                ("env" "test")
                ("http.method" "POST")
                ("http.route" "api/articles/<slug>/comments")
                ("http.status_code" "201")
                ("http.url" "http://<endpoint>/api/articles/comment-article-rules_stests_<workload>/comments")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("usr.id" "1")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "INSERT INTO \"comments_comment\" (\"article_id\", \"author_id\", \"content\", \"created\", \"updated\") VALUES (%s, %s, %s, %s, %s) RETURNING \"comments_comment\".\"id\"")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" 0.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "POST api/users")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("_dd.p.dm" "-3")
                ("_dd.p.ksr" "1")
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.is_authenticated" "False")
                ("django.view" "api-1.0.0:account_registration")
                ("env" "test")
                ("http.method" "POST")
                ("http.route" "api/users")
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
                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                  (service "<service>")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("_dd.svc_src" "m")
                      ("component" "django")
                      ("env" "test")
                      ("version" "1")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (native-fields
                                ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                              (service "<service>")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("_dd.svc_src" "m")
                                  ("component" "django")
                                  ("env" "test")
                                  ("version" "1")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (native-fields
                                      ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                    (service "<service>")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("_dd.svc_src" "m")
                                        ("component" "django")
                                        ("env" "test")
                                        ("version" "1")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (native-fields
                                                  ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                (service "<service>")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("_dd.svc_src" "m")
                                                    ("component" "django")
                                                    ("env" "test")
                                                    ("version" "1")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (native-fields
                                                        ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                      (service "<service>")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("_dd.svc_src" "m")
                                                          ("component" "django")
                                                          ("env" "test")
                                                          ("version" "1")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (native-fields
                                                                    ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                  (service "<service>")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("_dd.svc_src" "m")
                                                                      ("component" "django")
                                                                      ("env" "test")
                                                                      ("version" "1")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (native-fields
                                                                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                                        (service "<service>")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("_dd.svc_src" "m")
                                                                            ("component" "django")
                                                                            ("env" "test")
                                                                            ("version" "1")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "INSERT INTO \"accounts_user\" (\"password\", \"last_login\", \"is_superuser\", \"is_staff\", \"is_active\", \"date_joined\", \"email\", \"username\", \"bio\", \"image\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING \"accounts_user\".\"id\"")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" 0.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "INSERT INTO \"jwt_ninja_session\" (\"id\", \"created_at\", \"updated_at\", \"expired_at\", \"ip_address\", \"user_agent\", \"location\", \"user_id\", \"data\", \"refresh_jti\", \"previous_refresh_jti\", \"rotated_at\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
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
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (native-fields
                                                                                ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("_dd.base_service" "<service>")
                                                                                  ("_dd.svc_src" "sqlite")
                                                                                  ("component" "sqlite")
                                                                                  ("db.system" "sqlite")
                                                                                  ("env" "test")
                                                                                  ("span.kind" "client")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)
                                                                                  ("_dd.top_level" 1.0)
                                                                                  ("db.row_count" -1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (native-fields
                                                              ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                                            (service "<service>")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("_dd.svc_src" "m")
                                                                ("component" "django")
                                                                ("env" "test")
                                                                ("version" "1")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (native-fields
                                            ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                                          (service "<service>")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("_dd.svc_src" "m")
                                              ("component" "django")
                                              ("env" "test")
                                              ("version" "1")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (native-fields
                          ("duration" "meta" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" ))
                        (service "<service>")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("_dd.svc_src" "m")
                            ("component" "django")
                            ("env" "test")
                            ("version" "1")))
                        (metrics
                          ())
                        (children
                          ())))))))))))))
  ))
