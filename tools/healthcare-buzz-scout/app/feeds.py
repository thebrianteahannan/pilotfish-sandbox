"""Public industry feeds: news RSS, Google News, Federal Register, Stack Overflow, HN."""

from __future__ import annotations

import hashlib
import html
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
from typing import Any

_HERE = Path(__file__).resolve().parent
ROOT = _HERE if (_HERE / "config").is_dir() else _HERE.parent
FEEDS_PATH = ROOT / "config" / "feeds.json"
ATOM = "{http://www.w3.org/2005/Atom}"

# Healthcare / insurance move slowly. Older than this is not live buzz.
MAX_SIGNAL_AGE_DAYS = 730
FRESH_SQL = "(created_utc >= ? OR (created_utc < 1000000000 AND fetched_at >= ?))"

SOURCE_LABELS = {
    "reddit": "Reddit",
    "news": "News",
    "regs": "Regs",
    "stack": "Stack Overflow",
    "hn": "Hacker News",
    "jobs": "Jobs",
}


def load_feeds() -> dict[str, Any]:
    if not FEEDS_PATH.is_file():
        return {}
    return json.loads(FEEDS_PATH.read_text(encoding="utf-8"))


def source_label(source: str | None) -> str:
    return SOURCE_LABELS.get(source or "reddit", source or "reddit")


def min_created_utc() -> float:
    return (datetime.now(timezone.utc) - timedelta(days=MAX_SIGNAL_AGE_DAYS)).timestamp()


def min_fetched_iso() -> str:
    return (datetime.now(timezone.utc) - timedelta(days=MAX_SIGNAL_AGE_DAYS)).strftime("%Y-%m-%dT%H:%M:%SZ")


def signal_too_old(created_utc: Any = None, fetched_at: str | None = None) -> bool:
    dt = _when_dt(created_utc, fetched_at)
    if dt is None:
        return True
    days = (datetime.now(timezone.utc) - dt.astimezone(timezone.utc)).total_seconds() / 86400
    return days > MAX_SIGNAL_AGE_DAYS


def _when_dt(created_utc: Any = None, fetched_at: str | None = None):
    dt = None
    try:
        ts = float(created_utc or 0)
        if ts > 1_000_000_000:
            dt = datetime.fromtimestamp(ts, timezone.utc)
    except (TypeError, ValueError, OSError):
        dt = None
    if dt is None and fetched_at:
        raw = str(fetched_at).replace("Z", "+00:00")
        try:
            dt = datetime.fromisoformat(raw)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
        except ValueError:
            dt = None
    return dt


def format_when(created_utc: Any = None, fetched_at: str | None = None) -> str:
    """Posted time in ET plus age, so old signals are obvious."""
    from zoneinfo import ZoneInfo

    dt = _when_dt(created_utc, fetched_at)
    if dt is None:
        return ""
    local = dt.astimezone(ZoneInfo("America/New_York"))
    days = max(0, int((datetime.now(timezone.utc) - dt.astimezone(timezone.utc)).total_seconds() // 86400))
    if days <= 0:
        age = "today"
    elif days == 1:
        age = "1 day ago"
    elif days < 60:
        age = f"{days} days ago"
    else:
        age = f"{max(1, days // 30)} mo ago"
    return f"{local.strftime('%b %-d, %Y %-I:%M %p ET')} · {age}"


def when_stale(created_utc: Any = None, fetched_at: str | None = None) -> bool:
    dt = _when_dt(created_utc, fetched_at)
    if dt is None:
        return False
    days = (datetime.now(timezone.utc) - dt.astimezone(timezone.utc)).total_seconds() / 86400
    return days >= 45


def _sid(prefix: str, key: str) -> str:
    return f"{prefix}_{hashlib.sha1(key.encode('utf-8', errors='replace')).hexdigest()[:16]}"


def _strip_html(raw: str) -> str:
    text = html.unescape(raw or "")
    text = re.sub(r"(?is)<script[^>]*>.*?</script>", " ", text)
    text = re.sub(r"(?is)<style[^>]*>.*?</style>", " ", text)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def _parse_created(value: str | None) -> float:
    if not value:
        return 0.0
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except ValueError:
        pass
    try:
        return parsedate_to_datetime(value).timestamp()
    except Exception:  # noqa: BLE001
        return 0.0


def _post(
    *,
    pid: str,
    title: str,
    body: str,
    url: str,
    source: str,
    channel: str,
    created: float,
    author: str = "",
    score: int = 0,
    comments: int = 0,
    flair: str = "",
    product_name: str = "",
) -> dict[str, Any]:
    return {
        "id": pid,
        "subreddit": channel,
        "title": html.unescape(title).strip(),
        "selftext": body,
        "url": url,
        "permalink": url,
        "author": author,
        "created_utc": created,
        "score": score,
        "num_comments": comments,
        "flair": flair,
        "source": source,
        "product_name": product_name,
    }


class FeedClient:
    def __init__(self, user_agent: str):
        self.user_agent = user_agent
        self.min_interval = float(os.environ.get("SCOUT_FEED_GAP", "1.2"))
        self._last = 0.0

    def _throttle(self) -> None:
        gap = self.min_interval - (time.time() - self._last)
        if gap > 0:
            time.sleep(gap)
        self._last = time.time()

    def fetch_bytes(self, url: str, *, accept: str) -> bytes:
        self._throttle()
        req = urllib.request.Request(
            url,
            headers={"User-Agent": self.user_agent, "Accept": accept},
        )
        try:
            with urllib.request.urlopen(req, timeout=40) as resp:
                return resp.read()
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")[:200]
            raise RuntimeError(f"HTTP {exc.code} for {url}: {body}") from exc

    def fetch_json(self, url: str) -> Any:
        raw = self.fetch_bytes(url, accept="application/json, */*")
        return json.loads(raw.decode("utf-8"))

    def parse_feed(self, raw: bytes) -> list[dict[str, str]]:
        text = raw.decode("utf-8-sig", errors="replace")
        # Some RSS feeds set Atom as the default xmlns and then use atom: undeclared
        if "<rss" in text[:500] and 'xmlns="http://www.w3.org/2005/Atom"' in text[:500]:
            text = text.replace('xmlns="http://www.w3.org/2005/Atom"', 'xmlns:atom="http://www.w3.org/2005/Atom"', 1)
        try:
            root = ET.fromstring(text)
        except ET.ParseError:
            text = re.sub(r"</?[A-Za-z_][\w.-]*:[A-Za-z_][\w.-]*[^>/]*/?>", " ", text)
            root = ET.fromstring(text)

        def local(tag: str) -> str:
            return tag.rsplit("}", 1)[-1].lower()

        def child_text(el: ET.Element, name: str) -> str:
            for c in list(el):
                if local(c.tag) == name:
                    return "".join(c.itertext()).strip()
            return ""

        def child_link(el: ET.Element) -> str:
            for c in list(el):
                if local(c.tag) == "link":
                    href = (c.get("href") or "").strip()
                    if href:
                        return href
                    if (c.text or "").strip():
                        return c.text.strip()
            return ""

        items: list[dict[str, str]] = []
        for el in root.iter():
            kind = local(el.tag)
            if kind not in {"item", "entry"}:
                continue
            items.append(
                {
                    "title": child_text(el, "title"),
                    "link": child_link(el),
                    "body": child_text(el, "description") or child_text(el, "summary") or child_text(el, "content") or child_text(el, "encoded"),
                    "date": child_text(el, "pubdate") or child_text(el, "updated") or child_text(el, "published") or child_text(el, "date"),
                    "guid": child_text(el, "guid") or child_text(el, "id"),
                }
            )
        return items

    def rss(self, url: str, *, channel: str, source: str = "news", limit: int = 15) -> list[dict[str, Any]]:
        raw = self.fetch_bytes(url, accept="application/rss+xml, application/atom+xml, application/xml, text/xml, */*")
        out: list[dict[str, Any]] = []
        for it in self.parse_feed(raw)[:limit]:
            link = it["link"]
            if not link:
                continue
            out.append(
                _post(
                    pid=_sid("rss", link),
                    title=it["title"] or link,
                    body=_strip_html(it["body"])[:2000],
                    url=link,
                    source=source,
                    channel=channel,
                    created=_parse_created(it["date"]),
                    author=channel,
                )
            )
        return out

    def federal_register(self, term: str, *, limit: int = 20) -> list[dict[str, Any]]:
        q = urllib.parse.urlencode(
            {"per_page": str(limit), "order": "newest", "conditions[term]": term}
        )
        data = self.fetch_json(f"https://www.federalregister.gov/api/v1/documents.json?{q}")
        out: list[dict[str, Any]] = []
        for doc in data.get("results") or []:
            num = str(doc.get("document_number") or "")
            url = doc.get("html_url") or doc.get("pdf_url") or ""
            if not num or not url:
                continue
            agencies = ", ".join(a.get("name") or "" for a in (doc.get("agencies") or []) if a.get("name"))
            abstract = _strip_html(doc.get("abstract") or "")[:2000]
            out.append(
                _post(
                    pid=f"fr_{num}",
                    title=doc.get("title") or num,
                    body=abstract or agencies,
                    url=url,
                    source="regs",
                    channel="federal-register",
                    created=_parse_created(doc.get("publication_date")),
                    author=agencies or "Federal Register",
                    flair="mandate",
                )
            )
        return out

    def stackoverflow(self, tag: str, *, limit: int = 15) -> list[dict[str, Any]]:
        q = urllib.parse.urlencode(
            {
                "order": "desc",
                "sort": "activity",
                "tagged": tag,
                "site": "stackoverflow",
                "pagesize": str(min(30, limit)),
                "filter": "withbody",
            }
        )
        data = self.fetch_json(f"https://api.stackexchange.com/2.3/questions?{q}")
        out: list[dict[str, Any]] = []
        for it in data.get("items") or []:
            qid = it.get("question_id")
            url = it.get("link") or ""
            if not qid or not url:
                continue
            tags = " ".join(it.get("tags") or [])
            body = _strip_html(it.get("body") or "")[:2000]
            out.append(
                _post(
                    pid=f"so_{qid}",
                    title=html.unescape(it.get("title") or str(qid)),
                    body=f"{tags}\n{body}".strip(),
                    url=url,
                    source="stack",
                    channel="stackoverflow",
                    created=float(it.get("creation_date") or 0),
                    author=(it.get("owner") or {}).get("display_name") or "",
                    score=int(it.get("score") or 0),
                    comments=int(it.get("answer_count") or 0),
                    flair=tag,
                )
            )
        return out

    def hackernews(self, query: str, *, limit: int = 15) -> list[dict[str, Any]]:
        q = urllib.parse.urlencode(
            {"query": query, "tags": "story", "hitsPerPage": str(min(30, limit))}
        )
        data = self.fetch_json(f"https://hn.algolia.com/api/v1/search?{q}")
        out: list[dict[str, Any]] = []
        for it in data.get("hits") or []:
            oid = str(it.get("objectID") or "")
            title = it.get("title") or ""
            url = it.get("url") or (f"https://news.ycombinator.com/item?id={oid}" if oid else "")
            if not oid or not title or not url:
                continue
            out.append(
                _post(
                    pid=f"hn_{oid}",
                    title=title,
                    body=_strip_html(it.get("story_text") or it.get("comment_text") or "")[:2000],
                    url=url,
                    source="hn",
                    channel="hn",
                    created=_parse_created(it.get("created_at")),
                    author=it.get("author") or "",
                    score=int(it.get("points") or 0),
                    comments=int(it.get("num_comments") or 0),
                )
            )
        return out


def fetch_all(user_agent: str, feeds: dict[str, Any] | None = None, *, limit: int = 15) -> tuple[list[dict[str, Any]], dict[str, int], list[str]]:
    cfg = feeds or load_feeds()
    client = FeedClient(user_agent)
    posts: list[dict[str, Any]] = []
    by_query: dict[str, int] = {}
    errors: list[str] = []

    def _take(key: str, fn) -> None:
        try:
            batch = fn()
            by_query[key] = len(batch)
            posts.extend(batch)
        except Exception as exc:  # noqa: BLE001
            errors.append(f"{key}: {exc}")

    for feed in cfg.get("rss") or []:
        _take(
            f"rss::{feed.get('id') or feed.get('name')}",
            lambda f=feed: client.rss(f["url"], channel=f.get("name") or f["id"], limit=limit),
        )
    for q in cfg.get("google_news") or []:
        url = "https://news.google.com/rss/search?" + urllib.parse.urlencode(
            {"q": q, "hl": "en-US", "gl": "US", "ceid": "US:en"}
        )
        _take(f"gnews::{q[:40]}", lambda u=url: client.rss(u, channel="Google News", limit=limit))
    for term in cfg.get("federal_register_terms") or []:
        _take("federal-register", lambda t=term: client.federal_register(t, limit=max(limit, 20)))
    for tag in cfg.get("stackexchange_tags") or []:
        _take(f"so::{tag}", lambda t=tag: client.stackoverflow(t, limit=limit))
    for hn_q in cfg.get("hackernews_queries") or []:
        _take(f"hn::{hn_q}", lambda q=hn_q: client.hackernews(q, limit=min(8, limit)))
    return posts, by_query, errors
