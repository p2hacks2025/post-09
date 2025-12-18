# app/schemas/step.py
from datetime import date as DateType
from typing import Optional

from pydantic import BaseModel, Field, ConfigDict

from app.schemas.user import UserResponse


class StepCreate(BaseModel):
    user_uuid: str = Field(..., description="ユーザーUUID")
    date: DateType = Field(..., description="日付 (YYYY-MM-DD)")
    step: int = Field(..., ge=0, description="歩数")


class StepUpdate(BaseModel):
    date: Optional[DateType] = Field(None, description="日付 (YYYY-MM-DD)")
    step: Optional[int] = Field(None, ge=0, description="歩数")


class StepResponse(BaseModel):
    uuid: str
    user_uuid: str
    date: DateType
    step: int

    user: Optional[UserResponse] = None

    model_config = ConfigDict(from_attributes=True)
