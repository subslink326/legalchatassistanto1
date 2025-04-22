"""
backend/db/database.py
----------------------
• Creates a single async SQLAlchemy engine from the DATABASE_URL in settings.
• Provides `async_session` (async scoped‑session factory) for DI.
• Exposes `Base` metadata for Alembic autogeneration.
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from typing import Annotated
import logging
import tenacity

from sqlalchemy.ext.asyncio import (
    AsyncAttrs,
    create_async_engine,
    async_sessionmaker,
    AsyncSession,
)
from sqlalchemy.orm import declarative_base

from backend.config import settings
from fastapi import Depends

log = logging.getLogger(__name__)

# -------------------- #
# 1.  Declarative base #
# -------------------- #
Base = declarative_base(cls=AsyncAttrs)  # type: ignore [valid-type]

# -------------------- #
# 2.  Engine & session #
# -------------------- #
engine = create_async_engine(
    settings.database_url,
    echo=settings.is_dev,           # SQL echo only in dev
    pool_pre_ping=True,
    pool_size=settings.db_pool_size,
    max_overflow=settings.db_max_overflow,
    connect_args={"connect_timeout": 10},
)

async_session: async_sessionmaker[AsyncSession] = async_sessionmaker(
    bind=engine,
    expire_on_commit=False,
)

# FastAPI dependency
@asynccontextmanager
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield a single DB session per request and ensure close/rollback."""
    async with async_session() as session:
        try:
            yield session
        except Exception as exc:
            await session.rollback()
            log.exception("DB transaction rolled back due to: %s", exc)
            raise
        finally:
            await session.close()


# -------------------- #
# 3.  Utility helpers  #
# -------------------- #
@tenacity.retry(
    stop=tenacity.stop_after_attempt(5),
    wait=tenacity.wait_exponential(multiplier=1, min=1, max=10),
    retry=tenacity.retry_if_exception_type(Exception),
    reraise=True,
)
async def init_models() -> None:
    """Create tables in dev/demo environments (not for production migrations).
    
    Note: For production, use Alembic migrations instead.
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        log.info("Database schema created.")


# Convenient typing alias for DI
DBSessionDep = Annotated[AsyncSession, Depends(get_db)]  # noqa: E402  (FastAPI import later)