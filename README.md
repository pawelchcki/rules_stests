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
    "otel_injection",
    "otlp_env",
    "realworld_app_suite",
)

realworld_app_suite(
    name = "my_python",
    app = "aiohttp",
    profile = "@rules_stests//corpus:python-aiohttp-auto-v0-65b0",
    injection = otel_injection(
        rootfs = "//agent:rootfs",
        prepend_path = {"PYTHONPATH": "{otel_rootfs}/auto"},
        require = ["{otel_rootfs}/auto/sitecustomize.py"],
    ),
    env = otlp_env(),
)
```

Compile-time Go instrumentation supplies its own app image and binary:

```starlark
oci_rootfs(name = "app_rootfs", image = ":instrumented_image")
realworld_app_suite(
    name = "my_go",
    app = "gin",
    rootfs = ":app_rootfs",
    otel_binary = "opt/app/bin/realworld-gin",
    profile = ":my_profile",
    env = otlp_env(logs = False),
)
```

Build the vendored Gin app with Orchestrion, LoongSuite, or another tool and
place its static executable in a `FROM scratch` image.

Use `otel_realworld_profile` without shapes for contract mode. Candidate
targets record observed topology; check reviewed candidates into a shape tree
and set `shape_root` for exact mode. Run a suite with `bazel test
//:my_python_otel_hurl_test`. Assemble a consumer report with
`REPORT_MANIFEST=//:otel_report_manifest REPORT_RULESET=@rules_stests` and
`tools/assemble_otel_report.sh`. See [`examples/plugin_agent`](examples/plugin_agent).

## Public API

`rules/defs.bzl` exports `REALWORLD_APPS`, `REALWORLD_HURL_CASES`, `oci_rootfs`,
`otel_injection`, `python_auto_injection`, `ruby_auto_injection`, `otlp_env`,
`realworld_app_suite`, `realworld_hurl_test_suite`,
`otel_realworld_profile`, `otel_standard_registry`, and
`otel_report_manifest`.

## Repository structure

```text
rules/       public Starlark API
corpus/      portable Scheme specifications and checked-in shapes
harness/     rootfs launcher, Hurl driver, and OTLP validation sink
fixtures/    reference declarations, apps, and agent image sources
report/      proof plans, receipts, and HTML report assembly
examples/    independently analyzed consumer modules
bazel/       OCI locks and module extensions
tools/       maintainer and report scripts
```

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
