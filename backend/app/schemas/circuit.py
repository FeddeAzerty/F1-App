from pydantic import BaseModel, ConfigDict


class CircuitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    circuit_ref: str
    name: str
    locality: str | None
    country: str | None
    latitude: float | None
    longitude: float | None
    url: str | None
