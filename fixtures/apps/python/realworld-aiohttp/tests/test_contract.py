from pathlib import Path

import pytest

from conduit import create_app
from conduit.db import create_engine, create_schema


@pytest.fixture
async def client(aiohttp_client, tmp_path: Path):
    database = tmp_path / "test.sqlite3"
    engine = create_engine(database)
    await create_schema(engine)
    await engine.dispose()
    return await aiohttp_client(create_app(database, "test-secret"))


async def register(client, suffix: str = "one") -> tuple[dict, str]:
    response = await client.post(
        "/api/users",
        json={
            "user": {
                "username": f"user_{suffix}",
                "email": f"user_{suffix}@example.com",
                "password": "password123",
            }
        },
    )
    document = await response.json()
    return document, document["user"]["token"]


async def create_article(client, token: str, title: str) -> dict:
    response = await client.post(
        "/api/articles",
        headers={"Authorization": f"Token {token}"},
        json={"article": {"title": title, "description": "description", "body": "body"}},
    )
    assert response.status == 201
    return (await response.json())["article"]


async def test_conflicts_are_standardized(client) -> None:
    await register(client)
    response = await client.post(
        "/api/users",
        json={"user": {"username": "user_one", "email": "other@example.com", "password": "password123"}},
    )
    assert response.status == 409
    assert await response.json() == {"errors": {"username": ["has already been taken"]}}


async def test_nullable_profile_fields_can_be_cleared(client) -> None:
    _, token = await register(client)
    headers = {"Authorization": f"Token {token}"}
    response = await client.put(
        "/api/user", headers=headers, json={"user": {"bio": "", "image": None}}
    )
    assert response.status == 200
    user = (await response.json())["user"]
    assert user["bio"] is None
    assert user["image"] is None


async def test_lists_are_newest_first_omit_bodies_and_keep_total(client) -> None:
    _, token = await register(client)
    first = await create_article(client, token, "First")
    second = await create_article(client, token, "Second")
    response = await client.get("/api/articles?author=user_one&limit=1")
    document = await response.json()
    assert document["articlesCount"] == 2
    assert document["articles"][0]["slug"] == second["slug"]
    assert document["articles"][0]["slug"] != first["slug"]
    assert "body" not in document["articles"][0]


async def test_missing_token_precedes_resource_lookup(client) -> None:
    response = await client.delete("/api/articles/does-not-exist")
    assert response.status == 401
    assert await response.json() == {"errors": {"token": ["is missing"]}}


async def test_v1_routes_remain_aliases(client) -> None:
    response = await client.get("/api/v1/tags")
    assert response.status == 200
    assert await response.json() == {"tags": []}
