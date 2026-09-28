# Datadog verification record

This record separates observed results, unsupported behavior, and verification limits. The source comparison point and receipt revision are `02bbcbba786bb9462beda4c27a0c73e20109a4fd`; verification ran before commit against the implementation changes on top of that revision. The fixed behavioral reference is [DataDog/system-tests at `ea8a5976064509df0a5232e314b22e7e90ca4d40`](https://github.com/DataDog/system-tests/tree/ea8a5976064509df0a5232e314b22e7e90ca4d40/tests). The checks are independently implemented and do not establish complete upstream parity.

## Post-rebase verification

The current branch is based on `7904241`, which already includes Falcon as the seventh Datadog profile. This branch adds five configuration cases for Falcon and each other profile. The current matrix has 112 exact-shape combinations, 35 new configuration cases across seven profiles, and 36 Python lab cases. The six-profile runs below remain historical evidence for the pre-rebase worktree.

All 11 post-rebase targets passed in fresh BuildBuddy remote runs. The [external-feature run](https://pawel.buildbuddy.io/invocation/e108fc6d-bf5c-4bee-8910-0d5946c04e18) passed seven profile targets and the Go unit target: 242 feature results passed, including all 35 new configuration cases, with the same three earlier unsupported results. The [lab run](https://pawel.buildbuddy.io/invocation/7f2d8b49-2920-48a1-9eae-0c8aa728c5bc) passed both wire-version targets and the Python unit target: all 36 cases passed after exact carrier parsing was added. The 890 retained files under `/tmp/moar-datadog-pr-evidence` have SHA-256 manifest `d401d6cc4c44535a7501de61d6125e8875981de6bf095b245d026e612ac371ec`; capture hashes and lab identities were independently checked. The 112 exact-shape combinations and full CI workflow have not been rerun for this branch.

## Pre-rebase coverage expansion

The earlier acceptance record below belongs to the 96-shape and 30-feature-case implementation at the `ea8a597…` comparison pin. The additional configuration and controlled-span cases use [DataDog/system-tests at `255dc57d719c4d33a1c45a1b41cd517c5cae5878`](https://github.com/DataDog/system-tests/tree/255dc57d719c4d33a1c45a1b41cd517c5cae5878/tests/parametric). The historical pass counts below do not include these new cases.

| Added check | Status | Scope |
| --- | --- | --- |
| Five configuration cases per external-feature profile | **Passed in fresh remote run** | All 30 new cases passed across six profiles. The final external-feature execution returned 207 passed case results and the same three prior unsupported results; its six profile targets, Go unit target, and native-sink target passed [BuildBuddy invocation `a82a8380`](https://pawel.buildbuddy.io/invocation/a82a8380-6838-4c25-8bdd-70d2785149be). The result checks `DD_TAGS` parsing, explicit service/environment/version precedence, and actual `DD_TRACE_AGENT_URL` delivery. |
| Python controlled-span lab | **Passed in fresh remote run** | All 36 cases passed: seven injection and eleven deterministic span-sampling cases per wire version on Python 4.14.0 with v0.4 and v0.5 native intake. Both lab targets and the Python unit target passed [BuildBuddy invocation `9734a342`](https://pawel.buildbuddy.io/invocation/9734a342-3562-4d4e-81b9-3d0f0ceb3686). |
| BuildBuddy fresh proof and retained evidence | **Pending CI** | `tools/run_datadog_parity.sh` runs `//fixtures:datadog_lab_suite` uncached and archives lab test outputs under `lab/`. |

These were locally initiated BuildBuddy remote executions against the pre-rebase worktree based on `a3c0f23`; they are not a Full test suite CI workflow result. The run artifacts comprise 784 retained files under `/tmp/moar-datadog-evidence` with SHA-256 manifest `00cde10b13f92c58281bb0fdfec46e3d01162b66156f14df0ebe147eb5be9b14`. The final capture hashes, lab identity and workload hashes, and effective Datadog configuration in the new cases were independently checked. The 96 exact-shape combinations had not been rerun for that expansion.

## Earlier acceptance status

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

## Benchmark executions

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

## Unsupported feature results

Unsupported results never count as passed. The completed feature run recorded exactly these cases:

| Profile | Case | Reason retained by the feature harness |
| --- | --- | --- |
| aiohttp, Python 4.14.0, v0.4 | `origin` | The pinned tracer emits duplicate MessagePack keys and intake rejects the payload. |
| Django, Python 4.14.0, v0.4 | `origin` | The pinned tracer emits duplicate MessagePack keys and intake rejects the payload. |
| Gin, Go 2.10.1, v0.4 | `manual-drop-rule` | The pinned tracer reapplies the keep rule when the root finishes, while the native graph shows dropped children. Standalone manual drop remains a separate passing check. |

The complete capability boundaries and remaining coverage gaps are recorded in [datadog-coverage.md](datadog-coverage.md#deliberate-boundaries-and-remaining-gaps).

## Verification scope

These are local executions on the executor identified in the benchmark record. CI now runs in BuildBuddy; this historical local record does not establish the current commit's CI status. The Ruby and Gin OCI images were not published. Matching the Ruby rebuild on this executor checks deterministic local inputs; reproducibility across container tools, operating systems, or architectures has not been established.

## Reproduction

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

bazel test "${flags[@]}" //fixtures:datadog_lab_suite \
  --nocache_test_results
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

All locally executable checks in the earlier acceptance table passed. The three explicitly unsupported feature results remain unsupported and do not count as passes. The new configuration and lab checks passed in the separate remote runs recorded above. The full CI workflow and its evidence archive have not yet been observed for this worktree.
