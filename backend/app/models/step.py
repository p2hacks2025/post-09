# app/models/step.py
import uuid

from sqlalchemy import Column, Integer, String, Date, ForeignKey, Boolean, DateTime, func, Index
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

    # 歩数
    step = Column(
        Integer,
        nullable=False,
        default=0,
    )

    is_started = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )

    __table_args__ = (
        Index("ix_step_user_date_created_at", "user_uuid", "created_at"),
    )


    # リレーション
    user = relationship("User", back_populates="steps")
