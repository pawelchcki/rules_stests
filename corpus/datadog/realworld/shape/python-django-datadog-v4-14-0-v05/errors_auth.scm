(define-library (datadog realworld shape python-django-datadog-v4-14-0-v05 errors_auth)
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
            (resource "GET api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "api/user")
                ("http.status_code" "401")))
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
                                                                          ()))))))))
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
                          ())))))))))))
    (
      (count 2)
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
                ("http.status_code" "409")))
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
                                                                              (error 1)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")
                                                                                  ("error.type" "sqlite3.IntegrityError")))
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
      (count 3)
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
                ("http.status_code" "422")))
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
                                                                          ()))))))))
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
            (resource "POST api/users/login")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "api/users/login")
                ("http.status_code" "401")))
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"email\" = %s LIMIT 21")
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
      (count 2)
      (roots
        (
          (
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "POST api/users/login")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "api/users/login")
                ("http.status_code" "422")))
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
                                                                          ()))))))))
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
      (count 2)
      (roots
        (
          (
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "PUT api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "PUT")
                ("http.route" "api/user")
                ("http.status_code" "200")))
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
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
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
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
                                                                              (resource "UPDATE \"accounts_user\" SET \"password\" = %s, \"last_login\" = NULL, \"is_superuser\" = %s, \"is_staff\" = %s, \"is_active\" = %s, \"date_joined\" = %s, \"email\" = %s, \"username\" = %s, \"bio\" = %s, \"image\" = NULL WHERE \"accounts_user\".\"id\" = %s")
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
            (resource "PUT api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "PUT")
                ("http.route" "api/user")
                ("http.status_code" "401")))
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
                                                                          ()))))))))
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
      (count 7)
      (roots
        (
          (
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "PUT api/user")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "PUT")
                ("http.route" "api/user")
                ("http.status_code" "422")))
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
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
                                                                              (resource "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
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
