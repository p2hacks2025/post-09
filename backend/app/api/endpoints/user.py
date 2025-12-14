# app/api/endpoints/user.py
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.crud.user import user_crud

router = APIRouter()


@router.post(
    "/users",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_user(*, db: Session = Depends(get_db), user_in: UserCreate):
    user = user_crud.create(db, obj_in=user_in)
    return user


@router.get(
    "/users",
    response_model=List[UserResponse],
)
def read_users(*, db: Session = Depends(get_db), skip: int = 0, limit: int = 100):
    users = user_crud.get_multi(db, skip=skip, limit=limit)
    return users


@router.get(
    "/users/{uuid}",
    response_model=UserResponse,
)
def read_user(*, db: Session = Depends(get_db), uuid: str):
    user = user_crud.get(db, uuid)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


@router.put(
    "/users/{uuid}",
    response_model=UserResponse,
)
def update_user(*, db: Session = Depends(get_db), uuid: str, user_in: UserUpdate):
    user = user_crud.get(db, uuid)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user = user_crud.update(db, db_obj=user, obj_in=user_in)
    return user


@router.delete(
    "/users/{uuid}",
    response_model=UserResponse,
)
def delete_user(*, db: Session = Depends(get_db), uuid: str):
    user = user_crud.get(db, uuid)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    deleted = user_crud.remove(db, uuid=uuid)
    return deleted
