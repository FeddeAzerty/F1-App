"""Thin HTTP client for the Jolpica F1 API with a Postgres-backed cache.

Jolpica (https://api.jolpi.ca/ergast/f1/) is the free, volunteer-run
successor to the deprecated Ergast API. It enforces a 200 requests/hour rate
limit, so every call in this module first checks `jolpica_cache` for a fresh
response before hitting the network. See README.md for the known
reliability caveats of relying on a volunteer-run API.
"""

from datetime import datetime, timedelta, timezone

import httpx
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.cache import JolpicaCache


class JolpicaAPIError(RuntimeError):
    """Raised when Jolpica returns an error or an unexpected payload."""


def _build_url(path: str) -> str:
    return f"{settings.jolpica_base_url.rstrip('/')}/{path.lstrip('/')}"


def fetch_json(db: Session, path: str, *, force_refresh: bool = False) -> dict:
    """Fetch `path` from Jolpica, transparently caching the response in Postgres.

    `path` is relative to `JOLPICA_BASE_URL`, e.g. "2024.json" or
    "2024/driverStandings.json".
    """
    url = _build_url(path)

    if not force_refresh:
        cached = db.query(JolpicaCache).filter(JolpicaCache.request_url == url).one_or_none()
        if cached is not None:
            age = datetime.now(timezone.utc) - cached.fetched_at
            if age < timedelta(seconds=settings.jolpica_cache_ttl_seconds):
                return cached.response_json

    try:
        response = httpx.get(url, timeout=settings.jolpica_request_timeout_seconds)
        response.raise_for_status()
        payload = response.json()
    except httpx.HTTPError as exc:
        raise JolpicaAPIError(f"Jolpica request failed for {url}: {exc}") from exc

    stmt = (
        insert(JolpicaCache)
        .values(request_url=url, response_json=payload, fetched_at=datetime.now(timezone.utc))
        .on_conflict_do_update(
            index_elements=[JolpicaCache.request_url],
            set_={"response_json": payload, "fetched_at": datetime.now(timezone.utc)},
        )
    )
    db.execute(stmt)
    db.commit()

    return payload


def fetch_all_races(db: Session, path: str, *, page_size: int = 100) -> list[dict]:
    """Fetches every page of a Jolpica endpoint shaped like `RaceTable.Races`
    (e.g. `{season}/results.json`) and returns the combined race list.

    Jolpica caps `limit` around 100 regardless of what's requested, so a
    season's full results (~20 per race x ~24 races) needs several pages.
    This is still far fewer requests than fetching each race individually.
    A race whose results happen to straddle a page boundary gets its
    `Results` merged back together across pages.
    """
    separator = "&" if "?" in path else "?"
    races_by_round: dict[str, dict] = {}
    order: list[str] = []
    offset = 0

    while True:
        page = fetch_json(db, f"{path}{separator}limit={page_size}&offset={offset}")
        mrdata = page["MRData"]
        races = mrdata["RaceTable"]["Races"]
        if not races:
            break

        for race_json in races:
            round_ = race_json["round"]
            if round_ not in races_by_round:
                races_by_round[round_] = race_json
                order.append(round_)
            else:
                races_by_round[round_]["Results"].extend(race_json.get("Results", []))

        offset += page_size
        if offset >= int(mrdata.get("total", 0)):
            break

    return [races_by_round[round_] for round_ in order]


def fetch_recent_circuit_races(
    db: Session, circuit_ref: str, *, max_pages: int = 4, page_size: int = 100
) -> list[dict]:
    """Fetches the most recent races at a circuit, from the tail end of
    Jolpica's `circuits/{ref}/results.json` (chronological ascending),
    capped at `max_pages` pages.

    Deliberately not `fetch_all_races`: that merges pages by round number
    alone, which is fine within a single season but collides across
    different seasons at the same circuit (round numbers repeat year to
    year) - this keys by (season, round) instead. It's also deliberately
    bounded rather than fetching full history: a circuit hosting since the
    1980s can have 500-900+ historical result rows, and resolving driver
    photos (see wikipedia/client.py) for every retired driver back to the
    1980s made this endpoint take over a minute in testing for one circuit.
    Recent races are also a more honest "current lap record" anyway, since
    old eras had very different cars/regulations and circuits are often
    literally a different physical layout than decades ago.
    """
    base_path = f"circuits/{circuit_ref}/results.json"
    first_page = fetch_json(db, f"{base_path}?limit=1&offset=0")
    total = int(first_page["MRData"].get("total", 0))
    if total == 0:
        return []

    races_by_key: dict[tuple[str, str], dict] = {}
    order: list[tuple[str, str]] = []
    offset = max(0, total - max_pages * page_size)

    while offset < total:
        page = fetch_json(db, f"{base_path}?limit={page_size}&offset={offset}")
        races = page["MRData"]["RaceTable"]["Races"]
        for race_json in races:
            key = (race_json["season"], race_json["round"])
            if key not in races_by_key:
                races_by_key[key] = race_json
                order.append(key)
            else:
                races_by_key[key]["Results"].extend(race_json.get("Results", []))
        offset += page_size

    return [races_by_key[key] for key in order]
