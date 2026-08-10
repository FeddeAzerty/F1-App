from datetime import datetime

from pydantic import BaseModel

class NewsArticleOut(BaseModel):
    title: str
    summary: str
    url: str | None
    image_url: str | None
    source: str | None
    published_at: datetime | None
