import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime

from app.core.config import settings

_HEADERS = {"User-Agent": "Mozilla/5.0 F1PortfolioApp/1.0 (portfolio project, non-commercial)"}

_cache: tuple[datetime, list[dict]] | None = None

def _parse_pub_date(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return parsedate_to_datetime(value).astimezone(timezone.utc).isoformat()
    except (TypeError, ValueError):
        return None

def _parse_feed(xml_bytes: bytes) -> list[dict]:
    root = ET.fromstring(xml_bytes)
    articles: list[dict] = []
    for item in root.findall(".//item"):
        enclosure = item.find("enclosure")
        articles.append(
            {
                "title": (item.findtext("title") or "").strip(),
                "summary": (item.findtext("description") or "").strip(),
                "url": item.findtext("link"),
                "image_url": enclosure.get("url") if enclosure is not None else None,
                "source": "motorsport.com",
                "published_at": _parse_pub_date(item.findtext("pubDate")),
            }
        )
    return articles

def fetch_f1_news(limit: int = 20) -> list[dict]:
    global _cache
    now = datetime.now(timezone.utc)
    if _cache is not None:
        fetched_at, articles = _cache
        if (now - fetched_at).total_seconds() < settings.news_cache_ttl_seconds:
            return articles[:limit]

    request = urllib.request.Request(settings.news_feed_url, headers=_HEADERS)
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            articles = _parse_feed(response.read())
    except (urllib.error.URLError, ET.ParseError):
        return _cache[1][:limit] if _cache is not None else []

    _cache = (now, articles)
    return articles[:limit]
