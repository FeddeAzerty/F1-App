from sqlalchemy import ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

class DriverStanding(Base):

    __tablename__ = "driver_standings"
    __table_args__ = (UniqueConstraint("season", "driver_id", name="uq_driver_standing_season_driver"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    season: Mapped[int] = mapped_column(Integer, index=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id"))
    constructor_id: Mapped[int | None] = mapped_column(ForeignKey("constructors.id"), nullable=True)
    position: Mapped[int | None] = mapped_column(Integer, nullable=True)
    position_text: Mapped[str | None] = mapped_column(String(16), nullable=True)
    points: Mapped[float] = mapped_column(default=0)
    wins: Mapped[int] = mapped_column(Integer, default=0)

    driver: Mapped["Driver"] = relationship()
    constructor: Mapped["Constructor"] = relationship()

class ConstructorStanding(Base):

    __tablename__ = "constructor_standings"
    __table_args__ = (
        UniqueConstraint("season", "constructor_id", name="uq_constructor_standing_season_constructor"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    season: Mapped[int] = mapped_column(Integer, index=True)
    constructor_id: Mapped[int] = mapped_column(ForeignKey("constructors.id"))
    position: Mapped[int | None] = mapped_column(Integer, nullable=True)
    position_text: Mapped[str | None] = mapped_column(String(16), nullable=True)
    points: Mapped[float] = mapped_column(default=0)
    wins: Mapped[int] = mapped_column(Integer, default=0)

    constructor: Mapped["Constructor"] = relationship()
