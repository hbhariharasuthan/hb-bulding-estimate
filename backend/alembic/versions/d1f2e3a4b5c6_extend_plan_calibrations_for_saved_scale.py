"""extend_plan_calibrations_for_saved_scale

Revision ID: d1f2e3a4b5c6
Revises: a7b8c9d0e1f2
Create Date: 2026-03-27 19:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "d1f2e3a4b5c6"
down_revision: Union[str, Sequence[str], None] = "a7b8c9d0e1f2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("plan_calibrations", sa.Column("scale_key", sa.String(length=20), nullable=True))
    op.add_column("plan_calibrations", sa.Column("dpi", sa.Integer(), nullable=True))
    op.add_column("plan_calibrations", sa.Column("mm_per_pixel", sa.Double(), nullable=True))
    op.add_column("plan_calibrations", sa.Column("output_unit", sa.String(length=10), nullable=True))
    op.add_column("plan_calibrations", sa.Column("x1", sa.Float(), nullable=True))
    op.add_column("plan_calibrations", sa.Column("y1", sa.Float(), nullable=True))
    op.add_column("plan_calibrations", sa.Column("x2", sa.Float(), nullable=True))
    op.add_column("plan_calibrations", sa.Column("y2", sa.Float(), nullable=True))
    op.add_column(
        "plan_calibrations",
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
    )
    op.add_column("plan_calibrations", sa.Column("updated_by", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_plan_calibrations_updated_by_users",
        "plan_calibrations",
        "users",
        ["updated_by"],
        ["user_id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_plan_calibrations_updated_by_users", "plan_calibrations", type_="foreignkey")
    op.drop_column("plan_calibrations", "updated_by")
    op.drop_column("plan_calibrations", "is_active")
    op.drop_column("plan_calibrations", "y2")
    op.drop_column("plan_calibrations", "x2")
    op.drop_column("plan_calibrations", "y1")
    op.drop_column("plan_calibrations", "x1")
    op.drop_column("plan_calibrations", "output_unit")
    op.drop_column("plan_calibrations", "mm_per_pixel")
    op.drop_column("plan_calibrations", "dpi")
    op.drop_column("plan_calibrations", "scale_key")
