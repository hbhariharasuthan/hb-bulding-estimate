from __future__ import annotations

from sqlalchemy import (
    BigInteger,
    DateTime,
    Double,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class Plan(Base):
    __tablename__ = "plans"

    __table_args__ = (Index("ix_plans_user_id", "user_id"),)

    plan_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False
    )

    plan_name: Mapped[str] = mapped_column(String(100), nullable=False)
    file_path: Mapped[str] = mapped_column(String(255), nullable=False)
    file_type: Mapped[str] = mapped_column(String(20), nullable=False)
    file_size: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    unit_system: Mapped[str | None] = mapped_column(String(10), nullable=True)
    scale_type: Mapped[str | None] = mapped_column(String(20), nullable=True)
    scale_ratio: Mapped[float | None] = mapped_column(Float, nullable=True)
    scale_factor: Mapped[float | None] = mapped_column(Double, nullable=True)
    dpi: Mapped[float | None] = mapped_column(Float, nullable=True)

    total_pages: Mapped[int | None] = mapped_column(Integer, nullable=True)
    current_page: Mapped[int | None] = mapped_column(Integer, nullable=True)
    page_scale_factor: Mapped[float | None] = mapped_column(Double, nullable=True)

    detected_units: Mapped[str | None] = mapped_column(String(20), nullable=True)
    blueprint_type: Mapped[str | None] = mapped_column(String(50), nullable=True)

    status: Mapped[str] = mapped_column(
        String(20), nullable=False, server_default="pending"
    )
    processing_progress: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default="0"
    )
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)

    upload_date: Mapped[object | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    created_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )
    updated_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )

    user: Mapped["User"] = relationship(back_populates="plans")
    calibrations: Mapped[list["PlanCalibration"]] = relationship(
        back_populates="plan", cascade="all,delete"
    )
    floors: Mapped[list["Floor"]] = relationship(
        back_populates="plan", cascade="all,delete"
    )
    elements: Mapped[list["Element"]] = relationship(
        back_populates="plan", cascade="all,delete"
    )
    material_estimate: Mapped["MaterialEstimate | None"] = relationship(
        back_populates="plan",
        cascade="all,delete",
        uselist=False,
    )

