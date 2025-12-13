# app/models/test_item.py
from sqlalchemy import Column, Integer, String
from app.db.base_class import Base

class TestItem(Base):
    __tablename__ = "test_items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
