(define-library (realworld scenario pagination)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((2 "DELETE" "/api/articles/{slug}" 204)
    (2 "GET" "/api/articles" 200)
    (1 "GET" "/api/tags" 200)
    (2 "POST" "/api/articles" 201)
    (1 "POST" "/api/users" 201)))
  ))
