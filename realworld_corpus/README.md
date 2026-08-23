# RealWorld Python corpus

This corpus vendors Python backend implementations of the
[RealWorld](https://github.com/realworld-apps/realworld) API. Each application
is pinned to an upstream commit, retains its upstream license, and includes a
Docker build that byte-compiles all Python sources before producing a runnable,
single-payload-layer `FROM scratch` image.

## Applications

| Application | Framework | Runtime database | Start command |
| --- | --- | --- | --- |
| `fastapi-realworld-example-app` | FastAPI | SQLite | `docker compose up --build` |
| `realworld-django-ninja` | Django Ninja | SQLite | `docker compose up --build` |

Run the command from the application's directory. Both applications publish
port `8000`, so run them one at a time unless you change the host-side port.

The FastAPI application applies Alembic migrations to a persisted SQLite file
and then starts Uvicorn. The Django Ninja application applies Django migrations
and starts Django's development server. Both default to `/data/realworld.sqlite3`.
These defaults are intended for corpus validation and local execution, not
production deployment.

The images also work without a container runtime: extract their only non-empty
OCI payload layer and execute `opt/app/bin/app`. See the repository-level README for the
`rules_oci` and `rules_itest` integration.
