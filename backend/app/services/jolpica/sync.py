"""Parses Jolpica API payloads and upserts them into our normalized tables.

Each `sync_*` function fetches the relevant Jolpica endpoint (via
`client.fetch_json`, which handles caching) and writes the result into
Postgres so the rest of the app reads from our own DB rather than Jolpica
directly on every request.
"""

from datetime import date, datetime, time

from sqlalchemy.orm import Session

from app.models.circuit import Circuit
from app.models.constructor import Constructor
from app.models.driver import Driver
from app.models.race import Race, RaceResult
from app.models.standings import ConstructorStanding, DriverStanding
from app.services.jolpica.client import fetch_all_races, fetch_json, fetch_recent_circuit_races
from app.services.wikipedia.client import fetch_driver_photo_url


def _parse_date(value: str | None) -> date | None:
    return datetime.strptime(value, "%Y-%m-%d").date() if value else None


def _parse_time(value: str | None) -> time | None:
    if not value:
        return None
    return datetime.strptime(value.rstrip("Z"), "%H:%M:%S").time()


def _parse_lap_time_seconds(value: str | None) -> float | None:
    """Parses a lap time string ("1:22.670" or, rarely, just "58.123")
    into total seconds, so lap times can be compared numerically."""
    if not value:
        return None
    parts = value.split(":")
    try:
        if len(parts) == 2:
            return int(parts[0]) * 60 + float(parts[1])
        return float(parts[0])
    except ValueError:
        return None


def _parse_session(session_json: dict | None) -> datetime | None:
    """Combines a Jolpica session block (e.g. Qualifying: {date, time}) into
    a single UTC datetime. Absent for sessions that don't apply to a given
    weekend (e.g. Sprint on a non-sprint weekend)."""
    if not session_json:
        return None
    d = _parse_date(session_json.get("date"))
    t = _parse_time(session_json.get("time"))
    if d is None:
        return None
    return datetime.combine(d, t or time())


def _upsert_circuit(db: Session, circuit_json: dict) -> Circuit:
    circuit = db.query(Circuit).filter(Circuit.circuit_ref == circuit_json["circuitId"]).one_or_none()
    location = circuit_json.get("Location", {})
    if circuit is None:
        circuit = Circuit(circuit_ref=circuit_json["circuitId"])
        db.add(circuit)

    circuit.name = circuit_json.get("circuitName", circuit.circuit_ref)
    circuit.locality = location.get("locality")
    circuit.country = location.get("country")
    circuit.latitude = float(location["lat"]) if location.get("lat") else None
    circuit.longitude = float(location["long"]) if location.get("long") else None
    circuit.url = circuit_json.get("url")
    db.flush()
    return circuit


def _upsert_driver(db: Session, driver_json: dict, *, resolve_photo: bool = True) -> Driver:
    driver = db.query(Driver).filter(Driver.driver_ref == driver_json["driverId"]).one_or_none()
    if driver is None:
        driver = Driver(driver_ref=driver_json["driverId"])
        db.add(driver)

    driver.code = driver_json.get("code")
    driver.permanent_number = (
        int(driver_json["permanentNumber"]) if driver_json.get("permanentNumber") else None
    )
    driver.given_name = driver_json["givenName"]
    driver.family_name = driver_json["familyName"]
    driver.date_of_birth = _parse_date(driver_json.get("dateOfBirth"))
    driver.nationality = driver_json.get("nationality")
    driver.url = driver_json.get("url")
    db.flush()

    # resolve_photo=False skips the Wikipedia round-trip for this upsert
    # (used when bulk-upserting many historical drivers who mostly won't
    # end up shown anywhere - see sync_circuit_history, which resolves
    # photos only for the couple of drivers it actually returns).
    if resolve_photo:
        _ensure_driver_photo(db, driver)

    return driver


def _ensure_driver_photo(db: Session, driver: Driver) -> None:
    """Resolved once per driver - photo_url stays "" only once Wikipedia
    has positively confirmed there's no photo; an inconclusive lookup
    (None - network error, or Wikimedia's edge blocking us as bot traffic,
    which happens intermittently - see wikipedia/client.py) leaves it NULL
    so it's retried later instead of being cached as a permanent "no
    photo" answer."""
    if driver.photo_url is not None or not driver.url:
        return
    photo = fetch_driver_photo_url(driver.url)
    if photo is not None:
        driver.photo_url = photo
        db.flush()


def _upsert_constructor(db: Session, constructor_json: dict) -> Constructor:
    constructor = (
        db.query(Constructor).filter(Constructor.constructor_ref == constructor_json["constructorId"]).one_or_none()
    )
    if constructor is None:
        constructor = Constructor(constructor_ref=constructor_json["constructorId"])
        db.add(constructor)

    constructor.name = constructor_json["name"]
    constructor.nationality = constructor_json.get("nationality")
    constructor.url = constructor_json.get("url")
    db.flush()
    return constructor


def _apply_result_timing(result: RaceResult, result_json: dict) -> None:
    """Parses the `Time` (race-winner elapsed time / gap-to-leader for other
    classified finishers) and `FastestLap` blocks from a Jolpica result
    entry. Both are absent for retirements/DNFs."""
    time_json = result_json.get("Time") or {}
    result.finish_time_millis = int(time_json["millis"]) if time_json.get("millis") else None
    result.finish_time = time_json.get("time")

    fastest_lap_json = result_json.get("FastestLap") or {}
    result.fastest_lap_rank = (
        int(fastest_lap_json["rank"]) if fastest_lap_json.get("rank") else None
    )
    result.fastest_lap_number = (
        int(fastest_lap_json["lap"]) if fastest_lap_json.get("lap") else None
    )
    result.fastest_lap_time = (fastest_lap_json.get("Time") or {}).get("time")
    speed_json = fastest_lap_json.get("AverageSpeed") or {}
    result.fastest_lap_speed_kph = float(speed_json["speed"]) if speed_json.get("speed") else None


def _upsert_race_schedule(db: Session, season: int, race_json: dict) -> Race:
    """Upserts a Race + its Circuit from a Jolpica race entry that only has
    schedule info (no Results key, or an entry from the schedule endpoint)."""
    circuit = _upsert_circuit(db, race_json["Circuit"])
    round_ = int(race_json["round"])

    race = db.query(Race).filter(Race.season == season, Race.round == round_).one_or_none()
    if race is None:
        race = Race(season=season, round=round_)
        db.add(race)

    race.race_name = race_json["raceName"]
    race.circuit_id = circuit.id
    race.race_date = _parse_date(race_json["date"])
    race.race_time = _parse_time(race_json.get("time"))
    race.url = race_json.get("url")

    # The results endpoint's race entries don't include session times at
    # all (no FirstPractice/Qualifying/etc. keys) - only touch these
    # columns when the source payload actually has the key, so syncing
    # results after a schedule sync doesn't wipe out session data that's
    # only available from the schedule endpoint.
    if "FirstPractice" in race_json:
        race.first_practice_at = _parse_session(race_json.get("FirstPractice"))
    if "SecondPractice" in race_json:
        race.second_practice_at = _parse_session(race_json.get("SecondPractice"))
    if "ThirdPractice" in race_json:
        race.third_practice_at = _parse_session(race_json.get("ThirdPractice"))
    if "Qualifying" in race_json:
        race.qualifying_at = _parse_session(race_json.get("Qualifying"))
    if "Sprint" in race_json:
        race.sprint_at = _parse_session(race_json.get("Sprint"))
    if "SprintQualifying" in race_json:
        race.sprint_qualifying_at = _parse_session(race_json.get("SprintQualifying"))

    db.flush()
    return race


def _upsert_result(db: Session, race: Race, result_json: dict, *, resolve_photo: bool = True) -> RaceResult:
    driver = _upsert_driver(db, result_json["Driver"], resolve_photo=resolve_photo)
    constructor = _upsert_constructor(db, result_json["Constructor"])

    result = (
        db.query(RaceResult)
        .filter(RaceResult.race_id == race.id, RaceResult.driver_id == driver.id)
        .one_or_none()
    )
    if result is None:
        result = RaceResult(race_id=race.id, driver_id=driver.id, constructor_id=constructor.id)
        db.add(result)

    result.constructor_id = constructor.id
    result.position = int(result_json["position"]) if result_json.get("position", "").isdigit() else None
    result.position_text = result_json.get("positionText")
    result.points = float(result_json.get("points", 0))
    result.grid = int(result_json["grid"]) if result_json.get("grid") else None
    result.laps = int(result_json["laps"]) if result_json.get("laps") else None
    result.status = result_json.get("status")
    _apply_result_timing(result, result_json)
    return result


def sync_season_schedule(db: Session, season: int) -> list[Race]:
    """Fetch and upsert the full race schedule for `season`."""
    payload = fetch_json(db, f"{season}.json")
    races_json = payload["MRData"]["RaceTable"]["Races"]

    races = [_upsert_race_schedule(db, season, race_json) for race_json in races_json]

    db.commit()
    races.sort(key=lambda r: r.round)
    return races


def sync_race(db: Session, season: int, round_: int) -> Race | None:
    """Fetch and upsert a single race, including results if Jolpica has
    published them. Races that haven't happened yet (or whose results
    aren't published) have no `Results` key - those fall back to
    schedule-only info instead of 404ing, so upcoming races are still
    viewable before the results endpoint has anything to say.
    """
    results_payload = fetch_json(db, f"{season}/{round_}/results.json")
    races_json = results_payload["MRData"]["RaceTable"]["Races"]

    if not races_json:
        schedule_payload = fetch_json(db, f"{season}/{round_}.json")
        schedule_races_json = schedule_payload["MRData"]["RaceTable"]["Races"]
        if not schedule_races_json:
            return None
        race = _upsert_race_schedule(db, season, schedule_races_json[0])
        db.commit()
        db.refresh(race)
        return race

    race_json = races_json[0]
    race = _upsert_race_schedule(db, season, race_json)

    for result_json in race_json.get("Results", []):
        _upsert_result(db, race, result_json)

    db.commit()
    db.refresh(race)
    return race


def sync_season_podiums(db: Session, season: int) -> list[Race]:
    """Fetch and upsert the top-3 finishers for every race in a season that
    has results published, using paginated whole-season requests
    (`fetch_all_races`) instead of one Jolpica call per race - built for
    views that need a season's worth of "who's on the podium" at once
    (e.g. a schedule grid) without a request per card.

    Only upserts podium (P1-P3) results; a race's full result list is
    still fetched lazily via `sync_race` when its detail screen is opened.
    """
    races_json = fetch_all_races(db, f"{season}/results.json")

    races: list[Race] = []
    for race_json in races_json:
        race = _upsert_race_schedule(db, season, race_json)
        for result_json in race_json.get("Results", []):
            position = result_json.get("position")
            if not (position and position.isdigit() and int(position) <= 3):
                continue
            _upsert_result(db, race, result_json)
        races.append(race)

    db.commit()
    races.sort(key=lambda r: r.round)
    return races


def sync_circuit_history(db: Session, circuit_ref: str) -> dict:
    """Fetches the circuit's recent races (see fetch_recent_circuit_races -
    bounded, not full history), upserts them into our normal races/results
    tables, and derives two facts: who won the most recent race held
    there, and the fastest lap among the races fetched. Built for
    upcoming-race pages, which otherwise have nothing to show.

    "Fastest lap" here means "fastest in the recent races we fetched," not
    a literal all-time record back to a circuit's first Grand Prix -
    intentionally, both for cost (resolving driver photos for 40-year-old
    entries made this endpoint take over a minute in testing) and honesty
    (old eras had very different cars, and many circuits have been
    reprofiled enough that an old lap time isn't really comparable to the
    current layout anyway).

    Driver photos are deliberately skipped during the bulk scan below
    (`resolve_photo=False`) - most of the ~15-20 races' worth of drivers
    scanned here never end up shown anywhere. Only the 2 drivers actually
    returned (last winner, lap record holder) get their photo resolved,
    which is what made this endpoint take 90+ seconds down to ~2-3s in
    testing.
    """
    races_json = fetch_recent_circuit_races(db, circuit_ref)
    if not races_json:
        return {"last_race": None, "last_winner": None, "lap_record": None}

    races: list[Race] = []
    for race_json in races_json:
        season = int(race_json["season"])
        race = _upsert_race_schedule(db, season, race_json)
        for result_json in race_json.get("Results", []):
            _upsert_result(db, race, result_json, resolve_photo=False)
        races.append(race)
    db.commit()

    races.sort(key=lambda r: (r.season, r.round))
    last_race = races[-1]
    db.refresh(last_race)
    last_winner = next((r for r in last_race.results if r.position == 1), None)

    lap_record_result: RaceResult | None = None
    lap_record_seconds: float | None = None
    for race in races:
        db.refresh(race)
        for result in race.results:
            if result.fastest_lap_rank != 1:
                continue
            seconds = _parse_lap_time_seconds(result.fastest_lap_time)
            if seconds is None:
                continue
            if lap_record_seconds is None or seconds < lap_record_seconds:
                lap_record_seconds = seconds
                lap_record_result = result

    if last_winner is not None:
        _ensure_driver_photo(db, last_winner.driver)
    if lap_record_result is not None:
        _ensure_driver_photo(db, lap_record_result.driver)
    db.commit()

    return {
        "last_race": last_race,
        "last_winner": last_winner,
        "lap_record": lap_record_result,
    }


def sync_driver_standings(db: Session, season: int) -> list[DriverStanding]:
    payload = fetch_json(db, f"{season}/driverStandings.json")
    standings_lists = payload["MRData"]["StandingsTable"]["StandingsLists"]
    if not standings_lists:
        return []

    standings: list[DriverStanding] = []
    for entry in standings_lists[0]["DriverStandings"]:
        driver = _upsert_driver(db, entry["Driver"])
        constructor = None
        if entry.get("Constructors"):
            constructor = _upsert_constructor(db, entry["Constructors"][0])

        standing = (
            db.query(DriverStanding)
            .filter(DriverStanding.season == season, DriverStanding.driver_id == driver.id)
            .one_or_none()
        )
        if standing is None:
            standing = DriverStanding(season=season, driver_id=driver.id)
            db.add(standing)

        standing.constructor_id = constructor.id if constructor else None
        standing.position = int(entry["position"]) if entry.get("position", "").isdigit() else None
        standing.position_text = entry.get("positionText")
        standing.points = float(entry.get("points", 0))
        standing.wins = int(entry.get("wins", 0))
        standings.append(standing)

    db.commit()
    standings.sort(key=lambda s: (s.position is None, s.position))
    return standings


def sync_constructor_standings(db: Session, season: int) -> list[ConstructorStanding]:
    payload = fetch_json(db, f"{season}/constructorStandings.json")
    standings_lists = payload["MRData"]["StandingsTable"]["StandingsLists"]
    if not standings_lists:
        return []

    standings: list[ConstructorStanding] = []
    for entry in standings_lists[0]["ConstructorStandings"]:
        constructor = _upsert_constructor(db, entry["Constructor"])

        standing = (
            db.query(ConstructorStanding)
            .filter(ConstructorStanding.season == season, ConstructorStanding.constructor_id == constructor.id)
            .one_or_none()
        )
        if standing is None:
            standing = ConstructorStanding(season=season, constructor_id=constructor.id)
            db.add(standing)

        standing.position = int(entry["position"]) if entry.get("position", "").isdigit() else None
        standing.position_text = entry.get("positionText")
        standing.points = float(entry.get("points", 0))
        standing.wins = int(entry.get("wins", 0))
        standings.append(standing)

    db.commit()
    standings.sort(key=lambda s: (s.position is None, s.position))
    return standings


def _result_summary(race_json: dict, result_json: dict) -> dict:
    position = result_json.get("position")
    return {
        "season": int(race_json["season"]),
        "round": int(race_json["round"]),
        "race_name": race_json["raceName"],
        "position": int(position) if position and position.isdigit() else None,
        "position_text": result_json.get("positionText"),
        "points": float(result_json.get("points", 0)),
    }


def sync_driver_detail(db: Session, driver_ref: str) -> dict | None:
    """Bio + career totals + recent results for one driver, from Jolpica's
    driver-scoped endpoints (a handful of cached calls). Returns None if
    the driver isn't found."""
    bio_payload = fetch_json(db, f"drivers/{driver_ref}.json")
    drivers_json = bio_payload["MRData"]["DriverTable"]["Drivers"]
    if not drivers_json:
        return None
    driver = _upsert_driver(db, drivers_json[0])
    db.commit()

    # Ergast/Jolpica support filtering results by finishing position, so
    # career wins is just the total of the position-1 result set.
    wins_payload = fetch_json(db, f"drivers/{driver_ref}/results/1.json?limit=1")
    career_wins = int(wins_payload["MRData"].get("total", 0))

    all_payload = fetch_json(db, f"drivers/{driver_ref}/results.json?limit=1")
    career_entries = int(all_payload["MRData"].get("total", 0))

    offset = max(0, career_entries - 5)
    recent_payload = fetch_json(db, f"drivers/{driver_ref}/results.json?limit=5&offset={offset}")
    recent_races = recent_payload["MRData"]["RaceTable"]["Races"]
    recent = [
        _result_summary(race_json, race_json["Results"][0])
        for race_json in recent_races
        if race_json.get("Results")
    ]
    recent.reverse()  # most recent first

    return {
        "driver": driver,
        "career_entries": career_entries,
        "career_wins": career_wins,
        "recent": recent,
    }


def _is_better_position(a: dict, b: dict) -> bool:
    """True if result `a` finished ahead of `b` (a numeric position beats
    None; lower number is better)."""
    if a["position"] is None:
        return False
    if b["position"] is None:
        return True
    return a["position"] < b["position"]


def sync_constructor_detail(db: Session, constructor_ref: str) -> dict | None:
    """Info + career race wins + recent results for one constructor."""
    info_payload = fetch_json(db, f"constructors/{constructor_ref}.json")
    constructors_json = info_payload["MRData"]["ConstructorTable"]["Constructors"]
    if not constructors_json:
        return None
    constructor = _upsert_constructor(db, constructors_json[0])
    db.commit()

    wins_payload = fetch_json(db, f"constructors/{constructor_ref}/results/1.json?limit=1")
    career_wins = int(wins_payload["MRData"].get("total", 0))

    count_payload = fetch_json(db, f"constructors/{constructor_ref}/results.json?limit=1")
    total = int(count_payload["MRData"].get("total", 0))
    offset = max(0, total - 10)
    recent_payload = fetch_json(
        db, f"constructors/{constructor_ref}/results.json?limit=10&offset={offset}"
    )
    recent_races = recent_payload["MRData"]["RaceTable"]["Races"]

    # A constructor fields two cars per race; keep the team's best finish
    # in each of the most recent races rather than a single result.
    by_round: dict[tuple[int, int], dict] = {}
    for race_json in recent_races:
        for result_json in race_json.get("Results", []):
            summary = _result_summary(race_json, result_json)
            key = (summary["season"], summary["round"])
            existing = by_round.get(key)
            if existing is None or _is_better_position(summary, existing):
                by_round[key] = summary

    recent = sorted(by_round.values(), key=lambda s: (s["season"], s["round"]), reverse=True)[:5]

    return {"constructor": constructor, "career_wins": career_wins, "recent": recent}


def sync_standings_progression(db: Session, season: int) -> dict:
    """Cumulative championship points per driver after each round of a
    season, for a progression line chart. Computed from one bulk
    whole-season results fetch (already cached), so it's a single Jolpica
    round-trip rather than one call per round.

    Note: this sums *race* points only - sprint-race points (a separate
    Jolpica endpoint) aren't included, so totals for sprint weekends are a
    slight underestimate. Good enough for a season-shape visualization.
    """
    races_json = fetch_all_races(db, f"{season}/results.json")
    if not races_json:
        return {"rounds": [], "drivers": []}

    races_sorted = sorted(races_json, key=lambda r: int(r["round"]))
    rounds = [int(r["round"]) for r in races_sorted]

    running: dict[str, float] = {}
    names: dict[str, str] = {}
    series: dict[str, list[float]] = {}

    for idx, race_json in enumerate(races_sorted):
        for result_json in race_json.get("Results", []):
            driver_json = result_json["Driver"]
            ref = driver_json["driverId"]
            names.setdefault(ref, driver_json.get("code") or driver_json["familyName"])
            running[ref] = running.get(ref, 0.0) + float(result_json.get("points", 0))
        # Everyone who's scored carries their total forward, so every series
        # has a value at every round (a flat segment where they didn't score).
        for ref in running:
            series.setdefault(ref, [0.0] * len(rounds))
            series[ref][idx] = running[ref]

    top_refs = sorted(running, key=lambda r: running[r], reverse=True)[:10]
    drivers = [
        {"driver_ref": ref, "name": names[ref], "cumulative_points": series[ref]}
        for ref in top_refs
    ]

    return {"rounds": rounds, "drivers": drivers}
