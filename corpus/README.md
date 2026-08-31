# OpenTelemetry proof corpus

The corpus separates specification features, executable OTLP facts, proof
rules, implementation metadata, workload contracts, and scenario topology.
There is no positional profile API and no source-only verification report.

## Layout

```text
otel/capture/shapes.scm                 named executable OTLP assertions
otel/proofs/*.scm                       signal-specific feature → assertion tables
otel/proofs.scm                         combined runtime lookup facade
otel/profile.scm                        labeled profile record and validator
otel/implementations/                   immutable version/source layers
realworld/contract.scm                  language-neutral HTTP workload
realworld/profiles/                     composed concrete profiles
realworld/shapes/<profile>/<case>/shape.scm
profile.bzl                             OtelProfileInfo and atomic targets
report/report/receipt.go                receipt trust boundary
```

`//corpus:otel_standard_registry` generates signal-specific Scheme standard
libraries and a JSON registry from the pinned compliance matrix. The registry
contains all 326 matrix IDs exactly once and assigns each a unique readable
binding such as `span/end` or `tracer/get`.

The three public `otel_profile` targets compile their Scheme authoring records
to normalized proof plans:

```text
//corpus:python_aiohttp_profile
//corpus:python_django_profile
//corpus:go_gin_profile
```

Consumers pass one of those labels to `realworld_hurl_test_suite` through
`otel_profile`. The target owns its implementation layers, signals, proof plan,
and scenario-shape mapping. A scenario is exact when the provider supplies a
shape and contract-only otherwise.

## Validation receipts

Every successful scenario compares the proofs actually executed by Scheme with
the normalized plan, then writes a schema-v1 receipt and its accepted capture to
`TEST_UNDECLARED_OUTPUTS_DIR/receipts/<profile>/`. Failed validation writes only
a failed capture. Set `OTEL_TEST_REVISION` to the lowercase 40-character current
commit; validation refuses to emit a receipt without it.

Candidate targets use the `_shape_candidate` suffix and write
`shapes/<profile>/<scenario>/shape.scm` under undeclared test outputs.

## Report assembly

The report assembler is `//corpus:feature_parity_generator`. It requires a
Bazel JSON build-event file from an uncached complete 39-scenario run, the three
normalized plans, all checked-in scenario shapes, and the current revision. It
rejects a build-event file that does not record `--nocache_test_results`, plus
absent, stale, duplicate, malformed, digest-mismatched, failed, or incomplete
receipts. Only accepted receipts create `verified` cells; unclaimed matrix rows
remain `not_exercised`.

The exact invocation is maintained in `buildbuddy.yaml`. The report servers no
longer build or infer a report; pass the explicitly assembled HTML file with
`--file`.
