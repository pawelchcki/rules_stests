(define-library (datadog shape rails)
  (export rails-app rack-request url user-agent action-controller without-runtimes
          active-record cached instantiate first-finished)
  (import (scheme base) (datadog trace-shape) (datadog shape tracers) (datadog shape http))
  (begin

; dd-trace-rb's Rack, Action Pack, and Active Record integrations.

(define rails-process
  "entrypoint.workdir:main,entrypoint.name:rails,entrypoint.basedir:bin,entrypoint.type:script,rails.application:realworld_rails,svc.user:true")
(define rails-app (dd-trace-rb rails-process))

;; The request --------------------------------------------------------------------

; rack.request. Once a controller handles the request, the Rack span takes the
; controller's "Controller#action" resource; requests rejected before routing
; to an action keep "<METHOD> <status>".
(define (rack-request method route status . clauses)
  (let ((controller (let find ((children (child-spans clauses)))
                      (cond ((null? children) #f)
                            ((equal? (span-name (car children)) "rails.action_controller")
                             (span-resource (car children)))
                            (else (find (cdr children)))))))
    (apply span "rack.request"
           (or controller (string-append method " " (number->string status)))
           (http-server-span method route status)
           (tag "component" "rack") (tag "operation" "request") service-version
           (tag "http.base_url" "http://<endpoint>")
           (tag "http.response.headers.x-request-id" "<request-id>")
           ; 204 responses have no body and therefore no content type.
           (and (not (= status 204))
                (tag "http.response.headers.content-type" "application/json; charset=utf-8"))
           (metric "_dd.measured" 1)
           clauses)))
; Rack records the request path without the scheme and host; those are in
; http.base_url.
(define (url path) (tag "http.url" path))

; rails.action_controller, resource "Controller#action".
(define (action-controller controller action . clauses)
  (apply span "rails.action_controller" (string-append controller "#" action)
         (span-type "web")
         (tag "component" "action_pack") (tag "operation" "controller")
         (tag "rails.route.controller" controller) (tag "rails.route.action" action)
         service-version
         (metric "_dd.measured" 1)
         (metric "rails.db.runtime" "<duration-ms>") (metric "rails.view.runtime" "<duration-ms>")
         clauses))
; Action Pack reports no database or view runtime for these actions (destroy
; actions and some validation failures in the reviewed captures).
(define without-runtimes
  (bundle (unmetric "rails.db.runtime") (unmetric "rails.view.runtime")))

;; Database -----------------------------------------------------------------------

; One SQL statement, reported under the "sqlite" service.
(define (active-record sql . clauses)
  (apply span "sqlite.query" sql
         (service "sqlite") (span-type "sql")
         (tag "_dd.svc_src" "active_record") (tag "component" "active_record")
         (tag "operation" "sql") (tag "span.kind" "client")
         (tag "active_record.db.vendor" "sqlite")
         (tag "active_record.db.name" "<fixture>/realworld.sqlite3")
         (tag "db.instance" "<fixture>/realworld.sqlite3")
         service-version
         clauses))
; Answered from Active Record's query cache.
(define cached (tag "active_record.db.cached" "true"))

; Active Record building `count` model objects of one class.
(define (instantiate class-name count . clauses)
  (apply span "active_record.instantiation" class-name
         (span-type "custom")
         (tag "component" "active_record") (tag "operation" "instantiation")
         (tag "active_record.instantiation.class_name" class-name)
         service-version
         (metric "_dd.measured" 1) (metric "active_record.instantiation.record_count" count)
         clauses))
  ))
