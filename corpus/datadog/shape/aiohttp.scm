(define-library (datadog shape aiohttp)
  (export aiohttp-app aiohttp-request url user-agent sqlalchemy rows)
  (import (scheme base) (datadog trace-shape) (datadog shape tracers) (datadog shape http))
  (begin

; dd-trace-py's aiohttp and SQLAlchemy integrations. SQLAlchemy records each
; statement in the request's context before aiosqlite hands it to its worker
; thread, so statements stay children of the request span. (The sqlite3
; integration is disabled for this fixture to avoid detached duplicates.)

(define aiohttp-process
  "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
(define (aiohttp-app wire) (dd-trace-py wire aiohttp-process))

; aiohttp.request, resource "<METHOD> <route>".
(define (aiohttp-request method route status . clauses)
  (apply span "aiohttp.request" (string-append method " " route)
         (http-server-span method route status)
         (tag "_dd.svc_src" "m") (tag "component" "aiohttp") service-version
         (metric "_dd.measured" 1)
         clauses))
; The path and query the request was sent to.
(define (url path) (tag "http.url" (string-append "http://<endpoint>" path)))

; One SQL statement, reported under the "sqlite" service.
(define (sqlalchemy sql . clauses)
  (apply span "sqlite.query" sql
         (service "sqlite") (span-type "sql")
         (tag "_dd.svc_src" "sqlalchemy") (tag "component" "sqlalchemy")
         (tag "span.kind" "client") (tag "sql.db" "<fixture>/realworld.sqlite3")
         service-version (metric "_dd.measured" 1)
         clauses))
; The cursor's rowcount, when SQLAlchemy reports one.
(define (rows count) (metric "db.row_count" count))
  ))
