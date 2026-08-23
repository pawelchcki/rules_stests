import re
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, AsyncGenerator, Iterable, Mapping, Optional, Sequence

import aiosqlite
from aiosql.adapters.aiosqlite import AioSQLiteAdapter


class SQLiteReturningAdapter(AioSQLiteAdapter):
    """Return the row produced by SQLite's RETURNING clause."""

    async def insert_returning(
        self,
        conn: "SQLiteConnection",
        _query_name: str,
        sql: str,
        parameters: Mapping[str, Any],
    ) -> Any:
        async with conn.execute(sql, parameters) as cursor:
            row = await cursor.fetchone()
        if row is None:
            raise RuntimeError("INSERT ... RETURNING did not produce a row")
        return row[0] if len(row.keys()) == 1 else row


class SQLiteConnection:
    """Expose the subset of asyncpg's connection API used by repositories."""

    def __init__(self, connection: aiosqlite.Connection) -> None:
        self._connection = connection

    def execute(
        self,
        sql: str,
        parameters: Optional[Mapping[str, Any]] = None,
    ) -> Any:
        return self._connection.execute(sql, parameters or {})

    def executemany(
        self,
        sql: str,
        parameters: Iterable[Mapping[str, Any]],
    ) -> Any:
        return self._connection.executemany(sql, parameters)

    async def executescript(self, sql: str) -> aiosqlite.Cursor:
        return await self._connection.executescript(sql)

    async def fetch(self, sql: str, *parameters: Any) -> Sequence[aiosqlite.Row]:
        sqlite_sql = re.sub(r"\$\d+", "?", sql)
        async with self._connection.execute(sqlite_sql, parameters) as cursor:
            return await cursor.fetchall()

    @asynccontextmanager
    async def transaction(self) -> AsyncGenerator[None, None]:
        await self._connection.execute("BEGIN IMMEDIATE")
        try:
            yield
        except BaseException:
            await self._connection.rollback()
            raise
        else:
            await self._connection.commit()


class SQLitePool:
    """Open one lightweight SQLite connection for each request."""

    def __init__(self, path: Path) -> None:
        self._path = path

    @classmethod
    def from_url(cls, database_url: str) -> "SQLitePool":
        prefix = "sqlite:///"
        if not database_url.startswith(prefix):
            raise ValueError("SQLite URL must use sqlite:///path syntax")
        return cls(Path(database_url.removeprefix(prefix)))

    @asynccontextmanager
    async def acquire(self) -> AsyncGenerator[SQLiteConnection, None]:
        connection = await aiosqlite.connect(self._path, isolation_level=None)
        connection.row_factory = aiosqlite.Row
        await connection.execute("PRAGMA foreign_keys = ON")
        try:
            yield SQLiteConnection(connection)
        finally:
            await connection.close()

    async def close(self) -> None:
        return None
