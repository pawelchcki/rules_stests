# Datadog tracing coverage

The fixed comparison reference is [DataDog/system-tests at ea8a5976064509df0a5232e314b22e7e90ca4d40](https://github.com/DataDog/system-tests/tree/ea8a5976064509df0a5232e314b22e7e90ca4d40/tests). These are independently implemented checks against native intake data, not a claim of complete upstream parity.

The [verification record](datadog-verification.md) distinguishes completed, pending, and unsupported acceptance results for the current worktree.

## Exact RealWorld profiles

| Application | Tracer | Intake | Scenarios |
| --- | --- | --- | ---: |
| aiohttp | Python 4.14.0 | v0.4 and v0.5 | 16 each |
| Django | Python 4.14.0 | v0.4 and v0.5 | 16 each |
| Rails | Ruby 2.42.0, Ruby ABI 3.3 | v0.4 | 16 |
| Gin | Go 2.10.1, Orchestrion 1.13.0 | v0.4 | 16 |

The 96 combinations retain exact native span shapes, including multiplicities, service identity, routes/resources, HTTP status/error classification, database operations and ancestry, exception metadata, and the reviewed field policy. Ruby Rack/controller/ActiveRecord and Go Gin/Gorm/database/sql layers remain distinct. Candidate captures were reviewed before enabling these shapes; `datadog-shape-review.json` records capture hashes and reviewed counts. Candidate generation does not produce a passing receipt.

Run `//fixtures:datadog_suite`. BuildBuddy's Full test suite runs the parity checks on the remote executor fleet, retaining and gating each of two uncached independent executions before running the next. `tools/retain_datadog_evidence.py` copies each manifest, compiled validator, receipt, capture, timing artifact, and test log. The gate requires complete scenario/profile coverage and matching revision and validator hashes. The same BuildBuddy workflow checks concurrent isolation, native features, shared OpenTelemetry regressions, and external consumers; its artifacts retain the Datadog evidence.

## Upstream-derived feature checks

Every feature result contains its exact upstream file URL, configuration, baseline capture hash, configured capture hash, and status. Held-parent cases also retain the early capture hash. The files are under each external-feature test's `test.outputs` directory.

| Check | Reference under pinned `tests/parametric/` | Evidence |
| --- | --- | --- |
| Datadog, W3C, B3 single/multiple extraction, disabled extraction, precedence | `test_headers_datadog.py`, `test_headers_tracecontext.py`, `test_headers_b3.py`, `test_headers_b3multi.py`, `test_headers_none.py`, `test_headers_precedence.py` | Full trace and parent identity for every marked request |
| Malformed nonnumeric, zero, overflowing IDs; 64/128-bit generation and extraction | `test_headers_datadog.py`, `test_128_bit_traceids.py` | Invalid context starts a new trace; high bits checked separately |
| Sampling priority and origin propagation | `test_headers_datadog.py` | Native sampling metrics and origin metadata |
| Service/environment/version, configured header tags, method, status, user agent, selective query redaction | `test_tracer.py` | Four marked requests; query control must contain the dummy secret before configured redaction |
| Sampling rules at zero/one and first-match precedence | `test_trace_sampling.py` | Exported sampling decisions; transport omission never substitutes for a drop decision |
| Manual keep/drop and disabled tracing | `test_sampling_manual.py`, `test_tracer.py` | Native priorities versus a normal baseline; disabled tracing requires an empty capture |
| Nested spans, controlled exception, outbound client/server ancestry and restored context | `test_tracer.py` | Exact probe multiplicities, parents, exception fields, sibling after outbound call |
| Partial flush thresholds 1, 2, 1000 and disabled control | `test_partial_flushing.py` | Completed children while HTTP parent is held, chunk metadata, and unchanged reconstruction after release |

Run `//fixtures:datadog_external_features_suite`. Python v0.4 origin propagation is explicitly reported as **unsupported** when the pinned tracer emits duplicate MessagePack keys and intake rejects the payload; it never counts as passed. Go 2.10.1 also reports the combined manual-drop/keep-rule case as **unsupported** only when the complete native graph shows dropped children but a root overwritten by the keep rule. Standalone manual keep/drop uses no sampling rules and is checked separately. Ruby uses its supported configuration API for partial flushing and Rack query quantization. Partial-chunk metadata is checked at the pinned SDK’s position: last span for Ruby, first span for Python/Go, with duplicate metadata rejected. Go's B3 single-header spelling is adapted explicitly in retained configuration.

## Concurrent request isolation

`//fixtures:datadog_parallel_suite` defaults to 32 workers and three repetitions of every scenario. Each profile runs one shared application and sink, with sequential Hurl requests inside each scenario. CI uses four workers and one repetition.

The proxy ledger records execution, sequence, request ID, method/path, response, incoming context, independent application SQL marker/count, and timing. Full 128-bit identities separate deliberate equal-low-bit callers. Every request requires one server span; every span requires an owner. Database hooks mark SQL before instrumentation, including cached Rails query events and both Go database and Gorm events. Go transaction lifecycle methods have no SQL text, so their request markers are attached through the SDK context before instrumentation and their calls are counted separately. Its bounded pool is established before startup reset. Counts include instrumented SQL operations/events, not only physical database round trips. Exact serial shapes remain unchanged; stress validation checks ownership and independently counted SQL events because shared contents affect query multiplicity.

Stress evidence contains the ledger, whole capture, hashes, configuration, assertion results, and observed proxy/native overlap. A serialized run cannot pass. Capture overflow fails explicitly (64 MiB aggregate, 8 MiB native intake request, bounded records and workload size). Only the coordinator resets once and drains once.

Targeted mutations cover moved SQL spans, wrong parents, duplicate/missing requests and spans, merged high bits, lost SQL, incorrect counts, missing markers, wrong service, and absent overlap.

## Validator execution and compatibility

Bazel compiles every effective Datadog Scheme validator to a cached bytecode artifact. Runtime execution stays in the bounded VM. Source validation remains available for diagnostic probes and profiles without a compiled artifact. Hand-written Scheme captures without indexed ancestry use a bounded parent walk that rejects ambiguous parents and crossed high bits; an explicit indexed rejection remains authoritative. Manifests and receipts bind source, compiler, and bytecode SHA-256 digests; mismatches fail. The compiler identity is the Bazel-produced sink executable, within the same trusted build boundary as the manifest.

Native topology uses an index of full trace identity and span ID plus child adjacency. Untagged partial chunks inherit high bits only through unambiguous parent relationships. Intake counters are incremental; ingestion appends only new records while complete dumps and failure artifacts remain available. Snapshot/quiescence safeguards are preserved.

Driver timing artifacts separate startup drain, workload, drain/validation, compilation, validation execution, and total driver time. Application startup is recorded by the launcher. Build compilation cost is recorded in action logs. `tools/benchmark_datadog.py` measures five uncached executions of the original 34 combinations per variant with warmed builds, alternating order on the same executor at the same concurrency; acceptance requires at least 40% lower median test window. Build time is reported separately.

## Deliberate boundaries and remaining gaps

Legacy v0.3, Ruby/Go v0.5, profiling, AppSec, IAST, dynamic instrumentation, remote configuration, and other non-tracing products are outside this matrix. Nonempty span links and structured metadata are not accepted by the exact native schema. Propagation checks do not cover every upstream malformed-header permutation or every injection-style combination. Sampling checks do not establish statistical accuracy at intermediate rates or span-sampling behavior. HTTP probes do not exercise every method/status permutation. Partial-flush checks use deterministic small traces rather than production-size endurance workloads.

Local Ruby/Gin payloads are built reproducibly with `tools/build_datadog_fixtures.sh`; this workflow verifies the reviewed rootfs payload digests and does not publish images. BuildBuddy sets `DATADOG_FIXTURE_CACHE` to reuse exported images on recycled runners, saves updated runner snapshots, and restores the newest available snapshot. Each fixture's cache key covers its build context, helper scripts, container-tool version, and network mode; every hit is checked against the reviewed payload digest before use. Cache hits and misses are printed in the workflow log. The OCI envelope may vary with the container tool's compression and history serialization, which do not affect the extracted rootfs the harness executes. Application Gemfiles and lockfiles remain untouched. Bootstrap checks cover frozen Bundler, repeated/early activation, incompatible or absent dependencies, ABI mismatch, and missing native extensions.

To reproduce the comparison, export the original revision to a separate directory and keep its Bazel output base separate. For this change the original 34-case revision is `02bbcbba786bb9462beda4c27a0c73e20109a4fd`. Run the benchmark after other builds/tests finish:

```sh
tools/benchmark_datadog.py --original /path/to/original-checkout \
  --original-revision 02bbcbba786bb9462beda4c27a0c73e20109a4fd \
  --original-output-base /tmp/datadog-original-bazel \
  --output /tmp/datadog-benchmark --jobs 4 \
  --cold-output-root /tmp/datadog-cold-builds
```

The optional cold-build run uses fresh Bazel action caches for both variants. Downloaded dependencies may still come from the shared repository cache; those timings are reported separately from the warmed test medians.
