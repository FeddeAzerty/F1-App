from datetime import date

from pydantic import BaseModel

from app.schemas.constructor import ConstructorOut
from app.schemas.driver import DriverOut


class CircuitHistoryOut(BaseModel):
    """Last winner + fastest lap among recent races at a circuit (not a
    literal all-time record - see sync_circuit_history for why). Shown on
    upcoming race pages in place of results that don't exist yet."""

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
