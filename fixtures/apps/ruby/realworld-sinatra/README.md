# Ruby version matrix

One shared Sinatra/Sequel RealWorld application runs on every stable Ruby
series from 1.9.3 onward, with one pinned latest patch per series. Releases
were checked against the [official Ruby release history](https://www.ruby-lang.org/en/downloads/releases/)
on 2026-10-03. The targets currently support Linux x86_64. Matrix tests carry the `manual`
tag so wildcard test runs do not start all versions; select a suite explicitly.
The BuildBuddy PR workflow selects `//fixtures:ruby_ci_suite`: all 17 smoke,
hygiene and Hurl tests on the newest pinned interpreter. Builds on `main` select
the full matrix and cross-version response parity, and publish their results.
Both selections retain normal action and test caching across iterations.

```bash
# All 15 versions: smoke, hygiene, HTTP conformance and cross-version data parity.
bazel test --config=ruby-matrix //fixtures:ruby_matrix_suite

# Select a series while developing.
bazel test //fixtures:ruby_2_7_suite
bazel build //fixtures:ruby_4_0_rootfs

# Repeat tests while retaining cached runtime and application builds.
bazel test //fixtures:ruby_2_7_suite --nocache_test_results

# Run entirely locally; limits parallel build actions too.
bazel test --config=local --jobs=8 //fixtures:ruby_matrix_suite
```

Bazel downloads checksum-pinned runtime images and source gems. The configured
LLVM toolchain builds bcrypt and SQLite extensions for each interpreter ABI.
App assembly runs a contract check with that exact interpreter, then creates
an empty SQLite database schema. WEBrick uses a fixed localhost server name
and disables reverse lookups so executor-specific DNS/NSS settings cannot
load host libc plugins into a historical interpreter. Tests copy the seed into private writable
state; the runtime and app trees remain immutable. No Docker daemon, host
Ruby, system compiler, network access during build actions, or registry
publication is needed.

## Pins and dependencies

`matrix.json` owns interpreter versions, immutable Linux/amd64 image digests,
Ruby library ABIs and dependency-group selection. `dependencies.lock.json`
owns every gem version and SHA256, including transitive dependencies. The
builder verifies gem identity, Ruby requirements and dependency requirements
using the original gem metadata.

| Series | Pinned release | Ruby ABI | Dependency group |
| --- | --- | --- | --- |
| 1.9.3 | 1.9.3-p551 | 1.9.1 | legacy |
| 2.0 | 2.0.0-p648 | 2.0.0 | legacy |
| 2.1 | 2.1.10 | 2.1.0 | legacy |
| 2.2 | 2.2.10 | 2.2.0 | legacy |
| 2.3 | 2.3.8 | 2.3.0 | classic |
| 2.4 | 2.4.10 | 2.4.0 | classic |
| 2.5 | 2.5.9 | 2.5.0 | classic |
| 2.6 | 2.6.10 | 2.6.0 | classic |
| 2.7 | 2.7.8 | 2.7.0 | classic |
| 3.0 | 3.0.7 | 3.0.0 | classic_webrick |
| 3.1 | 3.1.7 | 3.1.0 | current |
| 3.2 | 3.2.11 | 3.2.0 | current |
| 3.3 | 3.3.12 | 3.3.0 | current |
| 3.4 | 3.4.11 | 3.4.0 | current |
| 4.0 | 4.0.7 | 4.0.0 | current |

The legacy group uses Sinatra 1.4, Sequel 4 and sqlite3 1.3; classic uses
Sinatra 2.2, Sequel 5 and sqlite3 1.4. Ruby 3.0 adds the extracted WEBrick gem.
Current uses sqlite3 2.8 and WEBrick. Dependencies shared between groups are
downloaded once per version. SQLite 3.50.4 is a separately pinned amalgamation
in `MODULE.bazel`, compiled once and linked into each SQLite Ruby extension.
The compatibility shim supports the older images' libc symbol interface.

## CI performance

PRs run the latest pinned Ruby's plain API tests and official SDK trace suite.
The full `main` run covers all 15 API runtimes and all nine supported telemetry
runtimes. Standalone SDK labs and Django configuration variants also use one
base configuration in PRs and all configurations on `main`.

`--config=ruby-matrix` raises the remote action submission limit to 256; actual
concurrency remains limited by executor resources. Use `--config=local` without
that config for local execution. Ruby service tests request 0.5 CPU and 128 MB.

The pinned `rules_itest` patch emits the final JUnit result after service
shutdown, avoiding a separate remote fallback XML action. Successful child
reports are preserved; startup, test and shutdown failures produce failing XML.
Validate the patch with:

```bash
bazel test //harness:svcinit_junit_test @rules_itest//cmd/svcinit:svcinit_test
```

## Official OpenTelemetry coverage

The same application also runs all 15 RealWorld scenarios with captured trace
proofs on Ruby 2.5 through 4.0. Each supported runtime has its own profile in
the report's comparison selectors and feature tables. The version table links
directly to its captured `articles` traces. Telemetry receipts are collected
fresh for the report; the plain API matrix retains its ordinary test cache.

`telemetry.lock.json` pins compatible official SDK, OTLP exporter, Rack and
Sinatra instrumentation gems, including every transitive dependency and source
checksum. Google Protobuf's C extension is compiled against each Ruby ABI with
the configured LLVM toolchain. App assembly verifies every gem's original Ruby
and dependency requirements and loads the exact SDK/exporter before publishing
the bundle.
Ruby 2.6 and 2.7 pin Common 0.19.6: Common 0.19.7's Rack getter mutates a
frozen interpolated string on those interpreters and loses incoming context.
They use SDK 1.2.0 because SDK 1.2.1 calls a Common API absent from 0.19.6.
The build also creates a span with extracted incoming context to reject such
runtime API incompatibilities before server startup.

| Ruby series | Official SDK | Telemetry status |
| --- | --- | --- |
| 1.9.3, 2.0, 2.1, 2.2, 2.3, 2.4 | — | Unsupported: official OTLP exporter and Sinatra/Rack instrumentation require Ruby 2.5 or later |
| 2.5 | 1.0.3 | RealWorld traces |
| 2.6, 2.7 | 1.2.0 | RealWorld traces |
| 3.0 | 1.7.0 | RealWorld traces |
| 3.1, 3.2 | 1.10.0 | RealWorld traces |
| 3.3, 3.4, 4.0 | 1.13.1 | RealWorld traces |

HTTP request spans come from official Sinatra/Rack instrumentation. Sequel
has no official instrumentation gem; the application's SQL execution hook uses
the official SDK to create child spans for real prepared statements, excluding
bound values. The profiles verify runtime/SDK resource attributes, HTTP routes,
SQL span contracts, OTLP binary protobuf export and incoming W3C propagation.
This coverage is for traces; it makes no metrics or logs verification claim.
Unsupported telemetry rows retain their passing RealWorld API results.
The exporters selected for Ruby 2.5–3.0 predate OTLP's parent-remote flags.
Their propagation scenario verifies external-parent HTTP spans, but the three
feature proofs requiring those flags remain unclaimed. Ruby 3.1 and later
verify those feature proofs from the captured flags and incoming trace IDs.

The compatibility boundary is grounded in the published requirements of the
[earliest official exporter](https://rubygems.org/gems/opentelemetry-exporter-otlp/versions/0.6.0)
and [Sinatra instrumentation](https://rubygems.org/gems/opentelemetry-instrumentation-sinatra/versions/0.5.0).
Older SDK releases alone do not provide a compatible full HTTP-to-OTLP stack.

```bash
bazel test //fixtures:ruby_2_5_otel_hurl_test
bazel test //fixtures:ruby_4_0_otel_hurl_test
# All instrumented profiles, including every supported Ruby version:
bazel test //fixtures:otel_report_suite --nocache_test_results
```

## Identical RealWorld data

`//fixtures:ruby_matrix_parity_test` compares the full response data from the
same 76-request workload on all 15 versions. It drives the real HTTP server
against a private clone of the empty database seed, covering registration,
login, profile edits, follows, articles, filters, pagination, favorites,
comments, deletes, errors and Unicode usernames/titles/body text.

The test-only `parity/server.rb` fixes the clock and advances it by one second
per request; collision suffixes use a deterministic sequence. The comparator
checks exact JSON values and types, array order, HTTP status and content type.
Timestamps, JWTs, IDs, slugs and Unicode strings remain part of the comparison.
Only JSON object-key ordering is ignored. Each receipt must attest the exact
runtime pin, and missing or duplicate versions fail the gate.

Every app uses the same checksum-pinned pure Ruby `unicode_utils` normalizer
and data tables, so accented, decomposed and full-width titles produce the
same slugs across interpreter versions. Zero or negative page limits return
an empty page while retaining the total count.

```bash
bazel test //fixtures:ruby_matrix_parity_test
# Inspect one version's JSON receipt:
bazel build //fixtures:ruby_2_7_responses
```

Response receipts are small, independently cached Bazel outputs. Changing
the workload or its clock bootstrap rebuilds receipts and the comparison;
app bundles, native gems and runtimes remain cached. `--nocache_test_results`
reruns the comparator over those cached receipts; selecting the full matrix
suite also reruns its HTTP conformance tests. The parity bootstrap stays
outside the production app bundle and does not change its clock or randomness.

## Cache boundaries and rebuilds

```mermaid
flowchart LR
  Image["Pinned runtime image"] --> Runtime["Trimmed Ruby runtime + headers"]
  Gems["Pinned source gems"] --> Native["ABI-specific bcrypt / sqlite3"]
  Runtime --> Native
  SQLite["Shared SQLite object"] --> Native
  Runtime --> Bundle["Small app bundle + empty database"]
  Gems --> Bundle
  Native --> Bundle
  App["Application + build contract"] --> Bundle
  Bundle --> Tests["Independent HTTP tests"]
  Runtime --> Tests
```

| Change | Actions that rebuild |
| --- | --- |
| Application source or build contract | App bundle and affected tests |
| Pure Ruby gem pin | Bundles and tests selecting that dependency group |
| Native gem pin | That gem's extensions, dependent bundles and tests |
| Interpreter image pin | That runtime, its native extensions, bundle and tests |
| SQLite source or compatibility shim | Common SQLite object, SQLite links, bundles and tests |
| Parity workload or test clock | Response receipts and comparison; app builds remain cached |
| HTTP scenario | That scenario's tests; compiled apps remain cached |
| No changes | Bazel reuses build actions and test results |

A source-edit probe on Ruby 1.9.3 and 4.0 executed only two `RubyAppBundle`
actions, with no runtime extraction or native compilation. An unchanged build
executed no build actions. The matrix includes 255 per-version conformance tests and one cross-version
data parity test, with separate comparator and launcher/extractor unit tests.

Measured file content is 7–8 MiB per app and 33–95 MiB per runtime. All 15
app/runtime pairs total approximately 957 MiB before remote CAS deduplication;
filesystem block allocation is slightly larger. Compiler/toolchain outputs
and the download repository cache are additional one-time storage.

Runtime output contains the interpreter, headers, standard libraries and the
ELF shared-library dependency closure. Compiler binaries, static archives,
package caches and documentation are removed. App outputs contain only source,
selected gem libraries, two native extensions, gem specifications and the seed.
The runtime is a separate input/runfile, so app edits do not copy it into a new
output. Source images still occupy the Bazel repository cache on first fetch;
CAS deduplicates shared files and layers across actions. Avoid `bazel clean`
for ordinary source edits or test retries.

`//fixtures:ruby_<series>_runtime`, `_bcrypt`, `_sqlite3`, `_rootfs`, `_service`
and `_suite` expose each boundary explicitly (dots become underscores).
`bazel/ruby_matrix.bzl` declares downloads; `fixtures/ruby_build.bzl` declares
build actions; `fixtures/ruby_matrix.bzl` declares services and test suites.
Adding a series requires its reviewed runtime pin, ABI and dependency group in
`matrix.json`, plus its repository import in `MODULE.bazel`.
