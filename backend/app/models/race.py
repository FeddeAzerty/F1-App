from datetime import date, datetime, time

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String, Time, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Race(Base):
    __tablename__ = "races"
    __table_args__ = (UniqueConstraint("season", "round", name="uq_race_season_round"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    season: Mapped[int] = mapped_column(Integer, index=True)
    round: Mapped[int] = mapped_column(Integer)
    race_name: Mapped[str] = mapped_column(String(255))
    circuit_id: Mapped[int] = mapped_column(ForeignKey("circuits.id"))
    race_date: Mapped[date] = mapped_column(Date)
    race_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    # Race weekend session schedule (all UTC). Sprint/SprintQualifying are
    # only present on sprint weekends; SecondPractice/ThirdPractice are
    # absent on sprint weekends too (the sprint format replaces them).
    first_practice_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    second_practice_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    third_practice_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    qualifying_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    sprint_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    sprint_qualifying_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    circuit: Mapped["Circuit"] = relationship(back_populates="races")
    results: Mapped[list["RaceResult"]] = relationship(back_populates="race", order_by="RaceResult.position")


class RaceResult(Base):
    __tablename__ = "race_results"
    __table_args__ = (UniqueConstraint("race_id", "driver_id", name="uq_result_race_driver"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    race_id: Mapped[int] = mapped_column(ForeignKey("races.id"), index=True)
    driver_id: Mapped[int] = mapped_column(ForeignKey("drivers.id"))
    constructor_id: Mapped[int] = mapped_column(ForeignKey("constructors.id"))
    position: Mapped[int | None] = mapped_column(Integer, nullable=True)
    position_text: Mapped[str | None] = mapped_column(String(16), nullable=True)
    points: Mapped[float] = mapped_column(default=0)
    grid: Mapped[int | None] = mapped_column(Integer, nullable=True)
    laps: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[str | None] = mapped_column(String(64), nullable=True)

    # Race-winner's time is the full elapsed time (e.g. "1:33:56.820");
    # other classified finishers get a gap to the leader (e.g. "+2.363").
    # Both are null for retirements/DNFs.
    finish_time_millis: Mapped[int | None] = mapped_column(Integer, nullable=True)
    finish_time: Mapped[str | None] = mapped_column(String(32), nullable=True)

    # Fastest lap of the race has fastest_lap_rank == 1.
    fastest_lap_rank: Mapped[int | None] = mapped_column(Integer, nullable=True)
    fastest_lap_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    fastest_lap_time: Mapped[str | None] = mapped_column(String(32), nullable=True)
    fastest_lap_speed_kph: Mapped[float | None] = mapped_column(Float, nullable=True)

    race: Mapped["Race"] = relationship(back_populates="results")
    driver: Mapped["Driver"] = relationship()
    constructor: Mapped["Constructor"] = relationship()
