(define-library (otel profile python-auto-v0-65b0)
  (export python-service-resource-attributes
          python-sqlite-scope
          python-sqlalchemy-scope
          python-logging-scope
          python-system-metrics-scope
          python-http-scope
          python-database-bucket
          python-profile-shape
          python-counted-operation-buckets)
  (import (scheme base))
  (begin

(define python-resource-attributes
  '(("telemetry.sdk.language" (exact "python"))
    ("telemetry.sdk.name" (exact "opentelemetry"))
    ("telemetry.sdk.version" (exact "1.44.0"))
    ("service.instance.id" (uuid))
    ("telemetry.auto.version" (exact "0.65b0"))))

(define (python-service-resource-attributes service-name)
  (append python-resource-attributes
          (list (list "service.name" (list 'exact service-name)))))

(define python-sqlite-scope
  '(sqlite
    "opentelemetry.instrumentation.sqlite3"
    "0.65b0"
    ("db.system" "db.statement")
    ("db.system" "db.statement")
    (("db.system" (exact "sqlite")) ("db.statement" (nonempty)))
    ()))

(define python-sqlalchemy-scope
  '(sqlalchemy
    "opentelemetry.instrumentation.sqlalchemy"
    "0.65b0"
    ("db.name" "db.system")
    ("db.name" "db.system" "db.operation" "db.statement")
    (("db.system" (exact "sqlite")))
    ()))

; Metric and log scope declarations are (instrumentation-name version [required?]).
(define python-logging-scope
  '("opentelemetry.instrumentation.logging" ""))

(define python-system-metrics-scope
  '("opentelemetry.instrumentation.system_metrics" "0.65b0"))

(define (python-http-scope alias instrumentation-name attributes string-rules integer-keys)
  (list alias
        instrumentation-name
        "0.65b0"
        attributes
        attributes
        string-rules
        integer-keys))

(define (python-database-bucket count scope status matcher parent)
  (list count scope 'client status matcher parent 'absent))

(define (python-profile-shape scenario shapes)
  (let ((entry (assq scenario shapes)))
    (if entry (cdr entry) (error "missing implementation shape" scenario))))

(define (python-counted-operation-buckets counts operations make-bucket)
  (cond
    ((and (null? counts) (null? operations)) '())
    ((or (null? counts) (null? operations)) (error "operation count columns changed"))
    ((= (car counts) 0)
     (python-counted-operation-buckets (cdr counts) (cdr operations) make-bucket))
    (else
     (cons (make-bucket (car counts) (car operations))
           (python-counted-operation-buckets (cdr counts) (cdr operations) make-bucket)))))
  ))
