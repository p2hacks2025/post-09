# app/api/endpoints/symbol.py
import logging
from typing import List
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.symbol import SymbolCreate, SymbolUpdate, SymbolResponse, UserSymbolsResponse
from app.crud.symbol import symbol_crud
from app.core.timezone import JST, jst_day_to_utc_range
from app.core.config import DECAY_HOURS

router = APIRouter()

logger = logging.getLogger(__name__)

@router.post(
    "/symbols",
    response_model=SymbolResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_symbol(*, db: Session = Depends(get_db), symbol_in: SymbolCreate):
    logging.info("[START] create_symbol")
    try:
        symbol = symbol_crud.create(db, obj_in=symbol_in)
    except ValueError as e:
        logging.error(f"create_symbol failed: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    logging.info("[END] create_symbol")
    return symbol

@router.get(
    "/symbols",
    response_model=List[SymbolResponse],
)
def read_symbols(*, db: Session = Depends(get_db), skip: int = 0, limit: int = 100):
    logging.info("[START] read_symbols")
    symbols = symbol_crud.get_multi(db, skip=skip, limit=limit)
    logging.info("[END] read_symbols")
    return symbols

@router.get(
    "/symbols/{uuid}",
    response_model=SymbolResponse,
)
def read_symbol(*, db: Session = Depends(get_db), uuid: str):
    logging.info("[START] read_symbol")
    symbol = symbol_crud.get(db, uuid)
    if symbol is None:
        logging.error(f"Symbol with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Symbol not found")
    logging.info("[END] read_symbol")
    return symbol

@router.put(
    "/symbols/{uuid}",
    response_model=SymbolResponse,
)
def update_symbol(*, db: Session = Depends(get_db), uuid: str, symbol_in: SymbolUpdate):
    logging.info("[START] update_symbol")
    symbol = symbol_crud.get(db, uuid)
    if symbol is None:
        logging.error(f"Symbol with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Symbol not found")
    try:
        symbol = symbol_crud.update(db, db_obj=symbol, obj_in=symbol_in)
    except ValueError as e:
        logging.error(f"update_symbol failed: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    logging.info("[END] update_symbol")
    return symbol

@router.delete(
    "/symbols/{uuid}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_symbol(*, db: Session = Depends(get_db), uuid: str):
    logging.info("[START] delete_symbol")
    symbol = symbol_crud.get(db, uuid)
    if symbol is None:
        logging.error(f"Symbol with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Symbol not found")
    symbol_crud.remove(db, db_obj=symbol)
    logging.info("[END] delete_symbol")
    return

@router.get(
    "/users/{user_uuid}/symbols",
    response_model=UserSymbolsResponse,
)
def read_symbols_by_user(
    *, db: Session = Depends(get_db), user_uuid: str, skip: int = 0, limit: int = 100
):
    logging.info("[START] read_symbols_by_user")
    symbols = symbol_crud.get_multi_by_user(db, user_uuid=user_uuid, skip=skip, limit=limit)
    logging.info("[END] read_symbols_by_user")
    return UserSymbolsResponse(user_uuid=user_uuid, symbols=symbols)

# 特定のシンボルの、キラキラレベルが減少するまでの残り時間（hours）を取得するエンドポイント
@router.get(
    "/symbols/{uuid}/kirakira_remaining_time",
    response_model=int,
)
def get_kirakira_remaining_time(*, db: Session = Depends(get_db), uuid: str):
    logging.info("[START] get_kirakira_remaining_time")
    symbol = symbol_crud.get(db, uuid)
    if symbol is None:
        logging.error(f"Symbol with uuid {uuid} not found")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Symbol not found")

    if symbol.kirakira_level <= 0:
        logging.info("[END] get_kirakira_remaining_time")
        return 0  # キラキラレベルが0以下なら残り時間は0

        # Python側で現在時刻を作る（UTC推奨）
    now = datetime.now(timezone.utc)

    updated_at = symbol.updated_at
    # DBからnaive datetime（tz無し）が返る環境対策：UTC扱いで寄せる
    if updated_at.tzinfo is None:
        updated_at = updated_at.replace(tzinfo=timezone.utc)

    elapsed_hours = (now - updated_at).total_seconds() / 3600.0
    remaining = max(0, DECAY_HOURS - elapsed_hours)
    logging.info("[END] get_kirakira_remaining_time")
    return int(remaining)