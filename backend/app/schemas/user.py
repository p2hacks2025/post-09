# app/schemas/user.py
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

class UserCreate(BaseModel):
    name: str = Field(..., max_length=255)
    length: int = Field(..., ge=0, description="身長（cm）")
    weight: int = Field(..., ge=0, description="体重（kg）")

class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    length: Optional[int] = Field(None, ge=0)
    weight: Optional[int] = Field(None, ge=0)

class UserResponse(BaseModel):
    uuid: str
    name: str
    length: int
    weight: int

    # SQLAlchemyモデル → Pydantic 変換用
    model_config = ConfigDict(from_attributes=True)
