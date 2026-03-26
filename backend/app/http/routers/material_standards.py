from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
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
    )


def _build_masters_response(db: Session) -> MastersResponse:
    materials = db.query(MaterialMaster).order_by(MaterialMaster.name.asc()).all()
    properties = db.query(PropertyMaster).order_by(PropertyMaster.name.asc()).all()
    units = db.query(UnitMaster).order_by(UnitMaster.name.asc()).all()

    return MastersResponse(
        materials=[MasterItem(id=m.material_id, name=m.name) for m in materials],
        properties=[MasterItem(id=p.property_id, name=p.name) for p in properties],
        units=[MasterItem(id=u.unit_id, name=u.name) for u in units],
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
def list_property_masters(db: Session = Depends(get_db)) -> list[MasterItem]:
    rows = db.query(PropertyMaster).order_by(PropertyMaster.name.asc()).all()
    return [MasterItem(id=row.property_id, name=row.name) for row in rows]


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
    row = PropertyMaster(name=name)
    db.add(row)
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.property_id, name=row.name)


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
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.property_id, name=row.name)


@router.get(
    "/units",
    response_model=list[MasterItem],
    summary="List unit masters",
)
def list_unit_masters(db: Session = Depends(get_db)) -> list[MasterItem]:
    rows = db.query(UnitMaster).order_by(UnitMaster.name.asc()).all()
    return [MasterItem(id=row.unit_id, name=row.name) for row in rows]


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
    row = UnitMaster(name=name)
    db.add(row)
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.unit_id, name=row.name)


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
    db.commit()
    db.refresh(row)
    return MasterItem(id=row.unit_id, name=row.name)


@router.get(
    "",
    response_model=list[MaterialStandardItem],
    summary="List material standards",
    description="Lists all material standards with resolved master names.",
)
def list_material_standards(db: Session = Depends(get_db)) -> list[MaterialStandardItem]:
    rows = db.query(MaterialStandard).order_by(MaterialStandard.standard_id.asc()).all()
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

    db.commit()
    db.refresh(row)
    return _to_standard_item(row)
