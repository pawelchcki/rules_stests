import argparse
import os

from aiohttp import web

from conduit import create_app


def main() -> None:
    parser = argparse.ArgumentParser(description="RealWorld aiohttp server")
    parser.add_argument("--host", default=os.environ.get("LISTEN_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("LISTEN_PORT", "8000")))
    parser.add_argument("--database", default=os.environ.get("DATABASE_PATH", "realworld.sqlite3"))
    args = parser.parse_args()
    web.run_app(
        create_app(args.database, os.environ.get("SECRET_KEY")),
        host=args.host,
        port=args.port,
        print=None,
    )


if __name__ == "__main__":
    main()
