(define-library (realworld profile python-aiohttp-auto-v0-65b0)
  (export implementation-profile
          expected-resource-attributes
          expected-scopes
          event-policy-for
          server-scope
          render-server-span-name
          implementation-buckets-for)
  (import (scheme base)
          (otel profile python-auto-v0-65b0)
          (realworld contract))
  (begin

; Exact profile for OpenTelemetry Python auto-instrumentation 0.65b0 on aiohttp.
(define implementation-profile 'python-aiohttp-auto-v0-65b0)

(define expected-resource-attributes
  (python-service-resource-attributes "aiohttp-otel"))

(define expected-scopes
  (list
    python-sqlite-scope
    python-sqlalchemy-scope
    (python-http-scope
      'http
      "opentelemetry.instrumentation.aiohttp_server"
      '("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.target" "http.url" "http.user_agent" "net.host.name" "net.host.port")
      '(("http.scheme" (exact "http")) ("net.host.name" (exact "127.0.0.1")))
      '("net.host.port" "http.status_code"))))

(define (event-policy-for scenario) '(empty 0))
(define server-scope 'http)

(define (render-server-span-name method canonical-route)
  (string-append method " " canonical-route))

; Columns are scenario, connect, delete, insert, select, update.
(define implementation-shapes
  '((articles 21 2 3 77 3)
    (auth 20 0 1 23 11)
    (comments 17 3 5 41 0)
    (errors_articles 16 2 3 33 0)
    (errors_auth 13 0 1 15 2)
    (errors_authorization 11 1 4 25 0)
    (errors_comments 9 1 2 19 0)
    (errors_profiles 4 0 1 7 0)
    (favorites 12 2 3 46 0)
    (feed 16 3 5 58 0)
    (pagination 9 2 3 28 0)
    (profiles 9 1 3 17 0)
    (tags 5 1 3 11 0)))

(define statement-operations '("DELETE" "INSERT" "SELECT" "UPDATE"))

(define (sqlalchemy-statement-bucket count operation)
  (python-database-bucket
    count
    'sqlalchemy
    'unset
    (list 'prefix-suffix (string-append operation " /") "realworld.sqlite3")
    'child))

(define (sqlite-root-statement-bucket count operation)
  (python-database-bucket
    count 'sqlite 'unset (list 'exact operation) 'root))

(define (aiohttp-database-buckets shape)
  (let ((connect-count (car shape)) (statement-counts (cdr shape)))
  (append
    (python-counted-operation-buckets
      statement-counts statement-operations sqlalchemy-statement-bucket)
    (list (python-database-bucket connect-count 'sqlalchemy 'unset '(exact "connect") 'child))
    (python-counted-operation-buckets
      statement-counts statement-operations sqlite-root-statement-bucket))))

(define (implementation-buckets-for scenario)
  (aiohttp-database-buckets
    (python-profile-shape scenario implementation-shapes)))
  ))
