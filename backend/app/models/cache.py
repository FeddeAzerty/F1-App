from datetime import datetime

from sqlalchemy import DateTime, String, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class JolpicaCache(Base):
    """Raw response cache for Jolpica API requests.

    Keyed on the full request URL (including query string) so that repeated
    calls within `JOLPICA_CACHE_TTL_SECONDS` are served from Postgres instead
    of counting against Jolpica's 200 req/hour rate limit.
    """

    __tablename__ = "jolpica_cache"

    id: Mapped[int] = mapped_column(primary_key=True)
    request_url: Mapped[str] = mapped_column(String(1024), unique=True, index=True)
    response_json: Mapped[dict] = mapped_column(JSONB)
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
