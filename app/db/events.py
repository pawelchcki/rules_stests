from fastapi import FastAPI
from loguru import logger

from app.core.settings.app import AppSettings
from app.db.sqlite import SQLitePool


async def connect_to_db(app: FastAPI, settings: AppSettings) -> None:
    if settings.database_url.startswith("sqlite:"):
        logger.info("Connecting to SQLite")
        app.state.pool = SQLitePool.from_url(settings.database_url)
        logger.info("Connection established")
        return

    logger.info("Connecting to PostgreSQL")

    try:
        import asyncpg
    except ImportError as exc:
        raise RuntimeError(
            "PostgreSQL support is not installed in the SQLite-only portable bundle",
        ) from exc

    app.state.pool = await asyncpg.create_pool(
        str(settings.database_url),
        min_size=settings.min_connection_count,
        max_size=settings.max_connection_count,
    )

    logger.info("Connection established")


async def close_db_connection(app: FastAPI) -> None:
    logger.info("Closing connection to database")

    await app.state.pool.close()

    logger.info("Connection closed")
