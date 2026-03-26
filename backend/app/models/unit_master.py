from __future__ import annotations

from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class UnitMaster(Base):
    __tablename__ = "unit_masters"

    unit_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(20), nullable=False, unique=True)

    standards = relationship("MaterialStandard", back_populates="unit_ref")
