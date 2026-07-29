from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.constructor import Constructor
from app.schemas.constructor import ConstructorOut
from app.schemas.detail import ConstructorDetailOut, ResultSummary
from app.services.jolpica.sync import sync_constructor_detail

router = APIRouter(prefix="/api/constructors", tags=["constructors"])


@router.get("", response_model=list[ConstructorOut])
def list_constructors(db: Session = Depends(get_db)):
    """Read-only listing from Postgres, populated as a side effect of syncing races/standings."""
    return db.query(Constructor).order_by(Constructor.name).all()


@router.get("/{constructor_ref}", response_model=ConstructorDetailOut)
def get_constructor_detail(constructor_ref: str, db: Session = Depends(get_db)):
    """Info, career race wins, and recent results for one constructor."""
    detail = sync_constructor_detail(db, constructor_ref)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"No constructor '{constructor_ref}'")
    return ConstructorDetailOut(
        constructor=ConstructorOut.model_validate(detail["constructor"]),
        career_wins=detail["career_wins"],
        recent_results=[ResultSummary(**r) for r in detail["recent"]],
    )
