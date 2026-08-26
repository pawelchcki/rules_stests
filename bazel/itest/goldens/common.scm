(define-library (otel validation)
  (export otel-validate-contract otel-validate-exact)
  (import (scheme base) (scheme char) (scheme write))
  (begin

(define (contract-error message)
  (error (string-append "OTLP contract assertion: " message)))

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

(define (hex-character? character)
  (or (char-numeric? character)
      (and (char>=? character #\a) (char<=? character #\f))))

(define (valid-hex? value width)
  (and (= (string-length value) width)
       (let loop ((index 0) (nonzero #f))
         (if (= index width)
             nonzero
             (let ((character (string-ref value index)))
               (and (hex-character? character)
                    (loop (+ index 1) (or nonzero (not (char=? character #\0))))))))))

(define (uuid? value)
  (and (= (string-length value) 36)
       (let loop ((index 0))
         (if (= index 36)
             #t
             (and (if (memv index '(8 13 18 23))
                      (char=? (string-ref value index) #\-)
                      (hex-character? (string-ref value index)))
                  (loop (+ index 1)))))))

(define (loopback-port? value)
  (and (string-prefix? "127.0.0.1:" value)
       (> (string-length value) (string-length "127.0.0.1:"))))

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
       (and (tagged-value? 'string value) (loopback-port? (cadr value))))
      ((eq? kind 'integer)
       (tagged-value? 'integer value))
      (else (error "unknown value matcher" kind)))))

(define (attribute attributes key)
  (let ((entry (assoc key attributes)))
    (and entry (cadr entry))))

(define (attribute-count attributes key)
  (count (lambda (entry) (string=? (car entry) key)) attributes))

(define (attribute-integer attributes key)
  (let ((value (attribute attributes key)))
    (if (tagged-value? 'integer value) (cadr value) 'absent)))

(define (validate-requests requests)
  (for-each
    (lambda (signal)
      (check (> (count (lambda (request) (eq? (field 'signal request) signal)) requests) 0)
             "missing OTLP signal request"))
    '(traces metrics logs))
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
               "content-length header is not unique")))
    requests))

(define (validate-resources expected resources)
  (check (> (length resources) 0) "capture contains no resources")
  (for-each
    (lambda (resource)
      (let ((attributes (field 'attributes resource)))
        (check (= (field 'dropped-attributes resource) 0) "resource dropped attributes")
        (check (= (field 'entity-refs resource) 0) "resource has entity references")
        (check (= (length attributes) (length expected)) "resource attribute set changed")
        (for-each
          (lambda (rule)
            (let ((key (car rule)) (matcher (cadr rule)))
              (check (= (attribute-count attributes key) 1) "resource attribute missing or duplicated")
              (check (matches-value? matcher (attribute attributes key)) "resource attribute mismatch")))
          expected)))
    resources))

; A scope declaration is:
; (alias instrumentation-name version required-keys allowed-keys string-rules integer-keys)
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
        (check (= (field 'dropped-attributes scope) 0) "instrumentation scope dropped attributes")))
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
      (lambda (key) (check (= (attribute-count attributes key) 1) "required span attribute missing or duplicated"))
      required)
    (for-each
      (lambda (rule)
        (check (matches-value? (cadr rule) (attribute attributes (car rule))) "span string attribute mismatch"))
      string-rules)
    (for-each
      (lambda (key)
        (let ((value (attribute attributes key)))
          (check (and (tagged-value? 'integer value) (>= (cadr value) 0)) "span integer attribute mismatch")))
      integer-keys)))

(define (kind-name value)
  (check (and (integer? value) (>= value 0) (< value 6)) "invalid span kind")
  (list-ref '(unspecified internal server client producer consumer) value))

(define (status-name value)
  (check (and (integer? value) (>= value 0) (< value 3)) "invalid span status")
  (list-ref '(unset ok error) value))

(define (scope-alias expected-scopes name)
  (car (scope-declaration expected-scopes name)))

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
                 (check (= (field 'dropped-attributes event) 0) "event dropped attributes"))
               events))))
      (else (error "unknown event policy" mode)))))

(define (validate-spans expected-scopes event-policy spans)
  (let ((event-mode (car event-policy))
        (expected-event-count (cadr event-policy)))
    (check (> (length spans) 0) "capture contains no spans")
    (for-each
      (lambda (span)
        (begin
          (check (valid-hex? (field 'trace-id span) 32) "invalid trace ID")
          (check (valid-hex? (field 'span-id span) 16) "invalid span ID")
          (check (= (field 'id-count span) 1) "duplicate span ID within trace")
          (check (or (string=? (field 'parent-span-id span) "")
                     (valid-hex? (field 'parent-span-id span) 16))
                 "invalid parent span ID")
          (check (field 'parent-valid span) "span is its own parent")
          (check (string=? (field 'trace-state span) "") "trace state changed")
          (check (and (> (field 'start span) 0) (>= (field 'end span) (field 'start span)))
                 "span timestamps are not ordered")
          (check (= (field 'dropped-attributes span) 0) "span dropped attributes")
          (check (= (field 'dropped-events span) 0) "span dropped events")
          (check (= (field 'dropped-links span) 0) "span dropped links")
          (check (null? (field 'links span)) "span links changed")
          (check (= (field 'flags span) 256) "span flags changed")
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

(define (span-matches-bucket? span bucket expected-scopes spans)
  (and (eq? (scope-alias expected-scopes (field 'scope span)) (list-ref bucket 1))
       (eq? (kind-name (field 'kind span)) (list-ref bucket 2))
       (eq? (status-name (field 'status-code span)) (list-ref bucket 3))
       (matches-name? (list-ref bucket 4) (field 'name span))
       (eq? (field 'parent-class span) (list-ref bucket 5))
       (equal? (attribute-integer (field 'attributes span) "http.status_code") (list-ref bucket 6))))

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

(define (validate-metrics metrics)
  (check (> (length metrics) 0) "capture contains no metrics")
  (for-each
    (lambda (metric)
      (check (> (string-length (field 'scope metric)) 0) "metric has no instrumentation scope")
      (check (> (string-length (field 'name metric)) 0) "metric has no name")
      (check (member (field 'data-type metric)
                     '(gauge sum histogram exponential-histogram summary))
             "metric has no supported data type")
      (check (> (field 'data-points metric) 0) "metric has no data points"))
    metrics))

(define (valid-log-value? value)
  (and (pair? value)
       (cond
         ((eq? (car value) 'other) #f)
         ((eq? (car value) 'array)
          (and (pair? (cdr value))
               (every valid-log-value? (cadr value))))
         ((eq? (car value) 'kvlist)
          (and (pair? (cdr value))
               (every
                 (lambda (entry)
                   (and (pair? entry)
                        (pair? (cdr entry))
                        (string? (car entry))
                        (> (string-length (car entry)) 0)
                        (valid-log-value? (cadr entry))
                        (= (attribute-count (cadr value) (car entry)) 1)))
                 (cadr value))))
         (else #t))))

(define (validate-log-attributes attributes)
  (check (> (length attributes) 0) "log has no attributes")
  (for-each
    (lambda (entry)
      (check (> (string-length (car entry)) 0) "log attribute has no key")
      (check (valid-log-value? (cadr entry)) "log attribute has no value")
      (check (= (attribute-count attributes (car entry)) 1) "log attribute is duplicated"))
    attributes))

(define (validate-logs logs)
  (check (> (length logs) 0) "capture contains no logs")
  (for-each
    (lambda (log)
      (let ((trace-id (field 'trace-id log))
            (span-id (field 'span-id log))
            (time (field 'time log))
            (observed-time (field 'observed-time log)))
        (check (> (string-length (field 'scope log)) 0) "log has no instrumentation scope")
        (check (and (> time 0) (>= observed-time time)) "log timestamps are not ordered")
        (check (and (> (field 'severity-number log) 0)
                    (<= (field 'severity-number log) 24))
               "log severity number is invalid")
        (check (> (string-length (field 'severity-text log)) 0) "log severity text is empty")
        (check (valid-log-value? (field 'body log)) "log body is missing")
        (validate-log-attributes (field 'attributes log))
        (check (= (field 'dropped-attributes log) 0) "log dropped attributes")
        (check (member (field 'flags log) '(0 1 256 257)) "log flags are invalid")
        (check (or (and (string=? trace-id "") (string=? span-id ""))
                   (and (valid-hex? trace-id 32) (valid-hex? span-id 16)))
               "log trace context is incomplete")))
    logs))

(define (validate-capture expected-resource-attributes expected-scopes event-policy expected-span-buckets bucket-validator capture)
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
    (validate-requests requests)
    (validate-resources expected-resource-attributes resources)
    (validate-scopes expected-scopes scopes)
    (validate-spans expected-scopes event-policy spans)
    (bucket-validator expected-span-buckets expected-scopes spans)
    (validate-metrics metrics)
    (validate-logs logs)
    (display "valid OTLP capture\n")))

(define (otel-validate-contract expected-resource-attributes expected-scopes event-policy expected-span-buckets capture)
  (validate-capture expected-resource-attributes
                    expected-scopes
                    event-policy
                    expected-span-buckets
                    validate-contract-buckets
                    capture))

(define (otel-validate-exact expected-resource-attributes expected-scopes event-policy expected-span-buckets capture)
  (validate-capture expected-resource-attributes
                    expected-scopes
                    event-policy
                    expected-span-buckets
                    validate-buckets
                    capture))
  ))
