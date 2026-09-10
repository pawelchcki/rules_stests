# rules_stests

Portable RealWorld conformance suites for telemetry implementations, built on
[`rules_itest`](https://github.com/hermeticbuild/rules_itest). The repository
ships independent OpenTelemetry and Datadog proof corpora, a test harness, and reference
applications for Python, Ruby, and Go.

## Plug in an implementation

```starlark
# MODULE.bazel
bazel_dep(name = "rules_stests", version = "...")
```

Injected agents supply data to the generic launcher:

```starlark
load(
    "@rules_stests//rules:defs.bzl",
    "corpus_service",
    "oci_rootfs",
    "otel_injection",
    "otlp_env",
    "realworld_service_tests",
)

corpus_service(
    name = "my_python_service",
    rootfs = "@rules_stests//harness:aiohttp_rootfs",
    runtime = "python",
    instance = "my-python",
    command = "serve",
    args = ["--host", "127.0.0.1", "--port", "$${PORT}"],
    injection = otel_injection(
        rootfs = "//agent:rootfs",
        prepend_path = {"PYTHONPATH": "{otel_rootfs}/auto"},
        require = ["{otel_rootfs}/auto/sitecustomize.py"],
    ),
    env = otlp_env(),
    deps = ["@rules_stests//harness:otel_sink_service"],
    autoassign_port = True,
    http_health_check_address = "http://127.0.0.1:$${PORT}/api/tags",
    so_reuseport_aware = True,
    hygienic = False,
)

realworld_service_tests(
    name = "my_python",
    service = ":my_python_service",
    profile = "@rules_stests//corpus:python-aiohttp-auto-v0-65b0",
)
```

Compile-time Go instrumentation supplies its own app image and binary:

```starlark
oci_rootfs(name = "app_rootfs", image = ":instrumented_image")
corpus_service(
    name = "my_go_service",
    rootfs = ":app_rootfs",
    runtime = "native",
    instance = "my-go",
    command = "opt/app/bin/realworld-gin",
    args = ["serve", "--host", "127.0.0.1", "--port", "$${PORT}"],
    env = otlp_env(logs = False),
    deps = ["@rules_stests//harness:otel_sink_service"],
    autoassign_port = True,
    http_health_check_address = "http://127.0.0.1:$${PORT}/api/tags",
    hygienic = False,
)

realworld_service_tests(
    name = "my_go",
    service = ":my_go_service",
    profile = ":my_profile",
)
```

Build the vendored Gin app with Orchestrion, LoongSuite, or another tool and
place its static executable in a `FROM scratch` image.

Use `otel_realworld_profile` without shapes for contract mode. Candidate
targets record observed topology; check reviewed candidates into a shape tree
and set `shape_root` for exact mode. When a profile declares a scenario subset,
pass the same list as `scenarios` to `realworld_service_tests` so only those receipt
shards are generated.

Generate uncached receipt evidence and its build-event file before assembling a
consumer report:

```bash
revision="$(git rev-parse HEAD)"
bazel test //:otel_report_suite \
  --test_env="OTEL_TEST_REVISION=${revision}" \
  --nocache_test_results \
  --build_event_json_file=otel-profile.bep.json

REPORT_REVISION="${revision}" \
REPORT_REPOSITORY=owner/repository \
REPORT_MANIFEST=//:otel_report_manifest \
REPORT_RULESET=@rules_stests \
REPORT_RULESET_SOURCE_ROOT="https://github.com/pawelchcki/rules_stests/blob/<rules_stests-commit>" \
bazel run @rules_stests//tools:assemble_otel_report
```

`REPORT_RULESET_SOURCE_ROOT` must name the immutable dependency commit selected
by the consumer. See [`examples/plugin_agent`](examples/plugin_agent).

## Datadog tracing

The Python fixtures inject dd-trace-py 4.14.0 from the digest-pinned Datadog
package using `PYTHONPATH`. Bazel materializes the package; application processes
receive the injection and exporter environment. The default wire format is v0.5
MessagePack; each app also has a separate v0.4 MessagePack `tags` profile.

```bash
bazel test //fixtures:datadog_suite
```

For a custom service, use `datadog_python_injection(aiohttp = True)` for aiohttp (the default for Django is
`datadog_python_injection()`) and
`datadog_env(service = "aiohttp-datadog")`, declare a dependency on
`@rules_stests//harness:telemetry_sink_service`, and attach tests with:

```starlark
realworld_service_tests(
    name = "my_datadog",
    service = ":my_datadog_service",
    telemetry_profile = "@rules_stests//corpus:python-aiohttp-datadog-v4-14-0-v05",
    telemetry_sink = "@rules_stests//harness:telemetry_sink_service",
    scenarios = REALWORLD_BASE_HURL_CASES + ["propagation_datadog"],
)
```

Load `REALWORLD_BASE_HURL_CASES` from `@rules_stests//rules:hurl_test.bzl`.
The exporter and driver must select the same sink service. Both sink service
targets run `telemetry_sink` and accept both protocols. Existing
`otel_sink_service`, OTel flags, and `{otel_rootfs}` remain supported;
`instrumentation_injection` uses `{instrumentation_rootfs}` without OTel defaults.

Datadog dump, stats, reset, validation, and candidate operations use
`?protocol=datadog`; unqualified operations retain OTLP behavior. The Datadog
corpus asserts native intake metadata, IDs, completion, propagation, HTTP
classification, and exact parent/child trees. Shapes retain native service,
operation, resource, error, and selected tags/metrics. SQL resources, including stable literals, remain exact. Temporary database
paths are explicitly normalized; runtime IDs and timestamps stay in captures.

Set `TELEMETRY_TEST_REVISION` to the current 40-character commit to emit Datadog
schema-v2 receipts under test outputs `datadog/receipts`. Shape candidates are
under `datadog/shape`; candidate suites have the `_shape_candidates` suffix and
are manual targets. OTel receipts retain schema v1 and accept
`OTEL_TEST_REVISION` as a fallback. Datadog evidence stays outside the OTel HTML
report; Datadog HTML reporting is deferred.

## Public API

`rules/defs.bzl` exports `REALWORLD_APPS`, `REALWORLD_HURL_CASES`, `corpus_service`, `oci_rootfs`,
`otel_injection`, `python_auto_injection`, `ruby_auto_injection`, `otlp_env`,
`realworld_service_tests`, `realworld_app_suite`, `realworld_hurl_test_suite`,
`otel_realworld_profile`, `otel_standard_registry`, and
`otel_report_manifest`. Datadog adds `datadog_python_injection`, `datadog_env`,
`datadog_realworld_profile`, `instrumentation_injection`, and `TelemetryProfileInfo`.

`corpus_service` is independent of RealWorld. A service built by Bazel can use
`corpus_service(name = "queue", exe = "//queue:server", args = [...])` without
an OCI image, bundled runtime, or RealWorld-specific state setup. Its corpus
can attach its own tests. `realworld_service_tests` only adds RealWorld checks
to an existing service. `realworld_app_suite` remains a compatibility
convenience wrapper; fixtures and examples declare services explicitly.

## Repository structure

```text
rules/       public Starlark API
corpus/      portable Scheme specifications and checked-in shapes
harness/     rootfs launcher, Hurl driver, and dual-protocol telemetry sink
fixtures/    reference declarations, apps, and agent image sources
report/      proof plans, receipts, and HTML report assembly
examples/    independently analyzed consumer modules
bazel/       OCI locks, module extensions, and RBE platforms
tools/       maintainer and report scripts
```

## Reading the report

`//report:assemble` renders `feature-parity-report.html`, one self-contained HTML
artifact. Its default destination is **Implementation health**: feature categories
form the matrix rows and tested implementation configurations form the columns.
Filter by language, configuration/version, category, defined-check coverage,
verification result, upstream support, evidence basis, or feature text.

Three dimensions remain independent:

- **Checks defined** comes from normalized proof plans, including plans for
  unavailable runners. Expand a cell for assertions, evidence basis and sources,
  supporting RealWorld/framework fixtures, and associated scenario executions.
- **Results from this build** shows receipt-backed verification alongside passed,
  expected-failure, and no-result execution counts. These describe authored
  checks, not completeness against the entire specification. An expected failure
  retains its scenario reason; individual feature outcomes remain unknown unless
  accepted evidence independently establishes them.
- **Upstream support claims** retain their recorded language scope. They do not
  certify a particular framework, version, or configuration. Failure attribution,
  undocumented gaps, and specification-interpretation evidence are unavailable
  or unrecorded, never evidence of zero defects.

Only an executable proof plan backed by accepted current-revision receipts can
produce verification. Assembly rejects revision, digest, and receipt-completeness
failures before decoding captures for comparison. Profiles without receipts must
be explicitly declared unavailable; their planned checks do not verify features.
Configurations remain separate. Aggregation across applications would require a
later evidence-model change. Health retains existing evidence across all signals.

**RealWorld parity** compares instrumentation of the same application and workload.
Start with the implementation/scenario overview, select two configurations, then
expand scenario differences, trace groups, span trees, and field-value variants.
The default source is **Captured telemetry**. **Saved expectations** is a separate,
visibly labelled source; missing captures explain availability and never trigger
an automatic source change. Available one-sided captures remain inspectable.
Each capture shows its revision and scenario outcome. Differences are neutral and
never change health results. The scenario/check-coverage table lives here too;
scenarios outside a configuration's declared suite are excluded, not missing tests.

Captured protobuf JSON and OTLP JSON use a common report projection that preserves
value types and 64-bit integers. It includes resource and scope metadata, schema
URLs, span names/kinds/status, attributes, events, links, flags, and dropped counts.
Structural correspondence uses root structure, span kind, normalized name, and
child structure; scope does not determine pairing. Repeated structures retain
all occurrence references and value multiplicities. Pairing is structural, not
proof that two occurrences represent the same request.

**Semantic differences** excludes literal trace/span/link IDs and absolute
timestamps while retaining parent/link relationships. **Raw fields and timing**
includes IDs and timestamps; every occurrence also exposes them in its detail.
Protocol JSON spellings/defaults are normalized, while attribute names and typed
values are not rewritten. Attribute ordering is insignificant; array and event
order is preserved. Missing parents mark partial traces. Duplicate identities,
cycles, or unreadable trace data produce diagnostics without fabricated topology.
Captured datasets are stored once and comparisons reference their occurrences;
expanded trace and field detail is rendered on demand. This pass compares traces,
not metrics or logs.

**Evidence** and **Glossary** are secondary destinations. Health and parity retain
independent filters in navigation, with shareable feature-cell and trace/span
links. Browser back/forward restores selections. `#health` and `#parity` are the
primary routes. Legacy feature/status/language routes enter health; coverage and
comparison routes enter parity. Legacy `#compare` links retain saved-expectation
semantics. Existing profile, scenario, feature, and comparison filters still work.

Run report and assembly regression tests with:

```sh
bazel test --config=local //report:report_test //report:assemble_test
```

The report test emits `captured-report.html` in its undeclared outputs: an
800-span fixture for browser checks. With Playwright available to Node, run:

```sh
node report/browser_test.cjs bazel-testlogs/report/report_test/test.outputs/captured-report.html
```

The browser checks cover navigation, independent filters, history, legacy/deep
links, keyboard controls, escaping, lazy rendering, source selection, side swaps,
and missing-capture inspection. `PLAYWRIGHT_CHROMIUM_EXECUTABLE` can select an
existing Chromium installation.

## Remote execution

Every Bazel action, tests included, runs by default on a self-hosted BuildBuddy
executor fleet in the `linux-amd64-kvm` pool. Tests qualify because they never
start a container: apps launch as plain processes from OCI rootfs runfiles, the
OTLP collector is the in-tree Rust sink, and SQLite state is copied into
`$TEST_TMPDIR`. The executors therefore run bare isolation and need no Docker.

An API key is required and never lives in this repository. Put it in
`~/.bazelrc`:

```
common --remote_header=x-buildbuddy-api-key=<key>
```

In CI the BuildBuddy Workflow injects the same credential, so local and CI runs
share one cache and one executor fleet.

To build offline or debug a test in isolation, opt out:

```
bazel test --config=local //harness/...
```

That drops the executor, the cache and the build event stream, and falls back to
local sandboxed execution.

Executor health is checked on the Bazzite host with
`systemctl status buildbuddy-executor@ccd0.service` (and `@ccd1`). A third
worker, `fedora-silverblue`, stays registered in `linux-amd64-bare` for another
project; BuildBuddy schedules by exact pool, so it takes no work from here. It
could be re-registered under `linux-amd64-kvm` for more capacity if that project
agrees.

## Test tiers

Unit tests cover parsers and proof/report logic. Harness tests exercise OTLP
capture and validation. Plain app suites prove the upstream API contract;
instrumented shards prove telemetry profiles and shapes. Manual candidate
targets support profile authoring, while the report suite produces uncached CI
receipts.

`//fixtures:external_features_test` compares SDK configuration effects across
all four fixtures, preserving both passing observations and specific known
discrepancies. It adds 22 feature IDs beyond the Scheme proof corpus; see
[the results and reproduction commands](corpus/EXTERNAL_FEATURES.md).

## Further reading

See [`corpus/README.md`](corpus/README.md) for the specification model,
[`harness/README.md`](harness/README.md) for launcher and sink contracts, and
[`fixtures/apps/README.md`](fixtures/apps/README.md) for image provenance.
