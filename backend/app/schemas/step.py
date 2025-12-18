# app/schemas/step.py
from datetime import date as DateType, datetime as DateTimeType
from typing import Optional

from pydantic import BaseModel, Field, ConfigDict

from app.schemas.user import UserResponse


class StepCreate(BaseModel):
    user_uuid: str = Field(..., description="ユーザーUUID")
    date: DateType = Field(..., description="日付 (YYYY-MM-DD)")
    step: int = Field(..., ge=0, description="歩数")
    is_started: bool = Field(..., description="開始の歩数か判断")
    created_at: DateTimeType = Field(..., description="作成日時")

    model_config = ConfigDict(from_attributes=True)


class StepUpdate(BaseModel):
    date: Optional[DateType] = Field(None, description="日付 (YYYY-MM-DD)")
    step: Optional[int] = Field(None, ge=0, description="歩数")
    is_started: Optional[bool] = Field(None, description="開始の歩数か判断")


class StepResponse(BaseModel):
    uuid: str
    user_uuid: str
    date: DateType
    step: int
    is_started: bool

    user: Optional[UserResponse] = None

    model_config = ConfigDict(from_attributes=True)

class LatestSessionStepsResponse(BaseModel):
    user_uuid: str
    start_uuid: str
    stop_uuid: str
    started_at: DateTimeType
    stopped_at: DateTimeType
    steps: int = Field(..., description="歩数")

class DailyTotalStepsResponse(BaseModel):
    user_uuid: str
    date: DateType
    total_steps: int = Field(..., ge=0, description="その日の合計歩数")