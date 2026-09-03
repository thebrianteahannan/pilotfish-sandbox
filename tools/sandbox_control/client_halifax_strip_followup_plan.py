"""Halifax stripping follow-up: TEST merge drops Location_ABBR."""

from __future__ import annotations

import re
from pathlib import Path

from client_dive import HAL_MAP, STRIP_DATA, _replace_ed

KICKOUT = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate Stripping And Tweaking Excel/transform.xslt"
)
A04 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate ADT A04 HL7/transform.xslt"
)
MERGE = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/merge_multiple_patient_demographics.xslt"
)
DROP = "Clients/Med Rec/data/Halifax Stripping-Issue-Aug26th2026"

MERGE_OLD = """            <admLocation>
              <xsl:for-each select="PatientDemographics/admLocation[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admLocation>
            <LabName>"""

MERGE_NEW = """            <admLocation>
              <xsl:for-each select="PatientDemographics/admLocation[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admLocation>
            <admLocationAbbr>
              <xsl:for-each select="PatientDemographics/admLocationAbbr[string-length(.) != 0]">
                <xsl:sort data-type="text" order="descending" select="../absAdmitDate" />
                <xsl:if test="position() = 1">
                  <xsl:value-of select="." />
                </xsl:if>
              </xsl:for-each>
            </admLocationAbbr>
            <LabName>"""


def is_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if not re.search(r"halifax", blob, re.I):
        return False
    if not re.search(r"strip", blob, re.I):
        return False
    return bool(
        re.search(
            r"not working|still not|HAX0825|Stripping-Issue-Aug26|30101805251|30101976049",
            blob,
            re.I,
        )
    )


def propose_merge_keep_abbr(root: Path) -> list[dict]:
    path = root / MERGE
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    rec = _replace_ed(
        MERGE,
        "Keep Location_ABBR through the patient-demographics merge",
        "TEST route 2 debug-trace (14:09): the Halifax map wrote admLocationAbbr 4322 times. "
        "Merge Multiple Patient Demographics then rebuilt PD from a field list that omitted it. "
        "Strip saw admLocation=HAX and an empty abbr, so FLG 750 and the HAL hardcode both missed.",
        MERGE_OLD,
        MERGE_NEW,
        text,
    )
    return [rec] if rec else []


def apply(dive: dict, root: Path, email: str, subject: str) -> dict:
    edits = propose_merge_keep_abbr(root)
    if edits:
        dive["edits"] = edits
    already = bool(edits) and all(e.get("already_applied") for e in edits)
    dive["summary"] = (
        "TEST debug-trace proved the Halifax map writes Location_ABBR onto admLocationAbbr, "
        "then Merge Multiple Patient Demographics drops the field. Copy the sandbox merge XSLT "
        "onto TEST so strip can see OR TL / HMC 201. Do not re-apply the strip_data hardcode."
    )
    dive["ask"] = (
        "Halifax stripping is not working. Folder Halifax Stripping-Issue-Aug26th2026: "
        "HAX0825d.zip, the 20260802 pair, FLG workbook, and route 2 debug-trace. "
        "Example accounts 30101805251 CONVERY (OR TL) and 30101976049 TANNER (HMC 201)."
    )
    dive["intent"] = "strip"
    dive["codes"] = ["HMC 201", "HH IPM", "TL GI", "OR TL"]
    dive["feed"] = {
        "partition": "HAL",
        "name": "Halifax HAX",
        "software_id": "750",
        "xslt": MERGE,
    }
    dive["files"] = [
        {
            "path": MERGE,
            "hits": [
                {
                    "code": "admLocationAbbr",
                    "line": 115,
                    "text": (
                        "Sandbox already copies PatientDemographics/admLocationAbbr after admLocation. "
                        "TEST’s 2025-12-11 copy has no such line — that is the deploy."
                        if already
                        else "Add the admLocationAbbr copy after admLocation so merge does not drop Location_ABBR."
                    ),
                }
            ],
        },
        {
            "path": STRIP_DATA,
            "hits": [
                {
                    "code": "HMC201",
                    "line": 60,
                    "text": "Already on TEST. Hardcode and FLG locAbbr match both need a non-empty admLocationAbbr.",
                }
            ],
        },
        {
            "path": HAL_MAP,
            "hits": [
                {
                    "code": "LOCATION_ABBR",
                    "line": 308,
                    "text": "Already writes normalize-space(LOCATION_ABBR) onto admLocationAbbr. Proven on the TEST listener trace (4322 nodes).",
                }
            ],
        },
        {
            "path": A04,
            "hits": [
                {
                    "code": "stripped",
                    "line": 14,
                    "text": "ADT already skips @stripped. HAX0826 still has the accounts because strip never marked them.",
                }
            ],
        },
        {
            "path": KICKOUT,
            "hits": [
                {
                    "code": "FLG Location Charges",
                    "line": 43,
                    "text": "HAX0826 StrippingAndTweaking xml is 0 stripped groups/demos/charges.",
                }
            ],
        },
    ]
    dive["build_plan"] = [
        {
            "title": "What the TEST debug-trace showed",
            "paras": [
                f"Route 2 trace from {DROP}/debug-trace-fromTEST_Aug26th2026, transaction 18_19 "
                "(MedReceivables_Charges_20260802 at 14:09).",
            ],
            "bullets": [
                "Attributes: Partition=HAL, Client=HAX, SoftwareID=750.",
                "H2 lookup already has FLG_LOCATIONS HMC 201 / HH IPM / TL GI / OR TL for software 750.",
                "Listener into route 2 still has 4322 admLocationAbbr nodes (map worked).",
                "After Merge Multiple Patient Demographics: 0 admLocationAbbr. CONVERY and TANNER are admLocation=HAX only.",
                "Apply Stripping Rules then writes no stripped_flagged_* . HAX0826 counts stay 1458 / 25447.",
            ],
        },
        {
            "title": "The one file TEST does not have",
            "paras": [
                "Sandbox merge_multiple_patient_demographics.xslt already copies admLocationAbbr. "
                "The eip-root zip from TEST is the 2025-12-11 file without that block. "
                "Yesterday’s TEST zip packed only strip_data.xslt.",
            ],
            "bullets": [
                "Deploy only the merge XSLT. Do not re-apply the HAL / 750 hardcode.",
                "Do not delete HAX map lines. Do not strip every HAX row.",
                "FLG workbook does not need another drop after this file is on TEST.",
            ],
        },
        {
            "title": "Proof after the TEST copy",
            "paras": [
                "Re-drop the same 20260802 pair. Do not turn debug-trace back on unless HAX is still wrong.",
            ],
            "bullets": [
                "HAX ADT/DFT omit 30101805251 CONVERY and 30101976049 TANNER.",
                "Those two land on FLG Location Charges / StrippingAndTweaking.",
                "TANNER’s other Halifax accounts (HMC inpatient 30101936310, HH HPC 30102025708) stay on HAX.",
            ],
        },
    ]
    dive["risks"] = [
        "Deploy merge_multiple_patient_demographics.xslt only. Do not re-pack strip_data or DFT.",
        "Do not delete the HAX map lines. Those still split to HAX; stripping is a later step.",
        "Do not strip every HAX row. Only the four LocationAbbreviation codes.",
        "Software 750 is HAX (MedReceivables_Charges). AP_Halifax HAA is 751.",
        "Do not include Generate DFT DPT P03 HL7/transform.xslt in this request’s Code changes.",
        "Proof is the real 20260802 drop: those two accounts off HAX and on the strip kickout.",
    ]
    dive["start_work"] = (
        "The sandbox merge XSLT already has admLocationAbbr. Implement packs that one file "
        "for TEST. Capture Regression Baseline first if you need a sandbox compare. "
        "Proof on TEST is HAX ADT/DFT without 30101805251 / 30101976049."
    )
    return dive
