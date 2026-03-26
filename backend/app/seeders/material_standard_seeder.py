from __future__ import annotations

from app.db import SessionLocal
from app.models import MaterialMaster, MaterialStandard, PropertyMaster, UnitMaster
from app.seeders.material_seed_data import MATERIAL_STANDARDS


def seed_material_standards() -> None:
    session = SessionLocal()
    try:
        material_map = {
            row.name: row.material_id for row in session.query(MaterialMaster).all()
        }
        property_map = {
            row.name: row.property_id for row in session.query(PropertyMaster).all()
        }
        unit_map = {row.name: row.unit_id for row in session.query(UnitMaster).all()}

        for item in MATERIAL_STANDARDS:
            material_id = material_map.get(item["material_name"])
            property_id = property_map.get(item["property_name"])
            unit_id = unit_map.get(item["unit"])

            if material_id is None or property_id is None or unit_id is None:
                raise ValueError(
                    "Missing master data for standards seeding. "
                    "Run: --seeder material-masters first."
                )

            row = (
                session.query(MaterialStandard)
                .filter(MaterialStandard.material_id == material_id)
                .filter(MaterialStandard.property_id == property_id)
                .first()
            )
            if row is None:
                session.add(
                    MaterialStandard(
                        material_id=material_id,
                        property_id=property_id,
                        value=item["value"],
                        unit_id=unit_id,
                        default=True,
                    )
                )
            else:
                row.value = item["value"]
                row.unit_id = unit_id
                row.default = True

        session.commit()
        print(f"Material standards seeded: {len(MATERIAL_STANDARDS)}")
    finally:
        session.close()


if __name__ == "__main__":
    seed_material_standards()
