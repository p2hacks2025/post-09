# app/api/api.py
from fastapi import APIRouter

from app.api.endpoints import user, step

api_router = APIRouter()
api_router.include_router(user.router, tags=["user"], prefix="/user")
api_router.include_router(step.router, tags=["step"], prefix="/step")