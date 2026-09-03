"""Score Reddit posts for PilotFish healthcare / insurance fit."""

from __future__ import annotations

import re
from typing import Any


INTEGRATION_CUES = [
    r"\bintegrat",
    r"\binterface\b",
    r"\binterop",
    r"\bpipeline\b",
    r"\bconnect(?:ion|ing|or)?\b",
    r"\bmigrat",
    r"\btransform",
    r"\bmapping\b",
    r"\bhl7\b",
    r"\bfhir\b",
    r"\bedi\b",
    r"\bx12\b",
    r"\bacord\b",
    r"\btxlife\b",
    r"\behr\b",
    r"\bemr\b",
    r"\bengine\b",
    r"\bapi\b",
    r"\bwebhook",
    r"\bsftp\b",
    r"\bmllp\b",
]

PAIN_CUES = [
    r"\bneed(?:s|ed)?\b",
    r"\blooking for\b",
    r"\bstruggl",
    r"\bpain\b",
    r"\bbroken\b",
    r"\bfail(?:ing|ure)?\b",
    r"\bmanual\b",
    r"\bspreadsheet",
    r"\bhow (?:do|can|would) (?:i|we)\b",
    r"\brecommend",
    r"\balternative to\b",
    r"\breplace\b",
    r"\bvendor\b",
    r"\bhelp\b",
]

WORKFLOW_GAP_CUES = [
    r"\bworkflow\b",
    r"\bintegrat",
    r"\binterface\b",
    r"\beligib",
    r"\bprior auth",
    r"\bdenial",
    r"\bclaim",
    r"\bremit",
    r"\b835\b",
    r"\b837\b",
    r"\b270\b",
    r"\b271\b",
    r"\bhl7\b",
    r"\bfhir\b",
    r"\behr\b",
    r"\bemr\b",
    r"\bclearinghouse",
    r"\bpay(?:er|or)\b",
    r"\bpost(?:ing)?\b",
    r"\brework\b",
    r"\bmanual\b",
    r"\bexport\b",
    r"\bimport\b",
    r"\bapi\b",
    r"\bsftp\b",
    r"\bmapping\b",
    r"\bsupport\b",
    r"\bslow\b",
    r"\bdelay",
    r"\blimit(?:ation)?s?\b",
]


def _hits(text: str, patterns: list[str]) -> int:
    return sum(1 for p in patterns if re.search(p, text, re.I))


def score_post(post: dict[str, Any], capability_map: list[dict[str, Any]]) -> dict[str, Any]:
    blob = (
        f"{post.get('title','')}\n{post.get('selftext','')}\n{post.get('flair','')}\n"
        f"{post.get('like_text','')}\n{post.get('dislike_text','')}"
    ).lower()
    caps: list[dict[str, Any]] = []
    demos: set[str] = set()
    pitches: set[str] = set()
    topics: set[str] = set()
    why_bits: list[str] = []

    def _kw_hit(kw: str) -> bool:
        k = kw.lower().strip()
        if not k:
            return False
        # Short tokens must be whole words (avoid "edi" in "medicine", "orm" in "form")
        if len(k) <= 4 or k.isdigit() or re.fullmatch(r"\d+[a-z]*", k):
            return bool(re.search(rf"(?<![a-z0-9]){re.escape(k)}(?![a-z0-9])", blob))
        return k in blob

    for cap in capability_map:
        matched = [kw for kw in cap.get("keywords") or [] if _kw_hit(kw)]
        if not matched:
            continue
        weight = 12 + min(18, 3 * len(matched))
        caps.append({"id": cap["id"], "label": cap["label"], "matched": matched, "weight": weight})
        topics.add(cap["id"])
        for d in cap.get("demo_hints") or []:
            demos.add(d)
        for p in cap.get("pitch_refs") or []:
            pitches.add(p)
        why_bits.append(f"{cap['label']} ({', '.join(matched[:4])})")

    if not caps:
        return {
            "relevance": 0,
            "topics": [],
            "capabilities": [],
            "demo_hints": [],
            "pitch_refs": [],
            "why": "No PilotFish healthcare/insurance capability keywords matched.",
        }

    integ = _hits(blob, INTEGRATION_CUES)
    pain = _hits(blob, PAIN_CUES)
    gaps = _hits(blob, WORKFLOW_GAP_CUES)
    reddit_boost = min(15, int(post.get("score") or 0) // 5 + int(post.get("num_comments") or 0) // 3)
    base = sum(c["weight"] for c in caps)
    relevance = min(100, base + integ * 4 + pain * 5 + reddit_boost)

    # Job-board posts are the signal. Reddit career chatter is still noise.
    source = (post.get("source") or "reddit").lower()
    if source != "jobs" and re.search(r"\b(hiring|job|salary|resume|certification course|when (?:do|am) i supposed to (?:start )?apply)\b", blob):
        relevance = max(0, relevance - 25)
        why_bits.append("downranked: looks like hiring noise")
    if re.search(r"\b(pivot to tech|become an? (?:epic )?analyst|burned out rn|which ai certification)\b", blob):
        relevance = max(0, relevance - 20)
        why_bits.append("downranked: career pivot noise")
    if source == "jobs":
        relevance = min(100, relevance + 8)
        why_bits.append("hiring signal: company is staffing this hop")

    why = (
        f"Matched: {'; '.join(why_bits)}. "
        f"Integration cues={integ}, pain/ask cues={pain}, workflow-gap cues={gaps}, "
        f"reddit boost={reddit_boost}."
    )
    return {
        "relevance": relevance,
        "topics": sorted(topics),
        "capabilities": caps,
        "demo_hints": sorted(demos),
        "pitch_refs": sorted(pitches),
        "why": why,
    }
