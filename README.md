# rules_stests

Portable RealWorld conformance suites for telemetry implementations, built on
[`rules_itest`](https://github.com/hermeticbuild/rules_itest). The repository
ships an executable OpenTelemetry proof corpus, test harness, and reference
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

## Public API

`rules/defs.bzl` exports `REALWORLD_APPS`, `REALWORLD_HURL_CASES`, `corpus_service`, `oci_rootfs`,
`otel_injection`, `python_auto_injection`, `ruby_auto_injection`, `otlp_env`,
`realworld_service_tests`, `realworld_app_suite`, `realworld_hurl_test_suite`,
`otel_realworld_profile`, `otel_standard_registry`, and
`otel_report_manifest`.

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
harness/     rootfs launcher, Hurl driver, and OTLP validation sink
fixtures/    reference declarations, apps, and agent image sources
report/      proof plans, receipts, and HTML report assembly
examples/    independently analyzed consumer modules
bazel/       OCI locks, module extensions, and RBE platforms
tools/       maintainer and report scripts
```

## Reading the report

`//report:assemble` renders `feature-parity-report.html`, a single self-contained
page whose front end lives in `report/report/web/`. Start with **Instrumentation
status** and select one implementation. The default is the first implementation
with a passing receipt, or the first listed implementation if none passed.

- **Verified here**: the listed assertion passed with accepted evidence from this build.
- **Documented gap**: the report explicitly records an implementation gap.
- **Unknown**: this report has no accepted proof for the feature.
- **Not applicable**: the profile explicitly marks the feature as inapplicable.

Select a count to reveal its feature list. Categories start collapsed, with
Traces, Metrics, and Logs first. “No implementation gaps recorded” does not mean
full support: unknowns remain separate, and the current assembler does not
populate documented gaps. Upstream support and language maturity are secondary
reference information under **Upstream & feature details**.

**Test coverage** preserves the selected implementation and describes which
scenarios have telemetry checks and how detailed those checks are. **Trace
structure specified** means a saved scenario shape exists; **Shared telemetry
checks only** means the shared capture contract is defined. The independent
**Result in this build** column uses receipts: **Passed**, **Expected failure**,
or **No result for this build**. Scenarios outside the profile's declared set
say **Not in this test suite** and do not count as missing tests.

Only an executable proof plan backed by accepted current-revision receipts can
produce verification. Expected failures never verify features. Profiles without
receipts remain visibly unverified, even with saved shapes or upstream support
claims. Assembly still rejects partial receipt sets; a profile producing no
receipts must be explicitly declared unavailable. Assertions, evidence methods,
and receipt hashes are available in expandable details and **Evidence**.

**Compare traces** compares saved trace expectations. Trace groups match on their
root span, then spans match on kind and normalized name, with route parameters
collapsed so `api/articles/<slug>` and `api/articles/{slug}` align. Scope is shown
but never used for pairing. Groups start collapsed; left-only and right-only
structures have the same neutral styling. Differences carry no quality verdict.

Only the active view is shown. Existing hash routes (`#overview`, `#coverage`,
`#compare`, `#features`, `#receipts`, `#glossary`) and feature/comparison filters
remain supported. Add `profile=<profile-id>` to select an implementation in
status, coverage, or feature details. Feature links without `profile` retain
all-implementation scope. Filtered feature links reveal their matching details;
browser back/forward restores view and filter selections.

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

## Further reading

See [`corpus/README.md`](corpus/README.md) for the specification model,
[`harness/README.md`](harness/README.md) for launcher and sink contracts, and
[`fixtures/apps/README.md`](fixtures/apps/README.md) for image provenance.
