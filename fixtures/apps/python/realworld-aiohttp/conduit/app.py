from __future__ import annotations

import logging
import secrets
from datetime import UTC, datetime
from http import HTTPStatus
from pathlib import Path
from typing import Any

import jwt
from aiohttp import web
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError
from slugify import slugify
from sqlalchemy import delete, func, select
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from conduit.db import Article, ArticleTag, Comment, Favorite, Follow, User, create_engine, session_factory

LOG = logging.getLogger(__name__)
PASSWORDS = PasswordHasher(time_cost=1, memory_cost=8192, parallelism=1)


class ApiError(Exception):
    def __init__(self, status: int, field: str, message: str) -> None:
        self.status = status
        self.field = field
        self.message = message


def error(status: int, field: str, message: str) -> ApiError:
    return ApiError(status, field, message)


@web.middleware
async def errors_middleware(request: web.Request, handler: Any) -> web.StreamResponse:
    try:
        return await handler(request)
    except ApiError as exc:
        return web.json_response({"errors": {exc.field: [exc.message]}}, status=exc.status)
    except web.HTTPException as exc:
        field = "route" if exc.status == HTTPStatus.NOT_FOUND else "request"
        return web.json_response({"errors": {field: [exc.reason.lower()]}}, status=exc.status)
    except Exception:
        LOG.exception("unhandled request failure")
        return web.json_response({"errors": {"server": ["internal error"]}}, status=500)


def timestamp() -> str:
    return datetime.now(UTC).isoformat(timespec="microseconds").replace("+00:00", "Z")


async def payload(request: web.Request, wrapper: str) -> dict[str, Any]:
    try:
        value = await request.json()
    except Exception as exc:
        raise error(422, "body", "is invalid") from exc
    if not isinstance(value, dict) or not isinstance(value.get(wrapper), dict):
        raise error(422, wrapper, "is required")
    return value[wrapper]


def require_text(data: dict[str, Any], field: str, *, minimum: int = 1) -> str:
    value = data.get(field)
    if not isinstance(value, str) or not value.strip():
        raise error(422, field, "can't be blank")
    if len(value) < minimum:
        raise error(422, field, f"is too short (minimum is {minimum} characters)")
    return value


def optional_int(request: web.Request, name: str, default: int) -> int:
    try:
        result = int(request.query.get(name, default))
    except ValueError as exc:
        raise error(422, name, "must be an integer") from exc
    if result < 0:
        raise error(422, name, "must be greater than or equal to 0")
    return result


def make_token(app: web.Application, user_id: int) -> str:
    return jwt.encode({"sub": str(user_id)}, app["secret_key"], algorithm="HS256")


async def auth_user(request: web.Request, session: AsyncSession, *, required: bool) -> User | None:
    header = request.headers.get("Authorization")
    if header is None:
        if required:
            raise error(401, "token", "is missing")
        return None
    if not header.startswith("Token ") or not header[6:]:
        raise error(401, "token", "is invalid")
    try:
        token = jwt.decode(header[6:], request.app["secret_key"], algorithms=["HS256"])
        user_id = int(token["sub"])
    except Exception as exc:
        raise error(401, "token", "is invalid") from exc
    user = await session.get(User, user_id)
    if user is None:
        raise error(401, "token", "is invalid")
    return user


def user_document(app: web.Application, user: User) -> dict[str, Any]:
    return {
        "user": {
            "email": user.email,
            "token": make_token(app, user.id),
            "username": user.username,
            "bio": user.bio,
            "image": user.image,
        }
    }


async def profile_document(session: AsyncSession, user: User, viewer_id: int | None) -> dict[str, Any]:
    following = False
    if viewer_id is not None:
        following = bool(
            await session.scalar(
                select(func.count()).select_from(Follow).where(
                    Follow.follower_id == viewer_id, Follow.followed_id == user.id
                )
            )
        )
    return {"username": user.username, "bio": user.bio, "image": user.image, "following": following}


async def find_article(session: AsyncSession, slug: str) -> Article:
    article = await session.scalar(select(Article).where(Article.slug == slug))
    if article is None:
        raise error(404, "article", "not found")
    return article


async def article_document(
    session: AsyncSession, article: Article, viewer_id: int | None, *, include_body: bool
) -> dict[str, Any]:
    author = await session.get(User, article.author_id)
    assert author is not None
    tags = list(
        (
            await session.scalars(
                select(ArticleTag.tag).where(ArticleTag.article_id == article.id).order_by(ArticleTag.position)
            )
        ).all()
    )
    favorites_count = int(
        await session.scalar(select(func.count()).select_from(Favorite).where(Favorite.article_id == article.id)) or 0
    )
    favorited = False
    if viewer_id is not None:
        favorited = bool(
            await session.scalar(
                select(func.count()).select_from(Favorite).where(
                    Favorite.article_id == article.id, Favorite.user_id == viewer_id
                )
            )
        )
    result: dict[str, Any] = {
        "slug": article.slug,
        "title": article.title,
        "description": article.description,
        "tagList": tags,
        "createdAt": article.created_at,
        "updatedAt": article.updated_at,
        "favorited": favorited,
        "favoritesCount": favorites_count,
        "author": await profile_document(session, author, viewer_id),
    }
    if include_body:
        result["body"] = article.body
    return result


async def comment_document(session: AsyncSession, comment: Comment, viewer_id: int | None) -> dict[str, Any]:
    author = await session.get(User, comment.author_id)
    assert author is not None
    return {
        "id": comment.id,
        "createdAt": comment.created_at,
        "updatedAt": comment.updated_at,
        "body": comment.body,
        "author": await profile_document(session, author, viewer_id),
    }


async def register(request: web.Request) -> web.Response:
    data = await payload(request, "user")
    username = require_text(data, "username")
    email = require_text(data, "email")
    password = require_text(data, "password", minimum=8)
    async with request.app["sessions"]() as session:
        duplicate = await session.scalar(select(User).where(User.username == username))
        if duplicate is not None:
            raise error(409, "username", "has already been taken")
        duplicate = await session.scalar(select(User).where(User.email == email))
        if duplicate is not None:
            raise error(409, "email", "has already been taken")
        user = User(username=username, email=email, password_hash=PASSWORDS.hash(password), bio=None, image=None)
        session.add(user)
        try:
            await session.commit()
        except IntegrityError as exc:
            await session.rollback()
            field = "username" if await session.scalar(select(User).where(User.username == username)) else "email"
            raise error(409, field, "has already been taken") from exc
        return web.json_response(user_document(request.app, user), status=201)


async def login(request: web.Request) -> web.Response:
    data = await payload(request, "user")
    email = require_text(data, "email")
    password = require_text(data, "password")
    async with request.app["sessions"]() as session:
        user = await session.scalar(select(User).where(User.email == email))
        try:
            if user is None or not PASSWORDS.verify(user.password_hash, password):
                raise error(401, "credentials", "invalid")
        except VerificationError as exc:
            raise error(401, "credentials", "invalid") from exc
        return web.json_response(user_document(request.app, user))


async def get_current_user(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        return web.json_response(user_document(request.app, user))


async def update_current_user(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        data = await payload(request, "user")
        for field in ("username", "email"):
            if field in data:
                value = require_text(data, field)
                existing = await session.scalar(select(User).where(getattr(User, field) == value, User.id != user.id))
                if existing is not None:
                    raise error(409, field, "has already been taken")
                setattr(user, field, value)
        if "password" in data:
            user.password_hash = PASSWORDS.hash(require_text(data, "password", minimum=8))
        for field in ("bio", "image"):
            if field in data:
                value = data[field]
                if value is not None and not isinstance(value, str):
                    raise error(422, field, "is invalid")
                setattr(user, field, value or None)
        try:
            await session.commit()
        except IntegrityError as exc:
            await session.rollback()
            raise error(409, "user", "has already been taken") from exc
        return web.json_response(user_document(request.app, user))


async def get_profile(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        viewer = await auth_user(request, session, required=False)
        user = await session.scalar(select(User).where(User.username == request.match_info["username"]))
        if user is None:
            raise error(404, "profile", "not found")
        return web.json_response({"profile": await profile_document(session, user, viewer.id if viewer else None)})


async def change_follow(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        viewer = await auth_user(request, session, required=True)
        assert viewer is not None
        user = await session.scalar(select(User).where(User.username == request.match_info["username"]))
        if user is None:
            raise error(404, "profile", "not found")
        if request.method == "POST":
            await session.execute(
                sqlite_insert(Follow).values(follower_id=viewer.id, followed_id=user.id).on_conflict_do_nothing()
            )
        else:
            await session.execute(
                delete(Follow).where(Follow.follower_id == viewer.id, Follow.followed_id == user.id)
            )
        await session.commit()
        return web.json_response({"profile": await profile_document(session, user, viewer.id)})


async def create_article(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        data = await payload(request, "article")
        title = require_text(data, "title")
        description = require_text(data, "description")
        body = require_text(data, "body")
        tags = data.get("tagList", [])
        if not isinstance(tags, list) or any(not isinstance(tag, str) or not tag for tag in tags):
            raise error(422, "tagList", "is invalid")
        base_slug = slugify(title) or "article"
        slug = base_slug
        suffix = 2
        while await session.scalar(select(Article.id).where(Article.slug == slug)) is not None:
            slug = f"{base_slug}-{suffix}"
            suffix += 1
        now = timestamp()
        article = Article(
            author_id=user.id,
            slug=slug,
            title=title,
            description=description,
            body=body,
            created_at=now,
            updated_at=now,
        )
        session.add(article)
        await session.flush()
        for position, tag in enumerate(dict.fromkeys(tags)):
            session.add(ArticleTag(article_id=article.id, tag=tag, position=position))
        await session.commit()
        return web.json_response(
            {"article": await article_document(session, article, user.id, include_body=True)}, status=201
        )


async def get_article(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        viewer = await auth_user(request, session, required=False)
        article = await find_article(session, request.match_info["slug"])
        return web.json_response(
            {"article": await article_document(session, article, viewer.id if viewer else None, include_body=True)}
        )


async def list_articles(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        viewer = await auth_user(request, session, required=False)
        statement = select(Article)
        author = request.query.get("author")
        tag = request.query.get("tag")
        favorited = request.query.get("favorited")
        if author:
            statement = statement.join(User, User.id == Article.author_id).where(User.username == author)
        if tag:
            statement = statement.join(ArticleTag, ArticleTag.article_id == Article.id).where(ArticleTag.tag == tag)
        if favorited:
            favorite_user = User.__table__.alias("favorite_user")
            statement = (
                statement.join(Favorite, Favorite.article_id == Article.id)
                .join(favorite_user, favorite_user.c.id == Favorite.user_id)
                .where(favorite_user.c.username == favorited)
            )
        statement = statement.distinct()
        total = int(await session.scalar(select(func.count()).select_from(statement.subquery())) or 0)
        limit = optional_int(request, "limit", 20)
        offset = optional_int(request, "offset", 0)
        articles = list((await session.scalars(statement.order_by(Article.id.desc()).limit(limit).offset(offset))).all())
        documents = [
            await article_document(session, article, viewer.id if viewer else None, include_body=False)
            for article in articles
        ]
        return web.json_response({"articles": documents, "articlesCount": total})


async def feed_articles(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        viewer = await auth_user(request, session, required=True)
        assert viewer is not None
        statement = select(Article).join(Follow, Follow.followed_id == Article.author_id).where(
            Follow.follower_id == viewer.id
        )
        total = int(await session.scalar(select(func.count()).select_from(statement.subquery())) or 0)
        limit = optional_int(request, "limit", 20)
        offset = optional_int(request, "offset", 0)
        articles = list((await session.scalars(statement.order_by(Article.id.desc()).limit(limit).offset(offset))).all())
        documents = [await article_document(session, article, viewer.id, include_body=False) for article in articles]
        return web.json_response({"articles": documents, "articlesCount": total})


async def update_article(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        article = await find_article(session, request.match_info["slug"])
        if article.author_id != user.id:
            raise error(403, "article", "forbidden")
        data = await payload(request, "article")
        if "title" in data:
            article.title = require_text(data, "title")
        for field in ("description", "body"):
            if field in data:
                setattr(article, field, require_text(data, field))
        if "tagList" in data:
            tags = data["tagList"]
            if not isinstance(tags, list) or any(not isinstance(tag, str) or not tag for tag in tags):
                raise error(422, "tagList", "is invalid")
            await session.execute(delete(ArticleTag).where(ArticleTag.article_id == article.id))
            for position, tag in enumerate(dict.fromkeys(tags)):
                session.add(ArticleTag(article_id=article.id, tag=tag, position=position))
        article.updated_at = timestamp()
        await session.commit()
        return web.json_response({"article": await article_document(session, article, user.id, include_body=True)})


async def delete_article(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        article = await find_article(session, request.match_info["slug"])
        if article.author_id != user.id:
            raise error(403, "article", "forbidden")
        await session.delete(article)
        await session.commit()
        return web.Response(status=204)


async def change_favorite(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        article = await find_article(session, request.match_info["slug"])
        if request.method == "POST":
            await session.execute(
                sqlite_insert(Favorite).values(user_id=user.id, article_id=article.id).on_conflict_do_nothing()
            )
        else:
            await session.execute(
                delete(Favorite).where(Favorite.user_id == user.id, Favorite.article_id == article.id)
            )
        await session.commit()
        return web.json_response({"article": await article_document(session, article, user.id, include_body=True)})


async def add_comment(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        data = await payload(request, "comment")
        body = require_text(data, "body")
        article = await find_article(session, request.match_info["slug"])
        now = timestamp()
        comment = Comment(article_id=article.id, author_id=user.id, body=body, created_at=now, updated_at=now)
        session.add(comment)
        await session.commit()
        return web.json_response(
            {"comment": await comment_document(session, comment, user.id)}, status=201
        )


async def list_comments(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        viewer = await auth_user(request, session, required=False)
        article = await find_article(session, request.match_info["slug"])
        comments = list(
            (
                await session.scalars(select(Comment).where(Comment.article_id == article.id).order_by(Comment.id))
            ).all()
        )
        return web.json_response(
            {"comments": [await comment_document(session, comment, viewer.id if viewer else None) for comment in comments]}
        )


async def delete_comment(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        user = await auth_user(request, session, required=True)
        assert user is not None
        article = await find_article(session, request.match_info["slug"])
        try:
            comment_id = int(request.match_info["comment_id"])
        except ValueError as exc:
            raise error(404, "comment", "not found") from exc
        comment = await session.scalar(
            select(Comment).where(Comment.id == comment_id, Comment.article_id == article.id)
        )
        if comment is None:
            raise error(404, "comment", "not found")
        if comment.author_id != user.id:
            raise error(403, "comment", "forbidden")
        await session.delete(comment)
        await session.commit()
        return web.Response(status=204)


async def list_tags(request: web.Request) -> web.Response:
    async with request.app["sessions"]() as session:
        tags = list((await session.scalars(select(ArticleTag.tag).distinct().order_by(ArticleTag.tag))).all())
        return web.json_response({"tags": tags})


async def close_engine(app: web.Application) -> None:
    await app["engine"].dispose()


def add_routes(app: web.Application, prefix: str) -> None:
    app.router.add_post(f"{prefix}/users", register)
    app.router.add_post(f"{prefix}/users/login", login)
    app.router.add_get(f"{prefix}/user", get_current_user)
    app.router.add_put(f"{prefix}/user", update_current_user)
    app.router.add_get(f"{prefix}/profiles/{{username}}", get_profile)
    app.router.add_post(f"{prefix}/profiles/{{username}}/follow", change_follow)
    app.router.add_delete(f"{prefix}/profiles/{{username}}/follow", change_follow)
    app.router.add_get(f"{prefix}/articles/feed", feed_articles)
    app.router.add_get(f"{prefix}/articles", list_articles)
    app.router.add_post(f"{prefix}/articles", create_article)
    app.router.add_get(f"{prefix}/articles/{{slug}}", get_article)
    app.router.add_put(f"{prefix}/articles/{{slug}}", update_article)
    app.router.add_delete(f"{prefix}/articles/{{slug}}", delete_article)
    app.router.add_post(f"{prefix}/articles/{{slug}}/favorite", change_favorite)
    app.router.add_delete(f"{prefix}/articles/{{slug}}/favorite", change_favorite)
    app.router.add_get(f"{prefix}/articles/{{slug}}/comments", list_comments)
    app.router.add_post(f"{prefix}/articles/{{slug}}/comments", add_comment)
    app.router.add_delete(f"{prefix}/articles/{{slug}}/comments/{{comment_id}}", delete_comment)
    app.router.add_get(f"{prefix}/tags", list_tags)


def create_app(database: str | Path | None = None, secret_key: str | None = None) -> web.Application:
    database = database or Path("realworld.sqlite3")
    app = web.Application(middlewares=[errors_middleware])
    app["engine"] = create_engine(database)
    app["sessions"] = session_factory(app["engine"])
    app["secret_key"] = secret_key or secrets.token_hex(32)
    add_routes(app, "/api")
    add_routes(app, "/api/v1")
    app.on_cleanup.append(close_engine)
    return app
