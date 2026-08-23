from typing import Any


class BaseRepository:
    def __init__(self, conn: Any) -> None:
        self._conn = conn

    @property
    def connection(self) -> Any:
        return self._conn
