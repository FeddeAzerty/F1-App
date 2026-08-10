from datetime import date

from sqlalchemy import Date, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

class Driver(Base):
    __tablename__ = "drivers"

    id: Mapped[int] = mapped_column(primary_key=True)
    driver_ref: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    code: Mapped[str | None] = mapped_column(String(8), nullable=True)
    permanent_number: Mapped[int | None] = mapped_column(nullable=True)
    given_name: Mapped[str] = mapped_column(String(128))
    family_name: Mapped[str] = mapped_column(String(128))
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    nationality: Mapped[str | None] = mapped_column(String(128), nullable=True)
    url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    photo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    @property
    def full_name(self) -> str:
        return f"{self.given_name} {self.family_name}"
