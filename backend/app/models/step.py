# app/models/step.py
import uuid

from sqlalchemy import Column, Integer, String, Date, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship

from app.db.base_class import Base


class Step(Base):
    __tablename__ = "step"

    uuid = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True
    )

    # ユーザーのuuid（FK）
    user_uuid = Column(
        String(36),
        ForeignKey("user.uuid", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # 今日の日付（YYYY-MM-DD）
    date = Column(
        Date,
        nullable=False,
        index=True,
    )

    # 歩数
    step = Column(
        Integer,
        nullable=False,
        default=0,
    )

    # 同一ユーザーと同一日付の重複を禁止
    __table_args__ = (
        UniqueConstraint("user_uuid", "date", name="uq_step_user_date"),
        Index("ix_step_user_date", "user_uuid", "date"),
    )

    # リレーション
    user = relationship("User", back_populates="steps")
