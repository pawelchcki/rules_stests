(define-library (realworld scenario errors_profiles)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((1 "DELETE" "/api/profiles/{username}/follow" 401)
    (1 "DELETE" "/api/profiles/{username}/follow" 404)
    (1 "GET" "/api/profiles/{username}" 404)
    (1 "GET" "/api/tags" 200)
    (1 "POST" "/api/profiles/{username}/follow" 401)
    (1 "POST" "/api/profiles/{username}/follow" 404)
    (1 "POST" "/api/users" 201)))
  ))
