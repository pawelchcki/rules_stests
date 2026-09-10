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
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "GET api/profiles/<username>")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "api/profiles/<username>")
                ("http.status_code" "404")))
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
                                                                              (resource "SELECT QUOTE(?)")
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"username\" = %s LIMIT 21")
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
