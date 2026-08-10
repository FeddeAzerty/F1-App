from pydantic import BaseModel

class DriverProgression(BaseModel):
    driver_ref: str
    name: str
    cumulative_points: list[float]

class StandingsProgressionOut(BaseModel):

    rounds: list[int]
    drivers: list[DriverProgression]
