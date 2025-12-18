# app/crud/step.py
from typing import List, Optional, Tuple
from datetime import date
from datetime import date as date_type

from sqlalchemy import and_
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

    def get_by_user_and_date(
        self, db_session: Session, *, user_uuid: str, target_date: date
    ) -> Optional[Step]:
        return (
            db_session.query(Step)
            .filter(Step.user_uuid == user_uuid, Step.date == target_date)
            .first()
        )

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
            is_started=obj_in.is_started,
        )
        db_session.add(db_obj)
        try:
            db_session.commit()
        except IntegrityError as e:
            db_session.rollback()
            raise ValueError(
                f"Step already exists for user_uuid={obj_in.user_uuid} date={obj_in.date}"
            ) from e

        db_session.refresh(db_obj)
        return db_obj

    def update(self, db_session: Session, *, db_obj: Step, obj_in: StepUpdate) -> Step:
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
    
    def get_latest_stop(self, db_session: Session, *, user_uuid: str) -> Optional[Step]:
        return (
            db_session.query(Step)
            .filter(Step.user_uuid == user_uuid, Step.is_started == False)
            .order_by(Step.created_at.desc())
            .first()
        )

    # 直前の start を取得
    def get_previous_start_before(
        self, db_session: Session, *, user_uuid: str, before_created_at
    ) -> Optional[Step]:
        return (
            db_session.query(Step)
            .filter(
                Step.user_uuid == user_uuid,
                Step.is_started == True,
                Step.created_at < before_created_at,
            )
            .order_by(Step.created_at.desc())
            .first()
        )

    def calc_latest_session_steps(self, db_session: Session, *, user_uuid: str) -> Tuple[Step, Step, int]:
        """
        直近 stop と、その直前 start を探して diff を返す
        return: (start_row, stop_row, diff_steps)
        """
        stop_row = self.get_latest_stop(db_session, user_uuid=user_uuid)
        if stop_row is None:
            raise ValueError("No stop record (is_started=False) found for this user.")

        start_row = self.get_previous_start_before(
            db_session, user_uuid=user_uuid, before_created_at=stop_row.created_at
        )
        if start_row is None:
            raise ValueError("No start record (is_started=True) found before the latest stop.")

        diff = stop_row.step - start_row.step
        if diff < 0:
            # センサー値の巻き戻り/端末再起動などを想定
            raise ValueError("Step counter decreased between start and stop (diff < 0).")

        return start_row, stop_row, diff

    def calc_daily_total_steps(self, db_session: Session, *, user_uuid: str, target_date: date_type) -> int:
        """
        指定日の start/stop を created_at 順に見て、start->stop の差分を合算
        """
        rows = (
            db_session.query(Step)
            .filter(Step.user_uuid == user_uuid, Step.date == target_date)
            .order_by(Step.created_at.asc())
            .all()
        )

        total = 0
        current_start: Optional[Step] = None

        for r in rows:
            if r.is_started:
                # start は上書き（連続startが来たら最後を採用する運用）
                current_start = r
            else:
                # stop
                if current_start is None:
                    continue  # start無しstopは無視（必要ならエラーでもOK）
                diff = r.step - current_start.step
                if diff >= 0:
                    total += diff
                # 1セッション終了
                current_start = None

        return total



step_crud = CRUDStep()
