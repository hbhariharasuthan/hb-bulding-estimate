from __future__ import annotations

from app.db import SessionLocal
from app.models import MaterialMaster, PropertyMaster, UnitMaster
from app.seeders.material_seed_data import MATERIAL_STANDARDS


def seed_material_masters() -> None:
    session = SessionLocal()
    try:
        materials = sorted({item["material_name"] for item in MATERIAL_STANDARDS})
        properties = sorted({item["property_name"] for item in MATERIAL_STANDARDS})
        units = sorted({item["unit"] for item in MATERIAL_STANDARDS})

        for name in materials:
            if session.query(MaterialMaster).filter(MaterialMaster.name == name).first() is None:
                session.add(MaterialMaster(name=name))

        for name in properties:
            if session.query(PropertyMaster).filter(PropertyMaster.name == name).first() is None:
                session.add(PropertyMaster(name=name))

        for name in units:
            if session.query(UnitMaster).filter(UnitMaster.name == name).first() is None:
                session.add(UnitMaster(name=name))

        session.commit()
        print(
            "Material masters seeded: "
            f"{len(materials)} materials, "
            f"{len(properties)} properties, "
            f"{len(units)} units"
        )
    finally:
        session.close()


if __name__ == "__main__":
    seed_material_masters()
