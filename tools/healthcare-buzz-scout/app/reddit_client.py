"""Reddit fetch via Atom/RSS (JSON is often blocked); PullPush/OAuth optional."""

from __future__ import annotations

import base64
import html
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from typing import Any

ATOM = "{http://www.w3.org/2005/Atom}"


def _json_loads(raw: bytes) -> Any:
    return json.loads(raw.decode("utf-8"))


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
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return dt.timestamp()
    except ValueError:
        pass
    try:
        return parsedate_to_datetime(value).timestamp()
    except Exception:  # noqa: BLE001
        return 0.0


class RedditClient:
    def __init__(self, user_agent: str):
        self.user_agent = user_agent
        self._token: str | None = None
        self._token_expires = 0.0
        self.client_id = os.environ.get("REDDIT_CLIENT_ID", "").strip()
        self.client_secret = os.environ.get("REDDIT_CLIENT_SECRET", "").strip()
        self.use_pullpush = os.environ.get("SCOUT_USE_PULLPUSH", "1").strip() not in {"0", "false", "no"}
        self.min_interval = float(os.environ.get("SCOUT_REQUEST_GAP", "5.0"))
        self._last_request = 0.0

    @property
    def oauth_ready(self) -> bool:
        return bool(self.client_id and self.client_secret)

    def _throttle(self) -> None:
        gap = self.min_interval - (time.time() - self._last_request)
        if gap > 0:
            time.sleep(gap)
        self._last_request = time.time()

    def _headers(self, *, oauth: bool = False, accept: str = "application/atom+xml, application/xml, text/xml, */*") -> dict[str, str]:
        h = {"User-Agent": self.user_agent, "Accept": accept}
        if oauth and self._token:
            h["Authorization"] = f"Bearer {self._token}"
        return h

    def _ensure_token(self) -> None:
        if not self.oauth_ready:
            return
        if self._token and time.time() < self._token_expires - 60:
            return
        self._throttle()
        data = urllib.parse.urlencode(
            {"grant_type": "client_credentials", "device_id": "pilotfish-healthcare-buzz-scout"}
        ).encode()
        basic = base64.b64encode(f"{self.client_id}:{self.client_secret}".encode()).decode()
        req = urllib.request.Request(
            "https://www.reddit.com/api/v1/access_token",
            data=data,
            method="POST",
            headers={
                **self._headers(accept="application/json"),
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": f"Basic {basic}",
            },
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            payload = _json_loads(resp.read())
        self._token = payload.get("access_token")
        self._token_expires = time.time() + float(payload.get("expires_in") or 3600)

    def _fetch_bytes(self, url: str, *, accept: str) -> bytes:
        self._throttle()
        headers = self._headers(accept=accept)
        fetch_url = url
        if self.oauth_ready:
            self._ensure_token()
            if self._token and "reddit.com" in url:
                headers = self._headers(oauth=True, accept=accept)
                fetch_url = url.replace("https://www.reddit.com/", "https://oauth.reddit.com/")
        req = urllib.request.Request(fetch_url, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=45) as resp:
                return resp.read()
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")[:300]
            raise RuntimeError(f"HTTP {exc.code} for {url}: {body}") from exc

    def _parse_atom(self, raw: bytes, *, subreddit: str | None = None) -> list[dict[str, Any]]:
        root = ET.fromstring(raw)
        out: list[dict[str, Any]] = []
        for e in root.findall(f"{ATOM}entry"):
            title = e.findtext(f"{ATOM}title") or ""
            eid = e.findtext(f"{ATOM}id") or ""
            # ids look like t3_abc123 or full URL
            m = re.search(r"t3_([a-z0-9]+)", eid, re.I)
            if not m:
                m = re.search(r"/comments/([a-z0-9]+)/", eid, re.I)
            pid = m.group(1) if m else re.sub(r"\W+", "", eid)[-10:]
            if not pid:
                continue
            link_el = e.find(f"{ATOM}link")
            permalink = link_el.get("href") if link_el is not None else ""
            author = e.findtext(f"{ATOM}author/{ATOM}name") or ""
            author = author.removeprefix("/u/")
            content = e.findtext(f"{ATOM}content") or e.findtext(f"{ATOM}summary") or ""
            created = _parse_created(e.findtext(f"{ATOM}updated") or e.findtext(f"{ATOM}published"))
            sub = subreddit or ""
            if not sub and permalink:
                msub = re.search(r"/r/([^/]+)/", permalink)
                if msub:
                    sub = msub.group(1)
            out.append(
                {
                    "id": pid,
                    "subreddit": sub,
                    "title": html.unescape(title),
                    "selftext": _strip_html(content),
                    "url": permalink,
                    "permalink": permalink,
                    "author": author,
                    "created_utc": created,
                    "score": 0,
                    "num_comments": 0,
                    "flair": "",
                    "source": "reddit",
                }
            )
        return out

    def _parse_comment_atom(self, raw: bytes, *, post_id: str) -> list[dict[str, Any]]:
        root = ET.fromstring(raw)
        out: list[dict[str, Any]] = []
        for e in root.findall(f"{ATOM}entry"):
            eid = e.findtext(f"{ATOM}id") or ""
            # Skip the submission itself (t3_); keep comments (t1_)
            if eid.startswith("t3_") or f"t3_{post_id}" in eid:
                if not eid.startswith("t1_"):
                    continue
            m = re.search(r"t1_([a-z0-9]+)", eid, re.I)
            if not m:
                m = re.search(r"/comments/[^/]+/[^/]+/([a-z0-9]+)", eid, re.I)
            cid = m.group(1) if m else ""
            if not cid or cid == post_id:
                continue
            link_el = e.find(f"{ATOM}link")
            permalink = link_el.get("href") if link_el is not None else ""
            author = (e.findtext(f"{ATOM}author/{ATOM}name") or "").removeprefix("/u/")
            content = e.findtext(f"{ATOM}content") or e.findtext(f"{ATOM}summary") or ""
            created = _parse_created(e.findtext(f"{ATOM}updated") or e.findtext(f"{ATOM}published"))
            body = _strip_html(content)
            if not body:
                continue
            out.append(
                {
                    "id": cid,
                    "post_id": post_id,
                    "author": author,
                    "body": body,
                    "permalink": permalink,
                    "created_utc": created,
                    "score": 0,
                }
            )
        return out

    def fetch_comments(self, post: dict[str, Any], *, limit: int = 50) -> list[dict[str, Any]]:
        """Fetch comment bodies via post permalink Atom feed (JSON often blocked)."""
        post_id = str(post.get("id") or "")
        permalink = (post.get("permalink") or "").rstrip("/")
        if not post_id or not permalink:
            raise RuntimeError("post missing id/permalink")
        if not permalink.startswith("http"):
            permalink = "https://www.reddit.com" + permalink
        url = permalink + ".rss"
        try:
            raw = self._fetch_bytes(url, accept="application/atom+xml, application/xml, */*")
            return self._parse_comment_atom(raw, post_id=post_id)[:limit]
        except Exception as rss_err:  # noqa: BLE001
            if not self.use_pullpush:
                raise
            try:
                return self._pullpush_comments(post_id, limit=limit)
            except Exception as pp_err:  # noqa: BLE001
                raise RuntimeError(f"comment RSS failed ({rss_err}); PullPush failed ({pp_err})") from pp_err

    def _pullpush_comments(self, post_id: str, *, limit: int = 50) -> list[dict[str, Any]]:
        params = {
            "link_id": f"t3_{post_id}",
            "size": str(min(100, max(1, limit))),
            "sort": "desc",
            "sort_type": "score",
        }
        url = "https://api.pullpush.io/reddit/search/comment/?" + urllib.parse.urlencode(params)
        raw = self._fetch_bytes(url, accept="application/json")
        data = _json_loads(raw)
        items = data.get("data") if isinstance(data, dict) else data
        if not isinstance(items, list):
            items = []
        out: list[dict[str, Any]] = []
        for d in items:
            if not isinstance(d, dict):
                continue
            cid = str(d.get("id") or "").removeprefix("t1_")
            body = (d.get("body") or "").strip()
            if not cid or not body or body in {"[deleted]", "[removed]"}:
                continue
            permalink = d.get("permalink") or ""
            if permalink and not str(permalink).startswith("http"):
                permalink = "https://www.reddit.com" + permalink
            out.append(
                {
                    "id": cid,
                    "post_id": post_id,
                    "author": d.get("author") or "",
                    "body": body,
                    "permalink": permalink,
                    "created_utc": float(d.get("created_utc") or 0),
                    "score": int(d.get("score") or 0),
                }
            )
        return out

    def list_subreddit(self, subreddit: str, *, sort: str = "new", limit: int = 50) -> list[dict[str, Any]]:
        sort = sort if sort in {"new", "hot", "rising"} else "new"
        # Prefer Atom RSS — Reddit often blocks bare JSON from bots/datacenters.
        url = f"https://www.reddit.com/r/{urllib.parse.quote(subreddit)}/{sort}/.rss"
        try:
            raw = self._fetch_bytes(url, accept="application/atom+xml, application/xml, */*")
            return self._parse_atom(raw, subreddit=subreddit)[:limit]
        except Exception as exc:  # noqa: BLE001
            if "HTTP 429" in str(exc):
                raise
            # Fallback to subreddit root feed once
            fallback = f"https://www.reddit.com/r/{urllib.parse.quote(subreddit)}/.rss"
            raw = self._fetch_bytes(fallback, accept="application/atom+xml, application/xml, */*")
            return self._parse_atom(raw, subreddit=subreddit)[:limit]

    def search(
        self,
        *,
        query: str,
        subreddit: str | None = None,
        sort: str = "new",
        time_filter: str = "week",
        limit: int = 25,
    ) -> list[dict[str, Any]]:
        # RSS search
        params = {"q": query, "sort": sort, "t": time_filter}
        if subreddit:
            params["restrict_sr"] = "on"
            url = f"https://www.reddit.com/r/{urllib.parse.quote(subreddit)}/search.rss?{urllib.parse.urlencode(params)}"
        else:
            url = f"https://www.reddit.com/search.rss?{urllib.parse.urlencode(params)}"
        try:
            raw = self._fetch_bytes(url, accept="application/atom+xml, application/xml, */*")
            return self._parse_atom(raw, subreddit=subreddit)[:limit]
        except Exception as rss_err:  # noqa: BLE001
            if not self.use_pullpush:
                raise
            try:
                return self._pullpush_search(
                    query=query, subreddit=subreddit, sort=sort, time_filter=time_filter, limit=limit
                )
            except Exception as pp_err:  # noqa: BLE001
                raise RuntimeError(f"RSS search failed ({rss_err}); PullPush failed ({pp_err})") from pp_err

    def _pullpush_search(
        self,
        *,
        query: str,
        subreddit: str | None,
        sort: str,
        time_filter: str,
        limit: int,
    ) -> list[dict[str, Any]]:
        now = time.time()
        windows = {"day": 86400, "week": 604800, "month": 2592000, "year": 31536000}
        after = int(now - windows.get(time_filter, 604800))
        params: dict[str, str] = {
            "q": query,
            "size": str(min(100, max(1, limit))),
            "after": str(after),
            "sort": "desc",
            "sort_type": "created_utc" if sort == "new" else "score",
        }
        if subreddit:
            params["subreddit"] = subreddit
        url = "https://api.pullpush.io/reddit/search/submission/?" + urllib.parse.urlencode(params)
        raw = self._fetch_bytes(url, accept="application/json")
        data = _json_loads(raw)
        items = data.get("data") if isinstance(data, dict) else data
        if not isinstance(items, list):
            items = []
        out: list[dict[str, Any]] = []
        for d in items:
            if not isinstance(d, dict):
                continue
            pid = str(d.get("id") or "").removeprefix("t3_")
            if not pid:
                continue
            permalink = d.get("permalink") or ""
            if permalink and not str(permalink).startswith("http"):
                permalink = "https://www.reddit.com" + permalink
            out.append(
                {
                    "id": pid,
                    "subreddit": d.get("subreddit") or subreddit or "",
                    "title": d.get("title") or "",
                    "selftext": d.get("selftext") or "",
                    "url": d.get("url") or permalink,
                    "permalink": permalink,
                    "author": d.get("author") or "",
                    "created_utc": float(d.get("created_utc") or 0),
                    "score": int(d.get("score") or 0),
                    "num_comments": int(d.get("num_comments") or 0),
                    "flair": d.get("link_flair_text") or "",
                    "source": "reddit",
                }
            )
        return out
