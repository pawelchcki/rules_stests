(define-library (realworld scenario feed)
  (export expected-http-requests)
  (import (scheme base))
  (begin
(define expected-http-requests
  '((2 "DELETE" "/api/articles/{slug}" 204)
    (1 "DELETE" "/api/profiles/{username}/follow" 200)
    (4 "GET" "/api/articles/feed" 200)
    (1 "GET" "/api/tags" 200)
    (2 "POST" "/api/articles" 201)
    (1 "POST" "/api/profiles/{username}/follow" 200)
    (2 "POST" "/api/users" 201)))
  ))
