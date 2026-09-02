(define-library (realworld route)
  (export brace-route angle-bracket-route colon-route strip-leading-slash rename-parameter)
  (import (scheme base) (scheme char))
  (begin

(define (brace-route route) route)

(define (angle-bracket-route route)
  (list->string
    (map (lambda (character)
           (cond ((char=? character #\{) #\<)
                 ((char=? character #\}) #\>)
                 (else character)))
         (string->list route))))

(define (strip-leading-slash route)
  (if (and (> (string-length route) 0) (char=? (string-ref route 0) #\/))
      (substring route 1 (string-length route))
      route))

(define (rename-parameter from to)
  (lambda (name) (if (string=? name from) to name)))

(define (split-slash value)
  (let loop ((characters (string->list value)) (segment '()) (segments '()))
    (cond
      ((null? characters) (reverse (cons (list->string (reverse segment)) segments)))
      ((char=? (car characters) #\/)
       (loop (cdr characters) '() (cons (list->string (reverse segment)) segments)))
      (else (loop (cdr characters) (cons (car characters) segment) segments)))))

(define (join-slash segments)
  (if (null? (cdr segments))
      (car segments)
      (string-append (car segments) "/" (join-slash (cdr segments)))))

(define (brace-parameter segment)
  (let ((width (string-length segment)))
    (and (>= width 2)
         (char=? (string-ref segment 0) #\{)
         (char=? (string-ref segment (- width 1)) #\})
         (substring segment 1 (- width 1)))))

(define (colon-route canonical-route . optional-rename)
  (let ((rename (if (null? optional-rename) (lambda (name) name) (car optional-rename))))
    (join-slash
      (map (lambda (segment)
             (let ((parameter (brace-parameter segment)))
               (if parameter (string-append ":" (rename parameter)) segment)))
           (split-slash canonical-route)))))
  ))
