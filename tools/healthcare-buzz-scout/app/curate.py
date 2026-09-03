"""Curate Reddit comments into signals, demo ideas, and a reply draft."""

from __future__ import annotations

import re
from typing import Any

from score import INTEGRATION_CUES, PAIN_CUES, _hits

NOISE = [
    r"\blmao\b",
    r"\brofl\b",
    r"^🤣+$",
    r"\bvibe code\b",
    r"\bproduct research\b",
    r"\btoo low effort\b",
    r"\bai taking (?:their|our|your) job\b",
    r"\bthis\b\s*$",
]

SIGNAL = [
    r"\bautomat",
    r"\bmanual\b",
    r"\btime sink\b",
    r"\bdenial",
    r"\beligib",
    r"\bprior auth",
    r"\bclaim",
    r"\bpay(?:er|ors?)\b",
    r"\binterfac",
    r"\bintegrat",
    r"\bhl7\b",
    r"\bfhir\b",
    r"\bedi\b",
    r"\bx12\b",
    r"\behr\b",
    r"\bemr\b",
    r"\bepic\b",
    r"\bwork(?:flow|queue|list)\b",
    r"\bexception\b",
    r"\brework\b",
    r"\bre-?key",
    r"\bportal\b",
    r"\bfax\b",
    r"\bspreadsheet",
    r"\bclearinghouse",
    r"\bmapping\b",
    r"\btransform",
]

# Suggested Sandbox demos keyed by capability when comments reveal a gap.
DEMO_IDEAS: dict[str, list[dict[str, str]]] = {
    "edi_claims": [
        {
            "slug": "edi-837-denial-workqueue",
            "title": "837 → SNIP/companion → denial workqueue",
            "shows": "Ingest claims, validate SNIP + payer rules, park exceptions in a review queue with reason codes — not another dashboard.",
            "modules": "EDI snip/validation, Data Mapper, Decision/Routing, SQL or file Target",
        },
        {
            "slug": "edi-835-underpay-reconcile",
            "title": "835 remittance underpay reconciler",
            "shows": "Match 835s to expected payments, flag underpays/denials, emit a worklist + optional ticket payload.",
            "modules": "EDI 835 listener, XSLT/Data Mapper, SQL Target, notification listener",
        },
    ],
    "edi_eligibility_auth": [
        {
            "slug": "edi-278-status-aggregator",
            "title": "278 + portal status aggregator",
            "shows": "Normalize 278 responses and portal/email status scraps into one prior-auth worklist with attachable clinical docs.",
            "modules": "HTTP/EDI listeners, Attribute Swapper, Data Mapper, HTML/JSON Target",
        },
        {
            "slug": "eligibility-fhir-x12-facade",
            "title": "Eligibility façade: FHIR then 270/271 fallback",
            "shows": "Single clinic JSON: try CoverageEligibilityRequest, fall back to X12 270/271, return one shape to the front desk.",
            "modules": "HTTP Source, FHIR + EDI callouts, Decision, JSON Target",
        },
    ],
    "edi_enrollment": [
        {
            "slug": "834-broker-normalize",
            "title": "Multi-broker 834 / CSV enrollment normalizer",
            "shows": "Accept messy broker layouts, validate members, write clean member table + exception report (+ optional FHIR Coverage).",
            "modules": "Directory/FTP Source, Data Mapper, SQL Target, File Target",
        },
    ],
    "hl7_adt_oru": [
        {
            "slug": "hl7-fhir-fanout",
            "title": "HL7 ADT/ORU + FHIR fan-out bridge",
            "shows": "One canonical event → MLLP to legacy labs and FHIR R4 to the new care app.",
            "modules": "LLP Listener, HL7 transformer, FHIR REST Target, Route fork",
        },
    ],
    "fhir": [
        {
            "slug": "smart-on-fhir-bridge",
            "title": "SMART on FHIR app bridge + legacy dual-write",
            "shows": "App talks FHIR; engine dual-writes HL7/EDI where downstream still needs it.",
            "modules": "HTTP/FHIR Source, Data Mapper, HL7/EDI Targets",
        },
    ],
    "ehr_emr": [
        {
            "slug": "ehr-interface-engine-cutover",
            "title": "EHR interface-engine cutover sandbox",
            "shows": "Replace brittle Mirth/Rhapsody-style routes with graphical PilotFish assembly: ADT/ORU/orders, test inline, deploy.",
            "modules": "LLP/HTTP listeners, Data Mapper, eiTestBed-style validation story",
        },
    ],
    "acord_txlife": [
        {
            "slug": "acord-txlife-stp",
            "title": "ACORD TxLife / eApp → policy admin STP",
            "shows": "Validate TxLife/XML + PDF apps, transform to policy API, raise STP with exception queue for underwriting.",
            "modules": "HTTP/File Source, XML Data Mapper, REST Target, Decision",
        },
    ],
    "rcm_ops": [
        {
            "slug": "rcm-payer-call-context",
            "title": "RCM payer-call context packager",
            "shows": "When humans must call payers, auto-assemble claim + eligibility + prior-auth history into one packet so rework drops.",
            "modules": "SQL/File Sources, Data Mapper, HTML/PDF Target",
        },
    ],
}


def _kw_hit(blob: str, kw: str) -> bool:
    k = kw.lower().strip()
    if not k:
        return False
    if len(k) <= 4 or k.isdigit() or re.fullmatch(r"\d+[a-z]*", k):
        return bool(re.search(rf"(?<![a-z0-9]){re.escape(k)}(?![a-z0-9])", blob))
    return k in blob


def score_comment(comment: dict[str, Any], capability_map: list[dict[str, Any]]) -> dict[str, Any]:
    body = (comment.get("body") or "").strip()
    blob = body.lower()
    if len(body) < 12:
        return {"relevance": 0, "is_signal": False, "why": "too short", "matched_caps": []}

    noise = _hits(blob, NOISE)
    if noise and len(body) < 80:
        return {"relevance": 0, "is_signal": False, "why": "noise / meme", "matched_caps": []}

    matched_caps: list[dict[str, str]] = []
    for cap in capability_map:
        matched = [kw for kw in cap.get("keywords") or [] if _kw_hit(blob, kw)]
        if matched:
            matched_caps.append({"id": cap["id"], "label": cap["label"]})

    signal = _hits(blob, SIGNAL)
    integ = _hits(blob, INTEGRATION_CUES)
    pain = _hits(blob, PAIN_CUES)
    length_boost = 8 if len(body) >= 120 else (4 if len(body) >= 60 else 0)
    cap_boost = 10 * len(matched_caps)
    relevance = min(100, signal * 8 + integ * 5 + pain * 6 + length_boost + cap_boost - noise * 15)
    is_signal = relevance >= 22 and (signal >= 1 or matched_caps or (pain >= 1 and len(body) >= 80))

    why_bits = []
    if matched_caps:
        why_bits.append("caps: " + ", ".join(c["label"] for c in matched_caps[:3]))
    why_bits.append(f"signal={signal} pain={pain} integ={integ}")
    if noise:
        why_bits.append("some noise cues")
    return {
        "relevance": max(0, relevance),
        "is_signal": is_signal,
        "why": "; ".join(why_bits),
        "matched_caps": matched_caps,
    }


def suggest_demos(post: dict[str, Any], comments: list[dict[str, Any]], capability_map: list[dict[str, Any]]) -> list[dict[str, Any]]:
    existing = set(post.get("demo_hints") or [])
    cap_ids = {c.get("id") for c in (post.get("capabilities") or []) if c.get("id")}
    for c in comments:
        if not c.get("is_signal"):
            continue
        for mc in c.get("matched_caps") or []:
            if mc.get("id"):
                cap_ids.add(mc["id"])
        # Infer caps from comment body if post caps thin
        blob = (c.get("body") or "").lower()
        for cap in capability_map:
            if any(_kw_hit(blob, kw) for kw in cap.get("keywords") or []):
                cap_ids.add(cap["id"])

    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for cid in sorted(cap_ids):
        for idea in DEMO_IDEAS.get(cid) or []:
            slug = idea["slug"]
            if slug in seen or slug in existing:
                continue
            seen.add(slug)
            out.append(
                {
                    **idea,
                    "capability": cid,
                    "nearby_existing": sorted(existing),
                    "rationale": _demo_rationale(cid, post, comments),
                }
            )
    # If nothing new, propose extending nearest existing demos
    if not out and existing:
        for name in sorted(existing)[:3]:
            out.append(
                {
                    "slug": f"extend-{name}",
                    "title": f"Extend Sandbox demo `{name}` for this thread",
                    "shows": "Reuse the proven route skeleton, retarget sample payloads to the pains called out in curated comments.",
                    "modules": "Same stack as the nearby demo; add Decision + workqueue Target if exceptions dominate",
                    "capability": (post.get("topics") or ["general"])[0] if post.get("topics") else "general",
                    "nearby_existing": sorted(existing),
                    "rationale": "Comments reinforce an existing Sandbox demo — package a customer-specific variant.",
                }
            )
    return out[:5]


def _demo_rationale(cap_id: str, post: dict[str, Any], comments: list[dict[str, Any]]) -> str:
    snippets = []
    for c in comments:
        if not c.get("is_signal"):
            continue
        caps = {m.get("id") for m in (c.get("matched_caps") or [])}
        body = (c.get("body") or "").strip()
        if cap_id in caps or len(snippets) < 2:
            snippets.append(body[:140] + ("…" if len(body) > 140 else ""))
        if len(snippets) >= 2:
            break
    if snippets:
        return "From comments: " + " | ".join(snippets)
    return f"Aligned to post capabilities and title: {post.get('title', '')[:120]}"


def build_reply(post: dict[str, Any], comments: list[dict[str, Any]], demos: list[dict[str, Any]]) -> str:
    title = (post.get("title") or "this").strip()
    signals = [c for c in comments if c.get("is_signal")]
    pains = []
    for c in signals[:4]:
        body = re.sub(r"\s+", " ", (c.get("body") or "").strip())
        if len(body) > 160:
            body = body[:157] + "…"
        pains.append(f"- “{body}” — u/{c.get('author') or 'anon'}")

    caps = [c.get("label") for c in (post.get("capabilities") or []) if c.get("label")]
    cap_line = ", ".join(caps[:3]) if caps else "healthcare / insurance data integration"

    demo_line = ""
    if demos:
        d0 = demos[0]
        demo_line = (
            f"\n\nIf it’s useful, we’re packaging a small Sandbox demo around "
            f"“{d0.get('title')}” that shows: {d0.get('shows')}"
        )

    pain_block = "\n".join(pains) if pains else "- The thread’s pain looks like manual rework between systems / payers / EHR."

    return (
        f"Appreciate the thread on “{title}”.\n\n"
        f"The comments are doing the real work — a few that stood out:\n"
        f"{pain_block}\n\n"
        f"That’s exactly the class of problem graphical interface engines are built for "
        f"({cap_line}): validate and transform the real formats (X12/HL7/FHIR/ACORD), "
        f"fan out to the systems that still need them, and park the exceptions humans "
        f"actually have to touch — instead of another dashboard that ignores the phone-call / portal mess."
        f"{demo_line}\n\n"
        f"Happy to share a concrete route / sample if helpful (no pitch deck required) — "
        f"what’s the worst manual hop in your stack today?"
    )


def curate_thread(
    post: dict[str, Any],
    comments: list[dict[str, Any]],
    capability_map: list[dict[str, Any]],
) -> dict[str, Any]:
    scored: list[dict[str, Any]] = []
    for c in comments:
        s = score_comment(c, capability_map)
        scored.append({**c, **s})
    scored.sort(key=lambda x: (not x.get("is_signal"), -int(x.get("relevance") or 0)))
    demos = suggest_demos(post, scored, capability_map)
    reply = build_reply(post, scored, demos)
    themes: list[str] = []
    for c in scored:
        if c.get("is_signal"):
            for mc in c.get("matched_caps") or []:
                if mc.get("label") and mc["label"] not in themes:
                    themes.append(mc["label"])
    return {
        "comments": scored,
        "signal_count": sum(1 for c in scored if c.get("is_signal")),
        "themes": themes,
        "demo_suggestions": demos,
        "reply_draft": reply,
    }


def enrich_post(
    store: Any,
    post: dict[str, Any],
    capability_map: list[dict[str, Any]],
    *,
    force: bool = False,
    user_agent: str = "PilotFishSandboxHealthcareBuzzScout/1.0",
) -> dict[str, Any]:
    """Fetch comments if needed, curate, persist, return bundle for the UI."""
    from reddit_client import RedditClient  # local import keeps curate testable

    if (post.get("source") or "reddit") != "reddit":
        comments = store.list_comments(post["id"])
        curated = curate_thread(post, comments, capability_map)
        if force or not post.get("reply_draft"):
            store.save_curation(
                post["id"],
                reply_draft=curated["reply_draft"],
                demo_suggestions=curated["demo_suggestions"],
                themes=curated["themes"],
                signal_count=curated["signal_count"],
            )
            post = store.get_post(post["id"]) or post
        comments = curated["comments"]
        return {
            "post": post,
            "comments": comments,
            "signal_comments": [c for c in comments if c.get("is_signal")],
            "other_comments": [c for c in comments if not c.get("is_signal")],
            "demo_suggestions": curated["demo_suggestions"],
            "reply_draft": curated["reply_draft"],
            "themes": curated["themes"],
            "signal_count": curated["signal_count"],
            "error": None,
        }

    existing = store.list_comments(post["id"])
    err: str | None = None
    if force or not existing or not post.get("comments_fetched_at"):
        try:
            client = RedditClient(user_agent)
            raw_comments = client.fetch_comments(post)
            curated = curate_thread(post, raw_comments, capability_map)
            store.replace_comments(post["id"], curated["comments"])
            store.save_curation(
                post["id"],
                reply_draft=curated["reply_draft"],
                demo_suggestions=curated["demo_suggestions"],
                themes=curated["themes"],
                signal_count=curated["signal_count"],
            )
            post = store.get_post(post["id"]) or post
            comments = curated["comments"]
            demos = curated["demo_suggestions"]
            reply = curated["reply_draft"]
            themes = curated["themes"]
            signal_count = curated["signal_count"]
        except Exception as exc:  # noqa: BLE001
            err = str(exc)
            comments = existing
            demos = post.get("demo_suggestions") or []
            reply = post.get("reply_draft") or ""
            themes = post.get("comment_themes") or []
            signal_count = int(post.get("signal_comment_count") or 0)
            if not reply and comments:
                curated = curate_thread(post, comments, capability_map)
                demos = curated["demo_suggestions"]
                reply = curated["reply_draft"]
                themes = curated["themes"]
                signal_count = curated["signal_count"]
    else:
        comments = existing
        demos = post.get("demo_suggestions") or []
        reply = post.get("reply_draft") or ""
        themes = post.get("comment_themes") or []
        signal_count = int(post.get("signal_comment_count") or 0)
        if not reply:
            curated = curate_thread(post, comments, capability_map)
            demos = curated["demo_suggestions"]
            reply = curated["reply_draft"]
            themes = curated["themes"]
            signal_count = curated["signal_count"]
            store.save_curation(
                post["id"],
                reply_draft=reply,
                demo_suggestions=demos,
                themes=themes,
                signal_count=signal_count,
            )

    return {
        "post": post,
        "comments": comments,
        "signal_comments": [c for c in comments if c.get("is_signal")],
        "other_comments": [c for c in comments if not c.get("is_signal")],
        "demo_suggestions": demos,
        "reply_draft": reply,
        "themes": themes,
        "signal_count": signal_count,
        "error": err,
    }
