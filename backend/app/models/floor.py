from __future__ import annotations

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class Floor(Base):
    __tablename__ = "floors"

    __table_args__ = (Index("ix_floors_plan_id", "plan_id"),)

    floor_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    plan_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("plans.plan_id", ondelete="CASCADE"), nullable=False
    )

    floor_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    floor_number: Mapped[int | None] = mapped_column(Integer, nullable=True)

    created_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )
    updated_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )

    plan: Mapped["Plan"] = relationship(back_populates="floors")
    elements: Mapped[list["Element"]] = relationship(
        back_populates="floor", cascade="all,delete"
    )

