import argparse
import os
from pathlib import Path


def configure_environment() -> Path:
    root = Path(os.environ["REALWORLD_BUNDLE_ROOT"])
    state_dir = Path(
        os.environ.get("APP_STATE_DIR")
        or (Path(os.environ["TEST_TMPDIR"]) / "fastapi-realworld" if os.environ.get("TEST_TMPDIR") else "/data")
    )
    state_dir.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("APP_ENV", "dev")
    os.environ.setdefault("DATABASE_URL", f"sqlite:///{state_dir / 'realworld.sqlite3'}")
    os.environ.setdefault("SECRET_KEY", "rules-stests-development-only-secret")
    os.environ.setdefault("MAX_CONNECTIONS_COUNT", "1")
    os.environ.setdefault("MIN_CONNECTIONS_COUNT", "1")
    os.chdir(root / "src")
    return root


def migrate(root: Path) -> None:
    from alembic import command
    from alembic.config import Config

    config = Config(str(root / "src" / "alembic.ini"))
    config.set_main_option("script_location", str(root / "src" / "app" / "db" / "migrations"))
    command.upgrade(config, "head")


def serve(host: str, port: int) -> None:
    import uvicorn

    uvicorn.run("app.main:app", host=host, port=port, log_level="info")


def main() -> None:
    parser = argparse.ArgumentParser(description="Portable FastAPI RealWorld fixture")
    parser.add_argument("command", nargs="?", default="run", choices=("run", "migrate", "serve", "check"))
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    root = configure_environment()
    if args.command in ("run", "migrate"):
        migrate(root)
    if args.command in ("run", "serve"):
        serve(args.host, args.port)
    elif args.command == "check":
        from app.main import app

        if not app.routes:
            raise RuntimeError("FastAPI application has no routes")


if __name__ == "__main__":
    main()
