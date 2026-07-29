from pydantic import BaseModel


class DriverProgression(BaseModel):
    driver_ref: str
    name: str
    cumulative_points: list[float]


class StandingsProgressionOut(BaseModel):
    """Cumulative points per round for the top drivers - for a season
    progression line chart. `cumulative_points[i]` aligns with `rounds[i]`."""

    rounds: list[int]
    drivers: list[DriverProgression]
