from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.driver import Driver
from app.schemas.detail import DriverDetailOut, ResultSummary
from app.schemas.driver import DriverOut
from app.services.jolpica.sync import sync_driver_detail

router = APIRouter(prefix="/api/drivers", tags=["drivers"])

@router.get("", response_model=list[DriverOut])
def list_drivers(db: Session = Depends(get_db)):
    """Read-only listing from Postgres. Populated as a side effect of syncing
    races/standings; there's no standalone Jolpica "all drivers" sync here."""
    return db.query(Driver).order_by(Driver.family_name).all()

@router.get("/{driver_ref}", response_model=DriverDetailOut)
def get_driver_detail(driver_ref: str, db: Session = Depends(get_db)):
    """Bio, career totals, and recent results for one driver."""
    detail = sync_driver_detail(db, driver_ref)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"No driver '{driver_ref}'")
    return DriverDetailOut(
        driver=DriverOut.model_validate(detail["driver"]),
        career_entries=detail["career_entries"],
        career_wins=detail["career_wins"],
        recent_results=[ResultSummary(**r) for r in detail["recent"]],
    )
