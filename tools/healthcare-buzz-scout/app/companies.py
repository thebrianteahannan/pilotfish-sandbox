"""Running list of companies that may need PilotFish healthcare / insurance integration."""

from __future__ import annotations

import json
import re
from typing import Any

from db import utc_now
from jobs import NOT_COMPANY
from prospects import attach_rundown

COMPANY_STATUSES = ("new", "interested", "not_interested", "already_client")
STATUS_LABELS = {
    "new": "New",
    "interested": "Interested",
    "not_interested": "Not interested",
    "already_client": "Already a client",
}
OLD_STATUS = {
    "watching": "interested",
    "talking": "interested",
    "won": "already_client",
    "dismissed": "not_interested",
}

REASON_LABELS = {
    "hiring": "Hiring an integration person",
    "in_the_news": "Named in integration news",
    "public_ask": "Named in a public integration ask",
}

SKIP = NOT_COMPANY | {
    "company not named",
    "unlisted",
    "united states",
    "american hospital association",
    "cms",
    "onc",
    "wedi",
    "google",
    "microsoft",
    "amazon",
    "anthropic",
    "pr newswire",
    "newswire",
    "indeed",
    "job boards",
    "federal register",
    "stackoverflow",
    "hacker news",
    "oracle health",
    "oracle",
    "techtarget",
    "becker's hospital",
    "onc health",
}

SKIP_TAIL = re.compile(
    r"(?i)\b(association|society|journal|times|news|newswire|blog|university|college|conference|delivers|faster)\b"
)
STRICT_ORG_RE = re.compile(
    r"\b([A-Z][A-Za-z0-9&.'’-]{2,}(?:\s+[A-Z][A-Za-z0-9&.'’-]{2,}){0,2})\s+"
    r"(Hospitals?|Medical\s+Centers?|Health\s+Systems?|Health\s+Plans?|"
    r"Life\s+Insurance|Insurance\s+(?:Company|Group))\b"
)
STOP_ORG_PREFIX = {
    "acute",
    "eligible",
    "critical",
    "long-term",
    "long",
    "certain",
    "veteran",
    "qualified",
    "qualifying",
    "becker's",
    "beckers",
    "faster",
    "verisk",
    "verisk’s",
    "manulife canada delivers faster",
}
KNOWN = [
    (r"\belevance health\b", "Elevance Health", "insurance"),
    (r"\bunitedhealth|\bunited health(?:care)?\b", "UnitedHealth", "both"),
    (r"\bhumana\b", "Humana", "insurance"),
    (r"\bcigna\b", "Cigna", "insurance"),
    (r"\bcentene\b", "Centene", "insurance"),
    (r"\bmolina\b", "Molina Healthcare", "insurance"),
    (r"\bkaiser\b", "Kaiser Permanente", "healthcare"),
    (r"\bhca healthcare\b", "HCA Healthcare", "healthcare"),
    (r"\bascension\b", "Ascension", "healthcare"),
    (r"\bmayo clinic\b", "Mayo Clinic", "healthcare"),
    (r"\bcleveland clinic\b", "Cleveland Clinic", "healthcare"),
    (r"\bdenver health\b", "Denver Health", "healthcare"),
    (r"\bochsner\b", "Ochsner Health", "healthcare"),
    (r"\bthedacare\b", "ThedaCare", "healthcare"),
    (r"\bsummit health\b", "Summit Health", "healthcare"),
    (r"\bitiliti\b", "Itiliti Health", "insurance"),
    (r"\boscar health\b", "Oscar Health", "insurance"),
    (r"\bmanulife\b", "Manulife", "insurance"),
    (r"\baetna\b", "Aetna", "insurance"),
    (r"\bhighmark\b", "Highmark", "insurance"),
]
INS_HINT = re.compile(r"(?i)\b(insurance|acord|txlife|guidewire|duck creek|carrier|payer|life|p&c|underwrit)\b")
HC_HINT = re.compile(r"(?i)\b(hospital|health\s+system|hl7|fhir|ehr|emr|epic|cerner|meditech|clinic|lab)\b")


def _slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:80]


def _norm(name: str) -> str:
    return re.sub(r"\s+", " ", (name or "").strip())


def _keep(name: str) -> bool:
    n = _norm(name)
    if len(n) < 3 or n.lower() in SKIP or SKIP_TAIL.search(n):
        return False
    first = n.split()[0].lower().strip("’'")
    if first in STOP_ORG_PREFIX or n.lower() in {"the", "this", "that", "your"}:
        return False
    return True


def _market(name: str, blob: str, hops: list[str]) -> str:
    text = f"{name} {blob} {' '.join(hops)}"
    ins = bool(INS_HINT.search(text))
    hc = bool(HC_HINT.search(text))
    if ins and hc:
        return "both"
    if ins:
        return "insurance"
    if hc:
        return "healthcare"
    return "healthcare"


def _hops(post: dict[str, Any]) -> list[str]:
    out = []
    for cap in post.get("capabilities") or []:
        label = cap.get("label") or ""
        if label and label not in out:
            out.append(label)
    return out[:5]


def extract_from_posts(posts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    hits: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str]] = set()

    def add(name: str, reason: str, post: dict[str, Any]) -> None:
        name = _norm(name)
        if not _keep(name):
            return
        key = (_slug(name), reason, str(post.get("id") or ""))
        if key in seen:
            return
        seen.add(key)
        blob = f"{post.get('title') or ''} {post.get('selftext') or ''}"
        hops = _hops(post)
        src = post.get("source") or "reddit"
        hits.append(
            {
                "name": name,
                "reason": reason,
                "market": _market(name, blob, hops),
                "hops": hops,
                "score": int(post.get("relevance") or 0),
                "sample": {
                    "id": post.get("id"),
                    "title": post.get("title") or "",
                    "source": src,
                },
            }
        )

    for post in posts:
        if (post.get("status") or "new") == "dismissed":
            continue
        src = post.get("source") or "reddit"
        reason = "hiring" if src == "jobs" else ("in_the_news" if src in {"news", "regs", "hn"} else "public_ask")
        company = _norm(post.get("product_name") or "")
        if src == "jobs" and company:
            add(company, "hiring", post)
        blob = f"{post.get('title') or ''} {post.get('selftext') or ''}"
        for pat, name, _mkt in KNOWN:
            if re.search(pat, blob, re.I):
                add(name, reason, post)
        for m in STRICT_ORG_RE.finditer(blob):
            add(f"{m.group(1)} {m.group(2)}", reason, post)
    return hits


def upsert_company(store: Any, hit: dict[str, Any]) -> None:
    cid = _slug(hit["name"])
    if not cid:
        return
    now = utc_now()
    with store.connect() as conn:
        row = conn.execute("SELECT * FROM companies WHERE id=?", (cid,)).fetchone()
        if row:
            reasons = json.loads(row["reasons_json"] or "[]")
            hops = json.loads(row["hops_json"] or "[]")
            samples = json.loads(row["samples_json"] or "[]")
            if hit["reason"] not in reasons:
                reasons.append(hit["reason"])
            for h in hit.get("hops") or []:
                if h not in hops:
                    hops.append(h)
            sid = (hit.get("sample") or {}).get("id")
            if sid and not any(s.get("id") == sid for s in samples):
                samples = [hit["sample"], *samples][:8]
            hiring = int(row["hiring_count"] or 0) + (1 if hit["reason"] == "hiring" else 0)
            conn.execute(
                """
                UPDATE companies SET
                  name=?, market=?, score=?, hiring_count=?, signal_count=?,
                  reasons_json=?, hops_json=?, samples_json=?, last_seen=?, updated_at=?
                WHERE id=?
                """,
                (
                    hit["name"],
                    hit.get("market") or row["market"] or "",
                    max(int(row["score"] or 0), int(hit.get("score") or 0)),
                    hiring,
                    int(row["signal_count"] or 0) + 1,
                    json.dumps(reasons),
                    json.dumps(hops[:8]),
                    json.dumps(samples),
                    now,
                    now,
                    cid,
                ),
            )
            return
        conn.execute(
            """
            INSERT INTO companies (
              id, name, market, status, notes, score, hiring_count, signal_count,
              reasons_json, hops_json, samples_json, first_seen, last_seen, updated_at
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            """,
            (
                cid,
                hit["name"],
                hit.get("market") or "",
                "new",
                "",
                int(hit.get("score") or 0),
                1 if hit["reason"] == "hiring" else 0,
                1,
                json.dumps([hit["reason"]]),
                json.dumps((hit.get("hops") or [])[:8]),
                json.dumps([hit["sample"]] if hit.get("sample") else []),
                now,
                now,
                now,
            ),
        )


def normalize_company_status(store: Any) -> None:
    with store.connect() as conn:
        for old, new in OLD_STATUS.items():
            conn.execute("UPDATE companies SET status=? WHERE status=?", (new, old))


def refresh_companies(store: Any, *, rebuild: bool = False) -> int:
    normalize_company_status(store)
    if rebuild:
        with store.connect() as conn:
            conn.execute("DELETE FROM companies WHERE status='new'")
    posts = store.list_posts(status="all", limit=500)
    hits = extract_from_posts(posts)
    for hit in hits:
        upsert_company(store, hit)
    return len({_slug(h["name"]) for h in hits})


def list_companies(store: Any, *, status: str = "all", market: str = "", q: str = "") -> list[dict[str, Any]]:
    clauses = ["1=1"]
    args: list[Any] = []
    if status and status != "all":
        clauses.append("status=?")
        args.append(status)
    if market:
        clauses.append("(market=? OR market='both')")
        args.append(market)
    if q:
        like = f"%{q}%"
        clauses.append("(name LIKE ? OR notes LIKE ? OR hops_json LIKE ?)")
        args.extend([like, like, like])
    with store.connect() as conn:
        rows = conn.execute(
            f"""
            SELECT * FROM companies
            WHERE {' AND '.join(clauses)}
            ORDER BY
              CASE status WHEN 'interested' THEN 0 WHEN 'already_client' THEN 1 WHEN 'new' THEN 2 ELSE 3 END,
              score DESC, last_seen DESC
            """,
            args,
        ).fetchall()
    out = []
    for r in rows:
        d = dict(r)
        d["reasons"] = [REASON_LABELS.get(x, x) for x in json.loads(d.pop("reasons_json") or "[]")]
        d["hops"] = json.loads(d.pop("hops_json") or "[]")
        d["samples"] = json.loads(d.pop("samples_json") or "[]")
        d["status_label"] = STATUS_LABELS.get(d.get("status") or "new", d.get("status") or "new")
        attach_rundown(d)
        out.append(d)
    return out


def set_company(store: Any, company_id: str, *, status: str, notes: str | None = None) -> None:
    with store.connect() as conn:
        if notes is None:
            conn.execute(
                "UPDATE companies SET status=?, updated_at=? WHERE id=?",
                (status, utc_now(), company_id),
            )
        else:
            conn.execute(
                "UPDATE companies SET status=?, notes=?, updated_at=? WHERE id=?",
                (status, notes, utc_now(), company_id),
            )


def company_stats(store: Any) -> dict[str, int]:
    with store.connect() as conn:
        total = conn.execute("SELECT COUNT(*) FROM companies").fetchone()[0]
        hiring = conn.execute("SELECT COUNT(*) FROM companies WHERE hiring_count>0").fetchone()[0]
        hc = conn.execute("SELECT COUNT(*) FROM companies WHERE market IN ('healthcare','both')").fetchone()[0]
        ins = conn.execute("SELECT COUNT(*) FROM companies WHERE market IN ('insurance','both')").fetchone()[0]
        interested = conn.execute("SELECT COUNT(*) FROM companies WHERE status='interested'").fetchone()[0]
        clients = conn.execute("SELECT COUNT(*) FROM companies WHERE status='already_client'").fetchone()[0]
    return {
        "total": total,
        "hiring": hiring,
        "healthcare": hc,
        "insurance": ins,
        "interested": interested,
        "already_client": clients,
    }
