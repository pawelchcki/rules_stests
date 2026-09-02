(define-library (otel identifiers)
  (export valid-hex? uuid? valid-trace-state? valid-host-field? loopback-port-number)
  (import (scheme base) (scheme char) (otel base) (otel text))
  (begin

(define (valid-hex? value width)
  (and (= (string-length value) width)
       (let loop ((index 0) (nonzero #f))
         (if (= index width)
             nonzero
             (let ((character (string-ref value index)))
               (and (hex-character? character)
                    (loop (+ index 1) (or nonzero (not (char=? character #\0))))))))))

(define (lower-alpha? character)
  (and (char>=? character #\a) (char<=? character #\z)))

(define (trace-key-character? character)
  (or (lower-alpha? character)
      (ascii-digit? character)
      (memv character '(#\_ #\- #\* #\/))))

(define (character-index value wanted)
  (let loop ((index 0))
    (cond ((= index (string-length value)) #f)
          ((char=? (string-ref value index) wanted) index)
          (else (loop (+ index 1))))))

(define (valid-trace-key-part? value max-length first-predicate)
  (and (> (string-length value) 0)
       (<= (string-length value) max-length)
       (first-predicate (string-ref value 0))
       (let loop ((index 1))
         (or (= index (string-length value))
             (and (trace-key-character? (string-ref value index))
                  (loop (+ index 1)))))))

(define (valid-trace-state-key? key)
  (let ((separator (character-index key #\@)))
    (if separator
        (and (not (character-index (substring key (+ separator 1) (string-length key)) #\@))
             (valid-trace-key-part?
               (substring key 0 separator)
               241
               (lambda (character) (or (lower-alpha? character) (ascii-digit? character))))
             (valid-trace-key-part?
               (substring key (+ separator 1) (string-length key))
               14
               lower-alpha?))
        (valid-trace-key-part? key 256 lower-alpha?))))

(define (ows? character)
  (or (char=? character #\space) (char=? character #\tab)))

(define (trim-ows value)
  (let find-start ((start 0))
    (if (and (< start (string-length value)) (ows? (string-ref value start)))
        (find-start (+ start 1))
        (let find-end ((end (string-length value)))
          (if (and (> end start) (ows? (string-ref value (- end 1))))
              (find-end (- end 1))
              (substring value start end))))))

(define (split-on-comma value)
  (let loop ((index 0) (start 0) (members '()))
    (if (= index (string-length value))
        (reverse (cons (trim-ows (substring value start index)) members))
        (if (char=? (string-ref value index) #\,)
            (loop (+ index 1) (+ index 1)
                  (cons (trim-ows (substring value start index)) members))
            (loop (+ index 1) start members)))))

(define (valid-trace-state-value? value)
  (and (> (string-length value) 0)
       (<= (string-length value) 256)
       (not (ows? (string-ref value (- (string-length value) 1))))
       (let loop ((index 0))
         (or (= index (string-length value))
             (let* ((character (string-ref value index))
                    (code (char->integer character)))
               (and (>= code 32)
                    (<= code 126)
                    (not (memv character '(#\, #\=)))
                    (loop (+ index 1))))))))

(define (valid-trace-state-member? member)
  (let ((separator (character-index member #\=)))
    (and separator
         (not (character-index (substring member (+ separator 1) (string-length member)) #\=))
         (valid-trace-state-key? (substring member 0 separator))
         (valid-trace-state-value?
           (substring member (+ separator 1) (string-length member))))))

(define (valid-trace-state? value)
  (or (string=? value "")
      (and (<= (string-length value) 512)
           (let ((members (split-on-comma value)))
             (and (<= (length members) 32)
                  (every valid-trace-state-member? members)
                  (every
                    (lambda (member)
                      (= (count
                           (lambda (candidate)
                             (string=? (substring member 0 (character-index member #\=))
                                       (substring candidate 0 (character-index candidate #\=))))
                           members)
                         1))
                    members))))))

(define (uuid? value)
  (and (= (string-length value) 36)
       (let loop ((index 0))
         (if (= index 36)
             #t
             (and (if (memv index '(8 13 18 23))
                      (char=? (string-ref value index) #\-)
                      (hex-character? (string-ref value index)))
                  (loop (+ index 1)))))))

(define (decimal-string? value)
  (and (> (string-length value) 0)
       (let loop ((index 0))
         (or (= index (string-length value))
             (and (ascii-digit? (string-ref value index))
                  (loop (+ index 1)))))))

(define (valid-host-label? value)
  (and (> (string-length value) 0)
       (or (ascii-alpha? (string-ref value 0))
           (ascii-digit? (string-ref value 0)))
       (or (ascii-alpha? (string-ref value (- (string-length value) 1)))
           (ascii-digit? (string-ref value (- (string-length value) 1))))
       (let loop ((index 1))
         (or (>= index (- (string-length value) 1))
             (let ((character (string-ref value index)))
               (and (or (ascii-alpha? character)
                        (ascii-digit? character)
                        (char=? character #\-))
                    (loop (+ index 1))))))))

(define (valid-host-name? value)
  (and (> (string-length value) 0)
       (let loop ((remaining value))
         (let ((separator (character-index remaining #\.)))
           (if separator
               (and (> separator 0)
                    (< separator (- (string-length remaining) 1))
                    (valid-host-label? (substring remaining 0 separator))
                    (loop (substring remaining (+ separator 1) (string-length remaining))))
               (valid-host-label? remaining))))))

(define (valid-host-field? value)
  (if (and (> (string-length value) 0) (char=? (string-ref value 0) #\[))
      (let ((close (character-index value #\])))
        (and close
             (> close 1)
             (character-index (substring value 1 close) #\:)
             (every
               (lambda (character)
                 (or (hex-character? character)
                     (char=? character #\:)
                     (char=? character #\.)))
               (string->list (substring value 1 close)))
             (or (= close (- (string-length value) 1))
                 (and (char=? (string-ref value (+ close 1)) #\:)
                      (decimal-string?
                        (substring value (+ close 2) (string-length value)))))))
      (let ((separator (character-index value #\:)))
        (if separator
            (and (> separator 0)
                 (not (character-index
                        (substring value (+ separator 1) (string-length value))
                        #\:))
                 (valid-host-name? (substring value 0 separator))
                 (decimal-string?
                   (substring value (+ separator 1) (string-length value))))
            (valid-host-name? value)))))

(define loopback-prefix "127.0.0.1:")

(define (loopback-port-number value)
  (and (string-prefix? loopback-prefix value)
       (let* ((suffix (substring value (string-length loopback-prefix) (string-length value)))
              (port (and (decimal-string? suffix) (string->number suffix))))
         (and (integer? port) (> port 0) (<= port 65535) port))))
  ))
