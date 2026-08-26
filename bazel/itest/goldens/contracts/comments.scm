(define-library (realworld scenario comments)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((1 "DELETE" "/api/articles/{slug}" 204)
    (2 "DELETE" "/api/articles/{slug}/comments/{comment_id}" 204)
    (5 "GET" "/api/articles/{slug}/comments" 200)
    (1 "GET" "/api/tags" 200)
    (1 "POST" "/api/articles" 201)
    (3 "POST" "/api/articles/{slug}/comments" 201)
    (1 "POST" "/api/users" 201)))
  ))
