; The native Datadog traces of the errors_auth scenario, reviewed for python-django-datadog-v4-14-0-v05.
; Builders: corpus/datadog/shape/django.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-django-datadog-v4-14-0-v05 errors_auth)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape django))
  (begin

(define scenario-shape
  (traces (django-app "v0.5")
    (trace
      (django-request "GET" "api/user" 401
        (url "/api/user") (view "api-1.0.0:get_user")))
    (repeat 2
      (trace
        (django-request "PUT" "api/user" 200
          (url "/api/user") (view "api-1.0.0:get_user") (user "1" "ea_dup_rules_stests_<workload>")
          (sqlite "INSERT INTO \"jwt_ninja_session\" (\"id\", \"created_at\", \"updated_at\", \"expired_at\", \"ip_address\", \"user_agent\", \"location\", \"user_id\", \"data\", \"refresh_jti\", \"previous_refresh_jti\", \"rotated_at\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            (rows 1))
          (sqlite "PRAGMA foreign_keys = ON")
          (sqlite "PRAGMA legacy_alter_table = OFF")
          (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
          (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
          (times 2
            (sqlite "SELECT QUOTE(?)"))
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
          (sqlite "UPDATE \"accounts_user\" SET \"password\" = %s, \"last_login\" = NULL, \"is_superuser\" = %s, \"is_staff\" = %s, \"is_active\" = %s, \"date_joined\" = %s, \"email\" = %s, \"username\" = %s, \"bio\" = %s, \"image\" = NULL WHERE \"accounts_user\".\"id\" = %s"
            (rows 1))
          (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')"))))
    (trace
      (django-request "PUT" "api/user" 401
        (url "/api/user") (view "api-1.0.0:get_user")))
    (repeat 7
      (trace
        (django-request "PUT" "api/user" 422
          (url "/api/user") (view "api-1.0.0:get_user") (user "1" "ea_dup_rules_stests_<workload>")
          (sqlite "PRAGMA foreign_keys = ON")
          (sqlite "PRAGMA legacy_alter_table = OFF")
          (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
          (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
          (times 2
            (sqlite "SELECT QUOTE(?)"))
          (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')"))))
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
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "POST" "api/users" 409
        (url "/api/users") (view "api-1.0.0:account_registration")
        (sqlite "INSERT INTO \"accounts_user\" (\"password\", \"last_login\", \"is_superuser\", \"is_staff\", \"is_active\", \"date_joined\", \"email\", \"username\", \"bio\", \"image\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING \"accounts_user\".\"id\""
          (raised "sqlite3.IntegrityError" "UNIQUE constraint failed: accounts_user.email"))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "POST" "api/users" 409
        (url "/api/users") (view "api-1.0.0:account_registration")
        (sqlite "INSERT INTO \"accounts_user\" (\"password\", \"last_login\", \"is_superuser\", \"is_staff\", \"is_active\", \"date_joined\", \"email\", \"username\", \"bio\", \"image\") VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING \"accounts_user\".\"id\""
          (raised "sqlite3.IntegrityError" "UNIQUE constraint failed: accounts_user.username"))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (repeat 3
      (trace
        (django-request "POST" "api/users" 422
          (url "/api/users") (view "api-1.0.0:account_registration"))))
    (trace
      (django-request "POST" "api/users/login" 401
        (url "/api/users/login") (view "api-1.0.0:account_login")
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"email\" = %s LIMIT 21")
        (sqlite "SELECT QUOTE(?)")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (repeat 2
      (trace
        (django-request "POST" "api/users/login" 422
          (url "/api/users/login") (view "api-1.0.0:account_login"))))))
  ))
