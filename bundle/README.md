# Portable fixture bundle

The Dockerfile turns this application into a Linux/amd64, single-payload-layer
`FROM scratch` image. It uses uv only during the build to install the managed
CPython 3.9.25 runtime and the exact packages in `uv.lock`.

At runtime `/opt/app/bin/app` accepts `run`, `migrate`, `serve`, or `check`.
SQLite is the default and stores state under `APP_STATE_DIR` (normally `/data`,
or a directory below `TEST_TMPDIR` when extracted by a Bazel test). A migrated
SQLite template is copied there on first launch, so `run` and `serve` start
without running migrations.

After extracting the non-empty OCI layer, invoke `<rootfs>/opt/app/bin/app` directly.
The host needs Linux/amd64 and compatible glibc, but no Python or uv install.
