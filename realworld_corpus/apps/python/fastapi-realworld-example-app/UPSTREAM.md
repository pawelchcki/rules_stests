# Upstream provenance

- Repository: <https://github.com/nsidnev/fastapi-realworld-example-app>
- Commit: `029eb7781c60d5f563ee8990a0cbfb79b244538c`
- Imported: 2026-08-23
- License: MIT (`LICENSE`)

Corpus-specific changes are limited to the Dockerfile and Compose definition.
The image now byte-compiles the `app` package during its build, and Compose
provides a self-contained PostgreSQL service with development-only credentials.
