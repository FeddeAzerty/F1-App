from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import asc
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.race import Race
from app.schemas.race import RaceDetailOut, RaceOut, RaceResultOut
from app.services.jolpica.sync import sync_race, sync_season_podiums, sync_season_schedule

router = APIRouter(prefix="/api/races", tags=["races"])

@router.get("/{season}", response_model=list[RaceOut])
def get_season_schedule(season: int, db: Session = Depends(get_db)):
    """Race schedule for a season, cached in Postgres and refreshed from Jolpica as needed.

    This is the reference "fetch + cache" endpoint: it syncs from Jolpica
    (which itself checks the jolpica_cache table before hitting the network)
    and then returns the up-to-date rows straight from our own DB.
    """
    races = sync_season_schedule(db, season)
    if not races:
        raise HTTPException(status_code=404, detail=f"No races found for season {season}")
    return races

@router.get("/{season}/podiums", response_model=list[RaceDetailOut])
def get_season_podiums(season: int, db: Session = Depends(get_db)):
    """Top-3 finishers for every race in a season that has results
    published, fetched with far fewer Jolpica calls than hitting each
    race's detail endpoint individually. Built for the Schedule screen's
    grid view, which shows a podium preview per race card.

    Reuses `RaceDetailOut` - `results` here just means "top 3" rather than
    the full field. Builds response objects directly rather than assigning
    into `race.results` - that's a live SQLAlchemy relationship, and
    overwriting it would flag the excluded rows for removal (and race_id
    isn't nullable, so that'd blow up on the next flush).
    """
    races = sync_season_podiums(db, season)
    return [
        RaceDetailOut(
            **RaceOut.model_validate(race).model_dump(),
            results=sorted(
                (
                    RaceResultOut.model_validate(r)
                    for r in race.results
                    if r.position and r.position <= 3
                ),
                key=lambda r: r.position,
            ),
        )
        for race in races
    ]

@router.get("/{season}/{round_}", response_model=RaceDetailOut)
def get_race_detail(season: int, round_: int, db: Session = Depends(get_db)):
    """Single race, synced from Jolpica on demand. Includes results if
    Jolpica has published them; for races that haven't happened yet, this
    still returns the race/circuit info with an empty results list rather
    than 404ing."""
    race = sync_race(db, season, round_)
    if race is None:
        raise HTTPException(status_code=404, detail=f"No race found for {season} round {round_}")
    return race

@router.get("", response_model=list[RaceOut])
def list_cached_races(season: int | None = None, db: Session = Depends(get_db)):
    """Read-only listing straight from Postgres, no Jolpica call. Useful once data is synced."""
    query = db.query(Race).order_by(asc(Race.season), asc(Race.round))
    if season is not None:
        query = query.filter(Race.season == season)
    return query.all()
