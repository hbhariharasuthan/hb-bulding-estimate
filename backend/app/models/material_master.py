from __future__ import annotations

from sqlalchemy import Boolean, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class MaterialMaster(Base):
    __tablename__ = "material_masters"

    material_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="true")

    standards = relationship("MaterialStandard", back_populates="material")
