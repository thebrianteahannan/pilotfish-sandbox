"""Hiring posts: companies staffing HL7 / EDI / FHIR / insurance integration."""

from __future__ import annotations

import re
import urllib.parse
from typing import Any

from feeds import FeedClient, _parse_created, _post, _sid, _strip_html

KEEP = re.compile(
    r"(?i)\b("
    r"hl7|fhir|x12|\bedi\b|837|835|834|278|270|271|"
    r"interop(?:erability)?|"
    r"interface (?:analyst|engineer|developer|specialist|manager)|"
    r"integration (?:analyst|engineer|developer|specialist|architect)|"
    r"emr integration|hl7 analyst|edi analyst|edi engineer|"
    r"acord|txlife|guidewire|duck creek|mirth"
    r")\b"
)
AGGREGATE = re.compile(
    r"(?i)("
    r"\bjobs?(?:,)?\s+(in|and vacancies|& work|employment)\b|"
    r"\bnow hiring:\s*\d+|"
    r"^\d+\s+|"
    r"\b\d{2,}\s+\w[\w ]{0,40}\bjobs\b|"
    r"\bjob vacancies\b|"
    r"^current openings at\b|"
    r"^jobs at\b|"
    r"\bjobs\s*-\s*lever\b|"
    r"apply today to work"
    r")"
)
NOT_COMPANY = {
    "indeed",
    "remote",
    "hybrid",
    "onsite",
    "lever",
    "greenhouse",
    "hl7",
    "fhir",
    "edi",
    "x12",
    "mirth",
    "rhapsody",
    "cloverleaf",
    "epic",
    "cerner",
    "acord",
}
BOARD_SUFFIX = re.compile(r"\s+-\s+(Indeed|Lever|Greenhouse|LinkedIn|ZipRecruiter)\s*$", re.I)
JOB_WORDS = re.compile(
    r"(?i)\b(analyst|engineer|developer|specialist|architect|manager|consultant)\b"
)


def _is_job(title: str) -> bool:
    t = (title or "").strip()
    if not t or AGGREGATE.search(t) or not KEEP.search(t):
        return False
    return True


def _clean_company(name: str) -> str:
    n = re.sub(r"\s+", " ", (name or "").strip(" -|,;"))
    n = re.sub(r"(?i)\s+\((?:remote|hybrid|onsite)\)\s*$", "", n).strip()
    if not n or n.lower() in NOT_COMPANY:
        return ""
    return n


def parse_headline(title: str) -> tuple[str, str]:
    t = BOARD_SUFFIX.sub("", title or "").strip()
    m = re.search(r"Job Application for (.+?) at (.+)$", t, re.I)
    if m:
        return m.group(1).strip(), _clean_company(m.group(2))
    m = re.search(r"(?i)^(.+?)\s+(?:at|@)\s+(.+)$", t)
    if m and (JOB_WORDS.search(m.group(1)) or KEEP.search(m.group(1))):
        return m.group(1).strip(), _clean_company(m.group(2))
    parts = [p.strip() for p in re.split(r"\s+-\s+", t) if p.strip()]
    if len(parts) >= 2 and JOB_WORDS.search(parts[1]) and not JOB_WORDS.search(parts[0]):
        return parts[1], _clean_company(parts[0])
    if parts and JOB_WORDS.search(parts[0]):
        company = next(
            (
                _clean_company(p)
                for p in parts[1:]
                if _clean_company(p) and not re.fullmatch(r"[A-Z][a-z]+", p)
            ),
            "",
        )
        return parts[0], company
    return t, ""


def cluster_hiring(posts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_co: dict[str, dict[str, Any]] = {}
    for post in posts:
        if (post.get("source") or "") != "jobs":
            continue
        company = (post.get("product_name") or "").strip()
        if not company:
            _, company = parse_headline(post.get("title") or "")
        if not company or company.lower() in {"indeed", "remote", "lever", "greenhouse", "unlisted"}:
            continue
        rec = by_co.setdefault(
            company.lower(),
            {"company": company, "count": 0, "roles": [], "hops": [], "samples": []},
        )
        rec["count"] += 1
        title = post.get("title") or ""
        if title and title not in rec["roles"] and len(rec["roles"]) < 4:
            rec["roles"].append(title)
        for cap in post.get("capabilities") or []:
            label = cap.get("label") or ""
            if label and label not in rec["hops"]:
                rec["hops"].append(label)
        if len(rec["samples"]) < 2:
            rec["samples"].append({"id": post.get("id"), "title": title})
    out = sorted(by_co.values(), key=lambda r: -r["count"])
    return out[:24]


def backfill_job_companies(store: Any) -> int:
    n = 0
    with store.connect() as conn:
        rows = conn.execute(
            "SELECT id, title, product_name, author FROM posts WHERE COALESCE(source,'')='jobs'"
        ).fetchall()
        for r in rows:
            _, company = parse_headline(r["title"] or "")
            if not company or (
                (r["product_name"] or "") == company and (r["author"] or "") == company
            ):
                continue
            conn.execute(
                "UPDATE posts SET product_name=?, author=? WHERE id=?",
                (company, company, r["id"]),
            )
            n += 1
    return n


def _from_rss(client: FeedClient, query: str, *, limit: int) -> list[dict[str, Any]]:
    url = "https://news.google.com/rss/search?" + urllib.parse.urlencode(
        {"q": query, "hl": "en-US", "gl": "US", "ceid": "US:en"}
    )
    out: list[dict[str, Any]] = []
    for post in client.rss(url, channel="Job boards", source="jobs", limit=limit):
        title = post.get("title") or ""
        if not _is_job(title):
            continue
        role, company = parse_headline(title)
        post["product_name"] = company
        post["author"] = company or "job-board"
        post["flair"] = "hiring"
        post["selftext"] = (
            f"Hiring signal: {role or title}"
            + (f" at {company}." if company else ".")
            + " Company is staffing integration work — offer PilotFish instead of (or beside) the hire."
        )
        out.append(post)
    return out


def _greenhouse(client: FeedClient, token: str, name: str) -> list[dict[str, Any]]:
    data = client.fetch_json(f"https://boards-api.greenhouse.io/v1/boards/{token}/jobs")
    out: list[dict[str, Any]] = []
    for job in data.get("jobs") or []:
        title = job.get("title") or ""
        url = job.get("absolute_url") or ""
        if not url or not _is_job(title):
            continue
        out.append(
            _post(
                pid=_sid("gh", url),
                title=f"{title} at {name}",
                body=f"Hiring signal: {title} at {name}. Offer the engine + one owner, or sit beside the person they hire.",
                url=url,
                source="jobs",
                channel="Greenhouse",
                created=_parse_created(job.get("updated_at")),
                author=name,
                flair="hiring",
                product_name=name,
            )
        )
    return out


def _lever(client: FeedClient, token: str, name: str) -> list[dict[str, Any]]:
    data = client.fetch_json(f"https://api.lever.co/v0/postings/{token}?mode=json")
    if not isinstance(data, list):
        return []
    out: list[dict[str, Any]] = []
    for job in data:
        title = job.get("text") or ""
        url = job.get("hostedUrl") or job.get("applyUrl") or ""
        if not url or not _is_job(title):
            continue
        body = _strip_html(job.get("descriptionPlain") or "")[:1600]
        out.append(
            _post(
                pid=_sid("lv", url),
                title=f"{title} at {name}",
                body=(body or f"Hiring signal: {title} at {name}.")
                + " Offer PilotFish instead of (or beside) this hire.",
                url=url,
                source="jobs",
                channel="Lever",
                created=float(job.get("createdAt") or 0) / 1000.0,
                author=name,
                flair="hiring",
                product_name=name,
            )
        )
    return out


def fetch_jobs(user_agent: str, feeds: dict[str, Any] | None = None, *, limit: int = 15) -> tuple[list[dict[str, Any]], dict[str, int], list[str]]:
    from feeds import load_feeds

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

    for q in cfg.get("job_queries") or []:
        _take(f"jobs::{q[:48]}", lambda query=q: _from_rss(client, query, limit=limit))
    for board in cfg.get("job_ats") or []:
        kind = board.get("kind")
        token = board.get("token")
        name = board.get("name") or token
        if not token:
            continue
        if kind == "greenhouse":
            _take(f"gh::{token}", lambda t=token, n=name: _greenhouse(client, t, n))
        elif kind == "lever":
            _take(f"lever::{token}", lambda t=token, n=name: _lever(client, t, n))
    return posts, by_query, errors
