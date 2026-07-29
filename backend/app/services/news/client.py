"""Fetches F1 news headlines from a public RSS feed.

The original project reserved `NEWS_API_KEY` for a keyed news provider, but
motorsport.com publishes a free, no-key RSS feed of F1 news - so the news
section works out of the box with no key or signup. Parsed with the stdlib
XML parser (no extra dependency) and cached in-process for a few minutes so
we're not refetching on every page load.
"""

import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime

from app.core.config import settings

_HEADERS = {"User-Agent": "Mozilla/5.0 F1PortfolioApp/1.0 (portfolio project, non-commercial)"}

# Simple in-process cache: (fetched_at, articles). News isn't per-user and
# doesn't need Postgres - a short module-level TTL is plenty.
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
    """Returns recent F1 news articles, or an empty list if the feed can't
    be reached (the caller decides how to present that)."""
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
        # Serve stale cache if we have one, else empty.
        return _cache[1][:limit] if _cache is not None else []

    _cache = (now, articles)
    return articles[:limit]
