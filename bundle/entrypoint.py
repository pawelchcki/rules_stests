import argparse
import asyncio
import os
import shutil
from pathlib import Path


def configure_environment(materialize_seed: bool) -> tuple[Path, Path]:
    root = Path(os.environ["REALWORLD_BUNDLE_ROOT"])
    source_root = root / "src" if (root / "src").is_dir() else root
    state_dir = Path(
        os.environ.get("APP_STATE_DIR")
        or (Path(os.environ["TEST_TMPDIR"]) / "aiohttp-realworld" if os.environ.get("TEST_TMPDIR") else "/data")
    )
    state_dir.mkdir(parents=True, exist_ok=True)
    database = state_dir / "realworld.sqlite3"
    if materialize_seed and not database.exists():
        shutil.copyfile(root / "seed" / "realworld.sqlite3", database)
    os.environ["DATABASE_PATH"] = str(database)
    os.environ.setdefault("SECRET_KEY", "rules-stests-development-only-secret")
    os.chdir(source_root)
    return root, database


def init_db(database: Path) -> None:
    from conduit.db import create_engine, create_schema

    async def initialize() -> None:
        engine = create_engine(database)
        try:
            await create_schema(engine)
        finally:
            await engine.dispose()

    asyncio.run(initialize())


def serve(host: str, port: int, database: Path) -> None:
    from aiohttp import web

    from conduit import create_app

    web.run_app(create_app(database, os.environ["SECRET_KEY"]), host=host, port=port, print=None)


def main() -> None:
    parser = argparse.ArgumentParser(description="Portable aiohttp RealWorld fixture")
    parser.add_argument("command", nargs="?", default="run", choices=("run", "init-db", "serve", "check"))
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    _, database = configure_environment(args.command != "init-db")
    if args.command == "init-db":
        init_db(database)
    elif args.command in ("run", "serve"):
        serve(args.host, args.port, database)
    else:
        from conduit import create_app

        app = create_app(database, os.environ["SECRET_KEY"])
        if not app.router.routes():
            raise RuntimeError("aiohttp application has no routes")


if __name__ == "__main__":
    main()
