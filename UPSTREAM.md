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
   would no longer differ solely by instrumentation. The toolchain-complete
   Bookworm builder image is digest-pinned, so a source-tree identity never
   resolves mutable distro packages. `stretchr/testify` drops out with the
   upstream tests.
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
5. **Duplicate identities** are a `409` naming `username` or `email`. Both
   identities have database unique indexes; explicit checks provide the field
   name in the normal path, and translated constraint errors preserve the same
   response when concurrent requests race the checks.
6. **Explicit nulls.** `PUT /api/user` rejects a `null` username, email or
   password, and `PUT /api/articles/{slug}` rejects a `null` title,
   description, body or `tagList`. Because the validators are pre-filled from
   stored state, an explicit null is otherwise indistinguishable from an
   omitted field; `common.SuppliedFields` inspects the raw body to tell them
   apart.
7. **`tagList` semantics.** The field becomes a pointer so an omitted list
   leaves tags untouched while `[]` removes them. Repeated names are
   deduplicated, database failures are returned, and article creation or scalar
   changes, tag creation and association replacement share one transaction.
8. **Unique slugs.** Two articles sharing a title receive distinct slugs, even
   when creations race the unique index or an older matching article was soft
   deleted. Titles that cannot produce a routable non-empty slug are rejected,
   and an article keeps its slug across updates.
9. **Multiple-articles responses omit `body`.**
10. **Article listings** combine every supplied filter and order matching
    articles newest-first before applying pagination. The upstream association
    finds selected unordered pages and its mutually exclusive branches ignored
    later filters.
11. **Comment deletion** scopes the comment ID to the article named in the URL,
    so a comment cannot be deleted through a different article's route.
12. **JWT identity claims** are type-, range- and integer-checked before
    conversion, and must identify a stored user. Malformed, forged or stale
    signed tokens are rejected rather than panicking or entering protected
    handlers as an empty user.
13. **Favorites** have an atomic composite uniqueness invariant. Conflict-safe
    inserts keep repeated or concurrent favorite requests idempotent, and
    unfavorite hard-deletes the relationship so it can be created again.
14. **Article-user identities** have one database row per user, created with a
    conflict-safe insert so concurrent first use cannot split ownership across
    multiple rows.
15. **Passwords** use raw-field presence rather than a reserved sentinel to
    distinguish update omission from user input, and bcrypt length errors are
    returned instead of storing an unusable empty hash.
16. **Following relationships** have a composite unique index, conflict-safe
    creation and hard deletion, so follow/unfollow cycles remain idempotent
    without accumulating soft-deleted rows.
17. **Database failures** propagate from feed reads, startup initialization and
    every schema migration. The process cannot become healthy with a partial
    schema, and a failed feed query cannot masquerade as an empty success.
18. **Atomic profile updates** commit scalar fields and nullable bio/image
    clears together, so a failed clear cannot leave a partially applied user.
19. **Update envelopes** are required even though their fields are optional.
    `{}` is rejected while `{"user":{}}` and `{"article":{}}` remain valid
    no-op updates.

## Telemetry

`otelc` v1.1.0 instruments `net/http` (server spans, named `<METHOD> <gin
route>` with gin's own `:param` route templates) and `database/sql` (client
spans for the GORM queries). Two consequences are pinned in the corpus profile:

- Database spans are **root spans**, not children of the server span that
  caused them; the instrumentation does not propagate the request context into
  the driver.
- The resource is whatever the SDK's default detectors find, and carries no
  `telemetry.sdk.*` attributes. `container.id` appears only where the process's
  cgroup identifies a container, so the profile permits rather than requires it.
- The build exports **traces and metrics only**. Metrics come solely from
  `go.opentelemetry.io/contrib/instrumentation/runtime`; there are no HTTP or
  database metrics, and no OTLP log exporter is installed.
