# Upstream provenance

- Repository: <https://github.com/gothinkster/golang-gin-realworld-example-app>
- Commit: `626c372d259472148d93303f74aa9b9a1cdcef24`
- License: MIT (retained in `LICENSE`)

Gin + GORM + SQLite. The corpus copy vendors `hello.go`, `common/`, `users/`
and `articles/`; upstream's tests, fixtures, Postman collection and docs are
not carried over.

## Image

One image ships two binaries built from the same sources:

- `/opt/app/bin/realworld-gin` — plain `go build`
- `/opt/app/bin/realworld-gin-otel` — `otelc go build`, using
  [`opentelemetry-go-compile-instrumentation`](https://github.com/open-telemetry/opentelemetry-go-compile-instrumentation)
  v1.1.0

The pinned tool version fixes the telemetry shape and is therefore part of the
corpus profile name, `go-gin-otelbuild-v1-1-0`.

## Patches

### Build and launch

1. **`go.mod` modernization.** The `go` directive moves to 1.25 and
   `gin`, `validator`, `jwt` and `x/crypto` move to the minimum versions the
   instrumentation tool requires. Without this the tool rewrites those
   requirements itself for the instrumented build only, and the two binaries
   would no longer differ solely by instrumentation. `stretchr/testify` drops
   out with the upstream tests.
2. **`serve --host --port` argv** in `hello.go`, matching the corpus launcher
   convention. With no arguments the upstream `PORT` behaviour is unchanged.
   The database still lands at `./data/gorm.db`, which the launcher places in
   the per-instance state directory.
3. **`/etc/passwd` and `/etc/group`** entries for the image's unprivileged UID.
   The OpenTelemetry resource detectors look the running UID up in the password
   database; without them detection fails and the resource attributes are
   determined by that failure rather than by the instrumentation.

Upstream already serves `GET /api/tags`, which is reused as the health check.

### RealWorld contract conformance

The vendored application deviates from the pinned RealWorld Hurl suite in ways
that change observable status codes and response bodies, so they are patched
rather than expressed as expected failures.

1. **Error envelope.** `CommonError.Errors` becomes `map[string][]string`, and
   the error keys and messages follow the contract vocabulary: `not found`,
   `forbidden`, `is missing`, `can't be blank`, `has already been taken`,
   `invalid`. `NewValidatorError` names fields by their JSON spelling and
   separates a blank value from a malformed one.
2. **Unauthorized requests** return that envelope
   (`{"errors":{"token":["is missing"]}}`) instead of an empty body.
3. **Deletes** return an empty `204` instead of `200` with a body, and a delete
   of a missing article or comment is a `404` rather than a silent success.
4. **Nullable profile fields.** An unset `bio` or `image` serializes as `null`,
   and setting either to `""` or `null` clears it. A struct update skips empty
   values, so the columns are written directly.
5. **Duplicate identities** are a `409` naming `username` or `email`. Username
   has no unique index upstream, so both identities are checked explicitly.
6. **Explicit nulls.** `PUT /api/user` rejects a `null` username, email or
   password, and `PUT /api/articles/{slug}` rejects a `null` `tagList`. Because
   the validators are pre-filled from stored state, an explicit null is
   otherwise indistinguishable from an omitted field; `common.SuppliedFields`
   inspects the raw body to tell them apart.
7. **`tagList` semantics.** The field becomes a pointer so an omitted list
   leaves tags untouched while `[]` removes them, and the update replaces the
   association explicitly because a struct update only ever adds to it.
8. **Unique slugs.** Two articles sharing a title receive distinct slugs, and an
   article keeps its slug across updates.
9. **Multiple-articles responses omit `body`.**
10. **Author-filtered listings** are paged over the ordered query rather than
    over an association find, which ignored the ordering and returned the wrong
    page.

## Telemetry

`otelc` v1.1.0 instruments `net/http` (server spans, named `<METHOD> <gin
route>` with gin's own `:param` route templates) and `database/sql` (client
spans for the GORM queries). Two consequences are pinned in the corpus profile:

- Database spans are **root spans**, not children of the server span that
  caused them; the instrumentation does not propagate the request context into
  the driver.
- The build exports **traces and metrics only**. Metrics come solely from
  `go.opentelemetry.io/contrib/instrumentation/runtime`; there are no HTTP or
  database metrics, and no OTLP log exporter is installed.
