; The native Datadog traces of the feed scenario, reviewed for python-django-datadog-v4-14-0-v05.
; Builders: corpus/datadog/shape/django.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-django-datadog-v4-14-0-v05 feed)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape django))
  (begin

(define scenario-shape
  (traces (django-app "v0.5")
    (repeat 2
      (trace
        (django-request "POST" "api/articles" 201
          (url "/api/articles")
          (view "api-1.0.0:list_articles")
          (user "2" "feedc_rules_stests_<workload>")
          (sqlite-commit)
          (sqlite "BEGIN")
          (sqlite "INSERT INTO \"articles_article\" (\"author_id\", \"title\", \"summary\", \"content\", \"created\", \"updated\", \"slug\") VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING \"articles_article\".\"id\""
            (rows 0))
          (sqlite "PRAGMA foreign_keys = ON")
          (sqlite "PRAGMA legacy_alter_table = OFF")
          (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
          (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
          (sqlite "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\", COUNT(\"articles_article_favorites\".\"user_id\") AS \"num_favorites\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"id\" = %s GROUP BY \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" LIMIT 21")
          (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\" INNER JOIN \"articles_article_tags\" ON (\"articles_tag\".\"id\" = \"articles_article_tags\".\"tag_id\") WHERE \"articles_article_tags\".\"article_id\" = %s")
          (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
          (sqlite "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
          (sqlite "SELECT %s AS \"a\" FROM \"articles_article\" WHERE (\"articles_article\".\"slug\" = %s AND NOT (\"articles_article\".\"id\" IS NULL)) LIMIT 1")
          (times 4
            (sqlite "SELECT QUOTE(?)"))
          (sqlite "SELECT QUOTE(?), QUOTE(?)")
          (times 2
            (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?)"))
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?), QUOTE(?)")
          (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')"))))
    (trace
      (django-request "DELETE" "api/articles/<slug>" 204
        (url "/api/articles/feed-article-1-rules_stests_<workload>")
        (view "api-1.0.0:retrieve")
        (user "2" "feedc_rules_stests_<workload>")
        (sqlite-commit)
        (sqlite "BEGIN")
        (sqlite "DELETE FROM \"articles_article\" WHERE \"articles_article\".\"id\" IN (%s)"
          (rows 1))
        (sqlite "DELETE FROM \"articles_article_favorites\" WHERE \"articles_article_favorites\".\"article_id\" IN (%s)"
          (rows 0))
        (sqlite "DELETE FROM \"articles_article_tags\" WHERE \"articles_article_tags\".\"article_id\" IN (%s)"
          (rows 0))
        (sqlite "DELETE FROM \"comments_comment\" WHERE \"comments_comment\".\"article_id\" IN (%s)"
          (rows 0))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (times 8
          (sqlite "SELECT QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "DELETE" "api/articles/<slug>" 204
        (url "/api/articles/feed-article-2-rules_stests_<workload>")
        (view "api-1.0.0:retrieve")
        (user "2" "feedc_rules_stests_<workload>")
        (sqlite-commit)
        (sqlite "BEGIN")
        (sqlite "DELETE FROM \"articles_article\" WHERE \"articles_article\".\"id\" IN (%s)"
          (rows 1))
        (sqlite "DELETE FROM \"articles_article_favorites\" WHERE \"articles_article_favorites\".\"article_id\" IN (%s)"
          (rows 0))
        (sqlite "DELETE FROM \"articles_article_tags\" WHERE \"articles_article_tags\".\"article_id\" IN (%s)"
          (rows 0))
        (sqlite "DELETE FROM \"comments_comment\" WHERE \"comments_comment\".\"article_id\" IN (%s)"
          (rows 0))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" FROM \"articles_article\" WHERE \"articles_article\".\"slug\" = %s LIMIT 21")
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (times 8
          (sqlite "SELECT QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "GET" "api/articles/feed" 200
        (url "/api/articles/feed") (view "api-1.0.0:feed") (user "1" "feedm_rules_stests_<workload>")
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\", COUNT(\"articles_article_favorites\".\"user_id\") AS \"num_favorites\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" ORDER BY \"articles_article\".\"created\" DESC LIMIT 20")
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (sqlite "SELECT COUNT(*) FROM (SELECT EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\") subquery")
        (times 2
          (sqlite "SELECT QUOTE(?)"))
        (times 2
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "GET" "api/articles/feed" 200
        (url "/api/articles/feed") (view "api-1.0.0:feed") (user "1" "feedm_rules_stests_<workload>")
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (times 2
          (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21"))
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\", COUNT(\"articles_article_favorites\".\"user_id\") AS \"num_favorites\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" ORDER BY \"articles_article\".\"created\" DESC LIMIT 20")
        (times 2
          (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\" INNER JOIN \"articles_article_tags\" ON (\"articles_tag\".\"id\" = \"articles_article_tags\".\"tag_id\") WHERE \"articles_article_tags\".\"article_id\" = %s"))
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (times 2
          (sqlite "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1"))
        (sqlite "SELECT COUNT(*) FROM (SELECT EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\") subquery")
        (times 6
          (sqlite "SELECT QUOTE(?)"))
        (times 4
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "GET" "api/articles/feed" 200
        (url "/api/articles/feed?limit=1")
        (view "api-1.0.0:feed")
        (user "1" "feedm_rules_stests_<workload>")
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\", COUNT(\"articles_article_favorites\".\"user_id\") AS \"num_favorites\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" ORDER BY \"articles_article\".\"created\" DESC LIMIT 1")
        (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\" INNER JOIN \"articles_article_tags\" ON (\"articles_tag\".\"id\" = \"articles_article_tags\".\"tag_id\") WHERE \"articles_article_tags\".\"article_id\" = %s")
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (sqlite "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
        (sqlite "SELECT COUNT(*) FROM (SELECT EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\") subquery")
        (times 4
          (sqlite "SELECT QUOTE(?)"))
        (times 3
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "GET" "api/articles/feed" 200
        (url "/api/articles/feed?limit=1&offset=1")
        (view "api-1.0.0:feed")
        (user "1" "feedm_rules_stests_<workload>")
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"id\" = %s LIMIT 21")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\", COUNT(\"articles_article_favorites\".\"user_id\") AS \"num_favorites\", EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\", \"articles_article\".\"author_id\", \"articles_article\".\"title\", \"articles_article\".\"summary\", \"articles_article\".\"content\", \"articles_article\".\"created\", \"articles_article\".\"updated\", \"articles_article\".\"slug\" ORDER BY \"articles_article\".\"created\" DESC LIMIT 1 OFFSET 1")
        (sqlite "SELECT \"articles_tag\".\"id\", \"articles_tag\".\"name\" FROM \"articles_tag\" INNER JOIN \"articles_article_tags\" ON (\"articles_tag\".\"id\" = \"articles_article_tags\".\"tag_id\") WHERE \"articles_article_tags\".\"article_id\" = %s")
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (sqlite "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1")
        (sqlite "SELECT COUNT(*) FROM (SELECT EXISTS(SELECT %s AS \"a\" FROM \"accounts_user\" U0 INNER JOIN \"articles_article_favorites\" U1 ON (U0.\"id\" = U1.\"user_id\") WHERE (U1.\"article_id\" = (\"articles_article\".\"id\") AND U0.\"id\" = %s) LIMIT 1) AS \"is_favorite\" FROM \"articles_article\" LEFT OUTER JOIN \"articles_article_favorites\" ON (\"articles_article\".\"id\" = \"articles_article_favorites\".\"article_id\") WHERE \"articles_article\".\"author_id\" IN (SELECT U0.\"id\" FROM \"accounts_user\" U0 INNER JOIN \"accounts_user_followers\" U1 ON (U0.\"id\" = U1.\"from_user_id\") WHERE U1.\"to_user_id\" = %s) GROUP BY \"articles_article\".\"id\") subquery")
        (times 4
          (sqlite "SELECT QUOTE(?)"))
        (times 3
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "DELETE" "api/profiles/<username>/follow" 200
        (url "/api/profiles/feedc_rules_stests_<workload>/follow")
        (view "api-1.0.0:follow_profile")
        (user "1" "feedm_rules_stests_<workload>")
        (sqlite-commit)
        (sqlite "BEGIN")
        (sqlite "DELETE FROM \"accounts_user_followers\" WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user_followers\".\"to_user_id\" IN (%s))"
          (rows 1))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"username\" = %s LIMIT 21")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (times 2
          (sqlite "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1"))
        (times 3
          (sqlite "SELECT QUOTE(?)"))
        (sqlite "SELECT QUOTE(?), QUOTE(?)")
        (times 2
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (trace
      (django-request "POST" "api/profiles/<username>/follow" 200
        (url "/api/profiles/feedc_rules_stests_<workload>/follow")
        (view "api-1.0.0:follow_profile")
        (user "1" "feedm_rules_stests_<workload>")
        (sqlite-commit)
        (sqlite "BEGIN")
        (sqlite "INSERT OR IGNORE INTO \"accounts_user_followers\" (\"from_user_id\", \"to_user_id\") VALUES (%s, %s)"
          (rows 1))
        (sqlite "PRAGMA foreign_keys = ON")
        (sqlite "PRAGMA legacy_alter_table = OFF")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE \"accounts_user\".\"username\" = %s LIMIT 21")
        (sqlite "SELECT \"accounts_user\".\"id\", \"accounts_user\".\"password\", \"accounts_user\".\"last_login\", \"accounts_user\".\"is_superuser\", \"accounts_user\".\"is_staff\", \"accounts_user\".\"is_active\", \"accounts_user\".\"date_joined\", \"accounts_user\".\"email\", \"accounts_user\".\"username\", \"accounts_user\".\"bio\", \"accounts_user\".\"image\" FROM \"accounts_user\" WHERE (\"accounts_user\".\"id\" = %s AND \"accounts_user\".\"is_active\") LIMIT 21")
        (sqlite "SELECT \"jwt_ninja_session\".\"id\", \"jwt_ninja_session\".\"created_at\", \"jwt_ninja_session\".\"updated_at\", \"jwt_ninja_session\".\"expired_at\", \"jwt_ninja_session\".\"ip_address\", \"jwt_ninja_session\".\"user_agent\", \"jwt_ninja_session\".\"location\", \"jwt_ninja_session\".\"user_id\", \"jwt_ninja_session\".\"data\", \"jwt_ninja_session\".\"refresh_jti\", \"jwt_ninja_session\".\"previous_refresh_jti\", \"jwt_ninja_session\".\"rotated_at\" FROM \"jwt_ninja_session\" WHERE \"jwt_ninja_session\".\"id\" = %s LIMIT 21")
        (times 2
          (sqlite "SELECT %s AS \"a\" FROM \"accounts_user\" INNER JOIN \"accounts_user_followers\" ON (\"accounts_user\".\"id\" = \"accounts_user_followers\".\"to_user_id\") WHERE (\"accounts_user_followers\".\"from_user_id\" = %s AND \"accounts_user\".\"id\" = %s) LIMIT 1"))
        (times 3
          (sqlite "SELECT QUOTE(?)"))
        (sqlite "SELECT QUOTE(?), QUOTE(?)")
        (times 2
          (sqlite "SELECT QUOTE(?), QUOTE(?), QUOTE(?)"))
        (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')")))
    (repeat 2
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
          (sqlite "select sqlite_compileoption_used('ENABLE_MATH_FUNCTIONS')"))))))
  ))
