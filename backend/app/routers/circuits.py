from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.circuit_history import CircuitHistoryOut
from app.schemas.constructor import ConstructorOut
from app.schemas.driver import DriverOut
from app.services.jolpica.sync import sync_circuit_history

router = APIRouter(prefix="/api/circuits", tags=["circuits"])

@router.get("/{circuit_ref}/history", response_model=CircuitHistoryOut)
def get_circuit_history(circuit_ref: str, db: Session = Depends(get_db)):
    """Last winner + all-time fastest lap at a circuit - built for upcoming
    race pages, which otherwise have no results to show yet."""
    result = sync_circuit_history(db, circuit_ref)
    last_race = result["last_race"]
    if last_race is None:
        return CircuitHistoryOut(has_data=False)

    last_winner = result.get("last_winner")
    lap_record = result.get("lap_record")

    return CircuitHistoryOut(
        has_data=True,
        last_race_season=last_race.season,
        last_race_round=last_race.round,
        last_race_name=last_race.race_name,
        last_race_date=last_race.race_date,
        last_winner=DriverOut.model_validate(last_winner.driver) if last_winner else None,
        last_winner_constructor=(
            ConstructorOut.model_validate(last_winner.constructor) if last_winner else None
        ),
        lap_record_time=lap_record.fastest_lap_time if lap_record else None,
        lap_record_driver=DriverOut.model_validate(lap_record.driver) if lap_record else None,
        lap_record_constructor=(
            ConstructorOut.model_validate(lap_record.constructor) if lap_record else None
        ),
        lap_record_season=lap_record.race.season if lap_record else None,
    )
