from __future__ import annotations

from sqlalchemy import Boolean, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class MaterialStandard(Base):
    __tablename__ = "material_standards"

    standard_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    material_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    property_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    value: Mapped[float | None] = mapped_column(Float, nullable=True)
    unit: Mapped[str | None] = mapped_column(String(20), nullable=True)
    default: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default="false"
    )

