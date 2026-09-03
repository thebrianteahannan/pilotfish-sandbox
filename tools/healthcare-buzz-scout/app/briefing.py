"""Roll Reddit hits into demand, offers, prospect signals, and BD plays."""

from __future__ import annotations

import re
from collections import defaultdict
from typing import Any

from curate import DEMO_IDEAS
from jobs import cluster_hiring
from lanes import LANES, assign_lane, expand_clients
from systems import extract_systems

BUYING = [
    r"\blooking for\b",
    r"\bneed(?:s|ed)? (?:an? )?(?:vendor|consultant|partner|integrator|engine|tool)\b",
    r"\brfp\b",
    r"\brfi\b",
    r"\bevaluat(?:e|ing|ion)\b",
    r"\brecommend(?:ation)?\b",
    r"\banyone (?:use|using|tried|recommend)\b",
    r"\bwhich (?:engine|tool|vendor|product)\b",
    r"\bwhat (?:engine|tool|vendor)\b",
]

DISPLACE = [
    r"\balternative to\b",
    r"\breplace(?:ment|ing)?\b",
    r"\bswitch(?:ing)? (?:from|off|away)\b",
    r"\b(mirth|nextgen connect|rhapsody|cloverleaf|corepoint|ensemble)\b",
    r"\b(waystar|availity|change healthcare|changehc)\b.{0,40}\b(hate|slow|broken|limit)",
]

HIRE = [
    r"\bhir(?:e|ing)\b",
    r"\bwe(?:'re| are) (?:looking to )?hire\b",
    r"\bintegration (?:engineer|analyst|developer|specialist)\b",
    r"\binterface (?:analyst|engineer)\b",
]


def _blob(post: dict[str, Any]) -> str:
    return " ".join(
        str(post.get(k) or "")
        for k in ("title", "selftext", "why", "like_text", "dislike_text", "product_name")
    )


def _hits(blob: str, patterns: list[str]) -> list[str]:
    found = []
    for pat in patterns:
        if re.search(pat, blob, re.I):
            found.append(pat)
    return found


def signal_kinds(post: dict[str, Any]) -> list[str]:
    blob = _blob(post)
    kinds: list[str] = []
    if _hits(blob, BUYING):
        kinds.append("buying")
    if _hits(blob, DISPLACE):
        kinds.append("displace")
    if _hits(blob, HIRE):
        kinds.append("hire")
    if not kinds:
        kinds.append("community")
    return kinds


def _offer_for(cap_id: str, post: dict[str, Any]) -> dict[str, Any]:
    ideas = list(DEMO_IDEAS.get(cap_id) or [])
    if not ideas and cap_id == "edi_hard":
        ideas = list(DEMO_IDEAS.get("edi_claims") or [])
    existing = list(post.get("demo_hints") or [])
    idea = ideas[0] if ideas else None
    return {
        "existing_demos": existing[:4],
        "we_can_ship": (idea or {}).get("title") or (existing[0] if existing else "A targeted Sandbox route for this format"),
        "shows": (idea or {}).get("shows") or "Validate the real payload, map it, park exceptions.",
        "new_slug": (idea or {}).get("slug") or "",
    }


def _kind_label(kind: str) -> str:
    return {
        "sunset": "Engine sunset",
        "mandate": "Mandate / rule",
        "edi_hard": "Hard EDI / SNIP",
        "stuck": "Stuck on a weak engine",
        "expand": "Expand a current client",
        "buying": "In-market ask",
        "displace": "Replace / alternative",
        "hire": "Hiring (build vs buy)",
        "community": "Community pain",
    }.get(kind, kind)


def build_briefing(store: Any, cfg: dict[str, Any]) -> dict[str, Any]:
    caps_cfg = {c["id"]: c for c in (cfg.get("capability_map") or []) if c.get("id")}
    posts = store.list_posts(status="all", limit=400)
    active = [p for p in posts if (p.get("status") or "new") != "dismissed"]
    theme_posts = [p for p in active if (p.get("source") or "") != "jobs"]

    by_cap: dict[str, dict[str, Any]] = {}
    for post in theme_posts:
        for cap in post.get("capabilities") or []:
            cid = cap.get("id")
            if not cid:
                continue
            rec = by_cap.setdefault(
                cid,
                {
                    "id": cid,
                    "label": (caps_cfg.get(cid) or {}).get("label") or cap.get("label") or cid,
                    "count": 0,
                    "score_sum": 0,
                    "samples": [],
                    "demo_hints": set(),
                    "pitch_refs": set(),
                },
            )
            rec["count"] += 1
            rec["score_sum"] += int(post.get("relevance") or 0)
            if len(rec["samples"]) < 3:
                rec["samples"].append(
                    {
                        "id": post["id"],
                        "title": post.get("title") or "",
                        "source": post.get("source") or "reddit",
                        "relevance": post.get("relevance") or 0,
                    }
                )
            rec["demo_hints"].update(post.get("demo_hints") or [])
            rec["pitch_refs"].update(post.get("pitch_refs") or [])

    demand = []
    for cid, rec in by_cap.items():
        offer = _offer_for(cid, {"demo_hints": sorted(rec["demo_hints"])})
        demand.append(
            {
                "id": cid,
                "label": rec["label"],
                "count": rec["count"],
                "avg_relevance": round(rec["score_sum"] / rec["count"]) if rec["count"] else 0,
                "samples": rec["samples"],
                "existing_demos": sorted(rec["demo_hints"])[:5],
                "pitch_refs": sorted(rec["pitch_refs"])[:4],
                "we_can_ship": offer["we_can_ship"],
                "shows": offer["shows"],
                "new_slug": offer["new_slug"],
            }
        )
    demand.sort(key=lambda r: (-r["count"], -r["avg_relevance"]))

    prospects: list[dict[str, Any]] = []
    kind_counts: dict[str, int] = defaultdict(int)
    lane_counts: dict[str, int] = defaultdict(int)
    lane_samples: dict[str, list] = defaultdict(list)
    for post in active:
        lane = assign_lane(post)
        kinds = ([lane] if lane else []) + signal_kinds(post)
        if lane:
            lane_counts[lane] += 1
            if len(lane_samples[lane]) < 2:
                lane_samples[lane].append({"id": post["id"], "title": post.get("title") or ""})
        for kind in kinds:
            kind_counts[kind] += 1
        lead = kinds[0]
        if lead == "community" and int(post.get("relevance") or 0) < 40:
            continue
        cap0 = (post.get("capabilities") or [{}])[0]
        offer = _offer_for(str(cap0.get("id") or ""), post)
        prospects.append(
            {
                "id": post["id"],
                "kind": lead,
                "kind_label": _kind_label(lead),
                "title": post.get("title") or "",
                "source": post.get("source") or "reddit",
                "product_name": post.get("product_name") or "",
                "subreddit": post.get("subreddit") or "",
                "relevance": post.get("relevance") or 0,
                "created_utc": post.get("created_utc") or 0,
                "fetched_at": post.get("fetched_at") or "",
                "permalink": post.get("permalink") or "",
                "we_can_ship": offer["we_can_ship"],
                "shows": offer["shows"],
            }
        )
    rank = {"sunset": 0, "mandate": 1, "edi_hard": 2, "hire": 3, "stuck": 4, "displace": 5, "buying": 6}
    prospects.sort(key=lambda r: (rank.get(r["kind"], 8), -int(r["relevance"] or 0)))
    prospects = prospects[:18]

    expansions = expand_clients(demand)
    if expansions:
        lane_counts["expand"] = len(expansions)

    live_lanes = []
    for lane in LANES:
        lid = lane["id"]
        live_lanes.append(
            {
                **lane,
                "count": int(lane_counts.get(lid) or 0),
                "samples": lane_samples.get(lid) or [],
                "expansions": expansions if lid == "expand" else [],
            }
        )

    moves: list[dict[str, Any]] = []
    if lane_counts.get("sunset"):
        n = lane_counts["sunset"]
        moves.append(
            {
                "title": f"Work the {n} sunset / EOL signal{'s' if n != 1 else ''}",
                "do": "Someone’s engine is going dark. Offer a cutover of one live feed before the support date — every interface they already run is the book.",
            }
        )
    if lane_counts.get("mandate"):
        n = lane_counts["mandate"]
        moves.append(
            {
                "title": f"Ride the {n} mandate / rule thread{'s' if n != 1 else ''}",
                "do": "Same motion as COVID: the spec changed, the deadline is real. Stand up the payload (FHIR, 278, lab, ADT) and take it to current clients first.",
            }
        )
    if lane_counts.get("edi_hard"):
        n = lane_counts["edi_hard"]
        moves.append(
            {
                "title": f"Take the {n} hard EDI / SNIP ask{'s' if n != 1 else ''}",
                "do": "This is the specialist lane. Show SNIP + companion-guide edits and put a real EDI person on the call. Generalist engines bounce here.",
            }
        )
    if lane_counts.get("hire"):
        n = lane_counts["hire"]
        moves.append(
            {
                "title": f"Call the {n} compan{'ies' if n != 1 else 'y'} hiring an integration person",
                "do": "The hop is already in the job title. Offer a Sandbox route so the person they hire (or the one owner they keep) is productive in week two — not a three-person interface team.",
            }
        )
    if expansions:
        names = ", ".join(e["name"] for e in expansions)
        moves.append(
            {
                "title": f"Expand {names}",
                "do": "Match this week’s theme to a feed they still do by hand — another facility, carrier, or hop. Warm trust, faster SOW.",
            }
        )
    if lane_counts.get("stuck"):
        n = lane_counts["stuck"]
        moves.append(
            {
                "title": f"Unstick {n} “we’re trapped on this engine” ask{'s' if n != 1 else ''}",
                "do": "They wish it were better and think there is no alternative. Prove one hated hop on PilotFish. That is the switch they have been waiting for.",
            }
        )
    if demand and not moves:
        top = demand[0]
        moves.append(
            {
                "title": f"Package “{top['label']}” this week",
                "do": f"{top['count']} tracked asks. Refresh a nearby demo and send it to one current client in that lane.",
            }
        )

    systems = extract_systems(theme_posts)
    hiring = cluster_hiring(active)
    return {
        "demand": demand,
        "systems_in_use": systems["in_use"],
        "systems_missing": systems["missing"],
        "hiring_companies": hiring,
        "prospects": prospects,
        "moves": moves,
        "playbook": LANES,
        "live_lanes": live_lanes,
        "expansions": expansions,
        "kind_counts": dict(kind_counts),
        "lane_counts": dict(lane_counts),
        "active_count": len(active),
        "total_count": len(posts),
        "top_theme": demand[0]["label"] if demand else "",
    }
