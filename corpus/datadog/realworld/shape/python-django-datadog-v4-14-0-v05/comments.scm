(define-library (datadog realworld shape python-django-datadog-v4-14-0-v05 comments)
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
            (resource "DELETE api/articles/<slug>")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "DELETE")
                ("http.route" "api/articles/<slug>")
                ("http.status_code" "204")))
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
                                                                              (resource "DELETE FROM \"articles_article\" WHERE \"articles_article\".\"id\" IN (%s)")
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
                                                                              (resource "DELETE FROM \"articles_article_favorites\" WHERE \"articles_article_favorites\".\"article_id\" IN (%s)")
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
                                                                              (resource "DELETE FROM \"articles_article_tags\" WHERE \"articles_article_tags\".\"article_id\" IN (%s)")
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
                                                                              (resource "DELETE FROM \"comments_comment\" WHERE \"comments_comment\".\"article_id\" IN (%s)")
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
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
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
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
            (resource "DELETE api/articles/<slug>/comments/<comment_id>")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "DELETE")
                ("http.route" "api/articles/<slug>/comments/<comment_id>")
                ("http.status_code" "204")))
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
                                                                              (resource "DELETE FROM \"comments_comment\" WHERE \"comments_comment\".\"id\" IN (%s)")
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
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
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
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
                                                                              (resource "SELECT \"comments_comment\".\"id\", \"comments_comment\".\"article_id\", \"comments_comment\".\"author_id\", \"comments_comment\".\"content\", \"comments_comment\".\"created\", \"comments_comment\".\"updated\" FROM \"comments_comment\" WHERE \"comments_comment\".\"id\" = %s LIMIT 21")
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
            (resource "GET api/articles/<slug>/comments")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "api/articles/<slug>/comments")
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
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
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
                                                                              (resource "SELECT \"comments_comment\".\"id\", \"comments_comment\".\"article_id\", \"comments_comment\".\"author_id\", \"comments_comment\".\"content\", \"comments_comment\".\"created\", \"comments_comment\".\"updated\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE (U1.\"to_user_id\" = %s AND U0.\"id\" = (\"comments_comment\".\"author_id\")) LIMIT 1) AS \"author_following\", \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"comments_comment\" INNER JOIN \"accounts_user\" ON (\"comments_comment\".\"author_id\" = \"accounts_user\".\"id\") WHERE \"comments_comment\".\"article_id\" = %s ORDER BY \"comments_comment\".\"created\" DESC")
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
      (count 4)
      (roots
        (
          (
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "GET api/articles/<slug>/comments")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "GET")
                ("http.route" "api/articles/<slug>/comments")
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
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
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
                                                                              (resource "SELECT \"comments_comment\".\"id\", \"comments_comment\".\"article_id\", \"comments_comment\".\"author_id\", \"comments_comment\".\"content\", \"comments_comment\".\"created\", \"comments_comment\".\"updated\", %s AS \"author_following\", \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"comments_comment\" INNER JOIN \"accounts_user\" ON (\"comments_comment\".\"author_id\" = \"accounts_user\".\"id\") WHERE \"comments_comment\".\"article_id\" = %s ORDER BY \"comments_comment\".\"created\" DESC")
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
            (resource "POST api/articles")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "api/articles")
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
                                                                              (resource "INSERT INTO \"articles_article\" (\"author_id\", \"title\", \"summary\", \"content\", \"created\", \"updated\", \"slug\") VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING \"articles_article\".\"id\"")
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
                                                                              (resource "SELECT %s AS \"a\" FROM \"articles_article\" WHERE (\"articles_article\".\"slug\" = %s AND NOT (\"articles_article\".\"id\" IS NULL)) LIMIT 1")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
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
                                                                              (resource "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
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
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\", COUNT(\"articles_article_favorites\".\"user_id\") AS \"num_favorites\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"id\" = %s GROUP BY \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" LIMIT 21")
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
                                                                              (resource "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\" INNER JOIN \"articles_article_tags\" ON (\"articles_tag\".\"id\" = \"articles_article_tags\".\"tag_id\") WHERE \"articles_article_tags\".\"article_id\" = %s")
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
      (count 3)
      (roots
        (
          (
            (service "django-datadog")
            (name "django.request")
            (type "web")
            (resource "POST api/articles/<slug>/comments")
            (parent-kind "root")
            (error 0)
            (meta
              (
                ("component" "django")
                ("span.kind" "server")
                ("http.method" "POST")
                ("http.route" "api/articles/<slug>/comments")
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
                                                                              (resource "INSERT INTO \"comments_comment\" (\"article_id\", \"author_id\", \"content\", \"created\", \"updated\") VALUES (%s, %s, %s, %s, %s) RETURNING \"comments_comment\".\"id\"")
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
                                                                              (resource "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
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
                                                                              (resource "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
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
