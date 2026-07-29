from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# The whole project shares one .env file at the repo root (see .env.example).
# This keeps DB connection info and future API keys in a single place instead
# of duplicating them across backend/frontend.
REPO_ROOT = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=REPO_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Database
    database_url: str = "postgresql+psycopg2://f1user:changeme@localhost:5432/f1db"

    # Jolpica (Ergast successor) F1 API
    jolpica_base_url: str = "https://api.jolpi.ca/ergast/f1"
    jolpica_cache_ttl_seconds: int = 3600
    jolpica_request_timeout_seconds: float = 10.0

    # CORS
    cors_origins: str = "http://localhost:3000"

    # News - a free, no-key RSS feed (see app/services/news). news_api_key
    # stays reserved in case you later swap in a keyed provider.
    news_feed_url: str = "https://www.motorsport.com/rss/f1/news/"
    news_cache_ttl_seconds: int = 300
    news_api_key: str | None = None

    # Future integrations - not used yet, see app/services/sportradar
    sportradar_api_key: str | None = None

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


settings = Settings()
