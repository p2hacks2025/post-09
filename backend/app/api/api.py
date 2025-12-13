from fastapi import APIRouter

from app.api.endpoints import tests

api_router = APIRouter()
api_router.include_router(tests.router, tags=["tests"], prefix="/tests")