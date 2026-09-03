"""IRL Expanse G3: Lake Monroe / Osceola / Poinciana / Oviedo facility onboarding."""

from __future__ import annotations

import re
from pathlib import Path

from client_dive import _replace_ed

A04 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate ADT A04 HL7/transform.xslt"
)
ROUTE1 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/1 - Incoming Flat Files by Partition and Client/route.xml"
)
ADD_FAC = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/88a - Add New Facility/route.xml"
)

IRL_SW = "('517','514','515','516','518','519','520','521','522','523')"
IRL_SW_NEW = "('517','514','515','516','518','519','520','521','522','523','525','526','527','528')"
PV1_8 = (
    "$partitionName = 'IRL' and $facilityName = ('LAM','PUX','MAX','NFX','OCX','DEX','MIX',"
    "'NXX','OMC','OXX','SUN','JFX','PWX','LWX','COX','CAX','GUX','GAN','TWX','WAX','WFX',"
    "'GUP','GUQ','DEV','DEW','PES','WFP','WFQ')"
)
PV1_8_NEW = PV1_8[:-1] + (
    ",'CEX','CET','CER','CES','OSX','OXE','OXF','OXG','POX','POL','POM','OVX','OVH','OVJ','OVK')"
)
CDM_GAN = (
    "getAttribute('ClientName') == 'CAT' || getAttribute('ClientName') == 'GAN' || "
    "getAttribute('ClientName') == 'TWX'"
)
CDM_ADD = (
    "getAttribute('ClientName') == 'CAT' || getAttribute('ClientName') == 'GAN' || "
    "getAttribute('ClientName') == 'CEX' || getAttribute('ClientName') == 'OSX' || "
    "getAttribute('ClientName') == 'POX' || getAttribute('ClientName') == 'OVX' || "
    "getAttribute('ClientName') == 'TWX'"
)
LEGACY_GAN = (
    "getAttribute('ClientName') != 'CAT' &amp;&amp; getAttribute('ClientName') != 'GAN' "
    "&amp;&amp; getAttribute('ClientName') != 'WAX'"
)
LEGACY_ADD = (
    "getAttribute('ClientName') != 'CAT' &amp;&amp; getAttribute('ClientName') != 'GAN' "
    "&amp;&amp; getAttribute('ClientName') != 'CEX' &amp;&amp; getAttribute('ClientName') != 'OSX' "
    "&amp;&amp; getAttribute('ClientName') != 'POX' &amp;&amp; getAttribute('ClientName') != 'OVX' "
    "&amp;&amp; getAttribute('ClientName') != 'WAX'"
)
ROUTE2 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/route.xml"
)
STRIP_GAN = (
    "getAttribute('PartitionName') == 'IRL' &amp;&amp; getAttribute('ClientName') == 'GAN'"
)
STRIP_ADD = (
    STRIP_GAN
    + " || (getAttribute('PartitionName') == 'IRL' &amp;&amp; getAttribute('ClientName') == 'CEX')"
    + " || (getAttribute('PartitionName') == 'IRL' &amp;&amp; getAttribute('ClientName') == 'OSX')"
    + " || (getAttribute('PartitionName') == 'IRL' &amp;&amp; getAttribute('ClientName') == 'POX')"
    + " || (getAttribute('PartitionName') == 'IRL' &amp;&amp; getAttribute('ClientName') == 'OVX')"
)


def is_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if not re.search(r"IRL", blob, re.I):
        return False
    if not re.search(r"expanse", blob, re.I):
        return False
    if not re.search(r"new facilit", blob, re.I):
        return False
    return bool(re.search(r"Monroe|Osceola|Poinciana|Oviedo", blob, re.I))


def propose(root: Path) -> list[dict]:
    edits: list[dict] = []
    a04 = root / A04
    if a04.is_file():
        text = a04.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            A04,
            "Add IRL Expanse G3 software IDs to marital U and SE/CH/UN lists",
            "PID-16 default U and blank GT1.11 / IN1.17 SE/CH/UN already gate on IRL 514–523 plus CAT 524. "
            "Add 525 Osceola, 526 Poinciana, 527 Oviedo, and 528 Lake Monroe.",
            IRL_SW,
            IRL_SW_NEW,
            text,
        )
        if rec:
            rec["replace_all"] = True
            edits.append(rec)
        rec = _replace_ed(
            A04,
            "Add G3 facility codes to PV1-8 attending (NPI/name)",
            "PV1-8 attending from ATTENDINGDOCNPI/NAME uses the IRL facility-name list. "
            "Add the four hospitals and their ER split facilities.",
            PV1_8,
            PV1_8_NEW,
            text,
        )
        if rec:
            edits.append(rec)
    for rel, old, new, title, why in (
        (
            ROUTE1,
            CDM_GAN,
            CDM_ADD,
            "Allow CEX / OSX / POX / OVX on the expanded-CDM flat-file transform",
            "20R1 loads route.xml. Transform Flat File to XML-New-Expanse-Expanded-CDM is an allowlist.",
        ),
        (
            ROUTE1,
            LEGACY_GAN,
            LEGACY_ADD,
            "Keep CEX / OSX / POX / OVX off the legacy flat-file transform",
            "20R1 loads route.xml. The older raw-flat-file-specification.xml processor must not run for these clients.",
        ),
        (
            ROUTE2,
            STRIP_GAN,
            STRIP_ADD,
            "Apply PerfSite LC strip to the four new IRL hospital clients",
            "20R1 loads route.xml. Add CEX, OSX, POX, OVX to Apply Stripping Site Locations so LC charges kick out.",
        ),
    ):
        path = root / rel
        if not path.is_file():
            continue
        rec = _replace_ed(rel, title, why, old, new, path.read_text(encoding="utf-8", errors="replace"))
        if rec:
            edits.append(rec)
    return edits


def apply(dive: dict, root: Path, email: str, subject: str) -> dict:
    dive = dict(dive)
    dive["intent"] = "new_facility"
    dive["summary"] = (
        "Onboard four IRL Expanse G3 hospitals from the Sept 1 IRL N drop (XLSX + PTH5.COC* zips). "
        "Listeners are PTH5.COCCN / COCOS / COCPMA / COCOMC. Do not load CEX as software 524 — that ID is NHL CAT."
    )
    dive["ask"] = (
        "Add IRL Expanse facilities from Expanded expanse\\IRL\\IRL N: HCA Florida Lake Monroe "
        "(CEX + Casselberry/Heathrow/Mount Dora ERs), HCA FL Osceola (OSX + Hunters Creek/Millenia/"
        "Airport North), HCA FL Poinciana (POX + Champions/Haines), and Oviedo Medical Center "
        "(OVX + Baldwin/Alafaya/Maitland). Same Expanse programming list as GAN: strip LC, PID marital U, "
        "PV1-8 attending, admit/discharge rules, blank name/relationship defaults."
    )
    dive["codes"] = [
        "CEX", "CET", "CER", "CES",
        "OSX", "OXE", "OXF", "OXG",
        "POX", "POL", "POM",
        "OVX", "OVH", "OVJ", "OVK",
    ]
    dive["feed"] = {
        "partition": "IRL",
        "name": "IRL Expanse G3",
        "software_id": "525-528",
        "xslt": A04,
    }
    dive["files"] = [
        {
            "path": A04,
            "hits": [
                {"code": "PID.16", "line": 308, "text": "IRL marital default U — add 525–528"},
                {"code": "PV1.8", "line": 511, "text": "IRL attending facility list — add CEX/OSX/POX/OVX + ERs"},
                {"code": "GT1.11 / IN1.17", "line": 911, "text": "SE/CH/UN software list — add 525–528"},
            ],
        },
        {
            "path": ROUTE1,
            "hits": [
                {
                    "code": "GAN / GUX listeners",
                    "line": 2008,
                    "text": "Clone GAN; FileNameRestriction PTH5.COCCN.* / PTH5.COCOS.* / PTH5.COCPMA.* / PTH5.COCOMC.*",
                },
                {
                    "code": "CEX OSX POX OVX",
                    "line": 12479,
                    "text": "Expanded-CDM allowlist and legacy denylist on route.xml",
                },
            ],
        },
        {
            "path": ROUTE2,
            "hits": [{"code": "LC", "line": 408, "text": "PerfSite kickout apply-list on route.xml"}],
        },
        {
            "path": ADD_FAC,
            "hits": [
                {
                    "code": "88a",
                    "line": 8,
                    "text": "Load the four IRL N MedReceivables_NewFacilityInfo_IRL_{CEX,OSX,POX,OVX}.xlsx after changing CEX 524→528",
                }
            ],
        },
    ]
    dive["edits"] = propose(root)
    dive["build_plan"] = [
        {
            "title": "What this is",
            "paras": [
                "These are new Expanse software IDs for hospitals that already exist as older IRL feeds "
                "(Lake Monroe 175 CEN, Osceola 178 OSC, Poinciana 179 POI, Oviedo 241 OVI). "
                "Do not reuse those listeners or software IDs. Copy the IRL GAN / GUX expanded-CDM pattern.",
                "Drop folder: Clients/Med Rec/data/IRL Expanded Expanse - New Facilities - Sept1st2026/IRL N. "
                "Four 88a workbooks plus PTH5.COCCN / COCOS / COCPMA / COCOMC zips (four days each, 08071–08101). "
                "DATE_RANGE on every workbook row is 20260806.",
            ],
        },
        {
            "title": "Software IDs — change CEX workbook 524 → 528 before 88a",
            "paras": [
                "The CEX workbook still says SOFTWAREID 524. H2 already has 524 = NHL Catholic Medical (CAT), "
                "and 523 = GAN. CLIENT_CODES is keyed by SOFTWARE_ID — loading CEX as 524 would attach Monroe "
                "split codes to CAT. Change MedReceivables_NewFacilityInfo_IRL_CEX.xlsx to 528, then load.",
            ],
            "bullets": [
                "528 — CEX Lake Monroe. Workbook says 524; do not load that value.",
                "525 — OSX Osceola (workbook matches).",
                "526 — POX Poinciana (workbook matches).",
                "527 — OVX Oviedo (workbook matches).",
            ],
        },
        {
            "title": "CLIENT_SPLITS from the four XLSX files",
            "paras": [
                "FILE_HEADER_FACILITY_NAME is FacilityNameShouldBe, not a CLIENT_SPLITS column. "
                "Sample H records match the workbooks: HCA FL Lake Monroe, HCA FL Osceola, "
                "HCA FL Poinciana, HCA FL Oviedo Medical Center. IS_DEFAULT=1 on the hospital row.",
            ],
            "bullets": [
                "528 CEX — HCA Florida Lake Monroe Hospital (Central) / CEX / NA / CP20 / NA. "
                "ERs: CET Casselberry (PO), CER Heathrow (PH), CES Mount Dora (PI).",
                "525 OSX — HCA Florida Osceola Hospital / OSX / NB / CP27 / NB. "
                "ERs: OXE Hunters Creek (PB), OXF Millenia (PC), OXG Airport North (PE).",
                "526 POX — HCA Florida Poinciana Hospital / POX / NC / CP28 / NC. "
                "ERs: POL Champions (PF), POM Haines (PG).",
                "527 OVX — Oviedo Medical Center / OVX / NH / CP23 / NH. "
                "ERs: OVH Baldwin (NY), OVJ Alafaya (PP), OVK Maitland (PQ).",
            ],
        },
        {
            "title": "CLIENT_CODES from the workbooks (load as written)",
            "paras": [
                "Each workbook’s SPLIT_FACILITY / SPLIT_CODE / COMPARATOR columns are the 88a CLIENT_CODES rows. "
                "Hospital != the ER code; ER = the ER code. Two CEX/OVX IP codes are truncated to FSEDI in the sheet — load those strings, do not invent FSEDIP.",
            ],
            "bullets": [
                "CEX: XFC.FSED / XFC.FSEDIP, XFH.FSED / XFH.FSEDIP, XFMD.FSED / XFMD.FSEDI (CET, CER, CES).",
                "OSX: NHC.FSED / NHC.FSEDIP, NM.FSED / NM.FSEDIP, NAN.FSED / NAN.FSEDIP (OXE, OXF, OXG).",
                "POX: YCG.FSED / YCG.FSEDIP, YHC.FSED / YHC.FSEDIP (POL, POM).",
                "OVX: BOBP.FSED / BOBP.FSEDI, BOA.FSED / BOA.FSEDIP, BOM.FSED / BOM.FSEDIP (OVH, OVJ, OVK).",
                "88a FileNameRestriction is MedReceivables_NewFacilityInfo — these four filenames already match. Backup H2 first. Change CEX SOFTWAREID to 528 in the sheet before dropping.",
            ],
        },
        {
            "title": "Route 1 — four new pickups (names locked)",
            "paras": [
                "One DirectoryListener per hospital. ER facilities split from that file. Clone Pickup Flat Files – IRL – GAN "
                "(PTH5.GA.* / FacilityNameShouldBe HCA FL Gainesville Hospital).",
            ],
            "bullets": [
                "CEX: FileNameRestriction PTH5.COCCN.* — header HCA FL Lake Monroe (PTH5.COCCN.08101_V2.txt).",
                "OSX: FileNameRestriction PTH5.COCOS.* — header HCA FL Osceola. Do not use PTH5.COC.* or it will also eat COCCN / COCOMC / COCPMA.",
                "POX: FileNameRestriction PTH5.COCPMA.* — header HCA FL Poinciana.",
                "OVX: FileNameRestriction PTH5.COCOMC.* — header HCA FL Oviedo Medical Center.",
                "Set Facility Name + Set Partition and Client Name-IRL-{CEX,OSX,POX,OVX}. txt, CombineFiles=true, same $$FLAT_FILE_* dirs as GAN.",
                "Med Rec is 20R1: put OGNL and listeners on route.xml, not 26R1 modules/.",
            ],
        },
        {
            "title": "Route 2 / 3 and ADT rules from the email",
            "paras": [
                "Route 2 already reads all CLIENT_SPLITS. Route 3 splits on CLIENT_CODES once the DB rows exist. "
                "Most programming items already exist for IRL Expanse peers — extend the guard lists.",
            ],
            "bullets": [
                "PerfSite kickout — strip LC: add CEX/OSX/POX/OVX to Apply Stripping Site Locations (Start work). STRIP_PERFORMING_SITES already has LC globally.",
                "PID marital status default U: add 525–528 to the IRL software list (Start work).",
                "PV1-8 attending NPI/name: add the 15 facility codes to the IRL facility list (Start work).",
                "PV1-44 / PV1-45: inpatient sends admit and discharge today. Blank discharge is already OK. Blank admit still writes absAdmitdate (empty) unless charge date is earlier than admit on type I — verify on a G3 inpatient with a blank admit and, if needed, use first radExamServDate when admit is empty.",
                "PV2-28 ARSA follows the same admit / first-charge sourcing as PV1-44.",
                "Guarantor / subscriber name blank → patient: already global on ADT. No change expected.",
                "Blank relationship → SE (name equals patient), CH (≤17), UN (18+): add 525–528 to the IRL lists (Start work).",
                "DFT: no IRL 514–523 software list today. Still drop one G3 charge file and confirm FT1s after LC strip.",
            ],
        },
        {
            "title": "Suggested sequence and proof",
            "bullets": [
                "Change CEX SOFTWAREID 524 → 528 in the workbook.",
                "H2 backup, then 88a the four XLSX files.",
                "Route 1 listeners with the four PTH5.COC… restrictions.",
                "Edit 20R1 route.xml + A04 for the allowlists (525–528, not 524). Do not edit modules/.",
                "Drop PTH5.COCCN.08101 / COCOS.08101 / COCPMA.08101 / COCOMC.08101. Proof is CEX/OSX/POX/OVX ADT/DFT + LC kickout. Leave CEN/OSC/POI/OVI and GAN/CAT unchanged.",
            ],
        },
    ]
    dive["start_work"] = (
        "Med Rec is 20R1: change route.xml and the A04 stylesheet, not 26R1 modules/. "
        "This request also adds the four DirectoryListeners and H2 CLIENT_SPLITS/CODES (CEX=528). "
        "Proof is CEX/OSX/POX/OVX ADT/DFT and the LC kickout, not the stylesheet."
    )
    dive["risks"] = [
        "Do not 88a the CEX workbook at SOFTWAREID 524. H2 already has Catholic Medical on 524. Change the sheet to 528.",
        "Do not use FileNameRestriction PTH5.COC.* — COCCN, COCOS, COCOMC, and COCPMA would collide.",
        "Do not point these files at the old CEN / OSC / POI / OVI listeners (software 175 / 178 / 179 / 241).",
        "Workbook Mount Dora / Baldwin IP codes are XFMD.FSEDI and BOBP.FSEDI (not FSEDIP). Load as written.",
        "Blank-admit → first charge date is not a free global ADT change; prove it on a G3 inpatient before widening the when.",
        "Proof is the interface output for these four clients, not the plan PDF.",
    ]
    dive["questions"] = [
        {
            "text": "Confirm we should change MedReceivables_NewFacilityInfo_IRL_CEX.xlsx SOFTWAREID from 524 to 528 before 88a (524 is already NHL CAT in H2).",
            "status": "open",
        },
    ]
    return dive
