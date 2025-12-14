# app/api/endpoints/user.py
from typing import List
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.crud.user import user_crud

router = APIRouter()

logger = logging.getLogger(__name__)


@router.post(
    "/users",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_user(*, db: Session = Depends(get_db), user_in: UserCreate):
    logging.info("[START] create_user")
    user = user_crud.create(db, obj_in=user_in)
    logging.info("[END] create_user")
    return user


@router.get(
    "/users",
    response_model=List[UserResponse],
)
def read_users(*, db: Session = Depends(get_db), skip: int = 0, limit: int = 100):
    logging.info("[START] read_users")
    users = user_crud.get_multi(db, skip=skip, limit=limit)
    logging.info("[END] read_users")
    return users


@router.get(
    "/users/{uuid}",
    response_model=UserResponse,
)
def read_user(*, db: Session = Depends(get_db), uuid: str):
    logging.info("[START] read_user")
    user = user_crud.get(db, uuid)
    if user is None:
        logging.error(f"User with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    logging.info("[END] read_user")
    return user


@router.put(
    "/users/{uuid}",
    response_model=UserResponse,
)
def update_user(*, db: Session = Depends(get_db), uuid: str, user_in: UserUpdate):
    logging.info("[START] update_user")
    user = user_crud.get(db, uuid)
    if user is None:
        logging.error(f"User with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user = user_crud.update(db, db_obj=user, obj_in=user_in)
    logging.info("[END] update_user")
    return user


@router.delete(
    "/users/{uuid}",
    response_model=UserResponse,
)
def delete_user(*, db: Session = Depends(get_db), uuid: str):
    logging.info("[START] delete_user")
    user = user_crud.get(db, uuid)
    if user is None:
        logging.error(f"User with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    deleted = user_crud.remove(db, uuid=uuid)
    logging.info("[END] delete_user")
    return deleted
