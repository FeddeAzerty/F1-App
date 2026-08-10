import re
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from html.parser import HTMLParser
from io import StringIO

from app.core.config import settings

_HEADERS = {"User-Agent": "Mozilla/5.0 F1PortfolioApp/1.0 (portfolio project, non-commercial)"}

_cache: tuple[datetime, list[dict]] | None = None

_TRAILING_CTA = re.compile(r"\s*(\.{3}\s*)?(keep reading|read more|continue reading)\s*$", re.I)

_SPACING_TAGS = {"br", "p", "div", "li", "tr", "h1", "h2", "h3", "h4", "h5", "h6"}

class _TagStripper(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._parts = StringIO()

    def handle_data(self, data: str) -> None:
        self._parts.write(data)

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in _SPACING_TAGS:
            self._parts.write(" ")

    def handle_startendtag(self, tag: str, attrs) -> None:
        if tag in _SPACING_TAGS:
            self._parts.write(" ")

    def handle_endtag(self, tag: str) -> None:
        if tag in _SPACING_TAGS:
            self._parts.write(" ")

    @property
    def text(self) -> str:
        return self._parts.getvalue()

def _strip_html(value: str) -> str:
    stripper = _TagStripper()
    try:
        stripper.feed(value)
        stripper.close()
    except Exception:
        return " ".join(value.split())
    text = " ".join(stripper.text.split())
    return _TRAILING_CTA.sub("", text).strip()

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
                "title": _strip_html(item.findtext("title") or ""),
                "summary": _strip_html(item.findtext("description") or ""),
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
