(define-library (realworld profile python-django-auto-v0-65b0)
  (export implementation-profile
          expected-resource-attributes
          expected-scopes
          event-policy
          server-scope
          render-server-span-name)
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
    '(django
      "opentelemetry.instrumentation.django"
      "0.65b0"
      ("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.url" "http.user_agent" "net.host.name" "net.host.port" "net.peer.ip")
      ("http.flavor" "http.host" "http.method" "http.route" "http.scheme" "http.server_name" "http.status_code" "http.url" "http.user_agent" "net.host.name" "net.host.port" "net.peer.ip")
      (("http.scheme" (exact "http")) ("net.host.name" (loopback-port)) ("net.peer.ip" (exact "127.0.0.1")))
      ("net.host.port" "http.status_code"))))

(define event-policy 'exception-on-error)
(define server-scope 'django)

(define (render-server-span-name method canonical-route)
  (string-append method
                 " "
                 (angle-bracket-route
                   (substring canonical-route 1 (string-length canonical-route)))))
  ))
