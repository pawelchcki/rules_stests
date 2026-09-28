(define-library (datadog shape http)
  (export http-server-span user-agent)
  (import (scheme base) (datadog trace-shape))
  (begin

; Every RealWorld request is sent by Hurl; the unicode scenario overrides the
; agent with `user-agent`.
(define hurl-user-agent "hurl/8.0.1")

; The server span for one HTTP request: its method, the route template that
; matched, and the response status.
(define (http-server-span method route status)
  (bundle (span-type "web")
          (tag "span.kind" "server")
          (tag "http.method" method)
          (tag "http.route" route)
          (tag "http.status_code" (number->string status))
          (tag "http.useragent" hurl-user-agent)))

(define (user-agent value) (tag "http.useragent" value))
  ))
