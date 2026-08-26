(define-library (realworld scenario tags)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((1 "DELETE" "/api/articles/{slug}" 204)
    (2 "GET" "/api/tags" 200)
    (1 "POST" "/api/articles" 201)
    (1 "POST" "/api/users" 201)))
  ))
