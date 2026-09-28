; The native Datadog traces of the unicode scenario, reviewed for python-aiohttp-datadog-v4-14-0-v05.
; Builders: corpus/datadog/shape/aiohttp.scm; rendered by tools/datadog_shapes.py.
(define-library (datadog realworld shape python-aiohttp-datadog-v4-14-0-v05 unicode)
  (export scenario-shape)
  (import (scheme base) (datadog trace-shape) (datadog shape aiohttp))
  (begin

(define scenario-shape
  (traces (aiohttp-app "v0.5")
    (trace
      (aiohttp-request "GET" "/api/profiles/{username}" 404
        (url "/api/profiles/%C3%BCn%C3%AFc%C3%B8de_rules_stests_<workload>")
        (user-agent "rules-stests/ünïcødé")
        (sqlalchemy "SELECT users.id, users.username, users.email, users.password_hash, users.bio, users.image \nFROM users \nWHERE users.username = ?")))))
  ))
