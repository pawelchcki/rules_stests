(define-library (datadog realworld shape python-django-datadog-v4-14-0-v05 propagation)
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
            (service "django-datadog")
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
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "api/tags")
                ("http.status_code" "200")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 1.0)))
            (children
              (
                (
                  (service "django-datadog")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "django")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (service "django-datadog")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("component" "django")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "django-datadog")
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
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "api/tags")
                ("http.status_code" "200")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 1.0)))
            (children
              (
                (
                  (service "django-datadog")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "django")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (service "django-datadog")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("component" "django")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "django-datadog")
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
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "api/tags")
                ("http.status_code" "200")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 1.0)))
            (children
              (
                (
                  (service "django-datadog")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "django")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (service "django-datadog")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("component" "django")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "POST api/users")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "api/users")
                ("http.status_code" "201")))
            (metrics
              (
                ("_dd.measured" 1.0)
                ("_sampling_priority_v1" 2.0)))
            (children
              (
                (
                  (service "django-datadog")
                  (name "django.middleware")
                  (type "")
                  (resource "django.middleware.security.SecurityMiddleware.__call__")
                  (parent-kind "child")
                  (error 0)
                  (meta
                    (
                      ("component" "django")))
                  (metrics
                    ())
                  (children
                    (
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.contrib.sessions.middleware.SessionMiddleware.__call__")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          (
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_request")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.contrib.sessions.middleware.SessionMiddleware.process_response")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                ()))
                            (
                              (service "django-datadog")
                              (name "django.middleware")
                              (type "")
                              (resource "django.middleware.common.CommonMiddleware.__call__")
                              (parent-kind "child")
                              (error 0)
                              (meta
                                (
                                  ("component" "django")))
                              (metrics
                                ())
                              (children
                                (
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_request")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.common.CommonMiddleware.process_response")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      ()))
                                  (
                                    (service "django-datadog")
                                    (name "django.middleware")
                                    (type "")
                                    (resource "django.middleware.csrf.CsrfViewMiddleware.__call__")
                                    (parent-kind "child")
                                    (error 0)
                                    (meta
                                      (
                                        ("component" "django")))
                                    (metrics
                                      ())
                                    (children
                                      (
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.contrib.auth.middleware.AuthenticationMiddleware.__call__")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            (
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.auth.middleware.AuthenticationMiddleware.process_request")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  ()))
                                              (
                                                (service "django-datadog")
                                                (name "django.middleware")
                                                (type "")
                                                (resource "django.contrib.messages.middleware.MessageMiddleware.__call__")
                                                (parent-kind "child")
                                                (error 0)
                                                (meta
                                                  (
                                                    ("component" "django")))
                                                (metrics
                                                  ())
                                                (children
                                                  (
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_request")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.contrib.messages.middleware.MessageMiddleware.process_response")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        ()))
                                                    (
                                                      (service "django-datadog")
                                                      (name "django.middleware")
                                                      (type "")
                                                      (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.__call__")
                                                      (parent-kind "child")
                                                      (error 0)
                                                      (meta
                                                        (
                                                          ("component" "django")))
                                                      (metrics
                                                        ())
                                                      (children
                                                        (
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "corsheaders.middleware.CorsMiddleware.__call__")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              (
                                                                (
                                                                  (service "django-datadog")
                                                                  (name "django.middleware")
                                                                  (type "")
                                                                  (resource "django.middleware.common.CommonMiddleware.__call__")
                                                                  (parent-kind "child")
                                                                  (error 0)
                                                                  (meta
                                                                    (
                                                                      ("component" "django")))
                                                                  (metrics
                                                                    ())
                                                                  (children
                                                                    (
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_request")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.common.CommonMiddleware.process_response")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.middleware")
                                                                        (type "")
                                                                        (resource "django.middleware.csrf.CsrfViewMiddleware.process_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          ()))
                                                                      (
                                                                        (service "django-datadog")
                                                                        (name "django.view")
                                                                        (type "")
                                                                        (resource "ninja.operation._sync_view")
                                                                        (parent-kind "child")
                                                                        (error 0)
                                                                        (meta
                                                                          (
                                                                            ("component" "django")))
                                                                        (metrics
                                                                          ())
                                                                        (children
                                                                          (
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "INSERT INTO \"accounts_user\" (\"password\", \"last_login\", \"is_superuser\", \"is_staff\", \"is_active\", \"date_joined\", \"email\", \"username\", \"bio\", \"image\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING \"accounts_user\".\"id\"")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "INSERT INTO \"jwt_ninja_session\" (\"id\", \"created_at\", \"updated_at\", \"expired_at\", \"ip_address\", \"user_agent\", \"location\", \"user_id\", \"data\", \"refresh_jti\", \"previous_refresh_jti\", \"rotated_at\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA foreign_keys = ON")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "PRAGMA legacy_alter_table = OFF")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                (
                                                                                  ("_dd.measured" 1.0)))
                                                                              (children
                                                                                ())))))))))))
                                                          (
                                                            (service "django-datadog")
                                                            (name "django.middleware")
                                                            (type "")
                                                            (resource "django.middleware.clickjacking.XFrameOptionsMiddleware.process_response")
                                                            (parent-kind "child")
                                                            (error 0)
                                                            (meta
                                                              (
                                                                ("component" "django")))
                                                            (metrics
                                                              ())
                                                            (children
                                                              ())))))))))))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_request")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ()))
                                        (
                                          (service "django-datadog")
                                          (name "django.middleware")
                                          (type "")
                                          (resource "django.middleware.csrf.CsrfViewMiddleware.process_response")
                                          (parent-kind "child")
                                          (error 0)
                                          (meta
                                            (
                                              ("component" "django")))
                                          (metrics
                                            ())
                                          (children
                                            ())))))))))))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_request")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ()))
                      (
                        (service "django-datadog")
                        (name "django.middleware")
                        (type "")
                        (resource "django.middleware.security.SecurityMiddleware.process_response")
                        (parent-kind "child")
                        (error 0)
                        (meta
                          (
                            ("component" "django")))
                        (metrics
                          ())
                        (children
                          ())))))))))))))
  ))
