(define-library (realworld scenario profiles)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((1 "DELETE" "/api/profiles/{username}/follow" 200)
    (3 "GET" "/api/profiles/{username}" 200)
    (1 "GET" "/api/tags" 200)
    (1 "POST" "/api/profiles/{username}/follow" 200)
    (2 "POST" "/api/users" 201)))
  ))
