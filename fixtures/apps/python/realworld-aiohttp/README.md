# RealWorld aiohttp

This is the corpus copy of
[`stkrizh/realworld-aiohttp`](https://github.com/stkrizh/realworld-aiohttp),
pinned as documented in `UPSTREAM.md`. It serves the current RealWorld API with
aiohttp, SQLAlchemy's async engine, and `sqlite+aiosqlite`.

The canonical routes are under `/api`; `/api/v1` is retained as an upstream
compatibility alias. SQLite is the only supported database.

For local development:

```bash
uv sync
APP_STATE_DIR=.state REALWORLD_BUNDLE_ROOT="$PWD" \
  uv run python bundle/entrypoint.py init-db
APP_STATE_DIR=.state REALWORLD_BUNDLE_ROOT="$PWD" \
  uv run python bundle/entrypoint.py serve --port 8000
```

The OCI image embeds Python 3.11.15, all locked dependencies, and a ready empty
database seed. Runtime startup performs no migration or network access.
