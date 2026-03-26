from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .plan import Plan


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column("user_id", Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    hashed_password: Mapped[str] = mapped_column("password_hash", String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False)
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default="true"
    )
    is_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default="false"
    )

    created_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )
    updated_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default="now()"
    )

    plans: Mapped[list["Plan"]] = relationship(back_populates="user", cascade="all,delete")

    @property
    def user_id(self) -> int:
        return self.id

    @property
    def password_hash(self) -> str:
        return self.hashed_password

