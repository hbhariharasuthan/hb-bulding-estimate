from __future__ import annotations

from sqlalchemy import DateTime, Double, Float, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class PlanCalibration(Base):
    __tablename__ = "plan_calibrations"

    __table_args__ = (Index("ix_plan_calibrations_plan_id", "plan_id"),)

    calibration_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    plan_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("plans.plan_id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )

    page_number: Mapped[int | None] = mapped_column(Integer, nullable=True)

    pixel_length: Mapped[float | None] = mapped_column(Float, nullable=True)
    real_length: Mapped[float | None] = mapped_column(Float, nullable=True)
    unit: Mapped[str | None] = mapped_column(String(10), nullable=True)
    scale_factor: Mapped[float | None] = mapped_column(Double, nullable=True)

    reference_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    reference_label: Mapped[str | None] = mapped_column(String(100), nullable=True)

    created_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )
    updated_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )

    plan: Mapped["Plan"] = relationship(back_populates="calibrations")

