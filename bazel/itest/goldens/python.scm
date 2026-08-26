(define-library (otel profile python-auto-v0-65b0)
  (export python-service-resource-attributes
          python-sqlite-scope)
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
  ))
