from typing import Any, AsyncGenerator, Callable, Type

from fastapi import Depends
from starlette.requests import Request

from app.db.repositories.base import BaseRepository


def _get_db_pool(request: Request) -> Any:
    return request.app.state.pool


async def _get_connection_from_pool(
    pool: Any = Depends(_get_db_pool),
) -> AsyncGenerator[Any, None]:
    async with pool.acquire() as conn:
        yield conn


def get_repository(
    repo_type: Type[BaseRepository],
) -> Callable[[Any], BaseRepository]:
    def _get_repo(
        conn: Any = Depends(_get_connection_from_pool),
    ) -> BaseRepository:
        return repo_type(conn)

    return _get_repo
