"""Curated ads and campaigns from the live healthcare / insurance buzz."""

from __future__ import annotations

import urllib.parse
from typing import Any

from briefing import build_briefing

TRADE = [
    ("Becker’s HIT", "https://www.beckershospitalreview.com/healthcare-information-technology.html"),
    ("Fierce Healthcare", "https://www.fiercehealthcare.com/"),
    ("Healthcare IT News", "https://www.healthcareitnews.com/"),
    ("Insurance Journal", "https://www.insurancejournal.com/"),
]

# Search terms a buyer actually types. Not brand slogans.
SEARCH = {
    "edi_claims": ["837 835 integration", "X12 claims engine", "HIPAA EDI interface"],
    "edi_hard": ["SNIP validation", "X12 companion guide", "277CA 999 TA1"],
    "edi_eligibility_auth": ["270 271 engine", "278 prior authorization", "eligibility interface"],
    "edi_enrollment": ["834 enrollment interface", "HIPAA 834 mapping"],
    "hl7_adt_oru": ["HL7 ADT interface engine", "ORU interface analyst", "MLLP HL7"],
    "fhir": ["FHIR integration engine", "SMART on FHIR interface", "Bulk FHIR"],
    "ehr_emr": ["Epic interface engine", "EMR integration specialist", "EHR interface engine"],
    "acord_txlife": ["ACORD TxLife", "life insurance STP", "121 1122 interface"],
    "rcm_ops": ["RCM interface engine", "claims clearinghouse alternative"],
    "mandate_interop": ["CMS interoperability rule", "TEFCA QHIN interface", "prior auth FHIR"],
}

AUDIENCE = {
    "edi_claims": "Payer and RCM EDI managers who own 837/835",
    "edi_hard": "EDI specialists and clearinghouse leads who live in SNIP and companion guides",
    "edi_eligibility_auth": "Payer ops and prior-auth leads stuck on 270/271/278",
    "edi_enrollment": "Benefits / enrollment ops running 834 by hand or on a brittle map",
    "hl7_adt_oru": "Hospital interface analysts and HIT directors with ADT/ORU books",
    "fhir": "Interop architects standing up FHIR / SMART / Bulk",
    "ehr_emr": "Health-system IT after Epic / Cerner / MEDITECH hops",
    "acord_txlife": "Life carrier new-business and vendor-management leads",
    "rcm_ops": "RCM directors tired of portal re-key and clearinghouse limits",
    "mandate_interop": "Compliance + IT pairs who just got a deadline",
}


def _theme_ad(theme: dict[str, Any], rank: int) -> dict[str, Any]:
    cid = theme["id"]
    label = theme["label"]
    n = theme["count"]
    keys = SEARCH.get(cid) or [label]
    return {
        "id": f"search-{cid}",
        "kind": "search",
        "rank": rank,
        "title": f"Search ads for {label}",
        "why": f"{n} live asks this week. People are already naming the hop. Meet them on the query.",
        "audience": AUDIENCE.get(cid) or f"Teams hitting {label}",
        "channel": "Google Search",
        "headline": f"{label} — one route, not another hire",
        "ad_text": (
            f"This week’s feed is loud on {label}. "
            f"PilotFish maps the live payload, parks exceptions, and puts one owner on the hop. "
            f"See a Sandbox route that already speaks it."
        ),
        "offer": theme.get("we_can_ship") or "A Sandbox route for this hop",
        "keywords": keys,
        "place": "Google Search · exact + phrase on the keywords",
        "samples": theme.get("samples") or [],
    }


def _lane_ad(lane: dict[str, Any], extra: dict[str, Any]) -> dict[str, Any] | None:
    n = int(lane.get("count") or 0)
    lid = lane["id"]
    if lid == "expand" and extra.get("expansions"):
        n = len(extra["expansions"])
    if n <= 0 and lid != "expand":
        return None
    pack = {
        "sunset": {
            "title": "Engine sunset / cutover ads",
            "channel": "LinkedIn + Google Search",
            "audience": "CIOs and interface managers still on Mirth, Rhapsody, or Cloverleaf",
            "headline": "When the engine goes dark, the interfaces still have to run",
            "ad_text": "Sunset is a date, not a slide. Cut one live ADT or 837 over on PilotFish before support ends. The rest of the book follows.",
            "place": "LinkedIn: Interface Manager, Integration Architect · Search: Mirth alternative, Rhapsody migration",
            "keywords": ["Mirth alternative", "Rhapsody migration", "Cloverleaf replacement", "HL7 engine sunset"],
        },
        "mandate": {
            "title": "Mandate / deadline ads",
            "channel": "LinkedIn + trade (Becker’s, Fierce, Healthcare IT News)",
            "audience": "Compliance + HIT pairs with a CMS / ONC / TEFCA / prior-auth date",
            "headline": "The rule changed. The hop has a deadline.",
            "ad_text": "Same motion as COVID reporting: a new spec, a real date, every hospital and payer has to move data a new way. We already speak FHIR, 278, ADT, lab.",
            "place": "Sponsored in Fierce / Becker’s interoperability roundups · LinkedIn compliance + CIO",
            "keywords": ["CMS interoperability rule", "prior authorization FHIR", "TEFCA interface"],
        },
        "edi_hard": {
            "title": "Hard EDI / SNIP specialist ads",
            "channel": "Google Search + LinkedIn",
            "audience": "EDI managers who need SNIP, companion guides, 999/TA1/277CA",
            "headline": "SNIP and companion guides — not a generalist engine",
            "ad_text": "PilotFish is the superior EDI engine, with people who actually live in X12. Show the transaction and the edit level. Generalist tools bounce here.",
            "place": "Search: SNIP validation, X12 companion guide · LinkedIn: EDI Manager, Clearinghouse",
            "keywords": ["SNIP validation", "X12 companion guide", "277CA", "HIPAA 5010 engine"],
        },
        "hire": {
            "title": "Hiring-the-hop ads",
            "channel": "LinkedIn (hiring-manager titles) + Indeed competitor",
            "audience": "Hiring managers posting HL7 / EDI / FHIR / interface roles",
            "headline": "Your new analyst productive in week two",
            "ad_text": "The hop is already in the job title. Offer the engine plus one owner — or sit beside the person they hire. Not “don’t hire anyone.”",
            "place": "LinkedIn: “HL7 Analyst”, “EDI Engineer”, “Interface Manager” job posters",
            "keywords": ["HL7 analyst hire", "EDI engineer", "FHIR engineer", "interface analyst"],
        },
        "stuck": {
            "title": "Stuck-on-the-engine ads",
            "channel": "Reddit + LinkedIn",
            "audience": "Analysts who already wish Mirth / Rhapsody / Cloverleaf were better",
            "headline": "The hop you hate is easier to move than you think",
            "ad_text": "Lead with mapping, test, and exceptions — not rip-and-replace. One graphical route plus eiTestBed is the alternative they think does not exist.",
            "place": "r/healthIT, r/hl7, r/EDI sponsored or native · LinkedIn interface analysts",
            "keywords": ["Mirth mapping pain", "HL7 engine alternative", "interface exceptions"],
        },
        "expand": {
            "title": "Current-client expansion (not ads — outreach)",
            "channel": "Direct + one-pager",
            "audience": extra.get("client_names") or "Med Rec, CRL Plus",
            "headline": "The next hop at a shop that already trusts the engine",
            "ad_text": "Match this week’s theme to a feed they still do by hand. Warm trust, faster SOW. Ads do not beat a named next interface.",
            "place": "Account email + Sandbox recording, not paid media",
            "keywords": [],
        },
    }.get(lid)
    if not pack:
        return None
    return {
        "id": f"lane-{lid}",
        "kind": "lane",
        "rank": 20 + n,
        "why": f"{n} live signal{'s' if n != 1 else ''} in this lane this week.",
        "offer": "A Sandbox route for the named hop",
        "samples": lane.get("samples") or [],
        **pack,
    }


def _system_ad(systems: list[dict[str, Any]]) -> dict[str, Any] | None:
    engines = [s for s in systems if s.get("kind") == "engine"]
    if not engines:
        return None
    names = ", ".join(s["name"] for s in engines[:3])
    n = sum(int(s.get("count") or 0) for s in engines)
    return {
        "id": "displace-engine",
        "kind": "displace",
        "rank": n,
        "title": f"Displace ads against {names}",
        "why": f"{n} mentions of engines already in play. They named the stack. Talk to the hop, not “an engine.”",
        "audience": f"Shops running {names}",
        "channel": "Google Search + LinkedIn",
        "headline": f"Still on {engines[0]['name']}? Move one hated hop first",
        "ad_text": f"The feed keeps naming {names}. Do not sell a rip-and-replace. Prove ADT, 837, or FHIR on PilotFish beside what they already run.",
        "offer": "Side-by-side cutover of one live feed",
        "keywords": [f"{s['name']} alternative" for s in engines[:3]],
        "place": "Search: “[engine] alternative” · LinkedIn retarget interface titles",
        "samples": (engines[0].get("samples") or [])[:2],
    }


def _hire_company_ad(hiring: list[dict[str, Any]]) -> dict[str, Any] | None:
    named = [c for c in hiring if c.get("company")]
    if not named:
        return None
    names = ", ".join(c["company"] for c in named[:4])
    hops = []
    for c in named:
        for h in c.get("hops") or []:
            if h not in hops:
                hops.append(h)
    return {
        "id": "hire-accounts",
        "kind": "account",
        "rank": sum(int(c.get("count") or 0) for c in named),
        "title": "Account ads at companies hiring the hop",
        "why": f"{len(named)} named companies are staffing integration right now: {names}.",
        "audience": f"Hiring managers at {names}",
        "channel": "LinkedIn account lists (manual — we do not scrape LinkedIn)",
        "headline": "The hop is in the job title. The engine can sit beside the hire.",
        "ad_text": (
            f"They budgeted {hops[0] if hops else 'the interface'}. "
            "Offer a Sandbox route so the person they hire is productive in week two — or so one owner can run it."
        ),
        "offer": "Named-hop Sandbox demo for that company",
        "keywords": hops[:4],
        "place": "Upload the company list. Target Integration / EDI / Interface titles at those accounts.",
        "samples": [{"id": s.get("id"), "title": s.get("title")} for c in named[:3] for s in (c.get("samples") or [])][:3],
        "accounts": [c["company"] for c in named[:6]],
    }


def build_marketing(store: Any, cfg: dict[str, Any]) -> dict[str, Any]:
    brief = build_briefing(store, cfg)
    ideas: list[dict[str, Any]] = []
    for i, theme in enumerate((brief.get("demand") or [])[:5]):
        if theme.get("count"):
            ideas.append(_theme_ad(theme, 80 - i * 5))
    extra = {
        "expansions": brief.get("expansions") or [],
        "client_names": ", ".join(e["name"] for e in (brief.get("expansions") or [])),
    }
    for lane in brief.get("live_lanes") or []:
        ad = _lane_ad(lane, extra)
        if ad:
            ideas.append(ad)
    sys_ad = _system_ad(brief.get("systems_in_use") or [])
    if sys_ad:
        ideas.append(sys_ad)
    hire_ad = _hire_company_ad(brief.get("hiring_companies") or [])
    if hire_ad:
        ideas.append(hire_ad)

    ideas.sort(key=lambda r: -int(r.get("rank") or 0))
    for idea in ideas:
        _attach_do_links(idea)
    first = []
    for kind in ("search", "lane", "account"):
        pick = next((i for i in ideas if i["kind"] == kind), None)
        if pick:
            first.append(pick)
    channels = {}
    for idea in ideas:
        ch = idea.get("channel") or ""
        channels[ch] = channels.get(ch, 0) + 1
    return {
        "ideas": ideas,
        "first": first,
        "idea_count": len(ideas),
        "top_theme": brief.get("top_theme") or "",
        "active_count": brief.get("active_count") or 0,
        "hire_count": len(brief.get("hiring_companies") or []),
        "top_channel": max(channels, key=channels.get) if channels else "Google Search",
    }


def _g(q: str) -> str:
    return "https://www.google.com/search?" + urllib.parse.urlencode({"q": q})


def _li_all(q: str) -> str:
    return "https://www.linkedin.com/search/results/all/?" + urllib.parse.urlencode({"keywords": q})


def _li_jobs(q: str) -> str:
    return "https://www.linkedin.com/jobs/search/?" + urllib.parse.urlencode({"keywords": q})


def _attach_do_links(ad: dict[str, Any]) -> None:
    links: list[dict[str, str]] = []
    for kw in (ad.get("keywords") or [])[:4]:
        links.append({"label": f"Google “{kw}”", "href": _g(kw)})
    if ad.get("kind") in {"search", "lane", "displace"} and ad.get("keywords"):
        links.append({"label": "Google Ads", "href": "https://ads.google.com/"})
        links.append({"label": "Keyword Planner", "href": "https://ads.google.com/aw/keywordplanner"})
    ch = ad.get("channel") or ""
    if "LinkedIn" in ch:
        links.append({"label": "LinkedIn Campaign Manager", "href": "https://www.linkedin.com/campaignmanager/"})
        if ad.get("id") == "lane-mandate" or "mandate" in (ad.get("title") or "").lower():
            for name, href in TRADE[:3]:
                links.append({"label": name, "href": href})
        if ad.get("id") == "lane-hire":
            links.append({"label": "LinkedIn jobs: HL7 analyst", "href": _li_jobs("HL7 analyst")})
            links.append({"label": "LinkedIn jobs: EDI engineer", "href": _li_jobs("EDI engineer")})
    if ad.get("kind") == "account":
        for name in ad.get("accounts") or []:
            links.append({"label": f"LinkedIn: {name}", "href": _li_all(name)})
            links.append({"label": f"Google: {name}", "href": _g(name)})
        links.append({"label": "Companies tab", "href": "/companies"})
    if ad.get("id") == "lane-stuck":
        links.append({"label": "r/healthIT", "href": "https://www.reddit.com/r/healthIT/"})
        links.append({"label": "r/HL7", "href": "https://www.reddit.com/r/HL7/"})
    ad["do_links"] = links
