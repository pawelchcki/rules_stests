(define-library (datadog shape django)
  (export django-app django-request url user-agent view user sqlite sqlite-commit rows)
  (import (scheme base) (datadog trace-shape) (datadog shape tracers) (datadog shape http))
  (begin

; dd-trace-py's Django and sqlite3 integrations on the django-ninja RealWorld
; application.

(define django-process
  "entrypoint.basedir:main,entrypoint.name:-c,entrypoint.type:script,entrypoint.workdir:main,svc.user:true")
(define (django-app wire) (dd-trace-py wire django-process))

;; The request --------------------------------------------------------------------

; django.request, resource "<METHOD> <route>". Its child spans are the queries
; the view ran: they are placed inside the view span, which sits inside the
; middleware stack below.
(define (django-request method route status . clauses)
  (apply span "django.request" (string-append method " " route)
         (http-server-span method route status)
         (tag "_dd.svc_src" "m") (tag "component" "django") service-version
         (tag "django.app" "ninja") (tag "django.namespace" "api-1.0.0")
         (tag "django.request.class" "django.core.handlers.wsgi.WSGIRequest")
         (tag "django.response.class" "django.http.response.HttpResponse")
         (tag "django.user.is_authenticated" "False")
         (metric "_dd.measured" 1)
         (append (own-clauses clauses)
                 (list (middleware-stack
                         (apply internal-span "django.view" "ninja.operation._sync_view"
                                (child-spans clauses)))))))
(define (url path) (tag "http.url" (string-append "http://<endpoint>" path)))
; The resolved django-ninja view.
(define (view name) (tag "django.view" name))
; The authenticated user; requests are anonymous unless stated.
(define (user id name)
  (bundle (tag "django.user.id" id) (tag "django.user.is_authenticated" "True")
          (tag "django.user.name" name) (tag "usr.id" id)))

;; The middleware stack -------------------------------------------------------------

; Spans the Django integration records inside the application service.
(define (internal-span name resource . children)
  (apply span name resource
         (tag "_dd.svc_src" "m") (tag "component" "django") service-version
         children))

; settings.MIDDLEWARE, outermost first. Each entry's __call__ span contains
; the hooks it implements and the rest of the stack.
(define middleware
  '(("django.middleware.security.SecurityMiddleware" "process_request" "process_response")
    ("django.contrib.sessions.middleware.SessionMiddleware" "process_request" "process_response")
    ("django.middleware.common.CommonMiddleware" "process_request" "process_response")
    ("django.middleware.csrf.CsrfViewMiddleware" "process_request" "process_response")
    ("django.contrib.auth.middleware.AuthenticationMiddleware" "process_request")
    ("django.contrib.messages.middleware.MessageMiddleware" "process_request" "process_response")
    ("django.middleware.clickjacking.XFrameOptionsMiddleware" "process_response")
    ("corsheaders.middleware.CorsMiddleware")
    ("django.middleware.common.CommonMiddleware" "process_request" "process_response")))
; process_view hooks run next to the view, inside the innermost middleware.
(define view-hooks '("django.middleware.csrf.CsrfViewMiddleware.process_view"))

(define (middleware-stack view)
  (let wrap ((entries (reverse middleware))
             (inner (append (map (lambda (hook) (internal-span "django.middleware" hook)) view-hooks)
                            (list view))))
    (if (null? entries)
        (car inner)
        (let ((class (car (car entries))) (hooks (cdr (car entries))))
          (wrap (cdr entries)
                (list (apply internal-span "django.middleware" (string-append class ".__call__")
                             (append (map (lambda (hook)
                                            (internal-span "django.middleware" (string-append class "." hook)))
                                          hooks)
                                     inner))))))))

;; Database -----------------------------------------------------------------------

; One sqlite3 statement, reported under the "sqlite" service. sqlite3 reports
; a rowcount of -1 for statements that do not modify rows.
(define (sqlite sql . clauses)
  (apply span "sqlite.query" sql
         (service "sqlite") (span-type "sql")
         (tag "_dd.svc_src" "sqlite") (tag "component" "sqlite") (tag "db.system" "sqlite")
         (tag "span.kind" "client")
         (metric "_dd.measured" 1) (metric "db.row_count" -1)
         clauses))
(define (rows count) (metric "db.row_count" count))
; A transaction commit, which the integration records without the "sql" type.
(define (sqlite-commit . clauses)
  (apply span "sqlite.connection.commit" "sqlite.connection.commit"
         (service "sqlite")
         (tag "_dd.svc_src" "sqlite") (tag "component" "sqlite") (tag "db.system" "sqlite")
         (tag "span.kind" "client")
         clauses))
  ))
