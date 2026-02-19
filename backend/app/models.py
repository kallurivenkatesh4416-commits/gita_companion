from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


class Verse(Base):
    __tablename__ = "verses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    chapter: Mapped[int] = mapped_column(Integer, nullable=False)
    verse_number: Mapped[int] = mapped_column(Integer, nullable=False)
    ref: Mapped[str] = mapped_column(String(16), nullable=False, unique=True, index=True)
    chapter_name: Mapped[str] = mapped_column(String(64), nullable=False, default="")
    sanskrit: Mapped[str] = mapped_column(Text, nullable=False)
    transliteration: Mapped[str] = mapped_column(Text, nullable=False, default="")
    translation: Mapped[str] = mapped_column(Text, nullable=False)
    translation_hi: Mapped[str] = mapped_column(Text, nullable=False, default="")
    tags: Mapped[list[str]] = mapped_column(JSONB, nullable=False, default=list)
    source: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    embedding: Mapped[list[float] | None] = mapped_column(Vector(384), nullable=True)

    favorites: Mapped[list["Favorite"]] = relationship(back_populates="verse", cascade="all,delete")


class Favorite(Base):
    __tablename__ = "favorites"
    __table_args__ = (UniqueConstraint("verse_id", name="uq_favorites_verse_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    verse_id: Mapped[int] = mapped_column(ForeignKey("verses.id", ondelete="CASCADE"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    verse: Mapped[Verse] = relationship(back_populates="favorites")
