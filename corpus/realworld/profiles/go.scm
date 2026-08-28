(define-library (otel profile go-otelbuild-v0)
  (export go-service-resource-attributes
          go-schema-url
          go-instrumentation-version
          go-http-scope
          go-database-sql-scope
          go-runtime-metrics-scope
          go-runtime-metric-descriptors
          go-runtime-metric-point-schemas
          go-metric-aggregation
          go-database-bucket
          go-profile-shape
          expected-span-flags
          expected-trace-state
          expected-resource-schema-url)
  (import (scheme base))
  (begin

; Shared runtime layer for binaries built with
; open-telemetry/opentelemetry-go-compile-instrumentation. The tool links the
; instrumentation packages into the binary, so a pinned tool version pins the
; SDK version, the instrumentation scope names, and the scope version string.

; The tool builds its instrumentation packages without a version stamp, so
; every scope it installs reports this literal version.
(define go-instrumentation-version "dev")

; None of the tool's instrumentation packages declare a schema URL.
(define go-schema-url "")

; Resource attributes come from the OpenTelemetry Go SDK's default detectors,
; which read the host, the OS, and the running process. This build replaces the
; SDK's own resource with the detected one, so no telemetry.sdk.* attribute
; survives; only the constant values are pinned exactly, and the
; environment-derived ones are pinned by shape.
(define go-resource-attributes
  '(; The container detector contributes an ID only where the process's cgroup
    ; identifies one, which differs between a container runtime and a build
    ; sandbox, so it is permitted rather than required.
    ("container.id" (nonempty) optional)
    ("host.name" (nonempty))
    ("os.type" (exact "linux"))
    ("os.description" (nonempty))
    ("process.pid" (positive-integer))
    ("process.owner" (nonempty))
    ("process.command_args" (nonempty-array))
    ("process.executable.name" (nonempty))
    ("process.executable.path" (nonempty))
    ("process.runtime.name" (exact "go"))
    ("process.runtime.version" (nonempty))
    ("process.runtime.description" (nonempty))))

(define expected-span-flags '(257))
(define expected-trace-state "")
; The detected resource carries the semantic-convention version the pinned SDK
; was built against.
(define expected-resource-schema-url "https://opentelemetry.io/schemas/1.43.0")

(define (go-service-resource-attributes service-name)
  (append go-resource-attributes
          (list (list "service.name" (list 'exact service-name)))))

; Span scope declarations are
; (alias instrumentation-name version required-keys allowed-keys string-rules
;  integer-keys schema-url).
(define (go-http-scope alias required-keys allowed-keys string-rules integer-keys)
  (list alias
        "go.opentelemetry.io/otelc/instrumentation/net/http"
        go-instrumentation-version
        required-keys
        allowed-keys
        string-rules
        integer-keys
        go-schema-url))

; The tool instruments database/sql rather than the ORM above it, so the SQLite
; connection is described with the client conventions of a networked database.
(define go-database-sql-scope
  '(database-sql
    "go.opentelemetry.io/otelc/instrumentation/database/sql"
    "dev"
    ("db.system.name" "db.operation.name" "db.query.text" "db.namespace" "server.address" "network.transport")
    ("db.system.name" "db.operation.name" "db.query.text" "db.namespace" "server.address" "network.transport")
    (("db.system.name" (exact "sqlite"))
     ("db.operation.name" (nonempty))
     ("db.query.text" (nonempty))
     ("db.namespace" (nonempty))
     ("server.address" (exact "sqlite3"))
     ("network.transport" (exact "tcp")))
    ()
    ""))

; Metric and log scope declarations are
; (instrumentation-name version schema-url [required?]).
(define go-runtime-metrics-scope
  '("go.opentelemetry.io/contrib/instrumentation/runtime" "0.70.0" ""))

; Descriptor fields are scope, name, description, unit, data type, and metadata.
(define go-runtime-metric-descriptors
  '(("go.opentelemetry.io/contrib/instrumentation/runtime" "go.memory.used" "Memory used by the Go runtime." "By" sum ())
    ("go.opentelemetry.io/contrib/instrumentation/runtime" "go.memory.allocated" "Memory allocated to the heap by the application." "By" sum ())
    ("go.opentelemetry.io/contrib/instrumentation/runtime" "go.memory.allocations" "Count of allocations to the heap by the application." "{allocation}" sum ())
    ("go.opentelemetry.io/contrib/instrumentation/runtime" "go.memory.gc.goal" "Heap size target for the end of the GC cycle." "By" sum ())
    ("go.opentelemetry.io/contrib/instrumentation/runtime" "go.goroutine.count" "Count of live goroutines." "{goroutine}" sum ())
    ("go.opentelemetry.io/contrib/instrumentation/runtime" "go.processor.limit" "The number of OS threads that can execute user-level Go code simultaneously." "{thread}" sum ())
    ("go.opentelemetry.io/contrib/instrumentation/runtime" "go.config.gogc" "Heap size target percentage configured by the user, otherwise 100." "%" sum ())))

; Point schemas are metric name, the exact attribute keys, and value matchers.
(define go-runtime-metric-point-schemas
  '(("go.memory.used" ("go.memory.type") (("go.memory.type" (one-of "other" "stack"))))
    ("go.memory.allocated" () ())
    ("go.memory.allocations" () ())
    ("go.memory.gc.goal" () ())
    ("go.goroutine.count" () ())
    ("go.processor.limit" () ())
    ("go.config.gogc" () ())))

; The Go SDK's default reader exports cumulative aggregations. The second field
; pins the subset of sums whose monotonic bit is set.
(define go-metric-aggregation
  '(cumulative
    ("go.memory.allocated"
     "go.memory.allocations")))

(define (go-database-bucket count scope status matcher parent)
  (list count scope 'client status matcher parent 'absent))

(define (go-profile-shape scenario shapes)
  (let ((entry (assq scenario shapes)))
    (if entry (cdr entry) (error "missing implementation shape" scenario))))
  ))
