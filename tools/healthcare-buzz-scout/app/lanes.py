"""The ways PilotFish actually wins integration work."""

from __future__ import annotations

import re
from typing import Any

# Lanes Brian named: sunset, mandate, expand, stuck, plus hard EDI (SNIP / standard change / specialists).
SUNSET = [
    r"\bsunset(?:ting|ted)?\b",
    r"\bend of (?:life|support|maintenance)\b",
    r"\beol\b",
    r"\beos\b",
    r"\bno longer (?:support|sell|offer)",
    r"\bdiscontinu",
    r"\bdeprecated\b",
    r"\bmigrat(?:e|ing|ion) off\b",
    r"\bforced (?:to )?(?:move|migrate|replace)\b",
]

MANDATE = [
    r"\bmandat(?:e|ed|ory)\b",
    r"\bfinal rule\b",
    r"\bcms\b",
    r"\bonc\b",
    r"\btefca\b",
    r"\bqhin\b",
    r"\binformation blocking\b",
    r"\b21st century cures\b",
    r"\binteroperability rule\b",
    r"\bprior auth(?:orization)? (?:final )?rule\b",
    r"\bpublic health emergency\b",
    r"\bcovid[- ]?(?:19|reporting|lab|mandate)",
    r"\bicd-?11\b",
    r"\bhtis?\b",
    r"\bcompliance (?:deadline|date|date)\b",
    r"\bby (?:january|july|december) 20\d\d\b",
]

STUCK = [
    r"\bstuck (?:on|with|using)\b",
    r"\blocked in\b",
    r"\bno (?:good |real )?alternative\b",
    r"\bwish (?:there|we) (?:was|had) (?:something )?better\b",
    r"\bhate (?:mirth|rhapsody|cloverleaf|corepoint|the engine)\b",
    r"\bcan'?t (?:leave|switch|replace)\b",
    r"\btoo (?:hard|risky|expensive) to (?:switch|replace|migrate)\b",
    r"\beveryone(?:'s| is) on (?:mirth|rhapsody|cloverleaf)\b",
    r"\bunable to integrate\b",
    r"\bdoesn'?t (?:really )?integrat",
]

HIRE = [
    r"\bhir(?:e|ing)\b",
    r"\bwe(?:'re| are) (?:looking to )?hire\b",
    r"\bintegration (?:engineer|analyst|developer|specialist)\b",
    r"\binterface (?:analyst|engineer)\b",
    r"\bopen(?:ing)?s? (?:for|on) (?:an? )?(?:hl7|edi|fhir|interface)\b",
]

# SNIP (sometimes said “SNP”), X12 version/companion-guide work — needs real EDI people.
EDI_HARD = [
    r"\bsnip\b",
    r"\bsnip[- ]?(?:level|[1-7])",
    r"\bsnp validat",
    r"\bcompanion guide",
    r"\bimplementation guide",
    r"\btr3\b",
    r"\bx12[- ]?(?:5010|8020|8030|version)",
    r"\b5010\b",
    r"\b8020\b",
    r"\bwedi\b",
    r"\bcaqh\b",
    r"\boperating rules\b",
    r"\b277ca\b",
    r"\bta1\b",
    r"\b999\b.{0,40}\b(ack|reject|edit)",
    r"\bedi (?:expert|specialist|consultant|guru)",
    r"\bneed(?:s|ed)? (?:an? )?(?:edi|x12) (?:person|people|expert|specialist)",
    r"\bstandard (?:change|version|upgrade)\b",
    r"\bnew x12\b",
    r"\bhipaa[- ]?(?:5010|x12|edi)\b",
]

# Existing sandbox clients — expand when a live theme matches what they already run.
CLIENTS = [
    {
        "name": "Med Rec",
        "slug": "med-rec",
        "already": "HL7 ADT/DFT, location stripping, charge files, kickout reports",
        "caps": ["hl7_adt_oru", "ehr_emr", "rcm_ops", "edi_claims", "mandate_interop", "edi_hard"],
        "more": "Another facility/partition, a new strip rule, DFT+ADT parity, or a charge feed they still key by hand.",
    },
    {
        "name": "CRL Plus",
        "slug": "crl-plus",
        "already": "Life new-business 121, ACORD 1122, status, attachments",
        "caps": ["acord_txlife", "edi_enrollment", "mandate_interop"],
        "more": "Another carrier map, a status hop they still email, or STP on a product that still stops for re-key.",
    },
]

LANES = [
    {
        "id": "sunset",
        "title": "Engine is sunsetting",
        "pitch": "When Mirth, Rhapsody, Cloverleaf, or another engine goes EOL, everyone on it has to land somewhere. That is a migration book of work — every interface they already run.",
        "do": "Find the sunset notice, list the shops still on that engine, and offer a side-by-side cutover of one live feed. Do not sell “an engine.” Sell “your ADT and 837 keep moving on the date they flip the lights off.”",
    },
    {
        "id": "mandate",
        "title": "A law or mandate just changed the hop",
        "pitch": "COVID reporting, CMS interop, TEFCA, prior-auth final rule, information blocking — the spec changes and every hospital/payer has to move data a new way. That is the same wave that filled the shop last time.",
        "do": "Name the rule, the deadline, and the payload (HL7, FHIR, 278, lab). Stand up a Sandbox route that already speaks that format and take it to people who must comply, including current clients.",
    },
    {
        "id": "edi_hard",
        "title": "Hard EDI — SNIP, standard changes, specialist work",
        "pitch": "PilotFish is the superior EDI engine, and we have people who actually live in X12. When the standard moves, when they need SNIP (sometimes said SNP) validation, companion guides, 999/TA1/277CA, or anything too sharp for a generalist — that is our work.",
        "do": "Lead with the transaction and the edit level, not a platform tour. Show SNIP + companion-guide rejects into a workqueue. Offer the expert, not a slide about “we do EDI.”",
    },
    {
        "id": "expand",
        "title": "More value for clients we already have",
        "pitch": "The fastest work is the next interface at Med Rec, CRL, or anyone already in production. They trust the engine. They still have a feed that is manual, a facility that was never mapped, or a mandate they have not wired yet.",
        "do": "Match this week’s buzzing theme to what that client already runs. Ask for the next partition, the next carrier, or the hop they still do in Excel.",
    },
    {
        "id": "hire",
        "title": "They're hiring the integration themselves",
        "pitch": "A posting for an HL7 / EDI / FHIR / interface analyst means the work is budgeted. They think they need a person. Often they need an engine plus one owner — or the person they hire still needs PilotFish beside them.",
        "do": "Open the company, name the hop in the job title, and offer a Sandbox route for that hop. Sell “your new analyst is productive in week two,” not “don’t hire anyone.”",
    },
    {
        "id": "stuck",
        "title": "Stuck on an engine that is not good enough",
        "pitch": "Comms and IT already wish it were better. They stay because switching looks worse than living with it — no alternative they trust. That is our opening: prove one painful hop is easier on PilotFish than staying.",
        "do": "Lead with the hop they hate (mapping, test, exceptions), not a rip-and-replace. One graphical route + eiTestBed is the alternative they think does not exist.",
    },
]


def _hits(blob: str, patterns: list[str]) -> bool:
    return any(re.search(p, blob, re.I) for p in patterns)


def assign_lane(post: dict[str, Any]) -> str | None:
    blob = " ".join(
        str(post.get(k) or "")
        for k in ("title", "selftext", "like_text", "dislike_text", "product_name")
    )
    if _hits(blob, SUNSET):
        return "sunset"
    if _hits(blob, MANDATE):
        return "mandate"
    if _hits(blob, EDI_HARD):
        return "edi_hard"
    if (post.get("source") or "") == "jobs" or _hits(blob, HIRE):
        return "hire"
    if _hits(blob, STUCK):
        return "stuck"
    return None


def lane_label(lane_id: str) -> str:
    return next((l["title"] for l in LANES if l["id"] == lane_id), lane_id)


def expand_clients(demand: list[dict[str, Any]]) -> list[dict[str, Any]]:
    hot = {d["id"]: d for d in demand}
    out = []
    for client in CLIENTS:
        hits = [hot[c] for c in client["caps"] if c in hot]
        if not hits:
            continue
        top = max(hits, key=lambda d: d["count"])
        out.append(
            {
                **client,
                "theme": top["label"],
                "theme_count": top["count"],
                "we_can_ship": top.get("we_can_ship") or "",
            }
        )
    return out
