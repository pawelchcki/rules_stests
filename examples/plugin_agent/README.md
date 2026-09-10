# Plug-in agent example

This module consumes `rules_stests` through the public API. It exercises a
generic Python injection, a consumer-defined contract-mode profile using the
Python preset, a consumer-defined Datadog profile, and an explicit Gin rootfs
for compile-time instrumentation.
Every service has its own `corpus_service` declaration; `realworld_service_tests`
separately attaches checks to its label.

Run `bazel test --build_tests_only //...` to analyze and build every suite, or
run one sharded suite such as `bazel test //:aiohttp_otel_hurl_test`.

An Orchestrion, LoongSuite, or other compile-time Go integration uses the same
Gin declaration: build the vendored `fixtures/apps/go/realworld-gin` app with
the tool into a `FROM scratch` image, then substitute only `rootfs`,
`command`, and the test suite's `profile`.

The local override is for this repository's CI. Published consumers should
remove it and select a released `rules_stests` version.

When assembling a report, set `REPORT_RULESET_SOURCE_ROOT` to
`https://github.com/pawelchcki/rules_stests/blob/<rules_stests-commit>` using the
immutable commit that supplies the selected module version.

Build `//:telemetry_api_check` to compile consumer-owned OTel and Datadog
manifests and check the shared `TelemetryProfileInfo` provider, protocol
identity, and default injection/sink labels across repository boundaries.
Run `//:example_datadog_hurl_test` for the Datadog `tags` scenario. Its receipts
and candidates remain separate from the OTel report manifest.

Datadog's aiohttp server integration needs `datadog_python_injection(aiohttp =
True)`: the launcher calls the package's `trace_app` hook before the server
starts. The same option enables Datadog’s SQLAlchemy integration for the
aiohttp fixture’s asynchronous SQLite engine, preserving request parentage
before database work enters aiosqlite’s worker thread. Django uses the default
injection without this aiohttp option.
