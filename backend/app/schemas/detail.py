from pydantic import BaseModel

from app.schemas.constructor import ConstructorOut
from app.schemas.driver import DriverOut


class ResultSummary(BaseModel):
    """One race line for a driver/constructor detail page."""

    season: int
    round: int
    race_name: str
    position: int | None
    position_text: str | None
    points: float


class DriverDetailOut(BaseModel):
    driver: DriverOut
    career_entries: int
    career_wins: int
    recent_results: list[ResultSummary]


class ConstructorDetailOut(BaseModel):
    constructor: ConstructorOut
    career_wins: int
    recent_results: list[ResultSummary]
