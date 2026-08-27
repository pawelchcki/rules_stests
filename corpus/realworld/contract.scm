(define-library (realworld contract)
  (export angle-bracket-route
          http-contract-buckets)
  (import (scheme base) (scheme char))
  (begin

; A portable RealWorld request observation is:
; (count method canonical-route http-status)
;
; Implementation profiles supply server-scope and render-server-span-name.
; This keeps the workload contract language-neutral while still checking each
; instrumentation implementation's exact span naming convention.

(define (angle-bracket-route route)
  (list->string
    (map (lambda (character)
           (cond ((char=? character #\{) #\<)
                 ((char=? character #\}) #\>)
                 (else character)))
         (string->list route))))

(define (http-contract-bucket observation server-scope render-server-span-name)
  (let ((count (list-ref observation 0))
        (method (list-ref observation 1))
        (route (list-ref observation 2))
        (status (list-ref observation 3)))
    (list count
          server-scope
          'server
          'unset
          (list 'exact (render-server-span-name method route))
          'root
          status)))

(define (http-contract-buckets observations server-scope render-server-span-name)
  (map (lambda (observation)
         (http-contract-bucket observation server-scope render-server-span-name))
       observations))
  ))

(define-library (realworld scenarios)
  (export expected-http-requests-for)
  (import (scheme base))
  (begin

; Startup health checks are reset before each workload and are intentionally
; absent from these portable request shapes.
(define scenario-shapes
  '((articles
      (1 "DELETE" "/api/articles/{slug}" 204)
      (6 "GET" "/api/articles" 200)
      (3 "GET" "/api/articles/{slug}" 200)
      (1 "GET" "/api/articles/{slug}" 404)
      (1 "POST" "/api/articles" 201)
      (1 "POST" "/api/users" 201)
      (3 "PUT" "/api/articles/{slug}" 200)
      (1 "PUT" "/api/articles/{slug}" 422))
    (auth
      (8 "GET" "/api/user" 200)
      (1 "POST" "/api/users" 201)
      (1 "POST" "/api/users/login" 200)
      (10 "PUT" "/api/user" 200))
    (comments
      (1 "DELETE" "/api/articles/{slug}" 204)
      (2 "DELETE" "/api/articles/{slug}/comments/{comment_id}" 204)
      (5 "GET" "/api/articles/{slug}/comments" 200)
      (1 "POST" "/api/articles" 201)
      (3 "POST" "/api/articles/{slug}/comments" 201)
      (1 "POST" "/api/users" 201))
    (errors_articles
      (2 "DELETE" "/api/articles/{slug}" 204)
      (1 "DELETE" "/api/articles/{slug}" 401)
      (1 "DELETE" "/api/articles/{slug}" 404)
      (1 "DELETE" "/api/articles/{slug}/favorite" 401)
      (1 "DELETE" "/api/articles/{slug}/favorite" 404)
      (1 "GET" "/api/articles/feed" 401)
      (1 "GET" "/api/articles/{slug}" 404)
      (2 "POST" "/api/articles" 201)
      (1 "POST" "/api/articles" 401)
      (3 "POST" "/api/articles" 422)
      (1 "POST" "/api/articles/{slug}/favorite" 401)
      (1 "POST" "/api/articles/{slug}/favorite" 404)
      (1 "POST" "/api/users" 201)
      (1 "PUT" "/api/articles/{slug}" 401)
      (2 "PUT" "/api/articles/{slug}" 404))
    (errors_auth
      (1 "GET" "/api/user" 401)
      (1 "POST" "/api/users" 201)
      (2 "POST" "/api/users" 409)
      (3 "POST" "/api/users" 422)
      (1 "POST" "/api/users/login" 401)
      (2 "POST" "/api/users/login" 422)
      (2 "PUT" "/api/user" 200)
      (1 "PUT" "/api/user" 401)
      (7 "PUT" "/api/user" 422))
    (errors_authorization
      (1 "DELETE" "/api/articles/{slug}" 204)
      (1 "DELETE" "/api/articles/{slug}" 403)
      (1 "DELETE" "/api/articles/{slug}/comments/{comment_id}" 403)
      (1 "GET" "/api/articles/{slug}/comments" 200)
      (1 "POST" "/api/articles" 201)
      (1 "POST" "/api/articles/{slug}/comments" 201)
      (2 "POST" "/api/users" 201)
      (1 "PUT" "/api/articles/{slug}" 403))
    (errors_comments
      (1 "DELETE" "/api/articles/{slug}" 204)
      (1 "DELETE" "/api/articles/{slug}/comments/{comment_id}" 401)
      (2 "DELETE" "/api/articles/{slug}/comments/{comment_id}" 404)
      (1 "GET" "/api/articles/{slug}/comments" 404)
      (1 "POST" "/api/articles" 201)
      (1 "POST" "/api/articles/{slug}/comments" 401)
      (1 "POST" "/api/articles/{slug}/comments" 404)
      (1 "POST" "/api/articles/{slug}/comments" 422)
      (1 "POST" "/api/users" 201))
    (errors_profiles
      (1 "DELETE" "/api/profiles/{username}/follow" 401)
      (1 "DELETE" "/api/profiles/{username}/follow" 404)
      (1 "GET" "/api/profiles/{username}" 404)
      (1 "POST" "/api/profiles/{username}/follow" 401)
      (1 "POST" "/api/profiles/{username}/follow" 404)
      (1 "POST" "/api/users" 201))
    (favorites
      (1 "DELETE" "/api/articles/{slug}" 204)
      (1 "DELETE" "/api/articles/{slug}/favorite" 200)
      (2 "GET" "/api/articles" 200)
      (2 "GET" "/api/articles/{slug}" 200)
      (1 "POST" "/api/articles" 201)
      (1 "POST" "/api/articles/{slug}/favorite" 200)
      (1 "POST" "/api/users" 201))
    (feed
      (2 "DELETE" "/api/articles/{slug}" 204)
      (1 "DELETE" "/api/profiles/{username}/follow" 200)
      (4 "GET" "/api/articles/feed" 200)
      (2 "POST" "/api/articles" 201)
      (1 "POST" "/api/profiles/{username}/follow" 200)
      (2 "POST" "/api/users" 201))
    (pagination
      (2 "DELETE" "/api/articles/{slug}" 204)
      (2 "GET" "/api/articles" 200)
      (2 "POST" "/api/articles" 201)
      (1 "POST" "/api/users" 201))
    (profiles
      (1 "DELETE" "/api/profiles/{username}/follow" 200)
      (3 "GET" "/api/profiles/{username}" 200)
      (1 "POST" "/api/profiles/{username}/follow" 200)
      (2 "POST" "/api/users" 201))
    (tags
      (1 "DELETE" "/api/articles/{slug}" 204)
      (1 "GET" "/api/tags" 200)
      (1 "POST" "/api/articles" 201)
      (1 "POST" "/api/users" 201))))

(define (expected-http-requests-for scenario)
  (let ((entry (assq scenario scenario-shapes)))
    (if entry (cdr entry) (error "missing RealWorld scenario" scenario))))
  ))
