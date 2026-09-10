(define-library (datadog realworld shape python-django-datadog-v4-14-0-v05 profiles)
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
            (resource "DELETE api/profiles/<username>/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "DELETE")
                ("http.route" "api/profiles/<username>/follow")
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
                                                                              (name "sqlite.connection.commit")
                                                                              (type "")
                                                                              (resource "sqlite.connection.commit")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                ())
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "BEGIN")
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
                                                                              (resource "DELETE FROM \"accounts_user_followers\" WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user_followers\".\"to_user_id\" IN (%s))")
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
                                                                              (resource "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
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
                                                                              (resource "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?)")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
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
                          ())))))))))))
    (
      (count 2)
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
                                                                              (resource "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
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
                          ())))))))))))
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
                          ())))))))))))
    (
      (count 1)
      (roots
        (
          (
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "POST api/profiles/<username>/follow")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "api/profiles/<username>/follow")
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
                                                                              (name "sqlite.connection.commit")
                                                                              (type "")
                                                                              (resource "sqlite.connection.commit")
                                                                              (parent-kind "child")
                                                                              (error 0)
                                                                              (meta
                                                                                (
                                                                                  ("component" "sqlite")
                                                                                  ("span.kind" "client")
                                                                                  ("db.system" "sqlite")))
                                                                              (metrics
                                                                                ())
                                                                              (children
                                                                                ()))
                                                                            (
                                                                              (service "sqlite")
                                                                              (name "sqlite.query")
                                                                              (type "sql")
                                                                              (resource "BEGIN")
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
                                                                              (resource "INSERT OR IGNORE INTO \"accounts_user_followers\" (\"from_user_id\", \"to_user_id\") VALUES (%s, %s)")
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
                                                                              (resource "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
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
                                                                              (resource "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?)")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?)")
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
