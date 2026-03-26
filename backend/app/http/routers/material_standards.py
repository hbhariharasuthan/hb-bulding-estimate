from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import MaterialMaster, PropertyMaster, UnitMaster

router = APIRouter(prefix="/material-standards", tags=["material-standards"])


@router.get("/masters")
def get_master_dropdowns(db: Session = Depends(get_db)):
    materials = db.query(MaterialMaster).order_by(MaterialMaster.name.asc()).all()
    properties = db.query(PropertyMaster).order_by(PropertyMaster.name.asc()).all()
    units = db.query(UnitMaster).order_by(UnitMaster.name.asc()).all()

    return {
        "materials": [{"id": m.material_id, "name": m.name} for m in materials],
        "properties": [{"id": p.property_id, "name": p.name} for p in properties],
        "units": [{"id": u.unit_id, "name": u.name} for u in units],
    }
