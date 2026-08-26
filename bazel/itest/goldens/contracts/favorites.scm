(define-library (realworld scenario favorites)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((1 "DELETE" "/api/articles/{slug}" 204)
    (1 "DELETE" "/api/articles/{slug}/favorite" 200)
    (2 "GET" "/api/articles" 200)
    (2 "GET" "/api/articles/{slug}" 200)
    (1 "GET" "/api/tags" 200)
    (1 "POST" "/api/articles" 201)
    (1 "POST" "/api/articles/{slug}/favorite" 200)
    (1 "POST" "/api/users" 201)))
  ))
