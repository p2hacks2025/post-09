# app/models/user.py
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from app.db.base_class import Base
import uuid

class User(Base):
    __tablename__ = "user"

    uuid = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True
    )

    name = Column(String(255), nullable=False)

    length = Column(Integer, nullable=False)  # 身長（cm）
    weight = Column(Integer, nullable=False)  # 体重（kg）

    steps = relationship(
        "Step",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    symbols = relationship(
        "Symbol",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )