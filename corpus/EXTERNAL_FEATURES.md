# External configuration feature experiments

The external suite adds **22 distinct specification feature IDs** to the 85
already covered by Scheme proof rules: **107 total, a 25.9% increase**. Nineteen
configuration experiments cover these IDs and a negative propagation check;
this counts feature IDs, not HTTP
requests, assertions, or language/feature pairs. A unit test checks the IDs
against the pinned compliance matrix, rejects overlap with existing proofs, and
enforces the 20% growth target.

Run the regression suite locally:

```sh
bazel test --config=local //harness/external_features:probe_test //fixtures:external_features_test
```

Each of aiohttp, Django, Gin, and Rails runs a fresh baseline application and
fresh instances with changed environment variables. The workload sends tagged
HTTP requests and duplicate registrations through the public API. No fixture
application or SDK code is changed. A separate `traceidratio=1` control makes
the comparison with `traceidratio=0` test the sampler argument itself.

The second expansion adds three feature IDs: default service naming, AlwaysOn
exemplar filtering, and homogeneous primitive arrays observed through captured
request headers. The batch processor experiments and propagation-disabled
experiment strengthen coverage without contributing additional feature IDs.

The fixture versions and image digests are pinned in
[`oci_images.lock.bzl`](../bazel/oci_images.lock.bzl). Findings below were
reproduced locally on 2026-09-09 with Python SDK 1.44.0 / auto-instrumentation
0.65b0, Ruby SDK 1.11.0 / logs SDK 0.5.1, and Gin's otelbuild 1.1.0 image.

## Observed discrepancies

The additional experiments found:

| Setting | Python aiohttp | Python Django | Go Gin | Ruby Rails |
| --- | --- | --- | --- | --- |
| Empty `OTEL_SERVICE_NAME` | Default `unknown_service` name | Default `unknown_service` name | `service.name` missing | `service.name` empty |
| `OTEL_BSP_MAX_EXPORT_BATCH_SIZE=1` | Single-span batches | Single-span batches | Still multi-span batches | Single-span batches |
| Capture `x-probe-feature` request header | Exact string array | Exact string array | Header absent | Header absent |
| `OTEL_PROPAGATORS=none` | Four independent root traces | HTTP 500 with context error | Four independent root traces | Four independent root traces |

The header experiment uses
`OTEL_INSTRUMENTATION_HTTP_CAPTURE_HEADERS_SERVER_REQUEST=x-probe-feature` and
sends `X-Probe-Feature: visible`. A pass requires the exact OTLP array
`["visible"]` on all four identified server spans. Absence in Go or Ruby under
this setting does not establish that their SDKs lack arrays or other ways to
configure header capture.

Django's propagation-disabled health request fails with
`AttributeError: 'NoneType' object has no attribute 'get'` in OpenTelemetry's
context lookup. The installed Python `CompositePropagator.extract` returns
the input context unchanged when the propagator list is empty, including
`None`. This is consistent with the captured context error; the test records
the exact diagnostic as `workload_rejected` and does not accept unrelated
HTTP failures. It stops on the first HTTP 500 instead of repeatedly issuing
failing requests.

AlwaysOn exemplar filtering was exercised while span sampling was disabled.
Python and Go exported exemplars under AlwaysOn for metric names that had no
exemplars in a matching TraceBased control. Metrics that already sampled a
remote parent in the control are excluded from both sides. Rails exports no
metrics in this fixture. A separate log batching control and a bounded burst
of duplicate registrations create an opportunity to batch error logs before
the batch cap is lowered to one.
The batch processor experiments prove the maximum export batch-size setting
only. They do not claim the matrix's `OTEL_BSP_*` and `OTEL_BLRP_*` wildcard
feature rows because queue saturation and timeout behavior are not covered.

The first expansion also established:

| Setting | Python aiohttp | Python Django | Go Gin | Ruby Rails |
| --- | --- | --- | --- | --- |
| Span string length = 8 | Enforced | Enforced | Enforced | Startup rejected: minimum 32 |
| Global string length = 8 | Enforced on spans | Enforced on spans | Enforced on spans | Startup rejected: minimum 32 |
| Span event count = 0 | No baseline events | Two events dropped | No baseline events | Startup rejected: must be positive |
| Log string length = 8 | Enforced | `request` is still 32 characters | No log export in this fixture | Startup rejected: minimum 32 |

Ruby's trace and log limit constructors reject the configuration before the
application becomes ready. The probe recognizes the exact `ArgumentError`
diagnostics in `opentelemetry/sdk/trace/span_limits.rb` and
`opentelemetry/sdk/logs/log_record_limits.rb`; unrelated startup errors remain
hard failures. These are observable implementation differences, not evidence
that Ruby lacks attribute limits generally. The environment-variable
[specification](https://opentelemetry.io/docs/specs/otel/configuration/sdk-environment-variables/)
defines the common configuration names and their intended effects.

Django emits `request="<WSGIRequest: POST '/api/users'>"` in its error logs.
The installed Python SDK's `_clean_extended_attribute_value` truncates native
strings but returns `str(value)` directly for unsupported object types. This
explains why the request object becomes an oversized string on the wire while
aiohttp's primitive string attributes are truncated. The saved expectation is
specifically `gap:request=32`; another oversized attribute or a different
length fails the regression test.

All four fixtures honored resource attributes, service-name precedence,
SDK disabling, both sampling experiments, and a global attribute-count cap of
two. Python's fixtures also demonstrated exemplar suppression and switching
HTTP histograms to exponential aggregation. Gin's baseline workload produces
no histograms or exemplars, so histogram switching and exemplar suppression
remain **not exercised** there; its separate AlwaysOn experiment does produce
exemplars. This Rails image exports no metrics, leaving these metric features
**not exercised**.

## Evidence and interpretation

Each test writes `external-features.json`, decoded `*.capture.json` files,
and `*.app.log` files to its Bazel undeclared outputs. Results contain SHA-256
hashes of captures and recognized startup/workload-rejection logs. Generate the full
comparison from a local run:

```sh
bazel-bin/harness/external_features/probe_/probe --compare \
  bazel-testlogs/fixtures/aiohttp_external_features_test/test.outputs/external-features.json \
  bazel-testlogs/fixtures/django_external_features_test/test.outputs/external-features.json \
  bazel-testlogs/fixtures/gin_external_features_test/test.outputs/external-features.json \
  bazel-testlogs/fixtures/rails_external_features_test/test.outputs/external-features.json
```

The comparison verifies hashes and re-evaluates every outcome from the retained
evidence. Missing evidence or edited outcomes are errors. If Bazel packages
undeclared outputs in ZIP files, extract each application's outputs into its
own directory first.

`pass` requires both an exercised baseline and the configured effect. Count
limits require dropped-item counters and the exact cap; string limits inspect
every exported scalar string attribute and require a value reaching the cap.
Sampler tests require other baseline signals to keep exporting. Missing
baseline events, logs, exemplars, or histograms produce `not_exercised`, never
a passing disable/limit result. Unit tests include ignored-setting mutations,
empty-capture checks, and protection against one good record masking violations.

The checked-in [expectations](../harness/external_features/expected.json) record
passes, specific gaps, startup/workload rejections, and missing workload opportunities.
An improvement or regression changes the expected outcome and fails the suite
until its evidence is reviewed. `--test_arg=--discover` records results without
comparing expectations when investigating a new fixture version.

These results are supplemental external observations. They do not mint the
Scheme proof-plan receipts used by the existing HTML report, and they do not
increase its **Verified here** counts. Each feature claim is limited to the
configuration and workload exercised here, rather than general SDK compliance.
Compression is excluded because the current Rust sink only accepts identity
encoding; its HTTP 415 response must not be counted as an exporter defect.
