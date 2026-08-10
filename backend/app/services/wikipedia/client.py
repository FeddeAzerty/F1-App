import json
import re
import urllib.error
import urllib.request

_WIKI_TITLE_RE = re.compile(r"/wiki/([^#?]+)")

_HEADERS = {"User-Agent": "Mozilla/5.0 F1PortfolioApp/1.0 (portfolio project, non-commercial)"}

def _extract_title(wiki_url: str) -> str | None:
    match = _WIKI_TITLE_RE.search(wiki_url)
    return match.group(1) if match else None

def fetch_driver_photo_url(wiki_url: str) -> str | None:
    title = _extract_title(wiki_url)
    if not title:
        return ""

    api_url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{title}"
    request = urllib.request.Request(api_url, headers=_HEADERS)

    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            thumbnail = json.loads(response.read()).get("thumbnail")
    except (urllib.error.URLError, ValueError):
        return None

    return thumbnail.get("source") if thumbnail else ""
