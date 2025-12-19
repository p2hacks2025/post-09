# app/schemas/symbol.py
from datetime import datetime as DateTimeType
from zoneinfo import ZoneInfo
from typing import Optional

from pydantic import BaseModel, Field, ConfigDict, field_serializer

from app.schemas.user import UserResponse

JST = ZoneInfo("Asia/Tokyo")
UTC = ZoneInfo("UTC")

class JSTResponseModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    @field_serializer("*")
    def _serialize_all(self, v):
        # datetime のみJSTへ（naiveならUTC扱いにしてからJSTへ）
        if isinstance(v, DateTimeType):
            if v.tzinfo is None:
                v = v.replace(tzinfo=UTC)
            return v.astimezone(JST)
        return v

class SymbolCreate(BaseModel):
    user_uuid: str = Field(..., description="ユーザーUUID")
    symbol_name: str = Field(..., description="シンボル名")
    symbol_x_coord: float = Field(..., description="シンボルのX座標")
    symbol_y_coord: float = Field(..., description="シンボルのY座標")
    kirakira_level: int = Field(0, ge=0, le=3, description="キラキラレベル")

    model_config = ConfigDict(from_attributes=True)

class SymbolUpdate(BaseModel):
    symbol_name: Optional[str] = Field(None, description="シンボル名")
    symbol_x_coord: Optional[float] = Field(None, description="シンボルのX座標")
    symbol_y_coord: Optional[float] = Field(None, description="シンボルのY座標")
    kirakira_level: Optional[int] = Field(0, ge=0, le=3, description="キラキラレベル")

    model_config = ConfigDict(from_attributes=True)

class SymbolResponse(JSTResponseModel):
    uuid: str
    user_uuid: str
    symbol_name: str
    symbol_x_coord: float
    symbol_y_coord: float
    kirakira_level: int
    created_at: DateTimeType
    updated_at: DateTimeType

    user: Optional[UserResponse] = None

    model_config = ConfigDict(from_attributes=True)

class UserSymbolsResponse(JSTResponseModel):
    user_uuid: str
    symbols: list[SymbolResponse] = Field(..., description="ユーザーのシンボル一覧")

    model_config = ConfigDict(from_attributes=True)