from __future__ import annotations

from sqlalchemy import Boolean, Float, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class MaterialStandard(Base):
    __tablename__ = "material_standards"

    standard_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    material_id: Mapped[int] = mapped_column(
        ForeignKey("material_masters.material_id"), nullable=False
    )
    property_id: Mapped[int] = mapped_column(
        ForeignKey("property_masters.property_id"), nullable=False
    )
    value: Mapped[float | None] = mapped_column(Float, nullable=True)
    unit_id: Mapped[int] = mapped_column(ForeignKey("unit_masters.unit_id"), nullable=False)
    default: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default="false"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default="true"
    )

    material = relationship("MaterialMaster", back_populates="standards")
    property = relationship("PropertyMaster", back_populates="standards")
    unit_ref = relationship("UnitMaster", back_populates="standards")

