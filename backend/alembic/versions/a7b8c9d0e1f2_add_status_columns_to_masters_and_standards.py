"""add status columns to masters and standards

Revision ID: a7b8c9d0e1f2
Revises: f2a1c9b8d7e6
Create Date: 2026-03-27 13:05:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a7b8c9d0e1f2"
down_revision: Union[str, Sequence[str], None] = "f2a1c9b8d7e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "material_masters",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
    )
    op.add_column(
        "property_masters",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
    )
    op.add_column(
        "unit_masters",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
    )
    op.add_column(
        "material_standards",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
    )


def downgrade() -> None:
    op.drop_column("material_standards", "is_active")
    op.drop_column("unit_masters", "is_active")
    op.drop_column("property_masters", "is_active")
    op.drop_column("material_masters", "is_active")
