import pathlib

import aiosql

from app.core.config import get_app_settings
from app.db.sqlite import SQLiteReturningAdapter

database_url = get_app_settings().database_url
driver_adapter = SQLiteReturningAdapter if database_url.startswith("sqlite:") else "asyncpg"

queries = aiosql.from_path(pathlib.Path(__file__).parent / "sql", driver_adapter)
