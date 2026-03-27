from __future__ import annotations

from sqlalchemy import Boolean, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class PropertyMaster(Base):
    __tablename__ = "property_masters"

    property_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False, unique=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="true")

    standards = relationship("MaterialStandard", back_populates="property")
