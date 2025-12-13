# app/api/endpoints/tests.py

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.test_item import TestItem

router = APIRouter()

@router.get("/")
def hw_test():
    return {"message": "Hello world!"}

@router.post("/test-db")
def create_test_item(name: str, db: Session = Depends(get_db)):
    item = TestItem(name=name)
    db.add(item)
    db.commit()
    db.refresh(item)
    return {"id": item.id, "name": item.name}


@router.get("/test-db")
def list_test_items(db: Session = Depends(get_db)):
    items = db.query(TestItem).all()
    return [{"id": i.id, "name": i.name} for i in items]
