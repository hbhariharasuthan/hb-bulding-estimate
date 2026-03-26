from __future__ import annotations

from sqlalchemy import (
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class Element(Base):
    __tablename__ = "elements"

    __table_args__ = (
        Index("ix_elements_plan_id", "plan_id"),
        Index("ix_elements_floor_id", "floor_id"),
    )

    element_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    plan_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("plans.plan_id", ondelete="CASCADE"), nullable=False
    )
    floor_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("floors.floor_id", ondelete="SET NULL"), nullable=True
    )

    element_type: Mapped[str] = mapped_column(String(50), nullable=False)
    coordinates: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    pixel_length: Mapped[float | None] = mapped_column(Float, nullable=True)
    pixel_area: Mapped[float | None] = mapped_column(Float, nullable=True)

    length: Mapped[float | None] = mapped_column(Float, nullable=True)
    width: Mapped[float | None] = mapped_column(Float, nullable=True)
    height: Mapped[float | None] = mapped_column(Float, nullable=True)

    thickness: Mapped[float | None] = mapped_column(Float, nullable=True)
    area: Mapped[float | None] = mapped_column(Float, nullable=True)
    volume: Mapped[float | None] = mapped_column(Float, nullable=True)

    detected_label: Mapped[str | None] = mapped_column(String(50), nullable=True)
    confidence_score: Mapped[float | None] = mapped_column(Float, nullable=True)

    created_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )
    updated_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )

    plan: Mapped["Plan"] = relationship(back_populates="elements")
    floor: Mapped["Floor | None"] = relationship(back_populates="elements")

