# app/schemas/step.py
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

class StepCreate(BaseModel):
    user_uuid: str = Field(..., description="ユーザーUUID")
    step: int = Field(..., ge=0, description="歩数")
    is_started: bool = Field(..., description="開始の歩数か判断")
    created_at: DateTimeType = Field(..., description="作成日時")

    model_config = ConfigDict(from_attributes=True)


class StepUpdate(BaseModel):
    step: Optional[int] = Field(None, ge=0, description="歩数")
    is_started: Optional[bool] = Field(None, description="開始の歩数か判断")


class StepResponse(JSTResponseModel):
    uuid: str
    user_uuid: str
    step: int
    is_started: bool
    created_at: DateTimeType

    user: Optional[UserResponse] = None

    model_config = ConfigDict(from_attributes=True)

class LatestSessionStepsResponse(JSTResponseModel):
    user_uuid: str
    start_uuid: str
    stop_uuid: str
    started_at: DateTimeType
    stopped_at: DateTimeType
    steps: int = Field(..., description="歩数")

class DailyTotalStepsResponse(JSTResponseModel):
    user_uuid: str
    total_steps: int = Field(..., ge=0, description="その日の合計歩数")