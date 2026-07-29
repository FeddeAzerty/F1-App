from datetime import date

from pydantic import BaseModel, ConfigDict


class DriverOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    driver_ref: str
    code: str | None
    permanent_number: int | None
    given_name: str
    family_name: str
    date_of_birth: date | None
    nationality: str | None
    url: str | None
    photo_url: str | None
