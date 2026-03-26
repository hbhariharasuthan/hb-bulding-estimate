"""normalize material standards to master tables

Revision ID: e1a2b3c4d5e6
Revises: c3f4d9a1b2e7
Create Date: 2026-03-26 19:05:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e1a2b3c4d5e6"
down_revision: Union[str, Sequence[str], None] = "c3f4d9a1b2e7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "material_masters",
        sa.Column("material_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=50), nullable=False),
        sa.PrimaryKeyConstraint("material_id"),
        sa.UniqueConstraint("name"),
    )
    op.create_table(
        "property_masters",
        sa.Column("property_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.PrimaryKeyConstraint("property_id"),
        sa.UniqueConstraint("name"),
    )
    op.create_table(
        "unit_masters",
        sa.Column("unit_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=20), nullable=False),
        sa.PrimaryKeyConstraint("unit_id"),
        sa.UniqueConstraint("name"),
    )

    op.add_column("material_standards", sa.Column("material_id", sa.Integer(), nullable=True))
    op.add_column("material_standards", sa.Column("property_id", sa.Integer(), nullable=True))
    op.add_column("material_standards", sa.Column("unit_id", sa.Integer(), nullable=True))

    # Seed master tables from existing standards
    op.execute(
        """
        INSERT INTO material_masters (name)
        SELECT DISTINCT COALESCE(material_name, 'Unknown')
        FROM material_standards
        """
    )
    op.execute(
        """
        INSERT INTO property_masters (name)
        SELECT DISTINCT COALESCE(property_name, 'unknown_property')
        FROM material_standards
        """
    )
    op.execute(
        """
        INSERT INTO unit_masters (name)
        SELECT DISTINCT COALESCE(unit, 'unitless')
        FROM material_standards
        """
    )

    # Backfill FK columns
    op.execute(
        """
        UPDATE material_standards ms
        SET material_id = mm.material_id
        FROM material_masters mm
        WHERE mm.name = COALESCE(ms.material_name, 'Unknown')
        """
    )
    op.execute(
        """
        UPDATE material_standards ms
        SET property_id = pm.property_id
        FROM property_masters pm
        WHERE pm.name = COALESCE(ms.property_name, 'unknown_property')
        """
    )
    op.execute(
        """
        UPDATE material_standards ms
        SET unit_id = um.unit_id
        FROM unit_masters um
        WHERE um.name = COALESCE(ms.unit, 'unitless')
        """
    )

    op.alter_column("material_standards", "material_id", nullable=False)
    op.alter_column("material_standards", "property_id", nullable=False)
    op.alter_column("material_standards", "unit_id", nullable=False)

    op.create_foreign_key(
        "fk_material_standards_material_id",
        "material_standards",
        "material_masters",
        ["material_id"],
        ["material_id"],
    )
    op.create_foreign_key(
        "fk_material_standards_property_id",
        "material_standards",
        "property_masters",
        ["property_id"],
        ["property_id"],
    )
    op.create_foreign_key(
        "fk_material_standards_unit_id",
        "material_standards",
        "unit_masters",
        ["unit_id"],
        ["unit_id"],
    )

    op.create_unique_constraint(
        "uq_material_standards_material_property",
        "material_standards",
        ["material_id", "property_id"],
    )

    op.drop_column("material_standards", "material_name")
    op.drop_column("material_standards", "property_name")
    op.drop_column("material_standards", "unit")


def downgrade() -> None:
    op.add_column(
        "material_standards", sa.Column("material_name", sa.String(length=50), nullable=True)
    )
    op.add_column(
        "material_standards", sa.Column("property_name", sa.String(length=50), nullable=True)
    )
    op.add_column("material_standards", sa.Column("unit", sa.String(length=20), nullable=True))

    op.execute(
        """
        UPDATE material_standards ms
        SET material_name = mm.name
        FROM material_masters mm
        WHERE ms.material_id = mm.material_id
        """
    )
    op.execute(
        """
        UPDATE material_standards ms
        SET property_name = pm.name
        FROM property_masters pm
        WHERE ms.property_id = pm.property_id
        """
    )
    op.execute(
        """
        UPDATE material_standards ms
        SET unit = um.name
        FROM unit_masters um
        WHERE ms.unit_id = um.unit_id
        """
    )

    op.drop_constraint("uq_material_standards_material_property", "material_standards", type_="unique")
    op.drop_constraint("fk_material_standards_unit_id", "material_standards", type_="foreignkey")
    op.drop_constraint("fk_material_standards_property_id", "material_standards", type_="foreignkey")
    op.drop_constraint("fk_material_standards_material_id", "material_standards", type_="foreignkey")

    op.drop_column("material_standards", "unit_id")
    op.drop_column("material_standards", "property_id")
    op.drop_column("material_standards", "material_id")

    op.drop_table("unit_masters")
    op.drop_table("property_masters")
    op.drop_table("material_masters")
