# OTLP contract corpus

Implementation-independent contract data for RealWorld API telemetry. Nothing
here depends on the Bazel harness in `//bazel/itest`; the files are plain R7RS
Scheme libraries plus JSON captures, consumable by any runner that can evaluate
them against an OTLP capture.

```text
otel/validation.scm                  (otel validation)     — the validators
otel/trace_shape.scm                 (otel trace-shape)    — trace shape matchers
realworld/contract.scm               (realworld contract), (realworld scenarios)
realworld/programs/validate.scm      exact validation program
realworld/programs/validate_contract.scm  contract-only validation program
realworld/profiles/python.scm        (otel profile python-auto-v0-65b0)
realworld/profiles/<profile>.scm     (realworld profile <profile>)
realworld/goldens/<profile>/<case>/golden.scm
                                     (realworld detail <profile> <case>)
```

## Library naming

A file's path mirrors the Scheme library it defines, so a library name can be
resolved to a file without consulting a build system. Library names use hyphens
where paths use underscores (`(otel trace-shape)` lives in `trace_shape.scm`),
because R7RS library names are symbols and Bazel labels prefer underscores.

`corpus/defs.bzl` is the Bazel-facing view of the same mapping:
`profile_library(profile)` and `golden_library(profile, case)` return labels,
and `contract_bundle` / `exact_bundle` return the libraries, the Scheme
`imports` they satisfy, and the validation program to run against them.

## What is portable and what is not

`realworld/contract.scm` holds the portable layer: the HTTP request multiset
each scenario produces and the bucketing rules that turn it into expected
server spans. Every implementation must satisfy it.

A **profile** names one instrumented implementation at one version, for example
`python-django-auto-v0-65b0`. It declares that implementation's resource
attributes, scope names, schema URL, and which non-server spans are legitimate.
`realworld/profiles/python.scm` factors out what all Python runtimes share.

A **golden** pins one profile's exact parent-child span forest for one scenario
as an unordered one-to-one multiset. Goldens are implementation specifications,
not portable contracts, which is why they are namespaced by profile.

Random IDs and timestamps stay integrity-checked rather than pinned. Where a
name genuinely varies (aiohttp's SQLAlchemy span names), use the explicit
`prefix-suffix` matcher rather than loosening the shape.

## Adding a profile

1. Write `realworld/profiles/<profile>.scm` defining
   `(realworld profile <profile>)` with the same exports as an existing
   profile. Start from the closest one.
2. Run the suite with `otel_exact = False`. Only the portable contract applies,
   so a new implementation can go green before its traces are pinned.
3. Generate goldens (below), review them, check them in, then switch to
   `otel_exact = True`.

## Promoting a golden candidate

Goldens are never rewritten by a passing test run and there is no update-mode
environment variable. Candidates come from separate `manual` targets that write
into Bazel's undeclared test outputs:

```bash
bazel test //bazel/itest/apps:aiohttp_otel_hurl_test_articles_golden_candidate \
  --nocache_test_results --test_output=streamed
```

Each candidate directory holds the raw JSON capture next to the generated
`golden.scm`. Read the capture to confirm the trace is the one you meant to
pin, then copy the candidate to
`realworld/goldens/<profile>/<case>/golden.scm`.

A candidate is generated under the contract-only program, so it reflects what
the implementation actually emitted. Promoting one without reading it converts
a live defect into a checked-in expectation. When telemetry is wrong but known,
record it in the suite's `otel_xfails` (or `otel_flaky_cases`) instead of
weakening the golden.

## Feature parity report

Build the deterministic, single-file OpenTelemetry feature and corpus coverage
dashboard with:

```bash
bazel build //corpus:feature_parity_report
# Open bazel-bin/corpus/feature-parity-report.html
```

For an HTTP workflow, run the checked-in JetBrains Bazel configuration **FP
Report Service**, or start the same target directly:

```bash
bazel run //corpus:feature_parity_http_server
```

The report is a data dependency of the server target, so this single Bazel
command builds it and starts the loopback service at
`http://127.0.0.1:8765/feature-parity-report.html`.

For a temporary public preview, run the JetBrains Bazel configuration **FP
Report Public**, or start its target directly:

```bash
bazel run //corpus:feature_parity_public_report
```

It prints a random `https://...trycloudflare.com` URL. The URL needs no account
or token, is reachable from the public internet, and exists only while the
target is running. The target uses a SHA-256-pinned cloudflared binary; Bazel
downloads it rather than relying on a host installation. This target currently
selects the matching pinned binary for Linux and macOS on x86-64 or ARM64, and
Windows on x86-64.

Open `http/feature-parity-report.http` in the JetBrains HTTP Client and select
one of the public environments from `http/http-client.env.json`:

- `local` uses the loopback service started by the run configuration.
- `tailscale` uses
  `https://bazzite.lamancha-minor.ts.net/feature-parity-report.html` and is
  reachable only from the configured tailnet.

To exercise a public preview in the HTTP Client, copy the URL printed by **FP
Report Public** into `fpReportBaseUrl` in a private HTTP Client environment.

Both routes serve the same Bazel output. The local server reopens the output on
each request, so rebuilding the report does not require restarting the service.

The report distinguishes upstream Go/Python support from repository evidence.
It also distinguishes exact goldens, portable contract-only coverage, and
unavailable coverage. The comparison view reports trace-shape count and content
differences without computing a similarity score or a parity verdict.

The upstream compliance matrix is a reviewed snapshot pinned by commit and
SHA-256 in `report/data/catalog.json`; report builds do not use the network.
Refreshing it is an explicit source-tree update from a selected 40-character
OpenTelemetry specification commit:

```bash
bazel run //corpus:update_feature_catalog -- \
  --revision=<opentelemetry-specification-commit>
bazel test //corpus:feature_parity_test
bazel build //corpus:feature_parity_report
```

Review the resulting matrix, metadata, stable feature IDs, and implementation
manifest evidence before committing an update. Signal maturity is maintained in
the catalog from the official OpenTelemetry language status page because it is
not part of the compliance matrix.
