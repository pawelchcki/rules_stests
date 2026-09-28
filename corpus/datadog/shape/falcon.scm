(define-library (datadog shape falcon)
  (export falcon-app sinatra-request url user-agent before-filter signed-in route failure
          sequel first-finished)
  (import (scheme base) (datadog trace-shape) (datadog shape tracers) (datadog shape http))
  (begin

; dd-trace-rb's Rack, Sinatra, and Sequel integrations on a Sinatra application
; served by Falcon, which runs every request in its own fiber.

(define falcon-process
  "entrypoint.workdir:main,entrypoint.name:server,entrypoint.basedir:bin,entrypoint.type:script,svc.user:true")
(define falcon-app (dd-trace-rb falcon-process))

;; The request --------------------------------------------------------------------

; Each request is three spans: rack.request, the sinatra.request it wraps, and
; the sinatra.route that handled it. All take the resource "<METHOD> <route>".
; Queries a before filter runs belong to sinatra.request (`before-filter`);
; the handler's queries and outcome belong to the route (`route`).
(define (before-filter . spans) (cons 'sinatra-before-filter spans))
(define (route . clauses) (cons 'sinatra-route clauses))

(define (tagged kind clauses)
  (let loop ((clauses clauses) (result '()))
    (cond ((null? clauses) (reverse result))
          ((and (pair? (car clauses)) (eq? (car (car clauses)) kind))
           (loop (cdr clauses) (append (reverse (cdr (car clauses))) result)))
          (else (loop (cdr clauses) result)))))
(define (untagged clauses)
  (let loop ((clauses clauses) (result '()))
    (cond ((null? clauses) (reverse result))
          ((and (pair? (car clauses)) (memq (car (car clauses)) '(sinatra-before-filter sinatra-route)))
           (loop (cdr clauses) result))
          (else (loop (cdr clauses) (cons (car clauses) result))))))

; Rack records the path with the query's keys but not their values
; (quantization); Sinatra records only the path.
(define (url path) (tag "http.url" path))
(define (path-only url)
  (let find ((index 0))
    (cond ((= index (string-length url)) url)
          ((char=? (string-ref url index) #\?) (substring url 0 index))
          (else (find (+ index 1))))))

(define (sinatra-request method route-path status . clauses)
  (let* ((resource (string-append method " " route-path))
         (own (untagged clauses))
         (url-clause (let find ((own own))
                       (cond ((null? own) #f)
                             ((and (pair? (car own)) (eq? (car (car own)) 'tag)
                                   (equal? (cadr (car own)) "http.url"))
                              (car own))
                             (else (find (cdr own))))))
         (sinatra-url (and url-clause (tag "http.url" (path-only (list-ref url-clause 2)))))
         ; 204 responses have no body and therefore no content type.
         (content-type (and (not (= status 204))
                            (tag "http.response.headers.content-type" "application/json; charset=utf-8")))
         (sinatra-tags (bundle (tag "component" "sinatra") (tag "sinatra.route.path" route-path)
                               service-version (metric "_dd.measured" 1))))
    (apply span "rack.request" resource
           (http-server-span method route-path status)
           (tag "component" "rack") (tag "operation" "request") service-version
           (tag "http.base_url" "http://<endpoint>")
           content-type
           ; A handler that answers 404 leaves Rack's route path empty.
           (and (= status 404) (tag "http.route.path" ""))
           (metric "_dd.measured" 1)
           (append
             own
             (list (apply span "sinatra.request" resource
                          (span-type "web") sinatra-tags (tag "operation" "request")
                          (tag "http.method" method) (tag "http.status_code" (number->string status))
                          content-type sinatra-url
                          (append
                            (tagged 'sinatra-before-filter clauses)
                            (list (apply span "sinatra.route" resource
                                         (span-type "web") sinatra-tags (tag "operation" "route")
                                         (tag "sinatra.app.name" "RealWorld::App")
                                         (tagged 'sinatra-route clauses))))))))))

; The application answers every rejection by raising RealWorld::Failure; the
; Sinatra integration records it on the route span with the errors it carries.
(define (failure errors) (raised "RealWorld::Failure" errors))

;; Database -----------------------------------------------------------------------

; One statement through Sequel, reported under the "sqlite" service. The
; application binds every value, so the SQL keeps its placeholders.
(define (sequel sql . clauses)
  (apply span "sequel.query" sql
         (service "sqlite") (span-type "sql")
         (tag "_dd.svc_src" "sequel") (tag "component" "sequel") (tag "operation" "query")
         (tag "span.kind" "client") (tag "db.system" "sqlite") (tag "sequel.db.vendor" "sqlite")
         (tag "db.instance" "<fixture>/realworld.sqlite3")
         (tag "sequel.db.name" "<fixture>/realworld.sqlite3")
         service-version
         clauses))

; The before filter resolves the request's token to its user.
(define signed-in (before-filter (sequel "SELECT * FROM `users` WHERE (`id` = :id) LIMIT 1")))
  ))
