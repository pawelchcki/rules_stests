# Datadog verification record

This record separates current 112-case evidence from the historical 96-case acceptance and performance comparison. The fixed behavioral reference is [DataDog/system-tests at `ea8a5976064509df0a5232e314b22e7e90ca4d40`](https://github.com/DataDog/system-tests/tree/ea8a5976064509df0a5232e314b22e7e90ca4d40/tests). The checks are independently implemented and do not establish complete upstream parity.

## Current matrix and publication

The matrix contains **seven profiles and 112 scenarios**: aiohttp and Django each run 16 scenarios on both v0.4 and v0.5; Rails, Falcon, and Gin each run 16 on v0.4. The implementation was updated from `origin/main` at `a9c7e40794755fe78f04b45b27a778b2e3c22aee`, whose [Full test suite](https://pawel.buildbuddy.io/invocation/7adf096e-97b5-4cef-adb0-62bb61ffe20d) and [Pages publication](https://github.com/pawelchcki/rules_stests/actions/runs/36547338400) passed.

Ruby, Gin, and Falcon were published on 2026-10-01 using `tools/publish_datadog_fixtures.sh`. Each anonymously pulled manifest and uncompressed rootfs layer matched its reviewed digest. No manifest or payload digest changed during publication. The source-tree identities are recorded in `bazel/oci_images.lock.bzl`.

| Fixture | Published image | Manifest SHA-256 |
| --- | --- | --- |
| Ruby tracer 2.42.0 | `ghcr.io/pawelchcki/rules_stest_agents` | `eb96229a846b2335a56e0fa2a4b6b454bceebcfe2cfb92b5a7b2841888fb61a8` |
| Gin / Go tracer 2.10.1 | `ghcr.io/pawelchcki/rules_stest_apps` | `ee6a879cae36694b99a967fc4ba62b797a269422bd80249f8c7939de07cd0166` |
| Falcon | `ghcr.io/pawelchcki/rules_stest_apps` | `e6ff3e6066d976206748a4820ad01477fd13a78f982e6b94ef073ca01b3ee0d4` |

BuildBuddy now consumes these published locks without rebuilding local fixtures. Its parity driver retains two uncached executions and generates a standalone Datadog HTML report after independently rechecking both with the coverage gate. The Pages workflow publishes the report at `datadog-report.html` after fresh local acceptance and retains its raw evidence in an Actions artifact. Publication from the new workflow starts when the change reaches `main`.

## Current acceptance evidence

These executions used implementation commit `e6ea9196e120ea1f682fc163ddebff299a1beff5`, consuming the published images without local repository overrides. Subsequent verification-document changes do not alter the tested implementation.

| Acceptance item | Observed result | Evidence |
| --- | --- | --- |
| First fresh exact-shape execution | **112/112 passed; 7 profiles gated** | [BuildBuddy execution](https://pawel.buildbuddy.io/invocation/8879b352-6f10-4807-8f98-6e96a0d10488); retained at `/tmp/datadog-closeout-evidence/execution-1`. |
| Second independent execution | **112/112 passed; 7 profiles gated** | [BuildBuddy execution](https://pawel.buildbuddy.io/invocation/9855d256-7586-4e49-bee9-41dfb7bc98b6); retained at `/tmp/datadog-closeout-evidence/execution-2`. |
| Concurrent isolation, 4 workers × 1 repetition | **7/7 profiles passed** | [BuildBuddy execution](https://pawel.buildbuddy.io/invocation/05985a65-5e68-4826-be34-9d16c1d466d6); each retained result has `assertionsPassed: true`, no failures, and observed overlap 4. |
| Full concurrent stress, 32 workers × 3 repetitions | **7/7 profiles passed** | [BuildBuddy execution](https://pawel.buildbuddy.io/invocation/2f5c59f7-2db2-4bce-aa6b-d545d85a9707); each retained result has `assertionsPassed: true`, no failures, overlap 32, and 489 ledger entries. Capture/ledger hashes were independently rechecked under `/tmp/datadog-closeout-evidence/full-stress`. |
| External-feature profiles | **207 passed; 3 unsupported; 0 failures** | [BuildBuddy execution](https://pawel.buildbuddy.io/invocation/8ef9c99a-4bd4-4141-af97-cf5fb3ba6891); all seven targets passed, retaining 210 results under `/tmp/datadog-closeout-evidence/features`. Unsupported cases remain Python v0.4 origin on aiohttp and Django, plus Gin manual-drop/keep-rule interaction. |
| Repository regressions | **259/259 targets passed** | [BuildBuddy execution](https://pawel.buildbuddy.io/invocation/8aef8c6c-899d-42f2-a7e6-13f63821649c); 61 executed and 198 were cached. This includes the final report mutation tests, Ruby receipt validation, sink, launcher, profile/report logic, bootstrap checks, telemetry labs, and non-report fixture tests. Receipt-producing OTel report targets are separately run uncached by CI. |
| Independent consumer and exported API | **74/74 tests passed; manifest/API builds passed** | [Consumer tests](https://pawel.buildbuddy.io/invocation/ccf0aa02-3ff0-4b00-85b2-32e5fe880ca1) were all cached; [manifest/API build](https://pawel.buildbuddy.io/invocation/cb6bb885-83bf-4b36-a06d-82a095fec118) passed. |
| Standalone HTML report | **Passed receipt revalidation and browser checks** | `/tmp/datadog-closeout-evidence/datadog-report.html`, SHA-256 `870016dcc9191fc2dc307455ee02225252d4af6f0f3de09b01d7ac83be74c963`; Chromium checks at 1440px and 390px cover filtering, expandable proofs, clearing filters, page errors, and page overflow. |
| Fixture publication | **All three published and anonymously verified** | `/tmp/datadog-closeout-publication.log`, SHA-256 `a88ee0a8aaa6a24927df2eb136020c8c34f613456b653e37822dc029321720cf`. |

Both receipt gates report `7 profiles, 112 scenarios`; each gate-log SHA-256 is `baed8f2ade1ca64d2e8506908b8851f5b07cf9d467413fd80dbbe9243482fca7`. The complete manifests, bytecode, captures, receipts, logs, and timings remain in their separate retention directories.

An initial [112-case attempt](https://pawel.buildbuddy.io/invocation/c5827bd2-f999-45c3-a6ab-b5ceac6b3b33) passed 111 cases and failed Rails `feed` when Puma encountered `EADDRINUSE` on its assigned port. That attempt was excluded from acceptance; its log and test artifacts were preserved at `/tmp/datadog-closeout-port-collision.log` and `/tmp/datadog-closeout-failed-feed`. Both complete executions above then passed without test retries or changes to validation.

## Reproduce the current evidence

The full driver runs the two exact-shape executions, their retention gates, report generation, the four-worker concurrent suite, and the external-feature suite. Use an empty image-override file to consume the published locks:

```sh
images=$(mktemp -d /tmp/datadog-images.XXXXXX)
evidence=$(mktemp -d /tmp/datadog-evidence.XXXXXX)
: > "$images/bazel.flags"
tools/run_datadog_parity.sh "$images" "$(git rev-parse HEAD)" "$evidence"
# Set DATADOG_BAZEL_CONFIG=local for four local build/test jobs instead of RBE.
```

Each execution is retained and gated before the next starts. Report generation rechecks the current bytes instead of trusting stored success logs. Unit mutations reject changed capture/bytecode, wrong revision, missing proofs, xfails, unclassified fields, reused directories, missing receipts, and differing contracts between executions. Scenario and feature counts remain distinct across repeated runs; occurrence counts explicitly describe the final run.

## Historical 96-case acceptance

The source comparison point and receipt revision below are `02bbcbba786bb9462beda4c27a0c73e20109a4fd`; verification ran before commit against the implementation changes on top of that revision. This historical six-profile record predates Falcon and the current publication and reporting work.

| Acceptance item | Status | Observed result and evidence |
| --- | --- | --- |
| First 96-case exact-shape execution | **Passed and gated** | `//fixtures:datadog_suite`: 96 of 96 passed. Run log: `/tmp/dd-96-execution-1.log`, SHA-256 `b994d04acfc7b05bfc0040b3ae1e7e47bdb08ac9c95dd5f5b5c70f61e142de14`. `/tmp/dd-acceptance/execution-1-retained` contains six manifests, 96 compiled validators, and complete per-scenario receipts, captures, timing files, and logs. The hardened gate read the retained bytecode and reports `6 profiles, 96 scenarios`; gate-log SHA-256 `d0bd63564a3aef547c7d24bc008e68028de05e02e2eb4a383accf50a566250e8`. |
| Second independent 96-case execution | **Passed and gated** | 96 of 96 passed after execution 1 was retained. Run log: `/tmp/dd-96-execution-2.log`, SHA-256 `e94ee7fbc7e3a166d96de345958fe6bf670a6bf92816badd314df2d3587263d1`. `/tmp/dd-acceptance/execution-2` contains the same complete 584-file evidence set. The hardened bytecode-aware gate also reports `6 profiles, 96 scenarios`. |
| External reference consumers and source compatibility | **Passed** | 33 of 33 passed, including `@rules_stests//corpus:datadog_conformance_test`. Log: `/tmp/dd-reference-consumers-final.log`, SHA-256 `58b61abe1021bc9e5968f21a3c3b3503aaf9144e7b7bb7b9f86f3609bb151695`. |
| Sink, feature-probe, driver, and coverage-gate unit targets | **Passed** | Four targets passed after the parallel-validator fixes; the driver and probe tests executed fresh while the unchanged sink and gate tests were cached. Log: `/tmp/dd-final-targeted.log`, SHA-256 `c199250ba173c018df79be0ea2b6eb0933de67af4de741b45a151e90a3e39a43`. |
| Hardened artifact-gate mutations | **Passed** | The updated coverage-gate unit target passed after adding retained-bytecode verification. Log: `/tmp/dd-artifact-gate-tests.log`, SHA-256 `a7f615e0b3f6d2bb15eb7db0e6eb19c6f782356c23d9f7a3ba2d48b53024de35`. |
| Ruby bootstrap mutations | **Passed** | `//harness:datadog_ruby_bootstrap_test` passed, including frozen application dependency files, repeated and early activation, absent/incompatible dependencies, ABI mismatch, missing native build marker, and missing native shared object. Log: `/tmp/dd-bootstrap-final.log`, SHA-256 `102c541e87873dc4661cd261bce59633429f22433e56b39677da46dfed068959`. |
| Local Ruby/Gin payload build and export | **Passed locally** | `tools/build_datadog_fixtures.sh` built, exported, and verified the reviewed OCI layouts. Ruby image config: `05868e2f5cec9f1cedbcd97aa6ccb4365e937aa27b1ecdec83ace0287b0a00a4`; Gin image config: `2debe58d90f89fd5f2c891bca005e00b3a68736a6c4222be6d4d977925162cc6`. Log: `/tmp/dd-image-verification.log`, SHA-256 `028926b43e828a001ae6a01522a36861cbbbb6423325ea992de808c2b98cfe00`. A same-executor no-cache Ruby rebuild matched its image identity. |
| Six native external-feature profiles | **Passed with three unsupported results** | The final current-source run completed all six profiles: 177 passed results, the three explicitly unsupported results below, and no failures. Each of the 180 results retains its upstream source, configuration, and capture hashes under `/tmp/dd-acceptance/features-final`. Run log: `/tmp/dd-final-features.log`, SHA-256 `00cdea5b1cec916e33f75519170d69e0f648625468d193d7ed2f5426dd60b762`. |
| Full parallel stress suite, 32 workers x 3 repetitions | **Passed** | All six profiles passed. Every retained result has `assertionsPassed: true`, no failures, 489 ledger entries, and observed overlap 32. Logs and capture/ledger/result triples are under `/tmp/dd-full-stress.log` and `/tmp/dd-acceptance/stress`; run-log SHA-256 `992f24e20a57a1d6fd5ebc5332e1e6d17c2a6ebfd3242c3a6ecdf308f36b43c1`. |
| OTel, report, launcher, sink, and external-feature regressions | **Passed** | 71 of 71 targets passed: 67 executed fresh and four unchanged unit targets were cached. This covers all four OTel RealWorld fixtures, OTel profile variants, the four shared external-feature fixtures, report, launcher, OTel sink, and Ruby bootstrap tests. Log: `/tmp/dd-otel-regressions.log`, SHA-256 `ee7c5b7ac4b0b57b18f4853ff2953c4ccc6d555a3cf34eee27684e5e9c39af2f`. |
| Five-run warmed benchmark and cold-build report | **Passed** | All 340 attempts passed across five uncached 34-case runs per variant. The original median test window was 117.881 seconds and the compiled median was 69.353 seconds, a 41.17% reduction. Fresh action-cache builds took 88.249 and 247.621 seconds respectively; downloaded repositories may be shared. Result: `/tmp/dd-benchmark/final-results/results.json`, SHA-256 `2bce95607325b43fc8e828cf6c321adb145c1331ca2c0661a820982a05344ce8`. |

## Historical benchmark executions

The acceptance metric uses the first test-attempt start through the last test-attempt finish. Invocation wall time is retained separately. Every row contains exactly 34 uncached passing attempts.

| Repetition | Original test window (s) | Compiled test window (s) |
| ---: | ---: | ---: |
| 1 | 116.386 | 67.151 |
| 2 | 120.122 | 70.527 |
| 3 | 118.380 | 69.353 |
| 4 | 117.531 | 68.583 |
| 5 | 117.881 | 70.238 |
| **Median** | **117.881** | **69.353** |

The measured reduction is **41.17%**, satisfying the required minimum of 40%. Warm build preparation took 4.161 seconds for the original and 4.526 seconds for the compiled implementation. Cold build cost is reported independently above and is not included in the warmed test-window comparison.

## Historical unsupported feature results

Unsupported results never count as passed. The completed feature run recorded exactly these cases:

| Profile | Case | Reason retained by the feature harness |
| --- | --- | --- |
| aiohttp, Python 4.14.0, v0.4 | `origin` | The pinned tracer emits duplicate MessagePack keys and intake rejects the payload. |
| Django, Python 4.14.0, v0.4 | `origin` | The pinned tracer emits duplicate MessagePack keys and intake rejects the payload. |
| Gin, Go 2.10.1, v0.4 | `manual-drop-rule` | The pinned tracer reapplies the keep rule when the root finishes, while the native graph shows dropped children. Standalone manual drop remains a separate passing check. |

The complete capability boundaries and remaining coverage gaps are recorded in [datadog-coverage.md](datadog-coverage.md#deliberate-boundaries-and-remaining-gaps).

## Historical verification scope

These are local executions on the executor identified in the benchmark record. CI now runs in BuildBuddy; this historical local record does not establish the current commit's CI status. The Ruby and Gin OCI images were not published. Matching the Ruby rebuild on this executor checks deterministic local inputs; reproducibility across container tools, operating systems, or architectures has not been established.

## Historical reproduction

All Bazel commands use the local executor with four build and test jobs and the reviewed local OCI layouts:

```sh
flags=(
  --config=local
  --jobs=4
  --local_test_jobs=4
  --override_repository=datadog_ruby_linux_amd64=/tmp/dd-ruby-revised-oci
  --override_repository=gin_datadog_realworld_linux_amd64=/tmp/dd-gin-context-oci
)
revision=$(git rev-parse HEAD)

bazel build "${flags[@]}" //tools/datadog_coverage:datadog_coverage

bazel test "${flags[@]}" //fixtures:datadog_suite \
  --test_env="TELEMETRY_TEST_REVISION=$revision" \
  --nocache_test_results

tools/retain_datadog_evidence.py \
  --revision "$revision" \
  --output /tmp/datadog-reproduction/execution-1 \
  --gate bazel-bin/tools/datadog_coverage/datadog_coverage_/datadog_coverage

bazel test "${flags[@]}" //fixtures:datadog_parallel_suite \
  --nocache_test_results

bazel test "${flags[@]}" \
  //fixtures:datadog_external_features_suite \
  //harness/external_features:probe_test
```

The second exact-shape execution must use a different retention directory. Retain and gate execution 1 before starting execution 2 so Bazel cannot overwrite its test outputs.

Run the performance comparison only after other executor work has stopped:

```sh
tools/benchmark_datadog.py \
  --original /tmp/dd-benchmark/original \
  --original-revision 02bbcbba786bb9462beda4c27a0c73e20109a4fd \
  --original-output-base /tmp/dd-benchmark/original-output \
  --output /tmp/dd-benchmark/final-results \
  --jobs 4 \
  --cold-output-root /tmp/dd-benchmark/cold-builds
```

All locally executable acceptance checks listed in this record passed. The three explicitly unsupported feature results remain unsupported and do not count as passes. CI execution and image publication remain outside this local verification result.
