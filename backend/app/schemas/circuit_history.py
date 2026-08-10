from datetime import date

from pydantic import BaseModel

from app.schemas.constructor import ConstructorOut
from app.schemas.driver import DriverOut

class CircuitHistoryOut(BaseModel):

    has_data: bool

    last_race_season: int | None = None
    last_race_round: int | None = None
    last_race_name: str | None = None
    last_race_date: date | None = None
    last_winner: DriverOut | None = None
    last_winner_constructor: ConstructorOut | None = None

    lap_record_time: str | None = None
    lap_record_driver: DriverOut | None = None
    lap_record_constructor: ConstructorOut | None = None
    lap_record_season: int | None = None
