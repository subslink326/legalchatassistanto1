"""
backend/db/models.py
--------------------
Defines ORM entities with sensible indexes and cascading rules:

User 1‑‑* Project 1‑‑* Document 1‑‑* Chunk
"""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    TIMESTAMP,
    Boolean,
    ForeignKey,
    String,
    Text,
    Integer,
    Index,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base

# ---------- Mixins ---------- #
class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class UUIDMixin:
    id: Mapped[uuid.UUID] = mapped_column(
        default=uuid.uuid4, primary_key=True, unique=True
    )


# ---------- Models ---------- #
class User(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "users"
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    projects: Mapped[list["Project"]] = relationship(
        back_populates="owner",
        cascade="all, delete-orphan",
        lazy="joined",
    )


class Project(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "projects"
    name: Mapped[str] = mapped_column(String(255), index=True)
    description: Mapped[str | None] = mapped_column(Text)

    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    owner: Mapped["User"] = relationship(back_populates="projects")

    documents: Mapped[list["Document"]] = relationship(
        back_populates="project", cascade="all, delete-orphan"
    )


class Document(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "documents"
    filename: Mapped[str] = mapped_column(String(255))
    content_type: Mapped[str] = mapped_column(String(128))
    pages: Mapped[int] = mapped_column(Integer)
    storage_path: Mapped[str] = mapped_column(String(512))

    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"), index=True
    )
    project: Mapped["Project"] = relationship(back_populates="documents")

    chunks: Mapped[list["Chunk"]] = relationship(
        back_populates="document", cascade="all, delete-orphan"
    )

    __table_args__ = (Index("ix_document_project_filename", "project_id", "filename"),)


class Chunk(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "chunks"
    page: Mapped[int] = mapped_column(Integer)
    page_line: Mapped[str | None] = mapped_column(String(32))
    token_count: Mapped[int] = mapped_column(Integer)

    text: Mapped[str] = mapped_column(Text)

    # Embedding vector ID in Qdrant; store as UUID/str for easy joins
    vector_id: Mapped[str | None] = mapped_column(String(64), index=True)

    document_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("documents.id", ondelete="CASCADE"), index=True
    )
    document: Mapped["Document"] = relationship(back_populates="chunks")

    __table_args__ = (
        Index("ix_chunk_doc_page_line", "document_id", "page", "page_line"),
    )

# ------- Forward refs for type checkers ------- #
if TYPE_CHECKING:  # pragma: no cover
    from .models import Project, Document
