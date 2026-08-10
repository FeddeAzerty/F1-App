from pydantic import BaseModel, ConfigDict

class ConstructorOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    constructor_ref: str
    name: str
    nationality: str | None
    url: str | None
