# rules_stests corpus

This repository contains portable, real-world application fixtures for
[`rules_itest`](https://github.com/hermeticbuild/rules_itest). The fixtures are
SQLite-backed Python APIs. Both are published in the shared
`ghcr.io/pawelchcki/rules_stest_apps` package under app-prefixed tags.

Each image is Linux/amd64, has a `FROM scratch` runtime, and contains exactly
one non-empty, gzip-compressed OCI payload layer. The payload includes a
uv-managed Python runtime, all locked wheels, the application source, a static
launcher, glibc for container execution, and an empty writable `/data`
directory. `uv` itself is only used while building. Exporters may retain
Docker's canonical empty layer; the extractor verifies and ignores it.

The same artifact supports two execution modes:

```text
container runtime -> /opt/app/bin/app run
unpacked layer    -> <rootfs>/opt/app/bin/app run
```

The unpacked mode needs a Linux/amd64 host with a compatible glibc, but does
not need Python, uv, a virtual environment, or a container runtime.

## Repository structure

```text
corpus/       standard registry, proof rules, profiles, and scenario shapes
rules/        reusable Starlark: realworld_hurl_test_suite, oci_rootfs
bazel/itest/  the harness: Go drivers, the Rust otel_sink, shared services
bazel/itest/apps/  this repo's own reference services (aiohttp, Django Ninja)
```

`corpus/` and `rules/` carry no dependency on `bazel/itest/apps`, so an
alternative OpenTelemetry implementation can run these testcases unchanged.
Corpus filenames mirror their Scheme library names: `corpus/otel/validation.scm`
defines `(otel validation)`, `corpus/realworld/profiles/<profile>.scm` defines
`(realworld profile <profile>)`. See [`corpus/README.md`](corpus/README.md).

## External use

Depend on this module and load the macro from `@rules_stests_corpus//rules`:

```starlark
# MODULE.bazel
bazel_dep(name = "rules_stests_corpus", version = "...")
```

```starlark
# BUILD.bazel
load("@rules_stests_corpus//rules:hurl_test.bzl", "realworld_hurl_test_suite")

realworld_hurl_test_suite(
    name = "my_otel",
    service = ":my_service",
    otel_profile = "@rules_stests_corpus//corpus:go_gin_profile",
    otel_sink = "@rules_stests_corpus//bazel/itest:otel_sink_service",
)
```

The offered `otel_sink_service`, Hurl rootfs, and driver all come from the
module. OpenTelemetry configuration is one `otel_profile` target: its provider
owns the implementation layers, normalized proof plan, signals, and exact
scenario-shape mapping.

## Bazel integration tests

OCI manifest digests are recorded in `bazel/oci_images.lock.bzl` and pulled by
`rules_oci`. A small Go executable verifies the manifest and layer digests,
rejects unsafe tar entries, and materializes an immutable rootfs as a Bazel
directory artifact. Extraction is a normal cacheable action keyed by the OCI
layout and extractor: it runs once, can live in a local or remote action cache,
and is shared by parallel tests. Local sandboxes reference the cached tree
through runfiles instead of copying or unpacking it into every `TEST_TMPDIR`.

Each app payload contains a ready, current-schema SQLite template. Only
writable state is private per service. The launcher first asks the filesystem for a reflink
copy-on-write clone of that template and falls back to copying the small seed
when reflinks are unavailable; the application rootfs remains immutable and
shared even when it is gigabytes large. `rules_itest` starts the service on an
assigned port, waits for `/api/tags`, and executes an API probe; migrations and
rootfs extraction are not on the test startup path. Bazel invokes Python
through the rootfs's bundled glibc loader and library path rather than the host
runtime.

The contract tests pin the upstream RealWorld API specs at commit
`5d510ce6ec41bb97723e92fbd8d3e3458a381c09`. They also pin the official Hurl
8.0.1 Linux/amd64 image by manifest digest. Bazel downloads both artifacts,
verifies their digests, overlays Hurl's OCI layers once as `:hurl_rootfs`, and
launches Hurl through the cached tree's musl loader. The test host therefore
needs no Hurl, Bruno, Node.js, Python, container runtime, or host shared
libraries.

The Hurl package is independent of `rules_itest`: point it at any running
RealWorld implementation by URL. It bundles the full upstream suite and can
run several explicitly selected files concurrently; `--jobs` controls that
command-line concurrency.

```bash
bazel run //bazel/itest:realworld_hurl -- \
  --base-url=http://127.0.0.1:8000 \
  --jobs=8

# Equivalent host/port form:
bazel run //bazel/itest:realworld_hurl -- --host=127.0.0.1 --port=8000
```

Pass one or more `.hurl` paths after the flags to run a selected subset. When
used by `service_test`, the same executable discovers the assigned service port
from `ASSIGNED_PORTS`; no endpoint-specific code is compiled into the package.
Any `rules_itest` service can use the reusable sharding macro:

```starlark
load("//rules:hurl_test.bzl", "realworld_hurl_test_suite")

realworld_hurl_test_suite(
    name = "my_app_contract_test",
    service = ":my_app_service",
)
```

The macro creates one independently schedulable Bazel test for each of the 13
upstream Hurl files and keeps the original name as an aggregate `test_suite`.
Across aiohttp and Django Ninja, with and without telemetry, this gives 52
topical contract tests. Every shard runs one Hurl job, avoiding a single huge
trace and allowing Bazel to parallelize validation safely.

The OpenTelemetry variants add the official, digest-locked Python
auto-instrumentation OCI rootfs to `PYTHONPATH`; no package installation or
image rebuild occurs. Its `sitecustomize.py` hook activates instrumentation at
Python startup. Traces, metrics, and logs are sent over OTLP/HTTP protobuf to
`:otel_sink_service`.

The sink is a Linux `#![no_std]` Rust binary built with `rules_rs` 0.0.102 and
Rust 1.97.1. It uses `alloc` with a bounded static `emballoc` heap and `rustix`
for networking, files, time, and process syscalls; it has no Rust standard
library or libc dependency. `POST /v1/traces`, `/v1/metrics`, and `/v1/logs`
accept OTLP protobuf, and the same endpoints also preserve OTLP JSON. Each
payload is retained with its signal, receive timestamp, remote address, HTTP
request line, content metadata, and all incoming headers. `GET /stats` exposes
request/span counters plus validator duration and process peak RSS. `GET /dump`
is the JSON snapshot boundary: it atomically freezes the live records, writes
the complete decoded document as pretty JSON, and returns the same bytes.
Later telemetry remains live for the next snapshot; `/validate` and
`/candidate` continue to consume the frozen records that produced the dump.
`GET /dump.scm` freezes and returns the same capture model as a canonical
S-expression, while `POST /validate` evaluates a Scheme body against it with a
256 KiB source limit. Validation stats retain compiler and VM call usage on
both success and failure. `POST /reset` clears every signal, while
`POST /reset/traces` creates a trace-only boundary without discarding startup
metrics and logs.
`GET /healthz` is the service health check. Each OTEL contract test waits for
startup traces to become quiescent, clears those traces, runs exactly one Hurl
topic, waits for its trace counts to become quiescent, and validates the
decoded traces, metrics, logs, request metadata, and HTTP headers. It does not
infer success from console logs. The sink and instrumented Python servers use
the `rules_itest` reuse-port handoff, so parallel shards retain their reserved
ports until each service has bound them.

The sink keeps its no-std entry point deliberately thin. `runtime` owns the
allocator, ELF entry point, panic path, and compiler shims; `platform` contains
raw console I/O; `server` routes requests; `http`, `otlp`, `storage`, and
`stats` each own one boundary; `data` contains the shared serialized model;
`trace_forest` canonicalizes protobuf, JSON, and mixed span captures; and
`scheme`, `validation`, and `proto` remain independent domain modules.

The snapshot is checked by Stak Scheme 0.12.23 inside the same no-std Rust
binary. Bazel pins the Stak crates, compiler bytecode, and prelude. A shape is
ordinary Scheme source: the embedded compiler reads it in memory for each
validation and immediately executes the resulting bytecode, so there is no
shape compilation action, host Scheme installation, subprocess, or magic
environment variable. The evaluator uses in-memory input/output and void file,
process, and clock implementations, plus fixed VM heaps, separate compiler and
runtime procedure-call budgets, and 1 MiB stdout/stderr caps, keeping shape
execution sandboxed. The sink can therefore also be run as a standalone OTLP
validator by ingesting telemetry and posting a rule to `/validate`.

The rules are real R7RS libraries, not load-order-dependent source fragments.
The test driver includes repeatable `--otel-library` files, turns repeatable
dot-separated `--otel-import` names into Scheme imports, then evaluates the
explicit `--otel-program`. A standalone client can equivalently post one
self-contained source bundle containing `define-library` declarations and a
program import to `/validate`.

The libraries deliberately separate five layers:

- `(otel validation)` checks transport and OTLP integrity: request metadata,
  exact resources and scopes, IDs, timestamp ordering, parents, events, links,
  dropped fields, flags, attributes, metric types and nonempty data points, and
  log timestamps, severity, body, attributes, flags, and trace context.
- `(realworld scenarios)` is one portable workload table. Its rows record only
  HTTP method, canonical route, status, and exact observation count. Every
  implementation selects a row by the injected `scenario-name` symbol.
- `(otel profile python-auto-v0-65b0)` holds facts shared by the current Python
  agent independently of the web framework. A Go or custom Python tracer can
  supply an equivalent language/runtime library without changing the workload.
- `(realworld profile <implementation>)` preserves implementation-wide behavior:
  resource identity, instrumentation libraries and versions, attribute schemas,
  per-scenario event policy, and server-span name rendering.
- `(otel trace-shape)` defines unordered hierarchical trace matchers, while each
  `(realworld shape <implementation> <scenario>)` library pins complete trace
  topology, scope, kind, status, name, and HTTP status without volatile IDs or
  timestamps. Repeated equivalent traces and children use `repeat`.

For example, the shared articles contract says:

```scheme
(define-library (realworld scenarios)
  (export expected-http-requests-for)
  (import (scheme base))
  (begin
    (define scenario-shapes
      '((articles
          (1 "DELETE" "/api/articles/{slug}" 204)
          (6 "GET" "/api/articles" 200))
        ...))
    (define (expected-http-requests-for scenario)
      (cdr (assq scenario scenario-shapes)))))
```

The aiohttp Python profile renders the canonical route as
`DELETE /api/articles/{slug}` in scope `http`; the Django Python profile
renders it as `DELETE api/articles/<slug>` in scope `django`. Both consume that
same portable row and the neutral Python helpers. Only their genuine tracing
differences remain in their profiles and generated detail libraries. For
example, an aiohttp detail shape contains:

```scheme
(trace (coverage 'complete)
  (unordered
    (span (scope "opentelemetry.instrumentation.aiohttp_server")
          (kind 'server)
          (status 'unset)
          (name (exact "GET /api/articles"))
          (http-status 200)
          (children (unordered
            (repeat 2
              (span (scope "opentelemetry.instrumentation.sqlalchemy")
                    (name (prefix-suffix "SELECT /" "realworld.sqlite3")))))))))
```

A Go implementation adds one new profile but imports the same scenario table.
A replacement Python tracer likewise gets a new named profile instead of
weakening or overwriting the auto-instrumentation profile; the old profile
remains an executable 1:1 specification.

The single validation program calls
`(validate-profile profile scenario-name capture validation-mode)`. The atomic
profile provider infers exact mode when it supplies a scenario shape and
contract mode otherwise. The suite exposes no independent library, signal,
shape-prefix, or exact-mode switches.

Known telemetry defects belong in the suite's `otel_xfails` dictionary rather
than in a weakened shape. Each entry maps a topic to a non-empty issue or
reason, for example:

```starlark
realworld_hurl_test_suite(
    name = "my_app_otel_test",
    service = ":my_app_otel_service",
    otel_profile = ":my_atomic_otel_profile",
    otel_sink = ":otel_sink_service",
    otel_xfails = {
        "comments": "https://example.invalid/issues/123",
    },
)
```

The Hurl workload and full OTLP validation still run. A Scheme contract
rejection is printed as `XFAIL`, tagged `otel-xfail`, and keeps its failed JSON
capture in undeclared outputs. A validation that starts passing becomes a hard
`XPASS` failure until the entry is removed. Sink failures, timeouts, validator
crashes, and other infrastructure errors are never swallowed by an xfail.
Contract rejections use a distinct HTTP 409 response; Scheme compilation, VM,
heap, call-budget, and output-budget failures remain validator errors and can
never satisfy an xfail.

The `errors_*` topics are ordinary passing contracts: their expected HTTP 4xx
responses and error spans describe application behavior, not known telemetry
defects.

Intermittent telemetry defects use `otel_flaky_cases`, also as a mapping from
topic to reason. Those targets receive Bazel's `flaky = True` behavior and an
`otel-flaky` tag: Bazel retries a failing attempt and reports `FLAKY` if a retry
passes, while exhausting the retries remains red. The aiohttp
`errors_profiles` topic is marked flaky because a late startup `/api/tags`
export can cross the explicit trace-only reset boundary; the exact shape is
unchanged, so the race remains visible instead of being accepted as valid
telemetry.

Random IDs and timestamps remain integrity-checked rather than pinned. The one
known random path fragment in aiohttp SQLAlchemy span names uses the explicit
`prefix-suffix` matcher. All other profile dimensions and counts are exact.

Shape generation is a separate manual target, never an update-mode
environment variable. It preserves both the raw JSON capture and a Scheme
candidate in Bazel's undeclared test outputs:

```bash
bazel test //bazel/itest/apps:aiohttp_otel_hurl_test_articles_shape_candidate \
  --nocache_test_results --test_output=streamed

# Generate every candidate, safely parallelized by Bazel.
bazel test //bazel/itest/apps:aiohttp_otel_hurl_test_shape_candidates \
  //bazel/itest/apps:django_otel_hurl_test_shape_candidates \
  --jobs=4 --nocache_test_results
```

The candidate is a deterministic, importable implementation-detail library for
inspection. Check it in under
`corpus/realworld/shapes/<profile>/<scenario>/shape.scm`. Portable HTTP contracts stay
in the single shared scenario table. Normal validation targets cannot rewrite
checked-in shapes. The driver reports HTTP wall time,
sink-measured evaluation time, and sink process peak RSS for each validation.
Configured profile names are propagated into candidate libraries, so a new
implementation can generate candidates before exact tests import them.

```bash
bazel test //bazel/itest/apps:aiohttp_test
bazel test //bazel/itest/apps:aiohttp_hurl_test
bazel test //bazel/itest/apps:django_test
bazel test //bazel/itest/apps:django_hurl_test

# The same probes and contracts with OpenTelemetry auto-instrumentation.
bazel test //bazel/itest:otel_sink_test
bazel test //bazel/itest/apps:aiohttp_otel_test
bazel test //bazel/itest/apps:aiohttp_otel_hurl_test
bazel test //bazel/itest/apps:django_otel_test
bazel test //bazel/itest/apps:django_otel_hurl_test
```

Run a fixture and keep it available for manual development with:

```bash
bazel run //bazel/itest/apps:aiohttp_service
bazel run //bazel/itest/apps:django_service
```

## Publication and source identity

Each application has a path-filtered GitHub Actions workflow. Both workflows
publish to `ghcr.io/pawelchcki/rules_stest_apps` with two app-prefixed,
immutable tags and no `latest` tag:

- `<app>-tree-<git-tree-oid>` identifies the exact application subtree.
- `<app>-v0.<workflow-run-number>` is the human-facing release tag.

The workflow also pushes `oci/<app>/v0.<run>` as a lightweight Git tag. Its
target is a deterministic, parentless synthetic commit whose tree is the
application subtree. After an anonymous pull and Bazel smoke test pass, the
workflow opens a PR updating the manifest digest lock. If repository policy
blocks Actions-created PRs, the validated lock branch remains available and the
job reports a warning instead of a false test failure.

The Dockerfiles pin their build images and `uv.lock` pins Python packages. The
workflow disables attestations and rewrites build timestamps. Once a
`<app>-tree-<git-tree-oid>` image exists, later releases reuse its exact
manifest rather than rebuilding or overwriting that content identity.
