# app/crud/symbol.py
from datetime import datetime, timedelta, timezone
from sqlalchemy import update, func
from sqlalchemy.orm import Session

from app.models.symbol import Symbol
from app.schemas.symbol import SymbolCreate, SymbolUpdate, SymbolResponse, UserSymbolsResponse
from app.core.timezone import jst_day_to_utc_range
from app.core.config import DECAY_HOURS

class CRUDSymbol:
    def decay_kirakira_levels(self, db_session: Session) -> int:
        cutoff = datetime.now(timezone.utc) - timedelta(hours=DECAY_HOURS)
        stmt = (
            update(Symbol)
            .where(Symbol.kirakira_level > 0)
            .where(Symbol.updated_at < cutoff)
            .values(
                kirakira_level=Symbol.kirakira_level - 1,
                updated_at=func.now(),
            )
        )
        result = db_session.execute(stmt)
        db_session.commit()
        return result.rowcount

    def get(self, db_session: Session, uuid: str) -> Symbol | None:
        return db_session.query(Symbol).filter(Symbol.uuid == uuid).first()
    
    def get_multi(self, db_session: Session, *, skip: int = 0, limit: int = 100) -> list[Symbol]:
        return db_session.query(Symbol).offset(skip).limit(limit).all()

    def get_multi_by_user(
        self, db_session: Session, *, user_uuid: str, skip: int = 0, limit: int = 100
    ) -> list[Symbol]:
        return (
            db_session.query(Symbol)
            .filter(Symbol.user_uuid == user_uuid)
            .order_by(Symbol.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def create(self, db_session: Session, *, obj_in: SymbolCreate) -> Symbol:
        db_obj = Symbol(
            user_uuid=obj_in.user_uuid,
            symbol_name=obj_in.symbol_name,
            symbol_x_coord=obj_in.symbol_x_coord,
            symbol_y_coord=obj_in.symbol_y_coord,
            kirakira_level=obj_in.kirakira_level,
        )
        db_session.add(db_obj)
        db_session.commit()
        db_session.refresh(db_obj)
        return db_obj

    def update(
        self, db_session: Session, *, db_obj: Symbol, obj_in: SymbolUpdate
    ) -> Symbol:
        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_obj, field, value)
        db_session.add(db_obj)
        db_session.commit()
        db_session.refresh(db_obj)
        return db_obj

symbol_crud = CRUDSymbol()