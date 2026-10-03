# Plug-in agent example

This module consumes the public `rules_stests` API. It exercises a generic
Python injection, a consumer-defined OpenTelemetry profile, and an explicit
Gin rootfs for compile-time instrumentation. Each service declares its own
`corpus_service`; `realworld_service_tests` attaches checks to its label.

Run `bazel test --build_tests_only //...`, or one sharded suite such as
`bazel test //:aiohttp_otel_hurl_test`. Build `//:otel_report_manifest` to check
consumer-owned profile compilation across repository boundaries.

The local override is for repository CI. Published consumers should choose
an immutable `rules_stests` revision. When assembling reports, set
`REPORT_RULESET_SOURCE_ROOT` to that revision's GitHub source URL.

Datadog consumer profiles and their API checks belong to `rules_datadog_stests`.
