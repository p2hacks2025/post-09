from fastapi import FastAPI

from app.api.api import api_router
from app.db.base_class import Base
from app.db.session import engine
from app.models import test_item

app = FastAPI()

Base.metadata.create_all(bind=engine)

app.include_router(api_router)