# app/main.py
from fastapi import FastAPI
from app.core.logging import setup_logging

from app.api.api import api_router
from app.db.base_class import Base
from app.db.session import engine
from app.models import User

setup_logging()

app = FastAPI()

Base.metadata.create_all(bind=engine)

app.include_router(api_router)