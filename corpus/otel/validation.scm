(define-library (otel validation)
  (export otel-validate-contract otel-validate-exact)
  (import (scheme base) (scheme char) (scheme write))
  (begin

(define (contract-error message)
  (display "[[OTLP-CONTRACT-V1:" (current-error-port))
  (display (string-length message) (current-error-port))
  (display "]]" (current-error-port))
  (display message (current-error-port))
  (error "OTLP contract sentinel"))

(define (check condition message)
  (if condition #t (contract-error message)))

(define (field key object)
  (let ((entry (assq key object)))
    (if entry (cadr entry) (contract-error "missing OTLP field"))))

(define (third values)
  (car (cdr (cdr values))))

(define (count predicate values)
  (let loop ((values values) (total 0))
    (if (null? values)
        total
        (loop (cdr values) (+ total (if (predicate (car values)) 1 0))))))

(define (every predicate values)
  (or (null? values)
      (and (predicate (car values)) (every predicate (cdr values)))))

(define (find predicate values)
  (cond ((null? values) #f)
        ((predicate (car values)) (car values))
        (else (find predicate (cdr values)))))

(define (sum values)
  (if (null? values) 0 (+ (car values) (sum (cdr values)))))

(define (string-prefix? prefix value)
  (and (<= (string-length prefix) (string-length value))
       (string=? prefix (substring value 0 (string-length prefix)))))

(define (string-suffix? suffix value)
  (let ((offset (- (string-length value) (string-length suffix))))
    (and (>= offset 0)
         (string=? suffix (substring value offset (string-length value))))))

(define (ascii-digit? character)
  (and (char>=? character #\0) (char<=? character #\9)))

(define (hex-character? character)
  (or (ascii-digit? character)
      (and (char>=? character #\a) (char<=? character #\f))
      (and (char>=? character #\A) (char<=? character #\F))))

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

(define loopback-prefix "127.0.0.1:")

(define (decimal-string? value)
  (and (> (string-length value) 0)
       (let loop ((index 0))
         (or (= index (string-length value))
             (and (ascii-digit? (string-ref value index))
                  (loop (+ index 1)))))))

(define (ascii-alpha? character)
  (or (and (char>=? character #\a) (char<=? character #\z))
      (and (char>=? character #\A) (char<=? character #\Z))))

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

(define (loopback-port-number value)
  (and (string-prefix? loopback-prefix value)
       (let* ((suffix (substring value (string-length loopback-prefix) (string-length value)))
              (port (and (decimal-string? suffix) (string->number suffix))))
         (and (integer? port) (> port 0) (<= port 65535) port))))

(define (tagged-value? tag value)
  (and (pair? value) (eq? (car value) tag) (pair? (cdr value))))

(define (matches-value? matcher value)
  (let ((kind (car matcher)))
    (cond
      ((eq? kind 'exact)
       (and (tagged-value? 'string value) (string=? (cadr matcher) (cadr value))))
      ((eq? kind 'uuid)
       (and (tagged-value? 'string value) (uuid? (cadr value))))
      ((eq? kind 'nonempty)
       (or (and (tagged-value? 'string value) (> (string-length (cadr value)) 0))
           (and (tagged-value? 'long-string value) (> (cadr value) 0))))
      ((eq? kind 'loopback-port)
       (and (tagged-value? 'string value) (loopback-port-number (cadr value))))
      ((eq? kind 'integer)
       (tagged-value? 'integer value))
      ((eq? kind 'nonnegative-integer)
       (and (tagged-value? 'integer value) (>= (cadr value) 0)))
      ((eq? kind 'positive-integer)
       (and (tagged-value? 'integer value) (> (cadr value) 0)))
      ((eq? kind 'http-status)
       (and (tagged-value? 'integer value) (>= (cadr value) 100) (<= (cadr value) 599)))
      ((eq? kind 'one-of)
       (and (tagged-value? 'string value) (member (cadr value) (cdr matcher))))
      ((eq? kind 'nonempty-array)
       (and (tagged-value? 'array value)
            (pair? (cadr value))
            (every (lambda (item)
                     (or (and (tagged-value? 'string item)
                              (string? (cadr item)))
                         ; The capture deliberately summarizes strings over
                         ; 256 bytes by their positive length.
                         (and (tagged-value? 'long-string item)
                              (integer? (cadr item))
                              (> (cadr item) 0))))
                   (cadr value))))
      (else (error "unknown value matcher" kind)))))

(define (attribute attributes key)
  (let ((entry (assoc key attributes)))
    (and entry (cadr entry))))

(define (attribute-count attributes key)
  (count (lambda (entry) (string=? (car entry) key)) attributes))

(define (attribute-integer attributes key)
  (let ((value (attribute attributes key)))
    (if (tagged-value? 'integer value) (cadr value) 'absent)))

; A profile declares the signals its implementation emits by declaring scopes
; for them. Traces are mandatory; an implementation with no metric or log scopes
; must neither send nor be required to send those signals.
(define (expected-signals expected-metric-scopes expected-log-scopes)
  (append '(traces)
          (if (null? expected-metric-scopes) '() '(metrics))
          (if (null? expected-log-scopes) '() '(logs))))

(define (validate-requests signals requests)
  (for-each
    (lambda (signal)
      (check (> (count (lambda (request) (eq? (field 'signal request) signal)) requests) 0)
             "missing OTLP signal request"))
    signals)
  (for-each
    (lambda (request)
      (check (memq (field 'signal request) signals) "unexpected OTLP signal request"))
    requests)
  (for-each
    (lambda (request)
      (let* ((signal (field 'signal request))
             (headers (field 'headers request))
             (expected-path (cond ((eq? signal 'traces) "/v1/traces")
                                  ((eq? signal 'metrics) "/v1/metrics")
                                  ((eq? signal 'logs) "/v1/logs")
                                  (else ""))))
        (check (string=? (field 'method request) "POST") "OTLP request method is not POST")
        (check (string=? (field 'path request) expected-path) "OTLP request path does not match signal")
        (check (string=? (field 'http-version request) "HTTP/1.1") "unexpected HTTP version")
        (check (> (field 'received-unix-nano request) 0) "invalid receive timestamp")
        (check (> (string-length (field 'remote-address request)) 0) "missing remote address")
        (check (member (field 'content-type request) '("application/x-protobuf" "application/protobuf" "application/json"))
               "unexpected OTLP content type")
        (check (member (field 'content-encoding request) '("" "identity")) "unexpected content encoding")
        (check (> (field 'content-length request) 0) "empty OTLP body")
        (check (= (field 'content-length request) (field 'decoded-length request)) "decoded length mismatch")
        (check (= (count (lambda (header) (string=? (car header) "content-type")) headers) 1)
               "content-type header is not unique")
        (check (= (count (lambda (header) (string=? (car header) "content-length")) headers) 1)
               "content-length header is not unique")
        (let ((host-headers (count (lambda (header) (string=? (car header) "host")) headers))
              (host (find (lambda (header) (string=? (car header) "host")) headers)))
          (check (= host-headers 1) "Host header is missing or duplicated")
          (check (valid-host-field? (cadr host)) "Host header is malformed"))
        (check (<= (count (lambda (header) (string=? (car header) "content-encoding")) headers) 1)
               "content-encoding header is not unique")))
    requests))

; A resource rule is (key matcher) or (key matcher optional). An optional rule
; describes an attribute a detector only contributes in some environments, such
; as a container ID; it must still match wherever it appears.
(define (optional-resource-rule? rule)
  (and (pair? (cdr (cdr rule))) (eq? (third rule) 'optional)))

(define (validate-resources expected expected-schema-url resources)
  (check (> (length resources) 0) "capture contains no resources")
  (for-each
    (lambda (resource)
      (let ((attributes (field 'attributes resource)))
        (check (= (field 'dropped-attributes resource) 0) "resource dropped attributes")
        (check (= (field 'entity-refs resource) 0) "resource has entity references")
        (check (string? (field 'schema-url resource)) "resource schema URL is not a string")
        (if expected-schema-url
            (check (string=? (field 'schema-url resource) expected-schema-url)
                   "resource schema URL changed")
            #t)
        (check (every (lambda (entry)
                        (find (lambda (rule) (string=? (car rule) (car entry))) expected))
                      attributes)
               "unexpected resource attribute")
        (for-each
          (lambda (rule)
            (let ((key (car rule)) (matcher (cadr rule)))
              (if (and (optional-resource-rule? rule)
                       (= (attribute-count attributes key) 0))
                  #t
                  (begin
                    (check (= (attribute-count attributes key) 1)
                           "resource attribute missing or duplicated")
                    (check (matches-value? matcher (attribute attributes key))
                           "resource attribute mismatch")))))
          expected)))
    resources)
  (let ((instance-rule (assoc "service.instance.id" expected)))
    (if instance-rule
        (let ((instance-id (attribute (field 'attributes (car resources)) "service.instance.id")))
          (for-each
            (lambda (resource)
              (check (equal? (attribute (field 'attributes resource) "service.instance.id")
                             instance-id)
                     "service instance ID changed across signals"))
            resources))
        #t)))

; A scope declaration is:
; (alias instrumentation-name version required-keys allowed-keys string-rules integer-keys schema-url)
(define (scope-declaration expected-scopes name)
  (find (lambda (scope) (string=? (cadr scope) name)) expected-scopes))

(define (validate-scopes expected-scopes scopes)
  (for-each
    (lambda (expected)
      (check (> (count (lambda (scope) (string=? (field 'name scope) (cadr expected))) scopes) 0)
             "expected instrumentation scope is missing"))
    expected-scopes)
  (for-each
    (lambda (scope)
      (let ((expected (scope-declaration expected-scopes (field 'name scope))))
        (check expected "unexpected instrumentation scope")
        (check (string=? (field 'version scope) (third expected)) "instrumentation scope version changed")
        (check (null? (field 'attributes scope)) "instrumentation scope attributes changed")
        (check (= (field 'dropped-attributes scope) 0) "instrumentation scope dropped attributes")
        (check (string=? (field 'schema-url scope) (list-ref expected 7))
               "instrumentation scope schema URL changed")))
    scopes))

(define (validate-span-attributes span expected-scopes)
  (let* ((expected (scope-declaration expected-scopes (field 'scope span)))
         (attributes (field 'attributes span))
         (required (list-ref expected 3))
         (allowed (list-ref expected 4))
         (string-rules (list-ref expected 5))
         (integer-keys (list-ref expected 6)))
    (check (every (lambda (entry) (member (car entry) allowed)) attributes) "unexpected span attribute")
    (for-each
      (lambda (entry)
        (begin
          (check (= (attribute-count attributes (car entry)) 1) "span attribute is duplicated")
          (check (valid-attribute-value? (cadr entry)) "span attribute has no value")))
      attributes)
    (for-each
      (lambda (key)
        (let ((value (attribute attributes key))
              (rule (find (lambda (rule) (string=? (car rule) key)) string-rules)))
          (check (= (attribute-count attributes key) 1) "required span attribute missing or duplicated")
          (if (or rule (member key integer-keys))
              #t
              (check (nonempty-string-value? value) "required span string attribute mismatch"))))
      required)
    (for-each
      (lambda (rule)
        (check (matches-value? (cadr rule) (attribute attributes (car rule))) "span string attribute mismatch"))
      string-rules)
    (for-each
      (lambda (key)
        (let ((value (attribute attributes key)))
          (check (and (tagged-value? 'integer value) (>= (cadr value) 0)) "span integer attribute mismatch")))
      integer-keys)
    (let ((host-rule (find (lambda (rule)
                             (and (string=? (car rule) "net.host.name")
                                  (eq? (car (cadr rule)) 'loopback-port)))
                           string-rules)))
      (if host-rule
          (let ((host (attribute attributes "net.host.name"))
                (port (attribute-integer attributes "net.host.port")))
            (check (and (tagged-value? 'string host)
                        (integer? port)
                        (= (loopback-port-number (cadr host)) port))
                   "loopback host and port attributes disagree"))
          #t))))

(define (kind-name value)
  (check (and (integer? value) (>= value 0) (< value 6)) "invalid span kind")
  (list-ref '(unspecified internal server client producer consumer) value))

(define (status-name value)
  (check (and (integer? value) (>= value 0) (< value 3)) "invalid span status")
  (list-ref '(unset ok error) value))

(define (scope-alias expected-scopes name)
  (car (scope-declaration expected-scopes name)))

(define exception-attribute-keys
  '("exception.type" "exception.message" "exception.stacktrace" "exception.escaped"))

(define (nonempty-string-value? value)
  (and (tagged-value? 'string value) (> (string-length (cadr value)) 0)))

(define (validate-exception-attributes attributes)
  (check (= (length attributes) (length exception-attribute-keys))
         "exception attribute set changed")
  (for-each
    (lambda (key)
      (check (= (attribute-count attributes key) 1)
             "exception attribute missing or duplicated"))
    exception-attribute-keys)
  (check (nonempty-string-value? (attribute attributes "exception.type"))
         "exception type is empty")
  (check (nonempty-string-value? (attribute attributes "exception.message"))
         "exception message is empty")
  (let ((stacktrace (attribute attributes "exception.stacktrace")))
    (check (and (tagged-value? 'long-string stacktrace)
                (> (cadr stacktrace) 256))
           "exception stacktrace is missing"))
  (let ((escaped (attribute attributes "exception.escaped")))
    (check (and (tagged-value? 'string escaped)
                (member (cadr escaped) '("True" "False")))
           "exception escaped flag is invalid")))

(define (validate-events mode span)
  (let ((events (field 'events span)))
    (cond
      ((eq? mode 'empty) (check (null? events) "span events changed"))
      ((eq? mode 'exception-on-error)
       (if (null? events)
           #t
           (begin
             (check (= (field 'status-code span) 2) "events occurred on a non-error span")
             (check (> (string-length (field 'status-message span)) 0) "error span has no status message")
             (for-each
               (lambda (event)
                 (check (string=? (field 'name event) "exception") "non-exception span event")
                 (check (and (>= (field 'time event) (field 'start span))
                             (<= (field 'time event) (field 'end span)))
                        "event timestamp is outside its span")
                 (check (= (field 'dropped-attributes event) 0) "event dropped attributes")
                 (validate-exception-attributes (field 'attributes event)))
               events))))
      (else (error "unknown event policy" mode)))))

(define (validate-span-status error-message-policy span)
  (let ((status (status-name (field 'status-code span)))
        (message (field 'status-message span)))
    (check (string? message) "span status message is malformed")
    (if (eq? status 'error)
        (cond ((eq? error-message-policy 'any) #t)
              ((eq? error-message-policy 'empty)
               (check (string=? message "") "error span status message changed"))
              ((eq? error-message-policy 'nonempty)
               (check (> (string-length message) 0) "error span status message is empty"))
              (else (error "unknown error status-message policy" error-message-policy)))
        (check (string=? message "") "non-error span has a status message"))))

(define (validate-spans expected-scopes event-policy expected-flags expected-trace-state error-message-policy spans)
  (let ((event-mode (car event-policy))
        (expected-event-count (cadr event-policy)))
    (check (> (length spans) 0) "capture contains no spans")
    (for-each
      (lambda (span)
        (begin
          (check (valid-hex? (field 'trace-id span) 32) "invalid trace ID")
          (check (valid-hex? (field 'span-id span) 16) "invalid span ID")
          (check (and (string? (field 'name span))
                      (> (string-length (field 'name span)) 0))
                 "span has no name")
          (check (= (field 'id-count span) 1) "duplicate span ID within trace")
          (check (or (string=? (field 'parent-span-id span) "")
                     (valid-hex? (field 'parent-span-id span) 16))
                 "invalid parent span ID")
          (check (field 'parent-valid span) "span parent topology is cyclic")
          (check (valid-trace-state? (field 'trace-state span)) "invalid trace state")
          (if expected-trace-state
              (check (string=? (field 'trace-state span) expected-trace-state) "trace state changed")
              #t)
          (check (and (> (field 'start span) 0) (>= (field 'end span) (field 'start span)))
                 "span timestamps are not ordered")
          (validate-span-status error-message-policy span)
          (check (= (field 'dropped-attributes span) 0) "span dropped attributes")
          (check (= (field 'dropped-events span) 0) "span dropped events")
          (check (= (field 'dropped-links span) 0) "span dropped links")
          (check (null? (field 'links span)) "span links changed")
          (check (member (field 'flags span) expected-flags) "span flags changed")
          (validate-span-attributes span expected-scopes)
          (validate-events event-mode span)))
      spans)
    (check (= expected-event-count
              (sum (map (lambda (span) (length (field 'events span))) spans)))
           "span exception event count changed")))

(define (matches-name? matcher name)
  (cond
    ((eq? (car matcher) 'exact) (string=? name (cadr matcher)))
    ((eq? (car matcher) 'prefix-suffix)
     (and (string-prefix? (cadr matcher) name) (string-suffix? (third matcher) name)))
    (else (error "unknown span name matcher" (car matcher)))))

; HTTP instrumentations name the response status after the semantic convention
; version they target. Which key a profile permits is pinned by its scope
; declaration, so bucketing accepts whichever one the span actually carries.
(define (span-http-status attributes)
  (let ((current (attribute-integer attributes "http.response.status_code")))
    (if (eq? current 'absent)
        (attribute-integer attributes "http.status_code")
        current)))

(define (span-matches-bucket? span bucket expected-scopes spans)
  (and (eq? (scope-alias expected-scopes (field 'scope span)) (list-ref bucket 1))
       (eq? (kind-name (field 'kind span)) (list-ref bucket 2))
       (eq? (status-name (field 'status-code span)) (list-ref bucket 3))
       (matches-name? (list-ref bucket 4) (field 'name span))
       (eq? (field 'parent-class span) (list-ref bucket 5))
       (equal? (span-http-status (field 'attributes span)) (list-ref bucket 6))))

(define (validate-buckets buckets expected-scopes spans)
  (check (= (sum (map car buckets)) (length spans)) "golden span total changed")
  (for-each
    (lambda (bucket)
      (check (= (car bucket)
                (count (lambda (span) (span-matches-bucket? span bucket expected-scopes spans)) spans))
             "golden span bucket count changed"))
    buckets))

(define (validate-contract-buckets buckets expected-scopes spans)
  (check (= (sum (map car buckets))
            (count (lambda (span)
                     (eq? (kind-name (field 'kind span)) 'server))
                   spans))
         "contract span total changed")
  (for-each
    (lambda (bucket)
      (check (= (car bucket)
                (count (lambda (span) (span-matches-bucket? span bucket expected-scopes spans)) spans))
             "contract span bucket count changed"))
    buckets))

(define (signal-scope-declaration expected name)
  (find (lambda (scope) (string=? (car scope) name)) expected))

(define (validate-signal-scopes expected items)
  (for-each
    (lambda (scope)
      (if (or (= (length scope) 3) (list-ref scope 3))
          (check (> (count (lambda (item) (string=? (field 'scope item) (car scope))) items) 0)
                 "expected signal instrumentation scope is missing")
          #t))
    expected)
  (for-each
    (lambda (item)
      (let ((scope (signal-scope-declaration expected (field 'scope item))))
        (check scope "unexpected signal instrumentation scope")
        (check (string=? (field 'scope-version item) (cadr scope))
               "signal instrumentation scope version changed")
        (check (string=? (field 'schema-url item) (third scope))
               "signal instrumentation scope schema URL changed")
        (check (null? (field 'scope-attributes item))
               "signal instrumentation scope attributes changed")
        (check (= (field 'scope-dropped-attributes item) 0)
               "signal instrumentation scope dropped attributes")))
    items))

(define (metric-descriptor metric)
  (list (field 'scope metric)
        (field 'name metric)
        (field 'description metric)
        (field 'unit metric)
        (field 'data-type metric)
        (field 'metadata metric)))

(define (validate-metric-metadata metadata)
  (for-each
    (lambda (entry)
      (begin
        (check (> (string-length (car entry)) 0) "metric metadata has no key")
        (check (valid-attribute-value? (cadr entry)) "metric metadata has no value")
        (check (= (attribute-count metadata (car entry)) 1) "metric metadata is duplicated")))
    metadata))

(define (validate-metric-aggregation expected metric)
  (let ((data-type (field 'data-type metric))
        (temporality (field 'aggregation-temporality metric))
        (monotonic (field 'monotonic metric)))
    (cond
      ((eq? data-type 'sum)
       (begin
         (check (member temporality '(delta cumulative)) "sum aggregation temporality is invalid")
         (check (boolean? monotonic) "sum monotonicity is invalid")))
      ((member data-type '(histogram exponential-histogram))
       (begin
         (check (member temporality '(delta cumulative)) "histogram aggregation temporality is invalid")
         (check (eq? monotonic 'absent) "histogram monotonicity is present")))
      (else
       (begin
         (check (eq? temporality 'absent) "aggregation temporality is present")
         (check (eq? monotonic 'absent) "aggregation monotonicity is present"))))
    (if expected
        (begin
          (if (member data-type '(sum histogram exponential-histogram))
              (check (eq? temporality (car expected)) "metric aggregation temporality changed")
              #t)
          (if (eq? data-type 'sum)
              (check (eq? monotonic (if (member (field 'name metric) (cadr expected)) #t #f))
                     "metric monotonicity changed")
              #t))
        #t)))

(define (same-attribute-keys? attributes expected)
  (and (= (length attributes) (length expected))
       (every (lambda (key) (= (attribute-count attributes key) 1)) expected)))

(define (validate-metric-point-attributes expected-schemas metric)
  (let ((points (field 'point-attributes metric)))
    (check (= (length points) (field 'data-points metric))
           "metric point attribute projection changed")
    (if expected-schemas
        (let ((schema (find (lambda (candidate)
                              (string=? (car candidate) (field 'name metric)))
                            expected-schemas)))
          (check schema "metric point attribute schema is missing")
          (for-each
            (lambda (attributes)
              (check (same-attribute-keys? attributes (cadr schema))
                     "metric point attribute keys changed")
              (for-each
                (lambda (rule)
                  (check (matches-value? (cadr rule) (attribute attributes (car rule)))
                         "metric point attribute value changed"))
                (third schema)))
            points))
        #t)))

(define (validate-metrics expected-scopes expected-descriptors expected-aggregation expected-point-schemas metrics)
  (check (or (null? expected-scopes) (> (length metrics) 0)) "capture contains no metrics")
  (validate-signal-scopes expected-scopes metrics)
  (for-each
    (lambda (metric)
      (check (> (string-length (field 'scope metric)) 0) "metric has no instrumentation scope")
      (check (> (string-length (field 'name metric)) 0) "metric has no name")
      (check (string? (field 'description metric)) "metric description is malformed")
      (check (string? (field 'unit metric)) "metric unit is malformed")
      (validate-metric-metadata (field 'metadata metric))
      (validate-metric-aggregation expected-aggregation metric)
      (check (member (field 'data-type metric)
                     '(gauge sum histogram exponential-histogram summary))
             "metric has no supported data type")
      (check (> (field 'data-points metric) 0) "metric has no data points")
      (check (field 'data-points-valid metric) "metric data point is malformed")
      (validate-metric-point-attributes expected-point-schemas metric)
      (if expected-descriptors
          (check (member (metric-descriptor metric) expected-descriptors)
                 "metric descriptor changed")
          #t))
    metrics)
  (if expected-descriptors
      (for-each
        (lambda (expected)
          (check (> (count (lambda (metric) (equal? (metric-descriptor metric) expected)) metrics) 0)
                 "expected metric descriptor is missing"))
        expected-descriptors)
      #t))

(define (valid-attribute-value? value)
  (and (pair? value)
       (cond
         ((eq? (car value) 'other) #f)
         ((eq? (car value) 'array)
          (and (pair? (cdr value))
               (every valid-attribute-value? (cadr value))))
         ((eq? (car value) 'kvlist)
          (and (pair? (cdr value))
               (every
                 (lambda (entry)
                   (and (pair? entry)
                        (pair? (cdr entry))
                        (string? (car entry))
                        (> (string-length (car entry)) 0)
                        (valid-attribute-value? (cadr entry))
                        (= (attribute-count (cadr value) (car entry)) 1)))
                 (cadr value))))
         (else #t))))

(define valid-log-value? valid-attribute-value?)

(define (validate-log-attributes required attributes)
  (if required (check (> (length attributes) 0) "log has no attributes") #t)
  (for-each
    (lambda (entry)
      (check (> (string-length (car entry)) 0) "log attribute has no key")
      (check (valid-log-value? (cadr entry)) "log attribute has no value")
      (check (= (attribute-count attributes (car entry)) 1) "log attribute is duplicated"))
    attributes))

(define (validate-logs expected-scopes policy logs)
  (check (or (null? expected-scopes) (> (length logs) 0)) "capture contains no logs")
  (validate-signal-scopes expected-scopes logs)
  (if (list-ref policy 5)
      (check (> (count
                  (lambda (log)
                    (and (> (string-length (field 'trace-id log)) 0)
                         (> (string-length (field 'span-id log)) 0)))
                  logs)
                0)
             "capture contains no trace-correlated logs")
      #t)
  (for-each
    (lambda (log)
      (check (member (list-ref policy 4) '(unnamed named any))
             "log event-name policy is invalid")
      (check (cond ((eq? (list-ref policy 4) 'unnamed)
                    (string=? (field 'event-name log) ""))
                   ((eq? (list-ref policy 4) 'named)
                    (> (string-length (field 'event-name log)) 0))
                   ((eq? (list-ref policy 4) 'any) #t)
                   (else #f))
             "log event name changed")
      (let ((severity-required (car policy))
            (attributes-required (cadr policy))
            (timestamps-required (third policy))
            (body-required (list-ref policy 3))
            (trace-id (field 'trace-id log))
            (span-id (field 'span-id log))
            (flags (field 'flags log))
            (time (field 'time log))
            (observed-time (field 'observed-time log)))
        (check (> (string-length (field 'scope log)) 0) "log has no instrumentation scope")
        (check (or (> time 0) (> observed-time 0)) "log has no timestamp")
        (check (or (= time 0) (= observed-time 0) (>= observed-time time))
               "log timestamps are not ordered")
        (if timestamps-required
            (check (and (> time 0) (> observed-time 0)) "log timestamp is unspecified")
            #t)
        (check (and (>= (field 'severity-number log) 0)
                    (<= (field 'severity-number log) 24))
               "log severity number is invalid")
        (if severity-required
            (begin
              (check (> (field 'severity-number log) 0) "log severity number is unspecified")
              (check (> (string-length (field 'severity-text log)) 0) "log severity text is empty"))
            #t)
        (if body-required
            (check (valid-log-value? (field 'body log)) "log body is missing")
            (check (or (equal? (field 'body log) '(other))
                       (valid-log-value? (field 'body log)))
                   "log body is malformed"))
        (validate-log-attributes attributes-required (field 'attributes log))
        (check (= (field 'dropped-attributes log) 0) "log dropped attributes")
        (check (member flags '(0 1)) "log flags are invalid")
        (check (or (not (and (string=? trace-id "") (string=? span-id "")))
                   (= flags 0))
               "log flags require trace context")
        (check (or (and (string=? trace-id "") (string=? span-id ""))
                   (and (valid-hex? trace-id 32) (valid-hex? span-id 16)))
               "log trace context is incomplete")))
    logs))

(define (validate-capture expected-resource-attributes expected-resource-schema-url expected-scopes expected-metric-scopes expected-metric-descriptors expected-metric-aggregation expected-metric-point-schemas expected-log-scopes log-policy event-policy expected-span-flags expected-trace-state error-message-policy expected-span-buckets bucket-validator capture)
  (let ((requests (field 'requests capture))
        (resources (field 'resources capture))
        (scopes (field 'scopes capture))
        (spans (field 'spans capture))
        (metrics (field 'metrics capture))
        (logs (field 'logs capture)))
    (check (field 'json-field-spellings-valid capture)
           "duplicate OTLP JSON field spellings")
    (check (field 'json-collections-valid capture)
           "malformed OTLP JSON collection")
    (check (field 'json-strings-valid capture)
           "malformed OTLP JSON string field")
    (validate-requests (expected-signals expected-metric-scopes expected-log-scopes) requests)
    (validate-resources expected-resource-attributes expected-resource-schema-url resources)
    (validate-scopes expected-scopes scopes)
    (validate-spans expected-scopes event-policy expected-span-flags expected-trace-state error-message-policy spans)
    (bucket-validator expected-span-buckets expected-scopes spans)
    (validate-metrics expected-metric-scopes expected-metric-descriptors expected-metric-aggregation expected-metric-point-schemas metrics)
    (validate-logs expected-log-scopes log-policy logs)
    (display "valid OTLP capture\n")))

(define (otel-validate-contract expected-resource-attributes expected-resource-schema-url expected-scopes expected-metric-scopes expected-log-scopes event-policy expected-span-buckets capture)
  (validate-capture expected-resource-attributes
                    expected-resource-schema-url
                    expected-scopes
                    expected-metric-scopes
                    #f
                    #f
                    #f
                    expected-log-scopes
                    '(#f #f #f #f any #f)
                    event-policy
                    '(0 1 256 257)
                    #f
                    'any
                    expected-span-buckets
                    validate-contract-buckets
                    capture))

(define (otel-validate-exact expected-resource-attributes expected-resource-schema-url expected-scopes expected-metric-scopes expected-metric-descriptors expected-metric-aggregation expected-metric-point-schemas expected-log-scopes log-policy event-policy expected-span-flags expected-trace-state error-message-policy expected-span-buckets capture)
  (validate-capture expected-resource-attributes
                    expected-resource-schema-url
                    expected-scopes
                    expected-metric-scopes
                    expected-metric-descriptors
                    expected-metric-aggregation
                    expected-metric-point-schemas
                    expected-log-scopes
                    log-policy
                    event-policy
                    expected-span-flags
                    expected-trace-state
                    error-message-policy
                    expected-span-buckets
                    validate-contract-buckets
                    capture))
  ))
