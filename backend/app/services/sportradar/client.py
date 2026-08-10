from app.core.config import settings

class SportradarNotConfiguredError(RuntimeError):
    pass

class SportradarClient:

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
