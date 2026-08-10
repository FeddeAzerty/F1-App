from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

REPO_ROOT = Path(__file__).resolve().parents[3]

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=REPO_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_url: str = "postgresql+psycopg2://f1user:changeme@localhost:5432/f1db"

    jolpica_base_url: str = "https://api.jolpi.ca/ergast/f1"
    jolpica_cache_ttl_seconds: int = 3600
    jolpica_request_timeout_seconds: float = 10.0

    cors_origins: str = "http://localhost:3000"

    news_feed_url: str = "https://www.motorsport.com/rss/f1/news/"
    news_cache_ttl_seconds: int = 300
    news_api_key: str | None = None

    sportradar_api_key: str | None = None

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def sqlalchemy_database_url(self) -> str:
        url = self.database_url
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql+psycopg2://", 1)
        elif url.startswith("postgresql://"):
            url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
        return url

settings = Settings()
