(define-library (datadog realworld shape python-django-datadog-v4-14-0-v04 propagation)
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
              ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "GET api/tags")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "11276220234964099125")
            (trace-id-high "b3f7d21c9e6a4805")
            (error 0)
            (meta
              (
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.is_authenticated" "False")
                ("django.view" "api-1.0.0:list_tags")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/tags")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/tags")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("traceparent" "00-b3f7d21c9e6a48059c7d2e8f4a1b6035-00f067aa0ba902b7-01")
                ("version" "1")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 1.0)
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
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
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
              ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "GET api/tags")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "11803532876627986230")
            (trace-id-high "4bf92f3577b34da6")
            (error 0)
            (meta
              (
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.is_authenticated" "False")
                ("django.view" "api-1.0.0:list_tags")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/tags")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/tags")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("traceparent" "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01")
                ("version" "1")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 1.0)
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
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
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
              ("duration" "meta" "metrics" "name" "parent_id" "resource" "service" "span_id" "start" "trace_id" "type" ))
            (service "<service>")
            (name "django.request")
            (type "web")
            (resource "GET api/tags")
            (parent-kind "remote")
            (parent-id "67667974448284343")
            (trace-id "9965072336285547154")
            (trace-id-high "8c1e0a5b6d2f4739")
            (error 0)
            (meta
              (
                ("_dd.p.tid" "<trace-id-high>")
                ("_dd.svc_src" "m")
                ("_dd.tags.process" "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
                ("component" "django")
                ("django.app" "ninja")
                ("django.namespace" "api-1.0.0")
                ("django.request.class" "django.core.handlers.wsgi.WSGIRequest")
                ("django.response.class" "django.http.response.HttpResponse")
                ("django.user.is_authenticated" "False")
                ("django.view" "api-1.0.0:list_tags")
                ("env" "test")
                ("http.method" "GET")
                ("http.route" "api/tags")
                ("http.status_code" "200")
                ("http.url" "http://<endpoint>/api/tags")
                ("http.useragent" "hurl/8.0.1")
                ("language" "python")
                ("runtime-id" "<runtime-id>")
                ("span.kind" "server")
                ("traceparent" "00-8c1e0a5b6d2f47398a4b0c7e1d5f3a92-00f067aa0ba902b7-01")
                ("version" "1")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_dd.top_level" 1.0)
                ("_dd.tracer_kr" 1.0)
                ("_sampling_priority_v1" 1.0)
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
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
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
