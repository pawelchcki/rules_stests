(define-library (realworld scenario auth)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((1 "GET" "/api/tags" 200)
    (8 "GET" "/api/user" 200)
    (1 "POST" "/api/users" 201)
    (1 "POST" "/api/users/login" 200)
    (10 "PUT" "/api/user" 200)))
  ))
