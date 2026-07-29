# F1 Portfolio App

A full-stack Formula 1 app (Android, iOS, Windows, macOS): race schedule,
results, and standings pulled from the
[Jolpica F1 API](https://api.jolpi.ca/ergast/f1/) and cached in Postgres,
plus a news placeholder and static ticket links.

## Stack

- **Backend:** Python / FastAPI, SQLAlchemy ORM, Alembic migrations
- **Database:** PostgreSQL, run locally via Docker Compose
- **App:** Flutter (Android, iOS, Windows, macOS) — `mobile_app/`
- **Data sources:**
  - [Jolpica F1 API](https://api.jolpi.ca/ergast/f1/) — the free, open-source
    successor to the deprecated Ergast API (schedule, results, standings)
  - [Wikipedia REST API](https://en.wikipedia.org/api/rest_v1/) — driver photos
  - [motorsport.com RSS](https://www.motorsport.com/rss/f1/news/) — news (no key)
  - [f1db/f1db](https://github.com/f1db/f1db) (CC BY 4.0) — track outline diagrams

## Features

- **Home** — live next-race countdown, your favourited drivers, upcoming races
- **Schedule** — season browser with a card grid (podium preview / session times,
  next race highlighted) and a results-table view
- **Race detail** — track outline diagram (theme-aware), live circuit map, weekend
  session schedule, full results with team-colour accents and fastest lap, or
  "at this circuit" history (last winner + fastest lap) for upcoming races
- **Standings** — drivers / teams tables, plus a season progression line chart
- **Driver & team pages** — bio, career stats, recent results, favourite toggle
- **News** — live F1 headlines with images
- **Tickets** — outbound links to official vendors
- **Light / dark theme** toggle throughout

> **Note:** an earlier Next.js web frontend lives in `frontend-legacy/`,
> retired in favor of the Flutter app. It's untouched and still builds/runs
> (`npm install && npm run dev`) but isn't part of the active project
> anymore — safe to delete once you're sure you don't need it for reference.

## ⚠️ Known limitation: Jolpica reliability

Jolpica is a **free, volunteer-run project** with no uptime SLA and a
**200 requests/hour** rate limit. It can be slow or briefly unavailable.
This app is built around that constraint:

- Every Jolpica response is cached in the `jolpica_cache` Postgres table
  (see `backend/app/services/jolpica/client.py`) with a configurable TTL
  (`JOLPICA_CACHE_TTL_SECONDS`, default 1 hour), so repeated requests are
  served from our own database instead of hitting Jolpica every time.
- Parsed data is also upserted into normalized tables (`races`, `drivers`,
  `constructors`, `race_results`, `driver_standings`, `constructor_standings`)
  so the app has something to show even if a sync temporarily fails.
- The Flutter app's screens catch fetch failures and show a friendly
  message rather than crashing if the API (or Jolpica) is briefly
  unreachable (see the `LoadStatus.error` branch in `home_screen.dart`).

If you're relying on this for anything time-sensitive, don't — treat it as
a best-effort data source, per Jolpica's own project stance.

## Project structure

```
F1Project/
├── docker-compose.yml       # Postgres only — backend/mobile_app run locally
├── .env.example              # Single source of env vars for the backend/Docker side
├── backend/
│   └── app/
│       ├── core/config.py    # Settings (reads root .env)
│       ├── db/                # SQLAlchemy engine/session/base
│       ├── models/            # ORM models: races, drivers, constructors, standings, cache
│       ├── schemas/           # Pydantic response models
│       ├── routers/           # FastAPI routes
│       └── services/
│           ├── jolpica/       # Jolpica HTTP client + cache + sync-to-DB logic
│           └── sportradar/    # Placeholder module for future Sportradar integration (not implemented)
├── mobile_app/                # Flutter app (Android, iOS, Windows, macOS)
│   └── lib/
│       ├── models/            # Dart classes mirroring backend Pydantic schemas
│       ├── services/          # ApiClient — http calls to the FastAPI backend
│       ├── providers/         # ChangeNotifier state (Provider package)
│       ├── screens/           # Home, Schedule, Standings, News, Tickets
│       └── widgets/           # AdaptiveNavScaffold, shared UI pieces
└── frontend-legacy/           # Retired Next.js web frontend, kept for reference
```

## Prerequisites

- Docker + Docker Compose
- Python 3.11+
- Flutter 3.32+ (`flutter doctor` should show the platforms you plan to target)

## Setup

### 1. Environment variables

```bash
cp .env.example .env
```

This root `.env` is read by both `docker-compose.yml` (Postgres credentials)
and the FastAPI backend (DB connection string, Jolpica config, and
placeholders for future API keys). The Flutter app doesn't need an env
file — its backend URL is resolved in code (see step 4 below).

### 2. Start Postgres

```bash
docker compose up -d
```

### 3. Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate      # Windows
# source .venv/bin/activate # macOS/Linux

pip install -r requirements.txt
alembic upgrade head         # creates all tables
uvicorn app.main:app --reload --port 8000
```

API docs: http://localhost:8000/docs

Try the reference endpoint (fetches from Jolpica, caches in Postgres, and
returns the season schedule):

```
GET http://localhost:8000/api/races/2024
```

Call it again — the second call is served from the `jolpica_cache` table
instead of calling Jolpica.

### 4. Flutter app

```bash
cd mobile_app
flutter pub get
flutter run -d windows   # or: macos, a connected Android/iOS device, or an emulator/simulator
flutter devices          # lists what's available to target
```

The backend URL is resolved automatically in
`mobile_app/lib/services/api_client.dart`:

- **iOS simulator, Windows, macOS:** `http://localhost:8000` works as-is,
  since the app runs natively alongside the backend.
- **Android emulator:** the emulator's `localhost` refers to itself, not
  your machine — the app automatically uses `http://10.0.2.2:8000` instead
  (a special alias the Android emulator provides for the host machine).
- **Physical device:** neither of the above reaches your dev machine.
  Override with your machine's LAN IP:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.23:8000
  ```

Currently only the **Home** screen calls the backend (`GET /api/races/{season}`,
filtered to upcoming races). Schedule, Standings, News, and Tickets are
wired into navigation but show a "coming soon" placeholder — see
`mobile_app/lib/screens/` for where to fill each one in.

## Database migrations

Schema changes go through Alembic. After editing a model in
`backend/app/models/`:

```bash
cd backend
alembic revision --autogenerate -m "describe the change"
alembic upgrade head
```

## API endpoints

| Endpoint | Description |
|---|---|
| `GET /api/races/{season}` | Season schedule — fetches from Jolpica (cached) and upserts into Postgres |
| `GET /api/races/{season}/{round}` | Single race with results (or session schedule only, for upcoming races) |
| `GET /api/races/{season}/podiums` | Top-3 per race for a whole season, in one bulk request |
| `GET /api/races?season=2024` | Read-only listing straight from Postgres, no Jolpica call |
| `GET /api/standings/drivers/{season}` | Driver standings |
| `GET /api/standings/constructors/{season}` | Constructor standings |
| `GET /api/circuits/{circuit_ref}/history` | Last winner + recent fastest lap at a circuit (for upcoming-race pages) |
| `GET /api/drivers` / `GET /api/constructors` | Read-only listings from Postgres |
| `GET /api/news` | Placeholder — static stub data for now |

## Driver photos

Jolpica doesn't provide driver photos and there's no free/legal API for
official F1 headshots, so the backend resolves each driver's photo from
their **Wikipedia** page (the URL Jolpica already gives us), caching the
result on `drivers.photo_url`. Wikipedia infobox images are freely
licensed and its REST API is built for this reuse. The Flutter
`DriverAvatar` widget still lets you override any driver with a bundled
`mobile_app/assets/drivers/{driver_ref}.png` if you'd rather pin a
specific image; otherwise it falls back to the Wikipedia photo, then a
generic icon.

## Future: Sportradar integration

`backend/app/services/sportradar/` is a deliberately empty/stubbed module
for lap times and live timing data once Sportradar API access is set up.
It's isolated from the Jolpica-backed models on purpose — see the
docstring in `client.py` for the intended approach (own tables, own sync
functions, own router) so it can be plugged in without touching the
existing schedule/standings code.

## Future: real news integration

`backend/app/routers/news.py` currently returns static placeholder data.
`NEWS_API_KEY` is already reserved in `.env.example` for whichever news
provider gets picked later.
