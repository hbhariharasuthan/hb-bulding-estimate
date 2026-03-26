from __future__ import annotations

import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker


DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    # Fallback for local dev / if compose env isn't set.
    "postgresql+psycopg2://admin:admin123@db:5432/bme_db",
)

# Using `future=True` behavior as SQLAlchemy 2.x style.
engine = create_engine(DATABASE_URL, future=True)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    future=True,
)


def get_db():
    """FastAPI dependency: provide a DB session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

