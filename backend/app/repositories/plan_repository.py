from __future__ import annotations

from sqlalchemy.orm import Session

from app.models import Plan


class PlanRepository:
    def __init__(self, db: Session):
        self.db = db

    def list_for_user(self, user_id: int, *, is_admin: bool) -> list[Plan]:
        query = self.db.query(Plan).order_by(Plan.plan_id.desc())
        if not is_admin:
            query = query.filter(Plan.user_id == user_id)
        return query.all()

    def get_for_user(self, plan_id: int, user_id: int, *, is_admin: bool) -> Plan | None:
        query = self.db.query(Plan).filter(Plan.plan_id == plan_id)
        if not is_admin:
            query = query.filter(Plan.user_id == user_id)
        return query.first()

    def create(
        self,
        *,
        user_id: int,
        plan_name: str,
        file_path: str,
        file_type: str,
        file_size: int | None,
    ) -> Plan:
        row = Plan(
            user_id=user_id,
            plan_name=plan_name,
            file_path=file_path,
            file_type=file_type,
            file_size=file_size,
            status="pending",
            processing_progress=0,
        )
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row

    def save(self, row: Plan) -> Plan:
        self.db.add(row)
        self.db.commit()
        self.db.refresh(row)
        return row

