# app/models/symbol.py
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func, UniqueConstraint, Float
from sqlalchemy.orm import relationship

from app.db.base_class import Base
import uuid

class Symbol(Base):
    __tablename__ = "symbol"

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

    symbol_name = Column(String(255), nullable=False)

    symbol_x_coord = Column(Float, nullable=False)

    symbol_y_coord = Column(Float, nullable=False)

    kirakira_level = Column(Integer, nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
        index=True,
    )

    __table_args__ = (
        UniqueConstraint('user_uuid', 'symbol_name', name='uq_user_symbol_name'),
    )

    # リレーション
    user = relationship("User", back_populates="symbols")