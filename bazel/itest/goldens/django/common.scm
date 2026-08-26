(define-library (realworld profile python-django-auto-v0-65b0)
  (export implementation-profile
          expected-resource-attributes
          expected-scopes
          expected-metric-scopes
          expected-log-scopes
          expected-span-flags
          event-policy-for
          server-scope
          render-server-span-name
          implementation-buckets-for)
  (import (scheme base)
          (otel profile python-auto-v0-65b0)
          (realworld contract))
  (begin

; Exact profile for OpenTelemetry Python auto-instrumentation 0.65b0 on Django.
(define implementation-profile 'python-django-auto-v0-65b0)

(define expected-resource-attributes
  (python-service-resource-attributes "django-otel"))

(define expected-scopes
  (list
    python-sqlite-scope
    (python-http-scope
      'django
      "opentelemetry.instrumentation.django"
      '("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.url" "http.user_agent" "net.host.name" "net.host.port" "net.peer.ip")
      '(("http.scheme" (exact "http")) ("net.host.name" (loopback-port)) ("net.peer.ip" (exact "127.0.0.1")))
      '("net.host.port" "http.status_code"))))

(define expected-metric-scopes
  (list
    (list "opentelemetry.instrumentation.django" "0.65b0" python-schema-url)
    python-system-metrics-scope))

(define expected-log-scopes
  (list
    '("django.request" "" "" #f)
    python-logging-scope))

(define (event-policy-for scenario)
  (list 'exception-on-error
        (list-ref (python-profile-shape scenario implementation-shapes) 5)))
(define server-scope 'django)

(define (render-server-span-name method canonical-route)
  (string-append method
                 " "
                 (angle-bracket-route
                   (substring canonical-route 1 (string-length canonical-route)))))

; Columns are scenario, begin, delete, insert, select, update, error-insert.
(define implementation-shapes
  '((articles 7 5 6 155 3 0)
    (auth 0 0 21 105 10 0)
    (comments 2 6 6 96 0 0)
    (errors_articles 4 8 4 100 0 0)
    (errors_auth 0 0 4 46 2 2)
    (errors_authorization 2 4 6 72 0 0)
    (errors_comments 2 4 3 55 0 0)
    (errors_profiles 0 0 2 16 0 0)
    (favorites 4 5 4 103 0 0)
    (feed 6 9 7 136 0 0)
    (pagination 4 8 4 72 0 0)
    (profiles 2 1 5 44 0 0)
    (tags 4 4 6 39 0 0)))

(define statement-operations '("BEGIN" "DELETE" "INSERT" "SELECT" "UPDATE"))

(define (django-database-bucket count operation)
  (python-database-bucket
    count 'sqlite 'unset (list 'exact operation) 'child))

(define (implementation-buckets-for scenario)
  (let* ((shape (python-profile-shape scenario implementation-shapes))
         (error-inserts (list-ref shape 5))
         (buckets (python-counted-operation-buckets
                    (list (list-ref shape 0)
                          (list-ref shape 1)
                          (list-ref shape 2)
                          (list-ref shape 3)
                          (list-ref shape 4))
                    statement-operations
                    django-database-bucket)))
    (if (= error-inserts 0)
        buckets
        (append buckets
                (list (python-database-bucket
                        error-inserts 'sqlite 'error '(exact "INSERT") 'child))))))
  ))
