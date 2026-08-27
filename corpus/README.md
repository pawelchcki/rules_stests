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
