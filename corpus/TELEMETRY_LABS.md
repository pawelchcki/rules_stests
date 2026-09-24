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

The lab suite has **122 distinct catalog IDs with passing receipt-producing
tests**. None overlap the 85 Scheme proof-rule IDs. All 22 IDs from the earlier
supplemental configuration experiments now have standalone lab proofs, leaving
**100 IDs new across all three suites**. The catalog test checks those counts
against the pinned matrix. These are feature IDs, not language/feature pairs or
HTTP requests. The report assembly command above validates and accepts the
receipts for the current revision.

| Application | Evidence exercised |
| --- | --- |
| Python | span lifecycle, links and limits, context and baggage, log SDK, custom carrier accessors, Prometheus metric mapping, SDK environment settings |
| Ruby | span attributes and events, baggage |
| Go | span concurrency and SDK processing, resources, meter views and cardinality, metric exporters and exemplars |

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
