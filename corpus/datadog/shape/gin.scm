(define-library (datadog shape gin)
  (export gin-app gin-request url user-agent
          gorm-query gorm-create gorm-update gorm-delete driver-call database-sql)
  (import (scheme base) (datadog trace-shape) (datadog shape tracers) (datadog shape http))
  (begin

; dd-trace-go's gin, GORM, and database/sql contribs, compiled in by Orchestrion.

(define gin-process
  "entrypoint.name:realworld-gin-datadog,entrypoint.type:executable,entrypoint.workdir:state,svc.user:true")
(define gin-app (dd-trace-go gin-process))

;; The request --------------------------------------------------------------------

; http.request, resource "<METHOD> <route>".
(define (gin-request method route status . clauses)
  (apply span "http.request" (string-append method " " route)
         (http-server-span method route status)
         (tag "component" "gin-gonic/gin") (tag "http.host" "<endpoint>") service-version
         clauses))
(define (url path) (tag "http.url" (string-append "http://<endpoint>" path)))

;; Database -----------------------------------------------------------------------

; One statement through database/sql, reported under the "sqlite3.db" service.
; `kind` is the database/sql call (Query, Exec, Begin, Commit, ...); calls
; without SQL use their kind as the resource.
(define (database-sql kind . clauses)
  (let ((sql (if (and (pair? clauses) (string? (car clauses))) (car clauses) kind))
        (clauses (if (and (pair? clauses) (string? (car clauses))) (cdr clauses) clauses)))
    (apply span "sqlite3.query" sql
           (service "sqlite3.db") (span-type "sql")
           (tag "_dd.svc_src" "opt.sql_driver") (tag "component" "database/sql")
           (tag "db.system" "other_sql") (tag "span.kind" "client")
           (tag "sql.query_type" kind)
           clauses)))

; A GORM operation, reported under the "gorm.db" service. GORM runs its
; statement through database/sql, so each operation contains the matching
; database-sql span: a Query for operations that return rows (query, create
; with RETURNING) and an Exec otherwise. `driver-call` states a different one.
(define (driver-call kind) (list 'gorm-driver kind))
(define (gorm-operation operation default-kind sql clauses)
  (apply span (string-append "gorm." operation) sql
         (service "gorm.db") (span-type "sql")
         (tag "_dd.svc_src" "gorm.io/gorm.v1") (tag "component" "gorm.io/gorm.v1")
         (database-sql (clause-value (own-clauses clauses) 'gorm-driver default-kind) sql)
         clauses))
(define (gorm-query sql . clauses) (gorm-operation "query" "Query" sql clauses))
(define (gorm-create sql . clauses) (gorm-operation "create" "Query" sql clauses))
(define (gorm-update sql . clauses) (gorm-operation "update" "Exec" sql clauses))
(define (gorm-delete sql . clauses) (gorm-operation "delete" "Exec" sql clauses))
  ))
