"""Fetch G2 product reviews via Wayback Machine (live G2 blocks bots)."""

from __future__ import annotations

import hashlib
import html
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

_HERE = Path(__file__).resolve().parent
ROOT = _HERE if (_HERE / "config").is_dir() else _HERE.parent
PRODUCTS_PATH = ROOT / "config" / "g2_products.json"


def _strip(raw: str) -> str:
    text = html.unescape(raw or "")
    text = re.sub(r"(?is)<script[^>]*>.*?</script>", " ", text)
    text = re.sub(r"(?is)<style[^>]*>.*?</style>", " ", text)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text).strip()


class G2Client:
    def __init__(self, user_agent: str, *, request_gap: float = 2.0):
        self.user_agent = user_agent
        self.min_interval = request_gap
        self._last = 0.0

    def _throttle(self) -> None:
        gap = self.min_interval - (time.time() - self._last)
        if gap > 0:
            time.sleep(gap)
        self._last = time.time()

    def _fetch(self, url: str) -> bytes:
        self._throttle()
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": self.user_agent,
                "Accept": "text/html,application/json,application/xhtml+xml,*/*",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.read()
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")[:200]
            raise RuntimeError(f"HTTP {exc.code} for {url}: {body}") from exc

    def load_products(self) -> list[dict[str, Any]]:
        return json.loads(PRODUCTS_PATH.read_text(encoding="utf-8"))

    def find_snapshot(self, slug: str) -> str | None:
        """Return a Wayback timestamp that has usable review HTML."""
        target = f"www.g2.com/products/{slug}/reviews"
        params = {
            "url": target,
            "output": "json",
            "filter": "statuscode:200",
            "limit": "15",
            "fl": "timestamp,original",
        }
        # Prefer mid-era snapshots (2020–2023) that still SSR review text
        cdx = "https://web.archive.org/cdx/search/cdx?" + urllib.parse.urlencode(params)
        raw = self._fetch(cdx)
        try:
            rows = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"bad CDX JSON for {slug}") from exc
        if not rows or len(rows) < 2:
            # try without www
            params["url"] = f"g2.com/products/{slug}/reviews"
            cdx = "https://web.archive.org/cdx/search/cdx?" + urllib.parse.urlencode(params)
            raw = self._fetch(cdx)
            rows = json.loads(raw.decode("utf-8"))
        stamps = [r[0] for r in rows[1:] if isinstance(r, list) and r]
        # Prefer snapshots from 2019–2023 (pre-heavy-SPA) then anything
        preferred = [s for s in stamps if s.startswith(("2019", "2020", "2021", "2022", "2023"))]
        ordered = preferred or stamps
        for ts in reversed(ordered):  # newest preferred within band
            return ts
        return None

    def fetch_product_reviews(self, product: dict[str, Any], *, limit: int = 25) -> list[dict[str, Any]]:
        slug = product["slug"]
        name = product.get("name") or slug
        ts = self.find_snapshot(slug)
        if not ts:
            raise RuntimeError(f"no Wayback snapshot for {slug}")
        url = f"https://web.archive.org/web/{ts}/https://www.g2.com/products/{slug}/reviews"
        raw = self._fetch(url)
        # gzip/deflate sometimes arrives compressed oddly; urllib usually decompresses
        try:
            html_text = raw.decode("utf-8")
        except UnicodeDecodeError:
            import gzip

            try:
                html_text = gzip.decompress(raw).decode("utf-8", errors="replace")
            except Exception:  # noqa: BLE001
                html_text = raw.decode("utf-8", errors="replace")

        if html_text.count("What do you like") < 2 and "itemprop=\"review\"" not in html_text:
            raise RuntimeError(f"snapshot {ts} for {slug} has no SSR reviews (likely SPA shell)")

        reviews = self._parse_reviews(html_text, product=product, archive_ts=ts)
        return reviews[:limit]

    def _parse_reviews(
        self,
        html_text: str,
        *,
        product: dict[str, Any],
        archive_ts: str,
    ) -> list[dict[str, Any]]:
        slug = product["slug"]
        name = product.get("name") or slug
        cards = re.findall(r'itemprop="review"(.*?)(?=itemprop="review"|$)', html_text, re.S | re.I)
        out: list[dict[str, Any]] = []
        for card in cards:
            like = self._extract_answer(card, r"What do you like best\?")
            dislike = self._extract_answer(card, r"What do you dislike\?")
            if not like and not dislike:
                body = _strip(
                    re.search(r'itemprop="reviewBody"[^>]*>(.*?)</(?:div|p|span)>', card, re.S | re.I).group(1)
                ) if re.search(r'itemprop="reviewBody"', card, re.I) else ""
                if not body:
                    continue
                like, dislike = body, ""
            dates = re.findall(r"(20\d{2}-\d{2}-\d{2})", card)
            created = 0.0
            if dates:
                try:
                    created = datetime.strptime(dates[0], "%Y-%m-%d").replace(tzinfo=timezone.utc).timestamp()
                except ValueError:
                    created = 0.0
            if not created and len(archive_ts) >= 8:
                try:
                    created = datetime.strptime(archive_ts[:8], "%Y%m%d").replace(tzinfo=timezone.utc).timestamp()
                except ValueError:
                    created = 0.0

            digest = hashlib.sha1(f"{slug}|{like}|{dislike}".encode()).hexdigest()[:12]
            rid = f"g2_{slug}_{digest}"
            title_bit = (dislike or like or "review")[:90]
            selftext = ""
            if like:
                selftext += f"What they like:\n{like}\n\n"
            if dislike:
                selftext += f"What they dislike (workflow gaps):\n{dislike}\n"
            out.append(
                {
                    "id": rid,
                    "source": "g2",
                    "subreddit": slug,
                    "product_name": name,
                    "product_category": product.get("category") or "",
                    "title": f"G2 · {name}: {title_bit}",
                    "selftext": selftext.strip(),
                    "like_text": like,
                    "dislike_text": dislike,
                    "url": f"https://www.g2.com/products/{slug}/reviews",
                    "permalink": f"https://www.g2.com/products/{slug}/reviews",
                    "author": "g2-reviewer",
                    "created_utc": created,
                    "score": 0,
                    "num_comments": 0,
                    "flair": product.get("category") or "G2",
                    "archive_ts": archive_ts,
                }
            )
        return out

    @staticmethod
    def _extract_answer(card: str, question: str) -> str:
        m = re.search(
            rf"{question}\s*</[^>]+>\s*<div[^>]*>(.*?)</div>",
            card,
            re.S | re.I,
        )
        return _strip(m.group(1)) if m else ""
