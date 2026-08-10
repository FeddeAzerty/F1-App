from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.progression import StandingsProgressionOut
from app.schemas.standings import ConstructorStandingOut, DriverStandingOut
from app.services.jolpica.sync import (
    sync_constructor_standings,
    sync_driver_standings,
    sync_standings_progression,
)

router = APIRouter(prefix="/api/standings", tags=["standings"])

@router.get("/drivers/{season}", response_model=list[DriverStandingOut])
def get_driver_standings(season: int, db: Session = Depends(get_db)):
    standings = sync_driver_standings(db, season)
    if not standings:
        raise HTTPException(status_code=404, detail=f"No driver standings found for season {season}")
    return standings

@router.get("/constructors/{season}", response_model=list[ConstructorStandingOut])
def get_constructor_standings(season: int, db: Session = Depends(get_db)):
    standings = sync_constructor_standings(db, season)
    if not standings:
        raise HTTPException(status_code=404, detail=f"No constructor standings found for season {season}")
    return standings

@router.get("/progression/{season}", response_model=StandingsProgressionOut)
def get_standings_progression(season: int, db: Session = Depends(get_db)):
    """Cumulative points per round for the top drivers - for a season
    progression line chart."""
    return sync_standings_progression(db, season)
