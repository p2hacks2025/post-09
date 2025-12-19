# app/api/api.py
from fastapi import APIRouter

from app.api.endpoints import user, step, symbol

api_router = APIRouter()
api_router.include_router(user.router, tags=["user"], prefix="/user")
api_router.include_router(step.router, tags=["step"], prefix="/step")
api_router.include_router(symbol.router, tags=["symbol"], prefix="/symbol")