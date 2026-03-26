from __future__ import annotations

from sqlalchemy import DateTime, Float, ForeignKey, Index, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class MaterialEstimate(Base):
    __tablename__ = "material_estimates"

    __table_args__ = (Index("ix_material_estimates_plan_id", "plan_id"),)

    estimate_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    plan_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("plans.plan_id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )

    bricks_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    cement_bags: Mapped[float | None] = mapped_column(Float, nullable=True)
    steel_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    sand_kg: Mapped[float | None] = mapped_column(Float, nullable=True)

    doors_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    windows_count: Mapped[int | None] = mapped_column(Integer, nullable=True)

    total_area: Mapped[float | None] = mapped_column(Float, nullable=True)
    total_volume: Mapped[float | None] = mapped_column(Float, nullable=True)

    estimate_date: Mapped[object | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    cost_estimate: Mapped[float | None] = mapped_column(Float, nullable=True)

    created_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )

    plan: Mapped["Plan"] = relationship(back_populates="material_estimate")

