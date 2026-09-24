# Standalone OpenTelemetry feature labs

The standalone labs exercise OpenTelemetry APIs and exporters through three
small HTTP applications. They do not use RealWorld routes or databases. Python
and Ruby run with the digest-pinned auto-instrumentation images; Go uses pinned
Go SDK modules. Each language has one application containing its feature
endpoints. The Python application is launched under several environment
configurations because SDK settings are read at process startup. These variants
also carry every feature ID from the earlier supplemental configuration suite.

Run the complete suite and produce current-revision receipts:

```sh
revision="$(git rev-parse HEAD)"
OTEL_TEST_REVISION="$revision" bazel test --config=local \
  --nocache_test_results --test_env=OTEL_TEST_REVISION \
  --build_event_json_file=otel-profile.bep.json \
  //fixtures:otel_report_suite //fixtures:telemetry_lab_suite
REPORT_REVISION="$revision" REPORT_REPOSITORY=owner/repository \
  REPORT_BAZEL_CONFIG=local tools/assemble_otel_report.sh
```

The lab suite has **133 distinct catalog IDs with passing receipt-producing
tests**. None overlap the 85 Scheme proof-rule IDs. All 22 IDs from the earlier
supplemental configuration experiments now have standalone lab proofs, leaving
**111 IDs new across all three suites**. The catalog test checks those counts
against the pinned matrix. These are feature IDs, not language/feature pairs or
HTTP requests. The report assembly command above validates and accepts the
receipts for the current revision.

| Application | Evidence exercised |
| --- | --- |
| Python | span lifecycle and explicit roots, links and limits, context and baggage including Jaeger and OpenTracing headers, log SDK and schema URLs, Prometheus metric mapping, SDK environment settings |
| Ruby | span attributes and events, baggage |
| Go | span concurrency and SDK processing, resources, meter views and cardinality, metric exporter flush outcomes and exemplars, OTLP HTTP retry and gzip behavior |

The HTTP probe calls each endpoint and checks both endpoint results and decoded
OTLP collected by the sink. Go's manual readers and Python's Prometheus reader
also expose SDK data that is not sent through OTLP. Every passing test writes a
`*.responses.json`, a `*.capture.json`, and a `*.proofs.json` to its Bazel
undeclared outputs. With `OTEL_TEST_REVISION` set, it also writes a normalized
receipt and accepted capture under `receipts/<profile>/<scenario>`. The
accepted capture includes the checked endpoint responses, so its receipt digest
covers the SDK data and the OTLP payload. For example:

```text
bazel-testlogs/fixtures/go_telemetry_lab_test/test.outputs/go-telemetry-lab.proofs.json
bazel-testlogs/fixtures/python_telemetry_lab_test/test.outputs/python-telemetry-lab.responses.json
bazel-testlogs/fixtures/go_telemetry_lab_test/test.outputs/receipts/go-telemetry-lab/base.json
```

The report assembler checks each lab receipt's revision, plan hash, capture
hash, and complete proof set before assigning **Verified here**. A claim applies
only to the pinned SDK, application call, and output asserted by its probe. The
earlier RealWorld configuration comparisons and their known gaps remain described in
[External feature experiments](EXTERNAL_FEATURES.md).

## Reproduced Python SDK log limit defect

`python_telemetry_lab_log_length_edge_test` runs the same standalone app with
`OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT=8`. Its ordinary string attribute
is exported as `abcdefgh`. In the same run, a byte attribute is exported as
the full 16-byte `abcdefghijklmnop`, and an object converted to a string is
also exported at 16 characters. The [common attribute rules](https://opentelemetry.io/docs/specs/otel/common/)
require string and byte values to be truncated to the configured length;
[LogRecord limits](https://opentelemetry.io/docs/specs/otel/logs/sdk/) use those
rules. The pinned Python SDK 1.44.0 implementation truncates strings before
returning them but returns bytes and newly converted strings without applying
the limit. The object case was seen earlier in Django's RealWorld logs; the
byte case was exposed by this standalone probe.

The scenario emits an `xfail` report receipt with no passing feature claim.
The test checks the exact oversized outputs, so a future SDK fix changes the
test result and requires reviewing the expectation. The captured OTLP is saved
at `bazel-testlogs/fixtures/python_telemetry_lab_log_length_edge_test/test.outputs/python-telemetry-lab-log-length-edge.capture.json`.

## Reproduced propagation and throttling defects

`python_telemetry_lab_ot_baggage_hyphen_test` injects two baggage keys through
the pinned OpenTracing propagator 0.65b0. `labkey` round-trips, while the valid
key `lab-key` disappears. The Jaeger propagator carries both keys in the same
app. OpenTelemetry's [Baggage API](https://opentelemetry.io/docs/specs/otel/baggage/api/)
allows baggage names as non-empty UTF-8 strings, and the
[W3C baggage token grammar](https://www.w3.org/TR/baggage/) permits the hyphen.
The OpenTracing propagator's outbound header-name filter omits it. This
scenario has an `xfail` receipt with no passing claim; the ordinary-key
round-trip separately supports the scoped OpenTracing propagator proof.

`go_telemetry_lab_retry_after_test` gives the pinned Go OTLP HTTP exporter
1.44.0 a `429` response with `Retry-After: 1`. It retries after its short
backoff (around 15–30 ms), rather than waiting one second. The
[OTLP/HTTP throttling rule](https://opentelemetry.io/docs/specs/otlp/)
defines this header value as seconds. The exporter converts the parsed integer
straight to a Go `time.Duration`, which interprets it as nanoseconds. This
scenario also emits an `xfail` receipt and does not claim throttling support.
The same in-process collector verifies that `400` is not retried, `503` is
retried with backoff, gzip payloads can be decompressed, and four exports can
be sent concurrently.
