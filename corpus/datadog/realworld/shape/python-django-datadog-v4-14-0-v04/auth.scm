(define-library (datadog realworld shape python-django-datadog-v4-14-0-v04 auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape))
  (begin
(define scenario-shape
  '(
    (
      (count 7)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "GET api/user")
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
                ("django.user.name" "auth_rules_stests_<workload>")
                ("django.view" "api-1.0.0:get_user")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
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
            (resource "GET api/user")
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
                ("django.user.name" "auth_rules_stests_<workload>_upd")
                ("django.view" "api-1.0.0:get_user")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
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
            (resource "POST api/users/login")
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
                ("django.view" "api-1.0.0:account_login")
                ("env" "test")
                ("http.method" "POST")
                ("http.route" "api/users/login")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/users/login")
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"email\" = %s LIMIT 21")
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
      (count 5)
      (roots
        (
          (
            (native-fields
              ("duration" "meta" "metrics" "name" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "PUT api/user")
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
                ("django.user.name" "auth_rules_stests_<workload>")
                ("django.view" "api-1.0.0:get_user")
                ("env" "test")
                ("http.method" "PUT")
                ("http.route" "api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
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
                                                                              (resource "UPDATE \"accounts_user\" SET \"password\" = %s, \"last_login\" = NULL, \"is_superuser\" = %s, \"is_staff\" = %s, \"is_active\" = %s, \"date_joined\" = %s, \"email\" = %s, \"username\" = %s, \"bio\" = %s, \"image\" = NULL WHERE \"accounts_user\".\"id\" = %s")
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
            (resource "PUT api/user")
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
                ("django.user.name" "auth_rules_stests_<workload>")
                ("django.view" "api-1.0.0:get_user")
                ("env" "test")
                ("http.method" "PUT")
                ("http.route" "api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
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
                                                                              (resource "UPDATE \"accounts_user\" SET \"password\" = %s, \"last_login\" = NULL, \"is_superuser\" = %s, \"is_staff\" = %s, \"is_active\" = %s, \"date_joined\" = %s, \"email\" = %s, \"username\" = %s, \"bio\" = %s, \"image\" = %s WHERE \"accounts_user\".\"id\" = %s")
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
            (resource "PUT api/user")
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
                ("django.user.name" "auth_rules_stests_<workload>_upd")
                ("django.view" "api-1.0.0:get_user")
                ("env" "test")
                ("http.method" "PUT")
                ("http.route" "api/user")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/user")
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
                                                                              (resource "UPDATE \"accounts_user\" SET \"password\" = %s, \"last_login\" = NULL, \"is_superuser\" = %s, \"is_staff\" = %s, \"is_active\" = %s, \"date_joined\" = %s, \"email\" = %s, \"username\" = %s, \"bio\" = %s, \"image\" = %s WHERE \"accounts_user\".\"id\" = %s")
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
