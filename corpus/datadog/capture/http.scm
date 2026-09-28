(define-library (datadog capture http)
  (export http-classification? server-tags? absolute-url? route-matches-url?)
  (import (scheme base) (datadog capture base))
  (begin

; HTTP server spans (system-tests test_semantic_conventions.py Test_Meta,
; test_standard_tags.py).

(define http-methods '("GET" "POST" "PUT" "DELETE" "PATCH" "HEAD" "OPTIONS" "TRACE"))
(define (status-code? value)
  (and (decimal? value) (= (string-length value) 3)
       (not (string<? value "100")) (string<? value "600")))
(define (web-spans capture) (filter web-span? (items capture 'spans)))

; The response status decides the error flag: only 5xx responses mark the
; server span as an error (system-tests Test_Config_HttpServerErrorStatuses).
(define (http-classification? capture)
  (and (pair? (web-spans capture))
       (all-spans capture
         (lambda (span)
           (or (not (web-span? span))
               (let ((status (tag span "http.status_code")))
                 (and (status-code? status)
                      (member (tag span "http.method") http-methods)
                      (equal? (field 'error span) (if (string<? status "500") 0 1)))))))))

; Every server span says it is one, which integration recorded it, and what
; request it served.
(define (server-tags? capture)
  (and (pair? (web-spans capture))
       (every (lambda (span)
                (and (equal? (tag span "span.kind") "server")
                     (nonempty-string? (tag span "component"))
                     (member (tag span "http.method") http-methods)
                     (status-code? (tag span "http.status_code"))
                     (nonempty-string? (tag span "http.route"))
                     (nonempty-string? (tag span "http.url"))
                     (string? (tag span "http.useragent"))))
              (web-spans capture))))

; http.url is the full URL including scheme and host.
(define (url-authority url)
  (let ((start (cond ((string-prefix? "http://" url) 7)
                     ((string-prefix? "https://" url) 8)
                     (else #f))))
    (and start
         (let find ((index start))
           (if (or (= index (string-length url)) (memv (string-ref url index) '(#\/ #\? #\#)))
               (substring url start index)
               (find (+ index 1)))))))
(define (absolute-url? capture)
  (and (pair? (web-spans capture))
       (every (lambda (span) (nonempty-string? (url-authority (tag span "http.url"))))
              (web-spans capture))))

; http.route is the template the request path matched: the same number of
; segments, literal segments equal, and each parameter (`:slug`, `{slug}`,
; `<slug>`, `<int:id>`) standing for one nonempty segment. Django routes are
; written without the leading slash.
(define (split-path path)
  (let loop ((index 0) (start 0) (result '()))
    (cond ((= index (string-length path))
           (reverse (if (> index start) (cons (substring path start index) result) result)))
          ((char=? (string-ref path index) #\/)
           (loop (+ index 1) (+ index 1)
                 (if (> index start) (cons (substring path start index) result) result)))
          (else (loop (+ index 1) start result)))))
(define (url-path url)
  (let* ((after-scheme
           (cond ((string-prefix? "http://" url) (substring url 7 (string-length url)))
                 ((string-prefix? "https://" url) (substring url 8 (string-length url)))
                 (else #f)))
         (path (if after-scheme
                   (let find ((index 0))
                     (cond ((= index (string-length after-scheme)) "/")
                           ((char=? (string-ref after-scheme index) #\/)
                            (substring after-scheme index (string-length after-scheme)))
                           (else (find (+ index 1)))))
                   url)))
    (let find ((index 0))
      (cond ((= index (string-length path)) path)
            ((memv (string-ref path index) '(#\? #\#)) (substring path 0 index))
            (else (find (+ index 1)))))))
(define (parameter-segment? segment)
  (let ((length (string-length segment)))
    (and (> length 1)
         (or (char=? (string-ref segment 0) #\:)
             (and (char=? (string-ref segment 0) #\{) (char=? (string-ref segment (- length 1)) #\}))
             (and (char=? (string-ref segment 0) #\<) (char=? (string-ref segment (- length 1)) #\>))))))
(define (route-matches? route path)
  (let loop ((template (split-path route)) (segments (split-path path)))
    (cond ((and (null? template) (null? segments)) #t)
          ((or (null? template) (null? segments)) #f)
          ((or (parameter-segment? (car template)) (string=? (car template) (car segments)))
           (loop (cdr template) (cdr segments)))
          (else #f))))
(define (route-matches-url? capture)
  (and (pair? (web-spans capture))
       (every (lambda (span)
                (let ((route (tag span "http.route")) (url (tag span "http.url")))
                  (and (string? route) (string? url) (route-matches? route (url-path url)))))
              (web-spans capture))))
  ))
