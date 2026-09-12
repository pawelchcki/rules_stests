# Datadog upstream assertion adapter

This adapter executes the unchanged D001 and D002 methods from Datadog
`test_headers_datadog.py`, pinned by revision and SHA-256 in `MODULE.bazel`.
It presents each of the four native server spans through the test's expected
`TestAgentAPI` and `APMLibrary` interfaces and verifies that the method requests
the headers configured by the Go probe.

The small `find_only_span`, `span_has_no_parent`, `ORIGIN`, and
`SAMPLING_PRIORITY_KEY` compatibility definitions match the pinned upstream
helpers. The remaining D003-D005 outbound-header tests and non-header feature
contracts continue to use the local harness because their required response
data or controls are not retained by this adapter.
