# rules_stests corpus

This repository contains portable, real-world application fixtures for
[`rules_itest`](https://github.com/hermeticbuild/rules_itest). The fixtures are
SQLite-backed Python APIs. Both are published in the shared
`ghcr.io/pawelchcki/rules_stest_apps` package under app-prefixed tags.

Each image is Linux/amd64, has a `FROM scratch` runtime, and contains exactly
one non-empty, gzip-compressed OCI payload layer. The payload includes a
uv-managed Python runtime, all locked wheels, the application source, a static
launcher, glibc for container execution, and an empty writable `/data`
directory. `uv` itself is only used while building. Exporters may retain
Docker's canonical empty layer; the extractor verifies and ignores it.

The same artifact supports two execution modes:

```text
container runtime -> /opt/app/bin/app run
unpacked layer    -> <rootfs>/opt/app/bin/app run
```

The unpacked mode needs a Linux/amd64 host with a compatible glibc, but does
not need Python, uv, a virtual environment, or a container runtime.

## Bazel integration tests

OCI manifest digests are recorded in `bazel/oci_images.lock.bzl` and pulled by
`rules_oci`. A small Go executable verifies the manifest and layer digests,
rejects unsafe tar entries, and materializes an immutable rootfs as a Bazel
directory artifact. Extraction is a normal cacheable action keyed by the OCI
layout and extractor: it runs once, can live in a local or remote action cache,
and is shared by parallel tests. Local sandboxes reference the cached tree
through runfiles instead of copying or unpacking it into every `TEST_TMPDIR`.

Each app payload contains a ready, current-schema SQLite template. Only
writable state is private per service. The launcher first asks the filesystem for a reflink
copy-on-write clone of that template and falls back to copying the small seed
when reflinks are unavailable; the application rootfs remains immutable and
shared even when it is gigabytes large. `rules_itest` starts the service on an
assigned port, waits for `/api/tags`, and executes an API probe; migrations and
rootfs extraction are not on the test startup path. Bazel invokes Python
through the rootfs's bundled glibc loader and library path rather than the host
runtime.

The contract tests pin the upstream RealWorld API specs at commit
`5d510ce6ec41bb97723e92fbd8d3e3458a381c09`. They also pin the official Hurl
8.0.1 Linux/amd64 image by manifest digest. Bazel downloads both artifacts,
verifies their digests, overlays Hurl's OCI layers once as `:hurl_rootfs`, and
launches Hurl through the cached tree's musl loader. The test host therefore
needs no Hurl, Bruno, Node.js, Python, container runtime, or host shared
libraries.

The Hurl package is independent of `rules_itest`: point it at any running
RealWorld implementation by URL. It bundles the full upstream suite and runs
four files concurrently by default; `--jobs` can tune that concurrency.

```bash
bazel run //bazel/itest:realworld_hurl -- \
  --base-url=http://127.0.0.1:8000 \
  --jobs=8

# Equivalent host/port form:
bazel run //bazel/itest:realworld_hurl -- --host=127.0.0.1 --port=8000
```

Pass one or more `.hurl` paths after the flags to run a selected subset. When
used by `service_test`, the same executable discovers the assigned service port
from `ASSIGNED_PORTS`; no endpoint-specific code is compiled into the package.
Any `rules_itest` service can use the reusable macro:

```starlark
load("//bazel/itest:hurl_test.bzl", "realworld_hurl_test")

realworld_hurl_test(
    name = "my_app_contract_test",
    service = ":my_app_service",
    specs = "@realworld_api_specs//:hurl_all",
)
```

Both aiohttp and Django Ninja run all 13 upstream Hurl files (154 requests).
The OpenTelemetry variants add the official, digest-locked Python
auto-instrumentation OCI rootfs to `PYTHONPATH`; no package installation or
image rebuild occurs. Its `sitecustomize.py` hook activates instrumentation at
Python startup. Traces, metrics, and logs are sent over OTLP/HTTP protobuf to
`:otel_sink_service`.

The sink is a Linux `#![no_std]` Rust binary built with `rules_rs` 0.0.102 and
Rust 1.97.1. It uses `alloc` with a bounded static `emballoc` heap and `rustix`
for networking, files, time, and process syscalls; it has no Rust standard
library or libc dependency. `POST /v1/traces`, `/v1/metrics`, and `/v1/logs`
accept OTLP protobuf, and the same endpoints also preserve OTLP JSON. Each
payload is written as decoded, pretty-printed JSON together with its signal,
receive timestamp, remote address, HTTP request line, content metadata, and all
incoming headers. `GET /dump` returns the current document and `GET /healthz`
is the service health check. Each OTEL contract test proves that all three
signals reached the sink with `service.name` resource metadata; it does not
infer success from console logs.

The Django contract variants use one Hurl job because concurrent writers can
deadlock its SQLite fixture; aiohttp retains the four-job default.

```bash
bazel test //bazel/itest:aiohttp_test
bazel test //bazel/itest:aiohttp_hurl_test
bazel test //bazel/itest:django_test
bazel test //bazel/itest:django_hurl_test

# The same probes and contracts with OpenTelemetry auto-instrumentation.
bazel test //bazel/itest:otel_sink_test
bazel test //bazel/itest:aiohttp_otel_test
bazel test //bazel/itest:aiohttp_otel_hurl_test
bazel test //bazel/itest:django_otel_test
bazel test //bazel/itest:django_otel_hurl_test
```

Run a fixture and keep it available for manual development with:

```bash
bazel run //bazel/itest:aiohttp_service
bazel run //bazel/itest:django_service
```

## Publication and source identity

Each application has a path-filtered GitHub Actions workflow. Both workflows
publish to `ghcr.io/pawelchcki/rules_stest_apps` with two app-prefixed,
immutable tags and no `latest` tag:

- `<app>-tree-<git-tree-oid>` identifies the exact application subtree.
- `<app>-v0.<workflow-run-number>` is the human-facing release tag.

The workflow also pushes `oci/<app>/v0.<run>` as a lightweight Git tag. Its
target is a deterministic, parentless synthetic commit whose tree is the
application subtree. After an anonymous pull and Bazel smoke test pass, the
workflow opens a PR updating the manifest digest lock. If repository policy
blocks Actions-created PRs, the validated lock branch remains available and the
job reports a warning instead of a false test failure.

The Dockerfiles pin their build images and `uv.lock` pins Python packages. The
workflow disables attestations and rewrites build timestamps. Once a
`<app>-tree-<git-tree-oid>` image exists, later releases reuse its exact
manifest rather than rebuilding or overwriting that content identity.
