"""Buyer-search probe: who ranks for PilotFish hops, and how to get in."""

from __future__ import annotations

import json
import os
import re
import urllib.parse
from collections import defaultdict
from pathlib import Path
from typing import Any

from db import utc_now
from feeds import FeedClient, ROOT, _strip_html

CFG_PATH = ROOT / "config" / "search_queries.json"

PLAYERS = [
    ("PilotFish", True, ["pilotfishtechnology.com", "pilotfish"]),
    ("Rhapsody / Lyniate", False, ["rhapsody.health", "lyniate.com", "rhapsody"]),
    ("Mirth / NextGen", False, ["nextgen.com", "mirthconnect", "mirth"]),
    ("Qvera", False, ["qvera.com", "qvera"]),
    ("Cloverleaf / Infor", False, ["infor.com", "cloverleaf"]),
    ("Corepoint", False, ["corepointhealth.com", "corepoint"]),
    ("InterSystems", False, ["intersystems.com", "healthshare", "ensemble"]),
    ("Dynamic Health IT", False, ["dynamichealthit.com"]),
    ("Folio3 / Decode Health", False, ["folio3.com", "folio3", "decode health"]),
    ("Integration Soup", False, ["integrationsoup.com", "hl7 soup", "hl7soup"]),
    ("Wi4", False, ["wi4.ai"]),
    ("Taction Software", False, ["tactionsoft.com", "taction software"]),
    ("Majware", False, ["majware.com"]),
    ("Healthcare IT Skills", False, ["healthcareitskills.com"]),
    ("Redox", False, ["redoxengine.com", "redox"]),
    ("MuleSoft", False, ["mulesoft.com", "mulesoft"]),
    ("Boomi", False, ["boomi.com", "boomi"]),
    ("Edifecs", False, ["edifecs.com", "edifecs"]),
    ("Waystar", False, ["waystar.com", "waystar"]),
    ("Smile CDR", False, ["smilecdr.com", "smile cdr"]),
    ("Firely", False, ["fire.ly", "firely"]),
    ("Oracle Health", False, ["oracle.com", "cerner"]),
    ("Epic", False, ["epic.com", "epic systems"]),
    ("Guidewire", False, ["guidewire.com", "guidewire"]),
    ("Duck Creek", False, ["duckcreek.com", "duck creek"]),
]
SKIP = {
    "bing.com",
    "microsoft.com",
    "capterra.com",
    "softwareadvice.com",
    "trustradius.com",
    "wikipedia.org",
    "wiktionary.org",
    "youtube.com",
    "merriam-webster.com",
    "dictionary.com",
    "thesaurus.com",
    "dictionary.cambridge.org",
    "thefreedictionary.com",
    "britannica.com",
    "imdb.com",
    "wikihow.com",
    "snipaste.com",
    "snipping-tools.com",
    "epicgames.com",
    "store.epicgames.com",
    "epic.org",
    "bestbuy.com",
    "zhihu.com",
    "baidu.com",
    "wordreference.com",
    "vocabulary.com",
    "nytimes.com",
    "gov.br",
}
SCHEMA = """
CREATE TABLE IF NOT EXISTS search_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  started_at TEXT, finished_at TEXT, error TEXT, detail_json TEXT
);
CREATE TABLE IF NOT EXISTS search_hits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id INTEGER, channel TEXT, query TEXT, theme TEXT,
  rank INTEGER, title TEXT, url TEXT, player TEXT, is_us INTEGER
);
"""


def load_search_cfg() -> dict[str, Any]:
    if not CFG_PATH.is_file():
        return {"web": [], "ai_ask": [], "listicles": [], "prompts": []}
    return json.loads(CFG_PATH.read_text(encoding="utf-8"))


def ensure_search(store: Any) -> None:
    with store.connect() as conn:
        conn.executescript(SCHEMA)


def _host(url: str) -> str:
    try:
        host = urllib.parse.urlparse(url).netloc.lower()
    except Exception:
        return ""
    return host[4:] if host.startswith("www.") else host


def _player(blob: str, url: str) -> tuple[str, bool]:
    hay = f"{blob} {url}".lower()
    for name, us, aliases in PLAYERS:
        if any(a in hay for a in aliases):
            return name, us
    host = _host(url)
    if not host or any(host == s or host.endswith("." + s) or s in host for s in SKIP):
        return "", False
    return host, False


def _bing(client: FeedClient, query: str) -> list[dict[str, Any]]:
    url = "https://www.bing.com/search?" + urllib.parse.urlencode({"q": query, "setlang": "en-US"})
    raw = client.fetch_bytes(url, accept="text/html").decode("utf-8", errors="replace")
    out = []
    cites = re.findall(r"<cite[^>]*>(.*?)</cite>", raw, re.S)
    rank = 0
    for cite in cites:
        text = _strip_html(cite).replace(" › ", "/").strip()
        if not text or text.startswith("http") and "bing.com" in text:
            continue
        guess = text.split()[0]
        if not guess.startswith("http"):
            guess = "https://" + guess.split("/")[0]
        host = _host(guess)
        if not host or any(s in host for s in SKIP):
            continue
        rank += 1
        player, us = _player(text, guess)
        if not player:
            continue
        out.append({"rank": rank, "title": text, "url": guess, "player": player, "is_us": us})
        if rank >= 10:
            break
    return out


def _listicle(client: FeedClient, page: str) -> list[str]:
    raw = client.fetch_bytes(page, accept="text/html").decode("utf-8", errors="replace")
    blob = _strip_html(raw)
    names = []
    for name, _us, aliases in PLAYERS:
        if any(re.search(rf"\b{re.escape(a)}\b", blob, re.I) for a in aliases if len(a) > 3):
            names.append(name)
    return names


def run_probe(store: Any) -> dict[str, Any]:
    ensure_search(store)
    cfg = load_search_cfg()
    ua = os.environ.get("SEARCH_UA") or (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
    )
    client = FeedClient(ua)
    client.min_interval = float(os.environ.get("SEARCH_GAP", "1.6"))
    errors: list[str] = []
    hits: list[dict[str, Any]] = []

    def take(channel: str, rec: dict[str, Any]) -> None:
        try:
            rows = _bing(client, rec["q"])
            for row in rows:
                hits.append({**row, "channel": channel, "query": rec["q"], "theme": rec.get("theme") or ""})
        except Exception as exc:  # noqa: BLE001
            errors.append(f"{channel}:{rec['q'][:40]}: {exc}")

    for rec in cfg.get("web") or []:
        take("web", rec)
    for rec in cfg.get("ai_ask") or []:
        take("ai_ask", rec)
    for page in cfg.get("listicles") or []:
        try:
            for i, name in enumerate(_listicle(client, page), start=1):
                us = name == "PilotFish"
                hits.append(
                    {
                        "channel": "ai_cite",
                        "query": page,
                        "theme": "listicle",
                        "rank": i,
                        "title": "Named in a comparison article AIs cite",
                        "url": page,
                        "player": name,
                        "is_us": us,
                    }
                )
        except Exception as exc:  # noqa: BLE001
            errors.append(f"listicle:{exc}")

    with store.connect() as conn:
        cur = conn.execute("INSERT INTO search_runs (started_at, detail_json) VALUES (?,?)", (utc_now(), "{}"))
        run_id = int(cur.lastrowid)
        for h in hits:
            conn.execute(
                """
                INSERT INTO search_hits (run_id, channel, query, theme, rank, title, url, player, is_us)
                VALUES (?,?,?,?,?,?,?,?,?)
                """,
                (run_id, h["channel"], h["query"], h["theme"], h["rank"], h["title"], h["url"], h["player"], int(bool(h["is_us"]))),
            )
        conn.execute(
            "UPDATE search_runs SET finished_at=?, error=?, detail_json=? WHERE id=?",
            (utc_now(), "; ".join(errors)[:800], json.dumps({"hits": len(hits), "errors": errors[:12]}), run_id),
        )
    return {"run_id": run_id, "hits": len(hits), "errors": errors}


def ingest_ai_paste(store: Any, *, source: str, text: str) -> int:
    ensure_search(store)
    names = []
    for name, us, aliases in PLAYERS:
        if any(re.search(rf"\b{re.escape(a)}\b", text, re.I) for a in aliases if len(a) > 3):
            names.append((name, us))
    if not names:
        return 0
    with store.connect() as conn:
        cur = conn.execute(
            "INSERT INTO search_runs (started_at, finished_at, detail_json) VALUES (?,?,?)",
            (utc_now(), utc_now(), json.dumps({"paste": source})),
        )
        run_id = int(cur.lastrowid)
        for i, (name, us) in enumerate(names, start=1):
            conn.execute(
                """
                INSERT INTO search_hits (run_id, channel, query, theme, rank, title, url, player, is_us)
                VALUES (?,?,?,?,?,?,?,?,?)
                """,
                (run_id, "ai_model", f"pasted {source}", "ai", i, source, "", name, int(us)),
            )
    return len(names)


def load_search(store: Any) -> dict[str, Any]:
    ensure_search(store)
    cfg = load_search_cfg()
    with store.connect() as conn:
        last = conn.execute(
            """
            SELECT r.* FROM search_runs r
            WHERE EXISTS (SELECT 1 FROM search_hits h WHERE h.run_id = r.id AND h.is_us = 1)
            ORDER BY r.id DESC LIMIT 1
            """
        ).fetchone()
        if not last:
            last = conn.execute("SELECT * FROM search_runs ORDER BY id DESC LIMIT 1").fetchone()
        hits = []
        if last:
            hits = [dict(r) for r in conn.execute("SELECT * FROM search_hits WHERE run_id=?", (last["id"],)).fetchall()]
    by_q: dict[str, dict[str, Any]] = {}
    players: dict[str, int] = defaultdict(int)
    us_present = 0
    queries = []
    for h in hits:
        if h["channel"] not in {"web", "ai_ask"}:
            continue
        rec = by_q.setdefault(h["query"], {"query": h["query"], "theme": h["theme"], "channel": h["channel"], "players": [], "us_rank": None})
        if h["player"] not in rec["players"]:
            rec["players"].append(h["player"])
        if h["is_us"] and rec["us_rank"] is None:
            rec["us_rank"] = h["rank"]
            us_present += 1
        players[h["player"]] += 1
    queries = sorted(
        by_q.values(),
        key=lambda r: (
            0 if r["us_rank"] is not None else 1,
            r["us_rank"] if r["us_rank"] is not None else 99,
            r.get("query") or "",
        ),
    )
    ranked = sorted(players.items(), key=lambda kv: -kv[1])
    plays = []
    for rec in queries:
        known = {n for n, _u, _a in PLAYERS}
        lead = [p for p in rec["players"] if p in known][:3] or rec["players"][:3]
        if rec["us_rank"] is None:
            plays.append(f"Absent on “{rec['query']}”. Publish a hop page and buy the phrase. Leaders: {', '.join(lead) or '—'}.")
        elif rec["us_rank"] > 5:
            plays.append(f"#{rec['us_rank']} on “{rec['query']}”. Tighten the title to the hop. Ahead of us: {', '.join(lead)}.")
    cites = sorted({h["player"] for h in hits if h["channel"] == "ai_cite"})
    if cites and "PilotFish" not in cites:
        plays.append("Comparison articles AIs cite do not name PilotFish. Get a crawlable “HL7 interface engine” page they can quote.")
    models = sorted({h["player"] for h in hits if h["channel"] == "ai_model"})
    return {
        "queries": queries,
        "ranked": [{"name": n, "count": c, "us": n == "PilotFish"} for n, c in ranked[:12]],
        "plays": plays[:8],
        "cites": cites,
        "models": models,
        "prompts": cfg.get("prompts") or [],
        "hit_count": len(hits),
        "query_count": len(queries),
        "us_present": us_present,
        "last": dict(last) if last else None,
        "top_other": next((n for n, _c in ranked if n != "PilotFish"), "—"),
    }
