# app/crud/step.py
from typing import List, Optional
from datetime import date

from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.step import Step
from app.schemas.step import StepCreate, StepUpdate


class CRUDStep:
    def get(self, db_session: Session, uuid: str) -> Optional[Step]:
        return db_session.query(Step).filter(Step.uuid == uuid).first()

    def get_multi(
        self, db_session: Session, *, skip: int = 0, limit: int = 100
    ) -> List[Step]:
        return db_session.query(Step).offset(skip).limit(limit).all()

    # 便利：ユーザー×日付で1件取得（「その日の歩数」）
    def get_by_user_and_date(
        self, db_session: Session, *, user_uuid: str, target_date: date
    ) -> Optional[Step]:
        return (
            db_session.query(Step)
            .filter(Step.user_uuid == user_uuid, Step.date == target_date)
            .first()
        )

    # 便利：ユーザーの歩数履歴一覧
    def get_multi_by_user(
        self, db_session: Session, *, user_uuid: str, skip: int = 0, limit: int = 100
    ) -> List[Step]:
        return (
            db_session.query(Step)
            .filter(Step.user_uuid == user_uuid)
            .order_by(Step.date.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def create(self, db_session: Session, *, obj_in: StepCreate) -> Step:
        db_obj = Step(
            user_uuid=obj_in.user_uuid,
            date=obj_in.date,
            step=obj_in.step,
        )
        db_session.add(db_obj)
        try:
            db_session.commit()
        except IntegrityError as e:
            # (user_uuid, date) のユニーク制約に引っかかる可能性がある
            db_session.rollback()
            raise ValueError(
                f"Step already exists for user_uuid={obj_in.user_uuid} date={obj_in.date}"
            ) from e

        db_session.refresh(db_obj)
        return db_obj

    def update(self, db_session: Session, *, db_obj: Step, obj_in: StepUpdate) -> Step:
        # Pydantic v2: model_dump(exclude_unset=True)
        update_data = obj_in.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            setattr(db_obj, field, value)

        db_session.add(db_obj)
        try:
            db_session.commit()
        except IntegrityError as e:
            db_session.rollback()
            raise ValueError("Step update failed due to constraint violation") from e

        db_session.refresh(db_obj)
        return db_obj

    def remove(self, db_session: Session, *, uuid: str) -> Step:
        obj = db_session.query(Step).filter(Step.uuid == uuid).first()
        if obj is None:
            raise ValueError(f"Step not found: uuid={uuid}")

        db_session.delete(obj)
        db_session.commit()
        return obj


step_crud = CRUDStep()
