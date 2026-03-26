from __future__ import annotations

import os
from collections.abc import AsyncGenerator

from fastapi import Depends
from fastapi_users_db_sqlalchemy import SQLAlchemyUserDatabase
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.models import User


def _async_database_url() -> str:
    raw = os.environ.get(
        "DATABASE_URL",
        "postgresql+psycopg2://admin:admin123@db:5432/bme_db",
    )
    if raw.startswith("postgresql+psycopg2://"):
        return raw.replace("postgresql+psycopg2://", "postgresql+asyncpg://", 1)
    if raw.startswith("postgresql://"):
        return raw.replace("postgresql://", "postgresql+asyncpg://", 1)
    return raw


engine = create_async_engine(_async_database_url())
async_session_maker = async_sessionmaker(engine, expire_on_commit=False)


async def get_async_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        yield session


async def get_user_db(session: AsyncSession = Depends(get_async_session)):
    yield SQLAlchemyUserDatabase(session, User)

