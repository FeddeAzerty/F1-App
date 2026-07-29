from datetime import date, datetime, time

from pydantic import BaseModel, ConfigDict

from app.schemas.circuit import CircuitOut
from app.schemas.constructor import ConstructorOut
from app.schemas.driver import DriverOut


class RaceResultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    position: int | None
    position_text: str | None
    points: float
    grid: int | None
    laps: int | None
    status: str | None
    finish_time_millis: int | None
    finish_time: str | None
    fastest_lap_rank: int | None
    fastest_lap_number: int | None
    fastest_lap_time: str | None
    fastest_lap_speed_kph: float | None
    driver: DriverOut
    constructor: ConstructorOut


class RaceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    season: int
    round: int
    race_name: str
    race_date: date
    race_time: time | None
    url: str | None
    circuit: CircuitOut
    first_practice_at: datetime | None
    second_practice_at: datetime | None
    third_practice_at: datetime | None
    qualifying_at: datetime | None
    sprint_at: datetime | None
    sprint_qualifying_at: datetime | None


class RaceDetailOut(RaceOut):
    results: list[RaceResultOut] = []
