# Plug-in agent example

This module consumes `rules_stests` through the public API. It exercises a
generic Python injection, a consumer-defined contract-mode profile using the
Python preset, and an explicit Gin rootfs for compile-time instrumentation.

Run `bazel test --build_tests_only //...` to analyze and build every suite, or
run one sharded suite such as `bazel test //:aiohttp_otel_hurl_test`.

An Orchestrion, LoongSuite, or other compile-time Go integration uses the same
Gin declaration: build the vendored `fixtures/apps/go/realworld-gin` app with
the tool into a `FROM scratch` image, then substitute only `rootfs`,
`otel_binary`, and `profile`.

The local override is for this repository's CI. Published consumers should
remove it and select a released `rules_stests` version.

When assembling a report, set `REPORT_RULESET_SOURCE_ROOT` to
`https://github.com/pawelchcki/rules_stests/blob/<rules_stests-commit>` using the
immutable commit that supplies the selected module version.
