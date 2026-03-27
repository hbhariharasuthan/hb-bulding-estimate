from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class SiteSetting(Base):
    __tablename__ = "site_settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    site_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    site_admin_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    site_logo: Mapped[str | None] = mapped_column(String(500), nullable=True)
    login_background: Mapped[str | None] = mapped_column(String(500), nullable=True)
    site_admin_contact_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    razorpay_key: Mapped[str | None] = mapped_column(String(255), nullable=True)
    razorpay_secret: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
