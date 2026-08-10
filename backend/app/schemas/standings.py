from pydantic import BaseModel, ConfigDict

from app.schemas.constructor import ConstructorOut
from app.schemas.driver import DriverOut

class DriverStandingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    position: int | None
    position_text: str | None
    points: float
    wins: int
    driver: DriverOut
    constructor: ConstructorOut | None

class ConstructorStandingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    position: int | None
    position_text: str | None
    points: float
    wins: int
    constructor: ConstructorOut
