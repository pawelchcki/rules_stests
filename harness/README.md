# Harness

The harness launches extracted OCI filesystems, drives RealWorld Hurl cases,
and validates captured OTLP without requiring a container runtime or host
language installation.

## Launcher

Extraction and launching are separate tools. `oci_rootfs_extract <layout>
<rootfs> <single|multi>` verifies and overlays an OCI layout as a Bazel build
action. `app_launcher --runtime=<python|ruby|native> --instance=<name>
--rootfs=<directory> [injection options] -- <command> [arguments...]` consumes
an already-materialized directory and executes the application directly.
Both tools remain Go executables and can evolve independently.

Corpora use the shared `corpus_service` macro from `//rules:defs.bzl`:

```starlark
corpus_service(
    name = "my_service",
    rootfs = ":my_app_rootfs",
    runtime = "native",
    instance = "my-app",
    command = "opt/app/bin/my-app",
    args = ["--port", "$${PORT}"],
    autoassign_port = True,
    http_health_check_address = "http://127.0.0.1:$${PORT}/healthz",
)
```

`python` and `ruby` use the existing bundled runtime layouts and take an
entrypoint/Rails command; `native` takes a rootfs-relative executable path.
The optional `injection` accepts the existing `otel_injection`,
`python_auto_injection`, and `ruby_auto_injection` configurations. The macro
declares app/agent runfiles and forwards service environment, dependencies,
health checks and lifecycle settings to `rules_itest`. `realworld_app_suite`
uses this same interface for plain services, instrumented services and variants.

| Option | Meaning |
| --- | --- |
| `--otel-rootfs=DIR` | Resolve agent data; enable the placeholder and OTel defaults |
| `--env=KEY=VALUE` | Set an environment variable after runtime isolation |
| `--prepend-path=KEY=VALUE` | Prepend one colon-separated path entry |
| `--append-path=KEY=VALUE` | Append one colon-separated path entry |
| `--require=PATH` | Fail before launch unless a substituted path exists |

Python owns `PYTHONHOME`, its application `PYTHONPATH`, and bundle root. Ruby
owns its Gem, library, database, loader, and bundle variables. Injection path
edits apply after those values, followed by explicit environment overrides.
When an OTel rootfs is present, missing service/exporter defaults are filled
in; inherited or explicit values win.

Rootfs extraction is a cacheable Bazel action. It verifies manifest and layer
digests, rejects paths escaping the output tree, applies OCI whiteouts, and
preserves otherwise-empty symlink targets for tree artifacts. App state is
private per service while immutable rootfs trees remain shared. It lives under
`TEST_TMPDIR` unless `APP_STATE_DIR` is supplied. `rules_itest` owns service
lifecycle within the Bazel test action; the launcher replaces itself with the
application process and adds no container runtime or isolation layer.

## Hurl driver

Run the complete upstream suite against any server:

```bash
bazel run //harness:realworld_hurl -- \
  --base-url=http://127.0.0.1:8000 --jobs=8
```

Pass selected `.hurl` files after the options to limit the run. Under
`service_test`, the driver reads assigned service ports, brackets the workload
with sink snapshots, and runs either validation or candidate generation.

## OTLP sink

`otel_sink_service` accepts OTLP/HTTP protobuf or JSON at `/v1/traces`,
`/v1/metrics`, and `/v1/logs`. `/healthz` reports readiness, `/stats` reports
capture and validator measurements, `/dump` freezes a JSON snapshot,
`/dump.scm` renders it as Scheme, `/reset` clears all signals, and
`/reset/traces` preserves startup metrics and logs. `/validate` executes a
profile bundle; `/candidate` renders a candidate trace shape.

The module map is intentionally narrow: `server` routes requests; `http` and
`otlp*` decode transports; `storage`, `data`, and `trace_forest` own capture
state; `scheme` and `validation` execute proofs; `runtime` and `platform` own
the no-std process boundary; `stats` records resource use.

An `otel_xfails` entry accepts only a Scheme contract rejection and turns an
unexpected pass into XPASS. `otel_flaky_cases` uses Bazel retries without
weakening the profile. Infrastructure, compiler, timeout, and sink failures
remain hard failures in both cases.
