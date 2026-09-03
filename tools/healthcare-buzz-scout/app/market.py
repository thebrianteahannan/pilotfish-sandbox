"""Who shows up in healthcare / insurance integration — and where PilotFish fits."""

from __future__ import annotations

import re
from typing import Any

from briefing import build_briefing
from competitors import build_competition
from searchcomp import load_search
from systems import CATALOG, _blob

# Qualitative seats — not purchased TAM. Installed-base reality Brian can sell against.
SEATS = [
    {
        "name": "Mirth / NextGen Connect",
        "kind": "engine",
        "seat": "Largest hospital interface installed base. Cheap, familiar, often the default.",
        "fit": "Displace on sunset, mapping pain, or test/exceptions — not a feature bake-off.",
    },
    {
        "name": "Rhapsody",
        "kind": "engine",
        "seat": "Common in larger health systems. Heavier, stickier, more license fear.",
        "fit": "Cut one hated hop beside it. Do not lead with rip-and-replace.",
    },
    {
        "name": "Cloverleaf",
        "kind": "engine",
        "seat": "Older installed base. Shows up in sunset / hard-to-staff talk.",
        "fit": "Date-driven cutover. Every interface they already run is the book.",
    },
    {
        "name": "Corepoint / HealthShare",
        "kind": "engine",
        "seat": "Mid-market and InterSystems shops. Smaller conversation than Mirth.",
        "fit": "Same motion as Rhapsody: one live feed, then the book.",
    },
    {
        "name": "PilotFish",
        "kind": "engine",
        "seat": "Challenger. One engine for healthcare and insurance. Graphical routes plus people who live in X12.",
        "fit": "Us. Lead with the hop (ADT, 837, SNIP, TxLife), not “another engine.”",
        "us": True,
    },
    {
        "name": "Epic / Oracle Health / MEDITECH",
        "kind": "ehr",
        "seat": "They own the chart and a lot of intra-EHR interface. Not an engine we replace.",
        "fit": "Sit on the edges: lab, payer, RCM, other facilities. Bridges is not the enemy.",
    },
    {
        "name": "Waystar / Availity / Change / Optum",
        "kind": "rcm",
        "seat": "Clearinghouse and portal gravity. They take a cut of claims traffic.",
        "fit": "When the portal is the integration, offer a real 837/835/270 hop. Do not pick a fight with the network.",
    },
    {
        "name": "Guidewire / Duck Creek",
        "kind": "insurance",
        "seat": "They own policy/claims admin. Integration around them is still up for grabs.",
        "fit": "ACORD / TxLife / status / attachments beside the core. We are the hop, not the admin system.",
    },
]

KIND_LABEL = {
    "engine": "Interface engines",
    "ehr": "EHR platforms (we sit beside)",
    "rcm": "RCM / clearinghouse",
    "insurance": "Insurance cores",
}


def _mentions(posts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows = []
    for name, kind, pats in CATALOG:
        count = 0
        samples = []
        for post in posts:
            if any(re.search(p, _blob(post), re.I) for p in pats):
                count += 1
                if len(samples) < 2:
                    samples.append({"id": post.get("id"), "title": post.get("title") or ""})
        rows.append({"name": name, "kind": kind, "count": count, "samples": samples})
    pf = 0
    for post in posts:
        if re.search(r"\bpilotfish\b|\beiconsole\b|\beiplatform\b", _blob(post), re.I):
            pf += 1
    rows.append({"name": "PilotFish", "kind": "engine", "count": pf, "samples": [], "us": True})
    return rows


def _pct(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    total = sum(int(r.get("count") or 0) for r in rows) or 1
    out = []
    for r in rows:
        rec = dict(r)
        rec["pct"] = round(100 * int(r.get("count") or 0) / total)
        out.append(rec)
    return sorted(out, key=lambda r: (-r["count"], r["name"]))


def build_market(store: Any, cfg: dict[str, Any]) -> dict[str, Any]:
    brief = build_briefing(store, cfg)
    posts = [p for p in store.list_posts(status="all", limit=400) if (p.get("status") or "new") != "dismissed"]
    all_m = _mentions(posts)
    engines = _pct([r for r in all_m if r["kind"] == "engine"])
    ehrs = _pct([r for r in all_m if r["kind"] == "ehr"])
    rcm = _pct([r for r in all_m if r["kind"] == "rcm"])
    ins = _pct([r for r in all_m if r["kind"] == "insurance"])
    talking = [r for r in engines + ehrs + rcm + ins if r["count"]]
    top = talking[0]["name"] if talking else "—"
    pf = next((r for r in engines if r.get("us")), {"count": 0, "pct": 0})
    lanes = {l["id"]: int(l.get("count") or 0) for l in brief.get("live_lanes") or []}
    demand = brief.get("demand") or []
    problem = []
    dtotal = sum(d["count"] for d in demand) or 1
    for d in demand[:6]:
        problem.append({**d, "pct": round(100 * d["count"] / dtotal)})
    search = load_search(store)
    comp = build_competition(search, all_m)
    return {
        "engines": engines,
        "ehrs": ehrs,
        "rcm": rcm,
        "insurance": ins,
        "seats": SEATS,
        "kind_label": KIND_LABEL,
        "problem": problem,
        "top_name": top,
        "pf_pct": pf.get("pct") or 0,
        "pf_count": pf.get("count") or 0,
        "named_count": len(talking),
        "active_count": brief.get("active_count") or 0,
        "hire_count": len(brief.get("hiring_companies") or []),
        "lane_counts": lanes,
        "top_theme": brief.get("top_theme") or "",
        **comp,
    }
