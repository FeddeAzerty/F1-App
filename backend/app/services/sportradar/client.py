"""Placeholder for the Sportradar Formula 1 API integration.

Not implemented yet — this module exists purely to give future work (lap
times, live timing data, telemetry) an obvious, isolated place to live once
Sportradar API access is sorted out. It should stay decoupled from the
Jolpica-backed models in `app.models`: Sportradar data is expected to be
higher-frequency and session/lap scoped rather than season/race scoped, so
plan on its own tables and its own router (`app/routers/sportradar.py`,
not yet created) rather than bolting it onto the existing schema.

Suggested next steps when picking this up:
  1. Add `SPORTRADAR_API_KEY` usage here (already present as a placeholder
     in app.core.config.Settings).
  2. Mirror the Jolpica pattern: a thin `fetch_*` client function backed by
     a dedicated cache/rate-limit strategy (Sportradar's limits differ from
     Jolpica's), plus `sync_*` functions that upsert into new models.
  3. Wire a new router into app/main.py once there's something to serve.
"""

from app.core.config import settings


class SportradarNotConfiguredError(RuntimeError):
    """Raised when Sportradar integration is invoked before it's built out."""


class SportradarClient:
    """Stub client. Every method raises until this integration is implemented."""

    def __init__(self) -> None:
        self.api_key = settings.sportradar_api_key

    def get_lap_times(self, *args, **kwargs):
        raise NotImplementedError(
            "Sportradar integration is not implemented yet. See "
            "app/services/sportradar/client.py for context."
        )

    def get_live_timing(self, *args, **kwargs):
        raise NotImplementedError(
            "Sportradar integration is not implemented yet. See "
            "app/services/sportradar/client.py for context."
        )
