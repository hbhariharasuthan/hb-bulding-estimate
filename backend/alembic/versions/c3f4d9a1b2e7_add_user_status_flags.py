"""add_user_status_flags

Revision ID: c3f4d9a1b2e7
Revises: 7906f18722c6
Create Date: 2026-03-26 10:40:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c3f4d9a1b2e7"
down_revision: Union[str, Sequence[str], None] = "7906f18722c6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "users",
        sa.Column("is_verified", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column("users", "is_verified")
    op.drop_column("users", "is_active")

