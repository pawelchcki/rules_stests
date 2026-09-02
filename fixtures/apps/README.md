# RealWorld corpus

This corpus vendors backend implementations of the
[RealWorld](https://github.com/realworld-apps/realworld) API. Each application
is pinned to an upstream commit, retains its upstream license, and produces a
runnable, single-payload-layer `FROM scratch` image. Every application's
`UPSTREAM.md` records its pinned commit and the patches applied to it.

## Applications

| Application | Framework | Runtime database | Start command | Port |
| --- | --- | --- | --- | --- |
| `python/realworld-aiohttp` | aiohttp | SQLite | `docker compose up --build` | 8000 |
| `python/realworld-django-ninja` | Django Ninja | SQLite | `docker compose up --build` | 8000 |
| `go/realworld-gin` | Gin + GORM | SQLite | `docker build . && docker run` | 8080 |
| `ruby/realworld-rails` | Rails | SQLite | `bundle exec rails server` | 3000 |

Run the command from the application's directory. The two Python applications
share port `8000`, so run them one at a time unless you change the host-side
port.

The Python images byte-compile all sources during the build. The Gin image is
built twice from the same sources and ships both binaries: `realworld-gin` from
a plain `go build`, and `realworld-gin-otel` built with
`opentelemetry-go-compile-instrumentation`, which emits OTLP from the
`OTEL_*` environment alone.

Both Python images contain a ready, current-schema SQLite template. On first launch they copy
it to `/data/realworld.sqlite3` and start serving immediately; later launches
preserve the writable database. aiohttp uses its asynchronous application
runner and Django Ninja uses Django's development server.
These defaults are intended for corpus validation and local execution, not
production deployment.

The Gin application migrates its schema on startup into `./data/gorm.db`,
relative to its working directory.

The images also work without a container runtime: extract their only non-empty
OCI payload layer and execute `opt/app/bin/app` (`opt/app/bin/realworld-gin`
for the Gin image). See the repository-level README for the
`rules_oci` and `rules_itest` integration.

## Publication and source identity

Path-filtered workflows publish app-prefixed immutable tags to
`ghcr.io/pawelchcki/rules_stest_apps`. `<app>-tree-<git-tree-oid>` identifies
the exact application subtree and `<app>-v0.<workflow-run-number>` is the
human-facing release tag; there is no `latest` tag. Each workflow also creates
an `oci/<app>/v0.<run>` tag at a deterministic parentless commit containing
that subtree, smoke-tests an anonymous pull, and proposes the resulting
manifest digest lock update.

Docker build images and language dependencies are pinned. Workflows disable
attestations and normalize build timestamps; if a tree-tag image already
exists, later releases reuse the exact manifest instead of rebuilding it.
