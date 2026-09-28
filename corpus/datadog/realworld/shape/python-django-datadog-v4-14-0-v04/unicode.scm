; The native Datadog traces of the unicode scenario, reviewed for python-django-datadog-v4-14-0-v04.
; Builders: corpus/datadog/shape/django.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-django-datadog-v4-14-0-v04 unicode)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape django))
  (begin

(define scenario-shape
  (traces (django-app "v0.4")
    (trace
      (django-request "GET" "api/profiles/<username>" 404
        (url "/api/profiles/ünïcøde_rules_stests_<workload>")
        (user-agent "rules-stests/Ã¼nÃ¯cÃ¸dÃ©")
        (view "api-1.0.0:get_profile")
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"username\" = %s LIMIT 21")
        (sqlite "SELECT QUOTE(?)")
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))))
  ))
