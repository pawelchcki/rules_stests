import argparse
import os
from pathlib import Path


def configure_environment() -> Path:
    root = Path(os.environ["REALWORLD_BUNDLE_ROOT"])
    state_dir = Path(
        os.environ.get("APP_STATE_DIR")
        or (Path(os.environ["TEST_TMPDIR"]) / "django-ninja-realworld" if os.environ.get("TEST_TMPDIR") else "/data")
    )
    state_dir.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("DEBUG", "True")
    os.environ.setdefault("DATABASE_URL", f"file:{state_dir / 'realworld.sqlite3'}")
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
    os.chdir(root / "src")
    return root


def migrate() -> None:
    import django
    from django.core.management import call_command

    django.setup()
    call_command("migrate", interactive=False, verbosity=1)


def serve(host: str, port: int) -> None:
    from django.core.management import execute_from_command_line

    execute_from_command_line(["manage.py", "runserver", "--noreload", f"{host}:{port}"])


def main() -> None:
    parser = argparse.ArgumentParser(description="Portable Django Ninja RealWorld fixture")
    parser.add_argument("command", nargs="?", default="run", choices=("run", "migrate", "serve", "check"))
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    configure_environment()
    if args.command in ("run", "migrate"):
        migrate()
    if args.command in ("run", "serve"):
        serve(args.host, args.port)
    elif args.command == "check":
        import django
        from django.core.management import call_command

        django.setup()
        call_command("check")


if __name__ == "__main__":
    main()
