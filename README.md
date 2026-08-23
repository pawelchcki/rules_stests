# rules_stests corpus

This repository contains portable, real-world application fixtures for
[`rules_itest`](https://github.com/hermeticbuild/rules_itest). The first two
fixtures are SQLite-backed Python APIs:

- FastAPI RealWorld: `ghcr.io/hannah-barbera/rules-stests-fastapi-realworld`
- Django Ninja RealWorld: `ghcr.io/hannah-barbera/rules-stests-django-ninja`

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
rejects unsafe tar entries, and extracts the layer below `TEST_TMPDIR`.
`rules_itest` runs database migrations as an `itest_task`, starts the service
on an assigned port, waits for `/api/tags`, and executes an API probe.

```bash
bazel test //bazel/itest:fastapi_test
bazel test //bazel/itest:django_test
```

Run a fixture and keep it available for manual development with:

```bash
bazel run //bazel/itest:fastapi_service
bazel run //bazel/itest:django_service
```

## Publication and source identity

Each application has a path-filtered GitHub Actions workflow. It publishes two
immutable tags without a `latest` tag:

- `tree-<git-tree-oid>` identifies the exact application subtree.
- `v0.<workflow-run-number>` is the human-facing release tag.

The workflow also pushes `oci/<app>/v0.<run>` as a lightweight Git tag. Its
target is a deterministic, parentless synthetic commit whose tree is the
application subtree. After an anonymous pull and Bazel smoke test pass, the
workflow opens a PR updating the manifest digest lock.

The Dockerfiles pin their build images and `uv.lock` pins Python packages. The
workflow disables attestations and rewrites build timestamps so a given app
tree produces the same single-payload-layer artifact.
