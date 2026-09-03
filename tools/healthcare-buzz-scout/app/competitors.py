"""Who we actually compete with — engines, SI shops, and SERP names."""

from __future__ import annotations

from typing import Any

# Public, sell-against facts. Not purchased TAM.
PROFILES = [
    {
        "id": "pilotfish",
        "name": "PilotFish",
        "kind": "us",
        "since": "2001",
        "hq": "Middletown, CT",
        "site": "https://healthcare.pilotfishtechnology.com",
        "aliases": ["pilotfish", "pilotfishtechnology.com"],
        "what": "One graphical engine for healthcare and insurance. Routes in eiConsole, run on eiPlatform, test in eiTestBed.",
        "does": "HL7 v2/MLLP, X12 (837/835/834/270/271/278, SNIP), FHIR, ACORD TxLife, SQL, files. People who live in the payload.",
        "known": "Sandbox already speaks the hops we sell. Med Rec ADT/DFT, CRL Plus life/status, EDI 837/835/999 demos.",
        "vs_us": "Us. Lead with the named hop, not “another engine.”",
    },
    {
        "id": "mirth",
        "name": "Mirth / NextGen Connect",
        "kind": "engine",
        "since": "2006",
        "hq": "NextGen (acquired 2016)",
        "site": "https://www.nextgen.com/solutions/interoperability/mirth-connect",
        "aliases": ["mirth / nextgen", "mirth", "nextgen connect"],
        "what": "The default hospital interface engine. Open-source roots, huge installed base, cheap to start, expensive to staff.",
        "does": "HL7 channels, JavaScript filters/transformers, FHIR add-ons, community + paid NextGen support.",
        "known": "Sunset and “mapping pain” talk. Shops hire Mirth analysts instead of buying a better engine. Wi4 and Taction implement on it.",
        "vs_us": "Do not bake-off features. Take one hated hop (ADT exceptions, 837, test) and sit beside the book.",
    },
    {
        "id": "rhapsody",
        "name": "Rhapsody",
        "kind": "engine",
        "since": "1997",
        "hq": "Boston — Orion → Lyniate (2019) → Rhapsody again",
        "site": "https://rhapsody.health/solutions/rhapsody",
        "aliases": ["rhapsody / lyniate", "rhapsody", "lyniate"],
        "what": "Enterprise engine in large health systems. Sticky license, Best-in-KLAS history, now the Rhapsody + Corepoint family.",
        "does": "HL7, FHIR, APIs, high-volume routing. Corepoint still sold beside it for mid-market GUI shops.",
        "known": "Shows up on “HL7 interface engine” search with us. License fear and hard-to-staff talk. We do not rip it out.",
        "vs_us": "Cut one live feed beside it. The rest of the book follows. Never lead with rip-and-replace.",
    },
    {
        "id": "cloverleaf",
        "name": "Cloverleaf / Infor",
        "kind": "engine",
        "since": "1990s",
        "hq": "Infor (HCI → Quovadx → Lawson → Infor)",
        "site": "https://www.infor.com/products/cloverleaf",
        "aliases": ["cloverleaf / infor", "cloverleaf"],
        "what": "Older hospital engine. Still running a lot of ADT/ORU books. Sunset and staffing are the open door.",
        "does": "HL7 v2 at scale, Infor stack. Talent is aging out.",
        "known": "Date-driven cutovers. Every interface they already run is the book we can take hop by hop.",
        "vs_us": "Same motion as Rhapsody: one feed before support ends, not a platform war.",
    },
    {
        "id": "corepoint",
        "name": "Corepoint",
        "kind": "engine",
        "since": "2009",
        "hq": "Now under Rhapsody / Lyniate",
        "site": "https://rhapsody.health",
        "aliases": ["corepoint"],
        "what": "GUI-first mid-market engine. Merged with Rhapsody in 2019; still a named install in a lot of hospitals.",
        "does": "HL7 mapping with less code than Mirth. Same parent as Rhapsody.",
        "known": "Smaller conversation than Mirth. Shows up when people want “easier than Rhapsody.”",
        "vs_us": "One live hop. We also cover X12 and TxLife they usually do not lead with.",
    },
    {
        "id": "intersystems",
        "name": "InterSystems HealthShare / Ensemble",
        "kind": "engine",
        "since": "1978",
        "hq": "Cambridge, MA",
        "site": "https://www.intersystems.com/products/healthshare/",
        "aliases": ["intersystems", "healthshare", "ensemble"],
        "what": "Database + interoperability suite. Ensemble/HealthShare shops bought a platform, not just an engine.",
        "does": "HL7, FHIR, HIE, IRIS data platform. Deep in IDNs and public HIE.",
        "known": "We do not replace IRIS. We take a feed they have not stood up or that is stuck in Ensemble.",
        "vs_us": "Sit on the edge. Named hop, not “leave InterSystems.”",
    },
    {
        "id": "qvera",
        "name": "Qvera (QIE)",
        "kind": "engine",
        "since": "2008",
        "hq": "Kaysville, UT (roots in 1997 MedShape)",
        "site": "https://www.qvera.com",
        "aliases": ["qvera"],
        "what": "Graphical HL7/FHIR engine aimed at hospitals that want less code than Mirth. ~1,000 orgs claimed.",
        "does": "QIE: HL7, CDA, FHIR, on-prem and cloud. Actively pitching Iguana refugees.",
        "known": "Closest “looks like us” healthcare-only GUI engine. Thin on hard X12 / life STP versus what we ship.",
        "vs_us": "We are the dual-industry engine. Beat them on 837/SNIP, TxLife, and one owner plus Sandbox proof.",
    },
    {
        "id": "iguana",
        "name": "Iguana / iNTERFACEWARE",
        "kind": "engine",
        "since": "1997",
        "hq": "Toronto",
        "site": "https://www.interfaceware.com",
        "aliases": ["iguana", "interfaceware"],
        "what": "Lua-scripted engine popular with vendors embedding interfaces. Recent licensing noise has shops shopping.",
        "does": "Iguana: HL7, FHIR, custom scripts. Sold to OEM/device and hospital teams.",
        "known": "Qvera and others are running migration plays. Sunset-shaped, even when the product still works.",
        "vs_us": "Date + hated hop. Graphical route plus eiTestBed is the alternative they think does not exist.",
    },
    {
        "id": "dhit",
        "name": "Dynamic Health IT",
        "kind": "engine",
        "since": "1999",
        "hq": "New Orleans, LA",
        "site": "https://dynamichealthit.com/software/tie/",
        "aliases": ["dynamic health it"],
        "what": "ONC-cert and quality-measure shop. TIE (ex-HL7Connect) is their HL7/CDA engine — ranked next to us on “HL7 interface engine.”",
        "does": "TIE, CQMsolution, ConnectEHR, FHIR API, MIPS registry. CQM and C-CDA more than claims EDI.",
        "known": "Real product competitor on the SERP. Small team, deep CQM. Not the X12/life engine.",
        "vs_us": "They win quality reporting. We win the hop: ADT, 837, SNIP, TxLife, one owner.",
    },
    {
        "id": "soup",
        "name": "Integration Soup / HL7 Soup",
        "kind": "engine",
        "since": "~2015",
        "hq": "HL7 Soup / Integration Host (Jason Bolstad)",
        "site": "https://www.integrationsoup.com",
        "aliases": ["integration soup", "integrationsoup.com"],
        "what": "Analyst-friendly HL7 editor plus a lightweight host. People find it when they search the category.",
        "does": "HL7 Soup editor (English readout of messages), Integration Host/Soup for HL7/FHIR/JSON/CSV, Azure/AWS extensions.",
        "known": "Ranks above us on “HL7 interface engine.” Strong as a viewer; not the enterprise + insurance book.",
        "vs_us": "They teach the message. We run the production route and the X12/TxLife they do not own.",
    },
    {
        "id": "folio3",
        "name": "Folio3 / Decode Health",
        "kind": "services",
        "since": "2005",
        "hq": "Folio3 Digital Health (Decode Health engine + SI)",
        "site": "https://digitalhealth.folio3.com",
        "aliases": ["folio3 / decode health", "folio3.com", "digitalhealth.folio3.com"],
        "what": "Software house that ranks #1 on “HL7 interface engine” by publishing listicles and selling Decode Health + Epic/FHIR services.",
        "does": "Decode Health (HL7/FHIR routing), Epic integration, custom build, managed ops. They put themselves on their own “best engines” pages.",
        "known": "SEO competitor more than installed-base. They name Rhapsody, Mirth, Cloverleaf, InterSystems — not us.",
        "vs_us": "Publish a hop page they cannot outrank with a listicle. We are the product; they are a services wrap.",
    },
    {
        "id": "wi4",
        "name": "Wi4",
        "kind": "services",
        "since": "2010s",
        "hq": "US — 501(c)(3) health-tech shop",
        "site": "https://wi4.ai",
        "aliases": ["wi4", "wi4.ai"],
        "what": "Nonprofit custom-dev shop. They implement Mirth; they do not sell an engine of their own.",
        "does": "Mirth channels, HL7/FHIR/X12 services, healthcare apps. Content ranks for interface-engine queries.",
        "known": "On the SERP with us. Their pitch is “hire us to work Mirth,” which is the hire-the-hop lane.",
        "vs_us": "Offer the engine plus one owner — or sit beside the person they would staff on Mirth.",
    },
    {
        "id": "taction",
        "name": "Taction Software",
        "kind": "services",
        "since": "2013",
        "hq": "US healthcare SI (they cite 20 years / 785+ builds)",
        "site": "https://www.tactionsoft.com",
        "aliases": ["taction software", "tactionsoft.com"],
        "what": "HIPAA/FHIR/Mirth body shop. Ranks on the same page because they write “HL7 integration services” pages.",
        "does": "Mirth, Rhapsody, Cloverleaf implementations; FHIR R4/SMART; Epic/Cerner connectors. Not their own engine.",
        "known": "Services competitor for the same budget as “hire an interface analyst.”",
        "vs_us": "Sandbox route vs a team of Mirth contractors. We still partner when they need an engine under the services.",
    },
    {
        "id": "majware",
        "name": "Majware",
        "kind": "content",
        "since": "—",
        "hq": "Knowledge hub + HL7/DICOM tools",
        "site": "https://majware.com",
        "aliases": ["majware", "majware.com"],
        "what": "Practitioner guides and an HL7 viewer. Not an interface engine. They rank because they write “interface engine” articles.",
        "does": "Guides, message viewer/validator, PACS/DICOM notes. They name Mirth, Rhapsody, Ensemble, Iguana, Cloverleaf — not us.",
        "known": "SERP neighbor, not a displace target.",
        "vs_us": "Get a crawlable hop page so engineers land on us, not a blog that lists everyone else.",
    },
    {
        "id": "hitskills",
        "name": "Healthcare IT Skills",
        "kind": "content",
        "since": "—",
        "hq": "Training / career site",
        "site": "https://healthcareitskills.com",
        "aliases": ["healthcare it skills", "healthcareitskills.com"],
        "what": "Jobs and training content that ranks for “HL7 interface engine.” Not a product.",
        "does": "Courses, career pages. Feeds the “hire an analyst” motion.",
        "known": "Same SERP as us. The buyer who lands here is staffing the hop.",
        "vs_us": "Account ads at shops posting those jobs. Engine plus one owner, not another course.",
    },
]

KIND_LABEL = {
    "us": "Us",
    "engine": "Interface engine",
    "services": "Services / SI (they implement engines)",
    "content": "Ranks on the page — not a product",
}

_ALIAS = {}
for _p in PROFILES:
    _ALIAS[_p["name"].lower()] = _p
    for _a in _p.get("aliases") or []:
        _ALIAS[_a.lower()] = _p


def resolve(name: str) -> dict[str, Any] | None:
    key = (name or "").strip().lower()
    if key in _ALIAS:
        return _ALIAS[key]
    for alias, prof in _ALIAS.items():
        if alias and alias in key:
            return prof
    return None


def build_competition(search: dict[str, Any], mentions: list[dict[str, Any]]) -> dict[str, Any]:
    mention_n = {r["name"]: int(r.get("count") or 0) for r in mentions}
    search_n: dict[str, int] = {}
    queries_for: dict[str, list[str]] = {}
    for rec in search.get("queries") or []:
        for player in rec.get("players") or []:
            prof = resolve(player)
            label = prof["name"] if prof else player
            search_n[label] = search_n.get(label, 0) + 1
            q = rec.get("query") or ""
            if q and q not in queries_for.setdefault(label, []):
                queries_for[label].append(q)
    ranked = search.get("ranked") or []
    for r in ranked:
        prof = resolve(r.get("name") or "")
        label = prof["name"] if prof else r.get("name")
        if label:
            search_n[label] = max(search_n.get(label, 0), int(r.get("count") or 0))

    cards = []
    seen = set()
    for prof in PROFILES:
        seen.add(prof["id"])
        buzz = 0
        for mname, n in mention_n.items():
            if resolve(mname) and resolve(mname)["id"] == prof["id"]:
                buzz += n
        cards.append(
            {
                **prof,
                "kind_label": KIND_LABEL.get(prof["kind"], prof["kind"]),
                "search_hits": search_n.get(prof["name"], 0),
                "buzz": buzz,
                "on_queries": queries_for.get(prof["name"], [])[:6],
            }
        )
    cards.sort(
        key=lambda r: (
            0 if r["kind"] == "us" else 1 if r["kind"] == "engine" else 2 if r["kind"] == "services" else 3,
            -int(r.get("search_hits") or 0),
            -int(r.get("buzz") or 0),
            r["name"],
        )
    )
    share = [q for q in (search.get("queries") or []) if q.get("us_rank")]
    return {
        "competitors": cards,
        "search_share": share,
        "engine_n": sum(1 for c in cards if c["kind"] == "engine"),
        "search_n": len(share),
    }
