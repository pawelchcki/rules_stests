# Upstream provenance

- Repository: <https://github.com/nsidnev/fastapi-realworld-example-app>
- Commit: `029eb7781c60d5f563ee8990a0cbfb79b244538c`
- Imported: 2026-08-23
- License: MIT (`LICENSE`)

Corpus-specific changes add a small SQLite compatibility layer, make the
initial Alembic migration portable, and adapt the Docker/Compose setup. The
image byte-compiles the `app` package during its build, and Compose persists a
self-contained SQLite database volume. PostgreSQL URLs remain supported.
