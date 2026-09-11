(define-library (datadog realworld shape python-django-datadog-v4-14-0-v05 unicode)
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
              ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "GET api/profiles/<username>")
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
                ("django.view" "api-1.0.0:get_profile")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/profiles/<username>")
                ("http.status_code" "404")
                ("http.url" "http://<endpoint>/api/profiles/ünïcøde_rules_stests_<workload>")
                ("http.useragent" "rules-stests/Ã¼nÃ¯cÃ¸dÃ©")
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
                    ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                          ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                      ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                      ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                      ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                            ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                  ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                  ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                        ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                        ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                        ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                              ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                    ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                          ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                          ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                          ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                          ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"username\" = %s LIMIT 21")
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
                                                                                ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                                              ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                            ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                                            ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                          ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
                          ("duration" "error" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
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
