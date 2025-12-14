# app/api/endpoints/step.py
from typing import List
import logging
from datetime import date as date_type

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.step import StepCreate, StepUpdate, StepResponse
from app.crud.step import step_crud

router = APIRouter()

logger = logging.getLogger(__name__)


@router.post(
    "/steps",
    response_model=StepResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_step(*, db: Session = Depends(get_db), step_in: StepCreate):
    logging.info("[START] create_step")
    try:
        step = step_crud.create(db, obj_in=step_in)
    except ValueError as e:
        logging.error(f"create_step failed: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    logging.info("[END] create_step")
    return step


@router.get(
    "/steps",
    response_model=List[StepResponse],
)
def read_steps(*, db: Session = Depends(get_db), skip: int = 0, limit: int = 100):
    logging.info("[START] read_steps")
    steps = step_crud.get_multi(db, skip=skip, limit=limit)
    logging.info("[END] read_steps")
    return steps


@router.get(
    "/steps/{uuid}",
    response_model=StepResponse,
)
def read_step(*, db: Session = Depends(get_db), uuid: str):
    logging.info("[START] read_step")
    step = step_crud.get(db, uuid)
    if step is None:
        logging.error(f"Step with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Step not found")
    logging.info("[END] read_step")
    return step


@router.put(
    "/steps/{uuid}",
    response_model=StepResponse,
)
def update_step(*, db: Session = Depends(get_db), uuid: str, step_in: StepUpdate):
    logging.info("[START] update_step")
    step = step_crud.get(db, uuid)
    if step is None:
        logging.error(f"Step with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Step not found")

    try:
        step = step_crud.update(db, db_obj=step, obj_in=step_in)
    except ValueError as e:
        logging.error(f"update_step failed: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    logging.info("[END] update_step")
    return step


@router.delete(
    "/steps/{uuid}",
    response_model=StepResponse,
)
def delete_step(*, db: Session = Depends(get_db), uuid: str):
    logging.info("[START] delete_step")
    step = step_crud.get(db, uuid)
    if step is None:
        logging.error(f"Step with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Step not found")

    try:
        deleted = step_crud.remove(db, uuid=uuid)
    except ValueError as e:
        logging.error(f"delete_step failed: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    logging.info("[END] delete_step")
    return deleted


# （任意・便利）ユーザーの歩数履歴を取得
@router.get(
    "/users/{user_uuid}/steps",
    response_model=List[StepResponse],
)
def read_steps_by_user(
    *, db: Session = Depends(get_db), user_uuid: str, skip: int = 0, limit: int = 100
):
    logging.info("[START] read_steps_by_user")
    steps = step_crud.get_multi_by_user(db, user_uuid=user_uuid, skip=skip, limit=limit)
    logging.info("[END] read_steps_by_user")
    return steps


# （任意・便利）ユーザー×日付の1件取得
@router.get(
    "/users/{user_uuid}/steps/{target_date}",
    response_model=StepResponse,
)
def read_step_by_user_and_date(
    *, db: Session = Depends(get_db), user_uuid: str, target_date: date_type
):
    logging.info("[START] read_step_by_user_and_date")
    step = step_crud.get_by_user_and_date(db, user_uuid=user_uuid, target_date=target_date)
    if step is None:
        logging.error(f"Step not found: user_uuid={user_uuid}, date={target_date}")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Step not found")
    logging.info("[END] read_step_by_user_and_date")
    return step
