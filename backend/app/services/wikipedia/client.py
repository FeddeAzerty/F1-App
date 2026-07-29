"""Resolves a driver's photo from Wikipedia.

Jolpica doesn't provide driver photos, and there's no free/legal API for
official F1 driver headshots. Wikipedia's own infobox images are almost
always freely licensed (Wikipedia requires it), and its REST API is
explicitly built for exactly this kind of reuse - so we resolve a photo
from the driver's Wikipedia page (already given to us by Jolpica as
`Driver.url`) instead of hosting/bundling anything ourselves.

Uses `urllib` (stdlib) rather than `httpx` deliberately: while building
this, identical requests through `httpx` were intermittently 403'd by
Wikimedia's Cloudflare-fronted edge (bot-detection on the client's
TLS/HTTP fingerprint, not on the User-Agent header - curl and `urllib`
consistently passed where `httpx` didn't). If this starts failing again
in the future, that's the first thing to re-check.

Results are cached on `Driver.photo_url` (see app/models/driver.py)
rather than re-fetched on every request.
"""

import json
import re
import urllib.error
import urllib.request

_WIKI_TITLE_RE = re.compile(r"/wiki/([^#?]+)")

# Wikipedia's API blocks requests with no/generic User-Agent per their
# reuse policy - see https://meta.wikimedia.org/wiki/User-Agent_policy.
_HEADERS = {"User-Agent": "Mozilla/5.0 F1PortfolioApp/1.0 (portfolio project, non-commercial)"}


def _extract_title(wiki_url: str) -> str | None:
    match = _WIKI_TITLE_RE.search(wiki_url)
    return match.group(1) if match else None


def fetch_driver_photo_url(wiki_url: str) -> str | None:
    """Returns a thumbnail URL, "" if Wikipedia positively confirms there's
    no photo on the page, or None if the lookup was inconclusive (network
    error, non-200 response, unparseable body).

    The None/"" distinction matters to the caller (`_upsert_driver`):
    only "" should be cached as a permanent answer. None means "we don't
    actually know" and should be retried on a later sync, not treated as
    an established fact.
    """
    title = _extract_title(wiki_url)
    if not title:
        return ""  # no Wikipedia page at all - nothing to ever find here

    api_url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{title}"
    request = urllib.request.Request(api_url, headers=_HEADERS)

    try:
        # urlopen raises HTTPError (a URLError subclass) on any non-2xx
        # status rather than returning it, so a successful `with` here
        # always means 200.
        with urllib.request.urlopen(request, timeout=5) as response:
            thumbnail = json.loads(response.read()).get("thumbnail")
    except (urllib.error.URLError, ValueError):
        return None

    return thumbnail.get("source") if thumbnail else ""
