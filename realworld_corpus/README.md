# RealWorld Python corpus

This corpus vendors Python backend implementations of the
[RealWorld](https://github.com/realworld-apps/realworld) API. Each application
is pinned to an upstream commit, retains its upstream license, and includes a
Docker build that byte-compiles all Python sources before producing a runnable
image.

## Applications

| Application | Framework | Runtime database | Start command |
| --- | --- | --- | --- |
| `fastapi-realworld-example-app` | FastAPI | SQLite | `docker compose up --build` |
| `realworld-django-ninja` | Django Ninja | SQLite | `docker compose up --build` |

Run the command from the application's directory. Both applications publish
port `8000`, so run them one at a time unless you change the host-side port.

The FastAPI application applies Alembic migrations to a persisted SQLite file
and then starts Uvicorn. The Django Ninja application uses an image-local
SQLite database, applies Django migrations, and then starts Django's
development server. These defaults are intended for corpus validation and
local execution, not production deployment.
