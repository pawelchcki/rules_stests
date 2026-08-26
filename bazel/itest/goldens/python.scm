(define-library (otel profile python-auto-v0-65b0)
  (export python-service-resource-attributes
          python-schema-url
          python-sqlite-scope
          python-sqlalchemy-scope
          python-logging-scope
          python-system-metrics-scope
          python-system-metric-descriptors
          python-metric-aggregation
          python-http-scope
          python-database-bucket
          python-profile-shape
          python-counted-operation-buckets
          expected-span-flags
          expected-log-severity-required)
  (import (scheme base))
  (begin

(define python-resource-attributes
  '(("telemetry.sdk.language" (exact "python"))
    ("telemetry.sdk.name" (exact "opentelemetry"))
    ("telemetry.sdk.version" (exact "1.44.0"))
    ("service.instance.id" (uuid))
    ("telemetry.auto.version" (exact "0.65b0"))))

(define python-schema-url "https://opentelemetry.io/schemas/1.11.0")

(define expected-span-flags '(256))
(define expected-log-severity-required #t)

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
    ()
    "https://opentelemetry.io/schemas/1.11.0"))

(define python-sqlalchemy-scope
  '(sqlalchemy
    "opentelemetry.instrumentation.sqlalchemy"
    "0.65b0"
    ("db.name" "db.system")
    ("db.name" "db.system" "db.operation" "db.statement")
    (("db.system" (exact "sqlite")))
    ()
    "https://opentelemetry.io/schemas/1.11.0"))

; Metric and log scope declarations are
; (instrumentation-name version schema-url [required?]).
(define python-logging-scope
  '("opentelemetry.instrumentation.logging" "" ""))

(define python-system-metrics-scope
  '("opentelemetry.instrumentation.system_metrics"
    "0.65b0"
    "https://opentelemetry.io/schemas/1.11.0"))

; Descriptor fields are scope, name, description, unit, data type, and metadata.
(define python-system-metric-descriptors
  '(("opentelemetry.instrumentation.system_metrics" "cpython.gc.collected_objects" "The total number of objects collected since interpreter start." "{object}" sum ())
    ("opentelemetry.instrumentation.system_metrics" "cpython.gc.collections" "The number of times a generation was collected since interpreter start." "{collection}" sum ())
    ("opentelemetry.instrumentation.system_metrics" "cpython.gc.uncollectable_objects" "The total number of uncollectable objects found since interpreter start." "{object}" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.context_switches" "Number of times the process has been context switched." "" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.cpu.time" "Total CPU seconds broken down by different states." "s" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.cpu.utilization" "Difference in process.cpu.time since the last measurement, divided by the elapsed time and number of CPUs available to the process." "1" gauge ())
    ("opentelemetry.instrumentation.system_metrics" "process.disk.io" "Disk bytes transferred for the process." "By" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.memory.usage" "The amount of physical memory in use." "By" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.memory.virtual" "The amount of committed virtual memory." "By" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.open_file_descriptor.count" "Number of file descriptors in use by the process." "" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.runtime.cpython.context_switches" "Runtime context switches" "switches" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.runtime.cpython.cpu.utilization" "Runtime CPU utilization" "1" gauge ())
    ("opentelemetry.instrumentation.system_metrics" "process.runtime.cpython.cpu_time" "Runtime cpython CPU time" "s" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.runtime.cpython.gc_count" "Runtime cpython GC count" "By" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.runtime.cpython.memory" "Runtime cpython memory" "By" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.runtime.cpython.thread_count" "Runtime active threads count" "" sum ())
    ("opentelemetry.instrumentation.system_metrics" "process.thread.count" "Process threads count." "" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.cpu.time" "System CPU time" "s" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.cpu.utilization" "System CPU utilization" "1" gauge ())
    ("opentelemetry.instrumentation.system_metrics" "system.disk.io" "System disk IO" "By" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.disk.operations" "System disk operations" "operations" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.disk.time" "System disk time" "s" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.memory.usage" "System memory usage" "By" gauge ())
    ("opentelemetry.instrumentation.system_metrics" "system.memory.utilization" "System memory utilization" "1" gauge ())
    ("opentelemetry.instrumentation.system_metrics" "system.network.connections" "System network connections" "connections" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.network.dropped_packets" "System network dropped_packets" "packets" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.network.errors" "System network errors" "errors" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.network.io" "System network io" "By" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.network.packets" "System network packets" "packets" sum ())
    ("opentelemetry.instrumentation.system_metrics" "system.swap.usage" "System swap usage" "pages" gauge ())
    ("opentelemetry.instrumentation.system_metrics" "system.swap.utilization" "System swap utilization" "1" gauge ())
    ("opentelemetry.instrumentation.system_metrics" "system.thread_count" "System active threads count" "" gauge ())))

; Python instrumentation in this profile exports cumulative aggregations.
; The second field pins the subset of sums whose monotonic bit is set.
(define python-metric-aggregation
  '(cumulative
    ("cpython.gc.collected_objects"
     "cpython.gc.collections"
     "cpython.gc.uncollectable_objects"
     "process.context_switches"
     "process.cpu.time"
     "process.disk.io"
     "process.runtime.cpython.context_switches"
     "process.runtime.cpython.cpu_time"
     "process.runtime.cpython.gc_count"
     "system.cpu.time"
     "system.disk.io"
     "system.disk.operations"
     "system.disk.time"
     "system.network.dropped_packets"
     "system.network.errors"
     "system.network.io"
     "system.network.packets")))

(define (python-http-scope alias instrumentation-name attributes string-rules integer-keys)
  (list alias
        instrumentation-name
        "0.65b0"
        attributes
        attributes
        string-rules
        integer-keys
        python-schema-url))

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
