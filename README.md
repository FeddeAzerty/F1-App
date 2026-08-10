# F1 Portfolio App

A full stack Formula 1 app (Android, iOS, Windows, macOS): race schedule,
results, and standings pulled from the
[Jolpica F1 API](https://api.jolpi.ca/ergast/f1/) and cached in Postgres,
plus live F1 news and links to official ticket vendors.

## Stack

- **Backend:** Python / FastAPI, SQLAlchemy ORM, Alembic migrations
- **Database:** PostgreSQL, run locally via Docker Compose
- **App:** Flutter (Android, iOS, Windows, macOS) — `mobile_app/`
- **Data sources:**
  - [Jolpica F1 API](https://api.jolpi.ca/ergast/f1/): the free, open-source
    successor to the deprecated Ergast API (schedule, results, standings)
  - [Wikipedia REST API](https://en.wikipedia.org/api/rest_v1/):driver photos
  - [motorsport.com RSS](https://www.motorsport.com/rss/f1/news/): news (no key)
  - [f1db/f1db](https://github.com/f1db/f1db) (CC BY 4.0): track outline diagrams

## Features

- **Home**: live next-race countdown, your favourited drivers, upcoming races
- **Schedule**: season browser with a card grid (podium preview / session times,
  next race highlighted) and a results-table view
- **Race detail**:track outline diagram (theme-aware), live circuit map, weekend
  session schedule, full results with team-colour accents and fastest lap, or
  "at this circuit" history (last winner + fastest lap) for upcoming races
- **Standings**: drivers / teams tables, plus a season progression line chart
- **Driver & team pages**:bio, career stats, recent results, favourite toggle
- **News**: live F1 headlines with images
- **Tickets**: outbound links to official vendors
- **Light / dark theme** toggle throughout

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
│           ├── news/          # F1 news RSS client (no API key needed)
│           ├── wikipedia/     # Driver photo resolution
│           └── sportradar/    # Placeholder module for future Sportradar integration (not implemented)
└── mobile_app/                # Flutter app (Android, iOS, Windows, macOS)
    ├── assets/circuits/       # Track outline SVGs (light + dark variants)
    └── lib/
        ├── models/            # Dart classes mirroring backend Pydantic schemas
        ├── services/          # ApiClient — http calls to the FastAPI backend
        ├── providers/         # ChangeNotifier state (Provider package)
        ├── screens/           # Home, Schedule, Standings, News, Tickets, detail pages
        ├── utils/             # Formatting, team colours, chart palette
        └── widgets/           # AdaptiveNavScaffold, shared UI pieces
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
file its backend URL is resolved in code (see step 4 below).

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

> **Note:** the app needs the backend running to show data. If every screen
> shows "Couldn't load this", check that `uvicorn` is up on port 8000 and
> that Postgres is running (`docker compose ps`).





Recommended free combination:

| Piece | Service | Why |
|---|---|---|
| Database | [Neon](https://neon.com) | Permanent free Postgres — no expiry |
| API | [Render](https://render.com) | Free Docker web service |

> Render also offers free Postgres, but it **expires after 30 days** — your
> demo would silently die a month later. Neon's free tier doesn't expire.

**Steps**

1. **Neon** — create a project, copy the connection string (looks like
   `postgres://user:pass@ep-xxx.neon.tech/neondb?sslmode=require`).
   The app rewrites the `postgres://` scheme for SQLAlchemy automatically.
2. **Render** — New → Blueprint, pick this repo. `render.yaml` configures the
   service; paste the Neon string as the `DATABASE_URL` env var when prompted.
3. Deploy. Migrations run automatically on container start
   (`alembic upgrade head`), so the schema builds itself on first boot.
4. Check `https://<your-service>.onrender.com/api/health` returns
   `{"status":"ok"}`.

**Free-tier caveats (worth knowing before sharing a link):**

- Render free services **sleep after 15 minutes idle**; the next request takes
  ~1 minute to wake. First load after a quiet period feels slow.
- Neon scales to zero too, adding a second or two on a cold start.
- After first use, data is cached in Postgres, so subsequent loads are fast.

## Building a distributable app

Point a release build at your deployed API with `--dart-define`:

```bash
cd mobile_app
flutter build windows --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com
```

The output folder (`build/windows/x64/runner/Release/`) contains the `.exe`
plus its DLLs — zip the whole folder to distribute it. Without the
`--dart-define`, the build defaults to `localhost:8000` and only works
alongside a locally running backend.

Swap `windows` for `apk` (Android) or `macos` — note macOS/iOS builds require
a Mac.

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
| `GET /api/standings/progression/{season}` | Cumulative points per round, for the season progression chart |
| `GET /api/circuits/{circuit_ref}/history` | Last winner + recent fastest lap at a circuit (for upcoming-race pages) |
| `GET /api/drivers` / `GET /api/constructors` | Read-only listings from Postgres |
| `GET /api/drivers/{driver_ref}` | Driver bio, career totals, recent results |
| `GET /api/constructors/{constructor_ref}` | Constructor info, career wins, recent results |
| `GET /api/news` | Latest F1 headlines from a public RSS feed (no API key) |

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

## News

`GET /api/news` serves live F1 headlines parsed from a public RSS feed
(motorsport.com by default, set via `NEWS_FEED_URL`) — no API key or
signup required, so the news section works out of the box. Responses are
cached in-process for `NEWS_CACHE_TTL_SECONDS`. `NEWS_API_KEY` stays
reserved in `.env.example` in case you later swap in a keyed provider.

## No API keys required

Every data source this project uses is free and key-free — Jolpica,
Wikipedia, the news RSS feed, and the bundled track diagrams. Clone it,
copy `.env.example`, and it runs. The `SPORTRADAR_API_KEY` / `NEWS_API_KEY`
slots are placeholders for optional future integrations and can stay empty.
