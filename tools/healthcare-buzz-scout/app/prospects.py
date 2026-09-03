"""Who a prospect is, what they do, and why they might need PilotFish."""

from __future__ import annotations

import re
from typing import Any

# Sell-against notes for named buyers. Fallback covers everyone else.
PROFILES = {
    "itiliti-health": {
        "who": "Eden Prairie prior-auth software shop (2019). Sells PA Checkpoint, Auto Auth, and policy digitization to health plans, TPAs, and Medicaid.",
        "does": "Turns medical policy into machine-readable rules and APIs for CMS-0057 (CRD / DTR / PAS). They are a PA product, not an interface engine.",
        "why": "Their whole product is the 278 / FHIR prior-auth hop. They need a real engine under the APIs — 270/271/278, FHIR PAS, exceptions — not another hire to wire every payer.",
        "site": "https://itilitihealth.com",
    },
    "elevance-health": {
        "who": "Anthem renamed. One of the largest US payers (commercial, Medicaid, Medicare). Da Vinci / FHIR community champion.",
        "does": "Claims, eligibility, prior auth, and provider data at national scale. Heavy X12 plus a FHIR mandate stack.",
        "why": "Hard EDI and FHIR at once. SNIP, companion guides, 270/271/278, and Da Vinci hops are the door — one route, not another clearinghouse project.",
        "site": "https://www.elevancehealth.com",
    },
    "cook-county-hospital": {
        "who": "Cook County Health — Chicago’s public safety-net system (Stroger and the county clinics).",
        "does": "High-volume ADT/ORU, Epic or peer EHR, labs, and public-health reporting. Budget and staffing are always tight.",
        "why": "HL7 and EHR-edge hops they cannot staff. Offer one ADT or lab route plus an owner, not a new interface team.",
        "site": "https://cookcountyhealth.org",
    },
    "denver-health": {
        "who": "Denver’s integrated safety-net system. Academic, Epic shop, live on Epic’s Coverage Requirements Discovery (prior auth) API.",
        "does": "Hospital + clinics + health plan pieces. Eligibility and prior-auth automation sitting on Epic.",
        "why": "The hop is 270/271/278 and FHIR CRD beside Epic — we sit on the edge, we do not replace the EHR.",
        "site": "https://www.denverhealth.org",
    },
    "ochsner-health": {
        "who": "Louisiana’s largest health system. Epic reference site; in the first wave of Epic real-time prior-auth / CRD.",
        "does": "Hospitals, clinics, and a lot of payer-facing traffic. They publish and adopt Epic interop features early.",
        "why": "Prior-auth and EHR-edge feeds (ADT, 278, FHIR). Same motion as Denver Health: one live hop beside Epic.",
        "site": "https://www.ochsner.org",
    },
    "thedacare": {
        "who": "Northeast Wisconsin health system. Also in Epic’s first instant prior-auth / CRD cohort.",
        "does": "Community hospitals and clinics on Epic. Smaller than Ochsner; same mandate pressure.",
        "why": "Eligibility / prior-auth hop with a deadline. Graphical 270/271/278 plus FHIR if they outgrow the Epic-only path.",
        "site": "https://thedacare.org",
    },
    "summit-health": {
        "who": "Large multi-specialty / VillageMD-aligned ambulatory group (Summit Health–CityMD and related brands).",
        "does": "High-volume outpatient. Epic prior-auth / CRD news tagged them with the other systems.",
        "why": "Clinic-scale eligibility and auth — 270/271/278 or FHIR PAS — without standing up a hospital interface shop.",
        "site": "https://www.summithealth.com",
    },
    "billiontoone": {
        "who": "Menlo Park molecular diagnostics (NASDAQ: BLLN). UNITY prenatal NIPT and Northstar liquid biopsy. Hiring an EMR Integration Specialist.",
        "does": "Lab orders and results into Epic Aura, athena, eClinicalWorks, OncoEMR. That is ORM/ORU and EHR mapping, not a science problem.",
        "why": "They budgeted the hop. Offer a Sandbox EMR/lab route so the person they hire is productive in week two — or so one owner can run it.",
        "site": "https://billiontoone.com",
    },
    "cadwell": {
        "who": "Kennewick, WA neurodiagnostics manufacturer (EEG, EMG, IONM). CadLink already speaks HL7 ADT/ORM into hospital EMRs. Hiring an HL7 Analyst.",
        "does": "Device + CadLink server to HIS/EMR. Bi-directional HL7 is the product edge, not the device.",
        "why": "Every new hospital is another ADT/ORM map. eiConsole plus eiTestBed is faster than staffing another HL7 analyst for each site.",
        "site": "https://www.cadwell.com",
    },
    "bellese": {
        "who": "Civic healthcare digital-services shop. They run CMS Hospital Quality Reporting and hire FHIR engineers (HAPI, Measure/MeasureReport, US Core).",
        "does": "QRDA / C-CDA / FHIR quality measures for thousands of hospitals submitting to CMS. They implement; they do not sell an engine.",
        "why": "FHIR measure and hospital-submit hops. PilotFish can sit under those APIs so they are not hand-wiring every MeasureReport.",
        "site": "https://bellese.io",
    },
    "penumbra": {
        "who": "Alameda medical-device company (stroke and vascular). Public. Hiring an EDI Analyst for hospital trading partners, GHX preferred.",
        "does": "Sells devices into hospitals. The hop is purchase-order / invoice / 837-style EDI with IDNs, not the catheter.",
        "why": "They are staffing EDI because GHX and hospital portals hurt. A real X12 route plus one owner beats another analyst on exceptions.",
        "site": "https://www.penumbrainc.com",
    },
    "kaiser-permanente": {
        "who": "The integrated giant — plan + hospitals + Epic. They build a lot in-house and still leak EHR and privacy-config pain in public threads.",
        "does": "ADT, claims, and FHIR at a scale most vendors never see. Hard to get in; when a hop is stuck, the pain is loud.",
        "why": "EHR-edge and inter-facility hops they will not staff on the core Epic team. Named proof only — one feed, not a rip.",
        "site": "https://www.kaiserpermanente.org",
    },
    "abl-life-insurance": {
        "who": "Korean life carrier, now under Woori Financial with Tongyang Life. Merger aimed at 2H 2027 (~₩55T combined).",
        "does": "Life products, distribution, and a systems mash-up while two books become one. News tagged our ACORD / TxLife theme.",
        "why": "Carrier–carrier integration is STP: new business, status, and vendor feeds. If they (or a US/partner book) need ACORD 121/1122, that is our hop. Weak if they stay Korea-only admin.",
        "site": "https://www.abllife.co.kr",
    },
    "manulife": {
        "who": "Canadian / Asian life and wealth giant (John Hancock in the US). In the news for faster Canada life approvals with AI.",
        "does": "New business, underwriting, and a lot of still-manual or vendor eApp / TxLife around the core.",
        "why": "Life STP is the product. ACORD 121/1122, status, and attachments beside the admin system — we are the hop, not the policy admin.",
        "site": "https://www.manulife.com",
    },
    "cigna": {
        "who": "Global payer (The Cigna Group). Claims, behavioral, and employer books. In the news on addiction-claim disputes.",
        "does": "837/835 at scale, plus 270/271/278. Companion-guide and SNIP pain is structural.",
        "why": "Hard EDI. Show SNIP and the live 837/835 — generalist engines bounce, we have people who live in X12.",
        "site": "https://www.cigna.com",
    },
    "aetna": {
        "who": "CVS Health’s payer. Commercial and Medicare. Showing up on CMS-0057 / prior-auth implementation talk.",
        "does": "Eligibility, auth, and claims. Mandate dates, not optional FHIR science projects.",
        "why": "CMS-0057 is 278 + FHIR PAS with a deadline. Same motion as COVID reporting: spec, date, payload.",
        "site": "https://www.aetna.com",
    },
    "unitedhealth": {
        "who": "Largest US payer / Optum parent. Plan plus a huge services and clearinghouse gravity well.",
        "does": "Claims, eligibility, and Optum interop. They are both a buyer and a stack we sit beside.",
        "why": "Hops Optum does not own — a named 837, 270, or FHIR feed — not a fight with the network.",
        "site": "https://www.unitedhealthgroup.com",
    },
    "humana": {
        "who": "Major Medicare-weighted payer.",
        "does": "MA claims, eligibility, and prior auth. Mandate and EDI volume.",
        "why": "270/271/278 and 837/835 with CMS dates. One Sandbox route for the named transaction.",
        "site": "https://www.humana.com",
    },
    "hca-healthcare": {
        "who": "Largest US hospital operator.",
        "does": "Massive ADT/ORU book, Epic/Meditech mix by division, lab and payer edges.",
        "why": "Do not pitch a rip. One hated interface at one division — then the book.",
        "site": "https://hcahealthcare.com",
    },
    "ascension": {
        "who": "Large Catholic health system.",
        "does": "Multi-state hospitals, EHR variance, shared services for interfaces.",
        "why": "Sunset or stuck engine at a region. One ADT or 837 hop with a local owner.",
        "site": "https://www.ascension.org",
    },
    "mayo-clinic": {
        "who": "Destination academic system (Rochester, Arizona, Florida).",
        "does": "Epic, research, and a lot of outside-lab / referring-facility traffic.",
        "why": "Edge hops (lab, referring ADT, FHIR) that the core Epic team will not pick up.",
        "site": "https://www.mayoclinic.org",
    },
    "cleveland-clinic": {
        "who": "Academic IDN, national and international footprint.",
        "does": "Epic plus specialty and affiliate feeds.",
        "why": "Same as Mayo: the hop on the edge, proven in Sandbox, not a platform bake-off.",
        "site": "https://my.clevelandclinic.org",
    },
}

WHY_BY_HOP = (
    ("SNIP", "Hard EDI — SNIP and companion guides. Generalist engines bounce; we live in X12."),
    ("837", "Claims / remits. Show the live 837/835 and park exceptions."),
    ("270", "Eligibility / prior auth. 270/271/278 or FHIR PAS with a date."),
    ("278", "Prior auth. Same motion as a mandate: spec, date, payload."),
    ("prior auth", "Prior auth. Same motion as a mandate: spec, date, payload."),
    ("HL7", "ADT/ORU/MLLP. One graphical route beside the EHR, not another analyst."),
    ("ADT", "ADT/ORU/MLLP. One graphical route beside the EHR, not another analyst."),
    ("FHIR", "FHIR / SMART / Bulk. We already speak it; they are staffing or buying the hop."),
    ("EHR", "EHR/EMR edge. Sit beside Epic/Cerner — orders, results, ADT — do not replace the chart."),
    ("ACORD", "Life STP. ACORD 121/1122 and status beside the admin system."),
    ("TxLife", "Life STP. ACORD 121/1122 and status beside the admin system."),
)


def _slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", (name or "").lower()).strip("-")[:80]


def _why_from_hops(hops: list[str], reasons: list[str], market: str) -> str:
    blob = " ".join(hops)
    for needle, text in WHY_BY_HOP:
        if needle.lower() in blob.lower():
            base = text
            break
    else:
        base = "A named integration hop showed up in the last two years of buzz."
    hiring = any("hiring" in (r or "").lower() or r == "Hiring an integration person" for r in reasons)
    if hiring:
        return f"{base} They are hiring the person. Offer the engine plus one owner — or sit beside the hire."
    if market == "insurance":
        return f"{base} Insurance core stays; we take the hop."
    return base


def attach_rundown(company: dict[str, Any]) -> dict[str, Any]:
    slug = company.get("id") or _slug(company.get("name") or "")
    hops = list(company.get("hops") or [])
    reasons = list(company.get("reasons") or [])
    market = company.get("market") or "healthcare"
    prof = PROFILES.get(slug)
    if prof:
        company["who"] = prof["who"]
        company["does"] = prof["does"]
        company["why_pf"] = prof["why"]
        company["site"] = prof.get("site") or ""
    else:
        kind = "healthcare organization" if market != "insurance" else "insurance organization"
        if any("hiring" in (r or "").lower() or "Hiring" in (r or "") for r in reasons):
            kind = f"{market} shop staffing an integration role"
        company["who"] = f"{company.get('name') or 'This company'} is a {kind} that landed on this list from the last two years of signals."
        company["does"] = (
            f"Hops in the feed: {', '.join(hops)}." if hops else "The feed named them but did not spell a hop yet."
        )
        company["why_pf"] = _why_from_hops(hops, reasons, market)
        company["site"] = ""
    return company
