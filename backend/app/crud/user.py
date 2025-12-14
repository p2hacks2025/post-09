# app/crud/user.py
from typing import List, Optional
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate


class CRUDUser:
    def get(self, db_session: Session, uuid: str) -> Optional[User]:
        return db_session.query(User).filter(User.uuid == uuid).first()

    def get_multi(
        self, db_session: Session, *, skip: int = 0, limit: int = 100
    ) -> List[User]:
        return db_session.query(User).offset(skip).limit(limit).all()

    def create(self, db_session: Session, *, obj_in: UserCreate) -> User:
        db_obj = User(
            name=obj_in.name,
            length=obj_in.length,
            weight=obj_in.weight,
        )
        db_session.add(db_obj)
        db_session.commit()
        db_session.refresh(db_obj)
        return db_obj

    def update(
        self, db_session: Session, *, db_obj: User, obj_in: UserUpdate
    ) -> User:
        # Pydantic v2: model_dump(exclude_unset=True)
        update_data = obj_in.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            setattr(db_obj, field, value)

        db_session.add(db_obj)
        db_session.commit()
        db_session.refresh(db_obj)
        return db_obj

    def remove(self, db_session: Session, *, uuid: str) -> User:
        obj = db_session.query(User).filter(User.uuid == uuid).first()
        if obj is None:
            # 最低限実装なのでここは例外にしておく（必要ならHTTPExceptionに変更）
            raise ValueError(f"User not found: uuid={uuid}")

        db_session.delete(obj)
        db_session.commit()
        return obj


user_crud = CRUDUser()
