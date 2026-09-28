; The native Datadog traces of the propagation scenario, reviewed for python-django-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/django.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-django-datadog-v4-14-0-v04 propagation)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape django))
  (begin

(define scenario-shape
  (traces (django-app "v0.4")
    (trace
      (django-request "GET" "api/tags" 200
        (url "/api/tags") (view "api-1.0.0:list_tags")
        (continues (traceparent "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "GET" "api/tags" 200
        (url "/api/tags") (view "api-1.0.0:list_tags")
        (continues (traceparent "00-8c1e0a5b6d2f47398a4b0c7e1d5f3a92-00f067aa0ba902b7-01"))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "GET" "api/tags" 200
        (url "/api/tags") (view "api-1.0.0:list_tags")
        (continues (traceparent "00-b3f7d21c9e6a48059c7d2e8f4a1b6035-00f067aa0ba902b7-01"))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\"")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "POST" "api/users" 201
        (url "/api/users") (view "api-1.0.0:account_registration")
        (sqlite "INSERT INTO \"accounts_user\" (\"password\", \"last_login\", \"is_superuser\", \"is_staff\", \"is_active\", \"date_joined\", \"email\", \"username\", \"bio\", \"image\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING \"accounts_user\".\"id\""
          (rows 0))
        (sqlite "INSERT INTO \"jwt_ninja_session\" (\"id\", \"created_at\", \"updated_at\", \"expired_at\", \"ip_address\", \"user_agent\", \"location\", \"user_id\", \"data\", \"refresh_jti\", \"previous_refresh_jti\", \"rotated_at\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
          (rows 1))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
        (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))))
  ))
