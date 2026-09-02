(define-library (otel runtime python-auto-v0-65b0)
  (export python-service-resource-attributes
          python-schema-url
          python-sqlite-scope
          python-sqlalchemy-scope
          python-logging-scope
          python-system-metrics-scope
          python-system-metric-descriptors
          python-system-metric-point-schemas
          python-metric-aggregation
          python-http-scope
          python-runtime-contract)
  (import (scheme base) (otel declarations))
  (begin

(define python-resource-attributes
  '(("telemetry.sdk.language" (exact "python"))
    ("telemetry.sdk.name" (exact "opentelemetry"))
    ("telemetry.sdk.version" (exact "1.44.0"))
    ("service.instance.id" (uuid))
    ("telemetry.auto.version" (exact "0.65b0"))))

(define python-schema-url "https://opentelemetry.io/schemas/1.11.0")

(define python-runtime-contract
  (list (span-flags '(256))
        (trace-state "")
        (resource-schema-url "")))

(define (python-service-resource-attributes service-name)
  (append python-resource-attributes
          (list (list "service.name" (list 'exact service-name)))))

(define python-sqlite-scope
  (span-scope
    (alias 'sqlite)
    (instrumentation "opentelemetry.instrumentation.sqlite3")
    (version "0.65b0")
    (required-keys "db.system" "db.statement")
    (allowed-keys "db.system" "db.statement")
    (string-rules '("db.system" (exact "sqlite")) '("db.statement" (nonempty)))
    (integer-keys)
    (schema-url python-schema-url)))

(define python-sqlalchemy-scope
  (span-scope
    (alias 'sqlalchemy)
    (instrumentation "opentelemetry.instrumentation.sqlalchemy")
    (version "0.65b0")
    (required-keys "db.name" "db.system")
    (allowed-keys "db.name" "db.system" "db.operation" "db.statement")
    (string-rules '("db.system" (exact "sqlite")))
    (integer-keys)
    (schema-url python-schema-url)))

; Metric and log scope declarations are
; (instrumentation-name version schema-url [required?]).
(define python-logging-scope
  (log-scope (instrumentation "opentelemetry.instrumentation.logging")
             (version "") (schema-url "")))

(define python-system-metrics-scope
  (metric-scope (instrumentation "opentelemetry.instrumentation.system_metrics")
                (version "0.65b0") (schema-url python-schema-url)))

; Descriptor fields are scope, name, description, unit, data type, and metadata.
(define python-system-metric-descriptors
  (map
    (lambda (descriptor)
      (metric-descriptor
        (instrumentation (list-ref descriptor 0))
        (metric (list-ref descriptor 1))
        (description (list-ref descriptor 2))
        (unit (list-ref descriptor 3))
        (data-type (list-ref descriptor 4))
        (metadata)))
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
    ("opentelemetry.instrumentation.system_metrics" "system.thread_count" "System active threads count" "" gauge ()))))

; Point schemas are metric name, the exact attribute keys, and value matchers.
(define python-system-metric-point-schemas
  (map
    (lambda (point)
      (point-schema
        (metric (list-ref point 0))
        (apply attribute-keys (list-ref point 1))
        (apply value-rules (list-ref point 2))))
    '(("cpython.gc.collected_objects" ("cpython.gc.generation" "generation") (("cpython.gc.generation" (nonnegative-integer)) ("generation" (one-of "0" "1" "2"))))
    ("cpython.gc.collections" ("cpython.gc.generation" "generation") (("cpython.gc.generation" (nonnegative-integer)) ("generation" (one-of "0" "1" "2"))))
    ("cpython.gc.uncollectable_objects" ("cpython.gc.generation" "generation") (("cpython.gc.generation" (nonnegative-integer)) ("generation" (one-of "0" "1" "2"))))
    ("process.context_switches" ("type") (("type" (one-of "involuntary" "voluntary"))))
    ("process.cpu.time" ("type") (("type" (one-of "system" "user"))))
    ("process.cpu.utilization" () ())
    ("process.disk.io" ("direction") (("direction" (one-of "read" "write"))))
    ("process.memory.usage" () ())
    ("process.memory.virtual" () ())
    ("process.open_file_descriptor.count" () ())
    ("process.runtime.cpython.context_switches" ("type") (("type" (one-of "involuntary" "voluntary"))))
    ("process.runtime.cpython.cpu.utilization" () ())
    ("process.runtime.cpython.cpu_time" ("type") (("type" (one-of "system" "user"))))
    ("process.runtime.cpython.gc_count" ("count") (("count" (one-of "0" "1" "2"))))
    ("process.runtime.cpython.memory" ("type") (("type" (one-of "rss" "vms"))))
    ("process.runtime.cpython.thread_count" () ())
    ("process.thread.count" () ())
    ("system.cpu.time" ("cpu" "state") (("cpu" (nonnegative-integer)) ("state" (one-of "idle" "iowait" "irq" "nice" "softirq" "steal" "system" "user"))))
    ("system.cpu.utilization" ("cpu" "state") (("cpu" (nonnegative-integer)) ("state" (one-of "idle" "iowait" "irq" "nice" "softirq" "steal" "system" "user"))))
    ("system.disk.io" ("device" "direction") (("device" (nonempty)) ("direction" (one-of "read" "write"))))
    ("system.disk.operations" ("device" "direction") (("device" (nonempty)) ("direction" (one-of "read" "write"))))
    ("system.disk.time" ("device" "direction") (("device" (nonempty)) ("direction" (one-of "read" "write"))))
    ("system.memory.usage" ("state") (("state" (one-of "cached" "free" "used"))))
    ("system.memory.utilization" ("state") (("state" (one-of "cached" "free" "used"))))
    ("system.network.connections" ("family" "protocol" "state" "type") (("family" (nonnegative-integer)) ("protocol" (nonempty)) ("state" (nonempty)) ("type" (nonnegative-integer))))
    ("system.network.dropped_packets" ("device" "direction") (("device" (nonempty)) ("direction" (one-of "receive" "transmit"))))
    ("system.network.errors" ("device" "direction") (("device" (nonempty)) ("direction" (one-of "receive" "transmit"))))
    ("system.network.io" ("device" "direction") (("device" (nonempty)) ("direction" (one-of "receive" "transmit"))))
    ("system.network.packets" ("device" "direction") (("device" (nonempty)) ("direction" (one-of "receive" "transmit"))))
    ("system.swap.usage" ("state") (("state" (one-of "free" "used"))))
    ("system.swap.utilization" ("state") (("state" (one-of "free" "used"))))
    ("system.thread_count" () ()))))

; Python instrumentation in this profile exports cumulative aggregations.
; The second field pins the subset of sums whose monotonic bit is set.
(define python-metric-aggregation
  (metric-aggregation
    (temporality 'cumulative)
    (monotonic-sums
     "cpython.gc.collected_objects"
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

(define (python-http-scope scope-alias instrumentation-name keys rules integers)
  (span-scope
    (alias scope-alias)
    (instrumentation instrumentation-name)
    (version "0.65b0")
    (apply required-keys keys)
    (apply allowed-keys keys)
    (apply string-rules rules)
    (apply integer-keys integers)
    (schema-url python-schema-url)))
  ))
