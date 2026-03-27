"""create site settings

Revision ID: f2a1c9b8d7e6
Revises: e1a2b3c4d5e6
Create Date: 2026-03-27 12:10:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "f2a1c9b8d7e6"
down_revision: Union[str, Sequence[str], None] = "e1a2b3c4d5e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "site_settings",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("site_name", sa.String(length=255), nullable=True),
        sa.Column("site_admin_email", sa.String(length=255), nullable=True),
        sa.Column("site_logo", sa.String(length=500), nullable=True),
        sa.Column("login_background", sa.String(length=500), nullable=True),
        sa.Column("site_admin_contact_number", sa.String(length=50), nullable=True),
        sa.Column("razorpay_key", sa.String(length=255), nullable=True),
        sa.Column("razorpay_secret", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("site_settings")
