from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.http.schemas.material_standards import (
    MasterCreateRequest,
    MastersResponse,
    MasterItem,
    MasterUpdateRequest,
    MaterialStandardCreateRequest,
    MaterialStandardItem,
    MaterialStandardUpdateRequest,
)
from app.models import MaterialMaster, MaterialStandard, PropertyMaster, UnitMaster

router = APIRouter(prefix="/api/v1/material-standards", tags=["Material Standards"])


def _to_standard_item(row: MaterialStandard) -> MaterialStandardItem:
    return MaterialStandardItem(
        standard_id=row.standard_id,
        material_id=row.material_id,
        material_name=row.material.name,
        property_id=row.property_id,
        property_name=row.property.name,
        value=row.value,
        unit_id=row.unit_id,
        unit_name=row.unit_ref.name,
        default=row.default,
        is_active=row.is_active,
    )


def _build_masters_response(db: Session) -> MastersResponse:
    materials = db.query(MaterialMaster).order_by(MaterialMaster.name.asc()).all()
    properties = db.query(PropertyMaster).order_by(PropertyMaster.name.asc()).all()
    units = db.query(UnitMaster).order_by(UnitMaster.name.asc()).all()

    return MastersResponse(
        materials=[MasterItem(id=m.material_id, name=m.name, is_active=m.is_active) for m in materials],
        properties=[MasterItem(id=p.property_id, name=p.name, is_active=p.is_active) for p in properties],
        units=[MasterItem(id=u.unit_id, name=u.name, is_active=u.is_active) for u in units],
    )


@router.get(
    "/material",
    response_model=MastersResponse,
    summary="Get material master dropdown data",
    description="Returns materials, properties, and units master data for frontend dropdowns.",
)
def get_material_dropdowns(db: Session = Depends(get_db)) -> MastersResponse:
    return _build_masters_response(db)


@router.get(
    "/masters",
    response_model=MastersResponse,
    summary="Get master dropdown data (deprecated)",
    description="Deprecated alias. Use /material instead.",
    deprecated=True,
)
def get_master_dropdowns(db: Session = Depends(get_db)) -> MastersResponse:
    return _build_masters_response(db)


@router.get(
    "/properties",
    response_model=list[MasterItem],
    summary="List property masters",
)
def list_property_masters(
    q: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    sort: str = Query(default="name"),
    order: str = Query(default="asc"),
    status_filter: str = Query(default="all"),
    db: Session = Depends(get_db),
) -> list[MasterItem]:
    query = db.query(PropertyMaster)
    if q:
        query = query.filter(PropertyMaster.name.ilike(f"%{q.strip()}%"))
    if status_filter == "active":
        query = query.filter(PropertyMaster.is_active.is_(True))
    elif status_filter == "inactive":
        query = query.filter(PropertyMaster.is_active.is_(False))
    sort_col = PropertyMaster.property_id if sort == "id" else PropertyMaster.name
    sort_expr = sort_col.desc() if order.lower() == "desc" else sort_col.asc()
    rows = query.order_by(sort_expr).offset((page - 1) * per_page).limit(per_page).all()
    return [MasterItem(id=row.property_id, name=row.name, is_active=row.is_active) for row in rows]


@router.post(
    "/properties",
    response_model=MasterItem,
    status_code=status.HTTP_201_CREATED,
    summary="Create property master",
)
def create_property_master(
    payload: MasterCreateRequest,
    db: Session = Depends(get_db),
) -> MasterItem:
    name = payload.name.strip()
    existing = db.query(PropertyMaster).filter(PropertyMaster.name == name).first()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Property master already exists.",
        )
    row = PropertyMaster(name=name, is_active=payload.is_active)
    db.add(row)
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.property_id, name=row.name, is_active=row.is_active)


@router.put(
    "/properties/{property_id}",
    response_model=MasterItem,
    summary="Update property master",
)
def update_property_master(
    property_id: int,
    payload: MasterUpdateRequest,
    db: Session = Depends(get_db),
) -> MasterItem:
    row = db.query(PropertyMaster).filter(PropertyMaster.property_id == property_id).first()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property master not found.")
    name = payload.name.strip()
    duplicate = (
        db.query(PropertyMaster)
        .filter(PropertyMaster.name == name, PropertyMaster.property_id != property_id)
        .first()
    )
    if duplicate is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Property master already exists.",
        )
    row.name = name
    row.is_active = payload.is_active
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.property_id, name=row.name, is_active=row.is_active)


@router.delete(
    "/properties/{property_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete property master",
)
def delete_property_master(property_id: int, db: Session = Depends(get_db)) -> None:
    row = db.query(PropertyMaster).filter(PropertyMaster.property_id == property_id).first()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property master not found.")
    in_use = db.query(MaterialStandard).filter(MaterialStandard.property_id == property_id).first()
    if in_use is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Property master is in use by material standards.",
        )
    db.delete(row)
    db.commit()


@router.get(
    "/units",
    response_model=list[MasterItem],
    summary="List unit masters",
)
def list_unit_masters(
    q: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    sort: str = Query(default="name"),
    order: str = Query(default="asc"),
    status_filter: str = Query(default="all"),
    db: Session = Depends(get_db),
) -> list[MasterItem]:
    query = db.query(UnitMaster)
    if q:
        query = query.filter(UnitMaster.name.ilike(f"%{q.strip()}%"))
    if status_filter == "active":
        query = query.filter(UnitMaster.is_active.is_(True))
    elif status_filter == "inactive":
        query = query.filter(UnitMaster.is_active.is_(False))
    sort_col = UnitMaster.unit_id if sort == "id" else UnitMaster.name
    sort_expr = sort_col.desc() if order.lower() == "desc" else sort_col.asc()
    rows = query.order_by(sort_expr).offset((page - 1) * per_page).limit(per_page).all()
    return [MasterItem(id=row.unit_id, name=row.name, is_active=row.is_active) for row in rows]


@router.post(
    "/units",
    response_model=MasterItem,
    status_code=status.HTTP_201_CREATED,
    summary="Create unit master",
)
def create_unit_master(
    payload: MasterCreateRequest,
    db: Session = Depends(get_db),
) -> MasterItem:
    name = payload.name.strip()
    existing = db.query(UnitMaster).filter(UnitMaster.name == name).first()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Unit master already exists.",
        )
    row = UnitMaster(name=name, is_active=payload.is_active)
    db.add(row)
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.unit_id, name=row.name, is_active=row.is_active)


@router.put(
    "/units/{unit_id}",
    response_model=MasterItem,
    summary="Update unit master",
)
def update_unit_master(
    unit_id: int,
    payload: MasterUpdateRequest,
    db: Session = Depends(get_db),
) -> MasterItem:
    row = db.query(UnitMaster).filter(UnitMaster.unit_id == unit_id).first()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unit master not found.")
    name = payload.name.strip()
    duplicate = (
        db.query(UnitMaster)
        .filter(UnitMaster.name == name, UnitMaster.unit_id != unit_id)
        .first()
    )
    if duplicate is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Unit master already exists.",
        )
    row.name = name
    row.is_active = payload.is_active
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.unit_id, name=row.name, is_active=row.is_active)


@router.delete(
    "/units/{unit_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete unit master",
)
def delete_unit_master(unit_id: int, db: Session = Depends(get_db)) -> None:
    row = db.query(UnitMaster).filter(UnitMaster.unit_id == unit_id).first()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unit master not found.")
    in_use = db.query(MaterialStandard).filter(MaterialStandard.unit_id == unit_id).first()
    if in_use is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Unit master is in use by material standards.",
        )
    db.delete(row)
    db.commit()


@router.get(
    "/materials",
    response_model=list[MasterItem],
    summary="List material masters",
)
def list_material_masters(
    q: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    sort: str = Query(default="name"),
    order: str = Query(default="asc"),
    status_filter: str = Query(default="all"),
    db: Session = Depends(get_db),
) -> list[MasterItem]:
    query = db.query(MaterialMaster)
    if q:
        query = query.filter(MaterialMaster.name.ilike(f"%{q.strip()}%"))
    if status_filter == "active":
        query = query.filter(MaterialMaster.is_active.is_(True))
    elif status_filter == "inactive":
        query = query.filter(MaterialMaster.is_active.is_(False))
    sort_col = MaterialMaster.material_id if sort == "id" else MaterialMaster.name
    sort_expr = sort_col.desc() if order.lower() == "desc" else sort_col.asc()
    rows = query.order_by(sort_expr).offset((page - 1) * per_page).limit(per_page).all()
    return [MasterItem(id=row.material_id, name=row.name, is_active=row.is_active) for row in rows]


@router.post(
    "/materials",
    response_model=MasterItem,
    status_code=status.HTTP_201_CREATED,
    summary="Create material master",
)
def create_material_master(payload: MasterCreateRequest, db: Session = Depends(get_db)) -> MasterItem:
    name = payload.name.strip()
    existing = db.query(MaterialMaster).filter(MaterialMaster.name == name).first()
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Material master already exists.")
    row = MaterialMaster(name=name, is_active=payload.is_active)
    db.add(row)
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.material_id, name=row.name, is_active=row.is_active)


@router.put(
    "/materials/{material_id}",
    response_model=MasterItem,
    summary="Update material master",
)
def update_material_master(
    material_id: int,
    payload: MasterUpdateRequest,
    db: Session = Depends(get_db),
) -> MasterItem:
    row = db.query(MaterialMaster).filter(MaterialMaster.material_id == material_id).first()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Material master not found.")
    name = payload.name.strip()
    duplicate = (
        db.query(MaterialMaster)
        .filter(MaterialMaster.name == name, MaterialMaster.material_id != material_id)
        .first()
    )
    if duplicate is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Material master already exists.")
    row.name = name
    row.is_active = payload.is_active
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.material_id, name=row.name, is_active=row.is_active)


@router.delete(
    "/materials/{material_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete material master",
)
def delete_material_master(material_id: int, db: Session = Depends(get_db)) -> None:
    row = db.query(MaterialMaster).filter(MaterialMaster.material_id == material_id).first()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Material master not found.")
    in_use = db.query(MaterialStandard).filter(MaterialStandard.material_id == material_id).first()
    if in_use is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Material master is in use by material standards.",
        )
    db.delete(row)
    db.commit()


@router.get(
    "",
    response_model=list[MaterialStandardItem],
    summary="List material standards",
    description="Lists all material standards with resolved master names.",
)
def list_material_standards(
    q: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    sort: str = Query(default="id"),
    order: str = Query(default="asc"),
    status_filter: str = Query(default="all"),
    db: Session = Depends(get_db),
) -> list[MaterialStandardItem]:
    query = db.query(MaterialStandard)
    if q:
        term = f"%{q.strip()}%"
        query = query.join(MaterialMaster).join(PropertyMaster).join(UnitMaster).filter(
            (MaterialMaster.name.ilike(term))
            | (PropertyMaster.name.ilike(term))
            | (UnitMaster.name.ilike(term))
        )
    if status_filter == "active":
        query = query.filter(MaterialStandard.is_active.is_(True))
    elif status_filter == "inactive":
        query = query.filter(MaterialStandard.is_active.is_(False))
    sort_col = MaterialStandard.standard_id
    if sort == "material":
        sort_col = MaterialStandard.material_id
    elif sort == "property":
        sort_col = MaterialStandard.property_id
    sort_expr = sort_col.desc() if order.lower() == "desc" else sort_col.asc()
    rows = query.order_by(sort_expr).offset((page - 1) * per_page).limit(per_page).all()
    return [_to_standard_item(row) for row in rows]


@router.post(
    "",
    response_model=MaterialStandardItem,
    status_code=status.HTTP_201_CREATED,
    summary="Create material standard",
    description="Creates a new material standard with material/property/unit IDs.",
)
def create_material_standard(
    payload: MaterialStandardCreateRequest,
    db: Session = Depends(get_db),
) -> MaterialStandardItem:
    material = db.query(MaterialMaster).filter(MaterialMaster.material_id == payload.material_id).first()
    prop = db.query(PropertyMaster).filter(PropertyMaster.property_id == payload.property_id).first()
    unit = db.query(UnitMaster).filter(UnitMaster.unit_id == payload.unit_id).first()
    if material is None or prop is None or unit is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid material_id, property_id, or unit_id.",
        )

    existing = (
        db.query(MaterialStandard)
        .filter(MaterialStandard.material_id == payload.material_id)
        .filter(MaterialStandard.property_id == payload.property_id)
        .first()
    )
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Standard already exists for this material and property.",
        )

    row = MaterialStandard(
        material_id=payload.material_id,
        property_id=payload.property_id,
        unit_id=payload.unit_id,
        value=payload.value,
        default=payload.default,
        is_active=payload.is_active,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return _to_standard_item(row)


@router.put(
    "/{standard_id}",
    response_model=MaterialStandardItem,
    summary="Update material standard",
    description="Updates unit/value/default for an existing material standard.",
)
def update_material_standard(
    standard_id: int,
    payload: MaterialStandardUpdateRequest,
    db: Session = Depends(get_db),
) -> MaterialStandardItem:
    row = db.query(MaterialStandard).filter(MaterialStandard.standard_id == standard_id).first()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Material standard not found.",
        )

    if payload.unit_id is not None:
        unit = db.query(UnitMaster).filter(UnitMaster.unit_id == payload.unit_id).first()
        if unit is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid unit_id.",
            )
        row.unit_id = payload.unit_id

    if payload.value is not None:
        row.value = payload.value
    if payload.default is not None:
        row.default = payload.default
    if payload.is_active is not None:
        row.is_active = payload.is_active

    db.commit()
    db.refresh(row)
    return _to_standard_item(row)


@router.delete(
    "/{standard_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete material standard",
)
def delete_material_standard(standard_id: int, db: Session = Depends(get_db)) -> None:
    row = db.query(MaterialStandard).filter(MaterialStandard.standard_id == standard_id).first()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Material standard not found.",
        )
    db.delete(row)
    db.commit()
