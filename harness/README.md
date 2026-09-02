# Harness

The harness launches extracted OCI filesystems, drives RealWorld Hurl cases,
and validates captured OTLP without requiring a container runtime or host
language installation.

## Launcher

`oci_bundle` has four modes. `extract` verifies and overlays an OCI layout.
`app` starts the bundled Python runtime, `app-ruby` starts the bundled Ruby and
Rails runtime, and `app-exec` starts a self-contained binary. App-mode options
must precede the instance, rootfs, and command; `--` ends option parsing.

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
private per service while immutable rootfs trees remain shared.

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
