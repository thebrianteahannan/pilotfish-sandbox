"""NSP / PPS MUE: DFT must look up MUE_EDITS by original CDM, like NHL."""

from __future__ import annotations

import re
from pathlib import Path

from client_dive import ADD_MUE, DFT_P03, is_mue_bug_ask, _replace_ed

NSP_PPS_MAP = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/1 - Incoming Flat Files by Partition and Client/"
    "transform-pps-and-nsp-flatfilexml-to-canconicalxml.xslt"
)
MUE_REPORT = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/MUE_Edits_Accounts_Report/transform.xslt"
)

OLD = (
    "                    <xsl:when test=\"$partitionName = 'NHL'\">\n"
    "                      <xsl:value-of select=\"radExamBillingCodeOrig\" />\n"
    "                    </xsl:when>"
)
NEW = (
    "                    <xsl:when test=\"$partitionName = 'NHL' or $partitionName = 'NSP' or $partitionName = 'PPS'\">\n"
    "                      <xsl:value-of select=\"radExamBillingCodeOrig\" />\n"
    "                    </xsl:when>"
)


def is_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if is_mue_bug_ask(email, subject):
        return False
    if not re.search(r"\bMUE", blob, re.I):
        return False
    if not re.search(r"\bNSP\b", blob, re.I) or not re.search(r"\bPPS\b", blob, re.I):
        return False
    return bool(re.search(r"2659|kickout|not working|nothing is generating", blob, re.I))


def propose(root: Path) -> list[dict]:
    path = root / DFT_P03
    if not path.is_file():
        return []
    rec = _replace_ed(
        DFT_P03,
        "Look up NSP / PPS MUE rows by original CDM, like NHL",
        "tweak_data copies the CPT onto radExamBillingCode when the charge is in MUE_EDITS. "
        "NSP/PPS then look up the table with that CPT, miss, skip the split, and never write MUE_EDIT_LOG.",
        OLD,
        NEW,
        path.read_text(encoding="utf-8", errors="replace"),
    )
    return [rec] if rec else []


def apply(dive: dict, root: Path, email: str, subject: str) -> dict:
    edits = propose(root)
    if edits:
        dive["edits"] = edits
    dive["summary"] = (
        "NSP and PPS MUEs never split because the DFT looks up MUE_EDITS with the tweaked CPT, "
        "not the original CDM. NHL already uses radExamBillingCodeOrig. Do the same for NSP and PPS "
        "so FT1.7 gets 2659 on extra lines and the MUE kickout fills."
    )
    dive["ask"] = (
        "MUEs are not working for NSP and PPS: no 2659 on the DFTs and nothing on the MUE kickout "
        "reports. Logs New_MUE_Edits_NSP / New_MUE_Edits_PPS. Raw NSP FLO/HIA/NOS and PPS CGM/PGM "
        "from 20260726. Software 760 / 761."
    )
    dive["intent"] = "change"
    dive["codes"] = ["2659", "760", "761"]
    dive["feed"] = {
        "partition": "NSP",
        "name": "NSP / PPS MUE",
        "software_id": "760",
        "xslt": DFT_P03,
    }
    dive["files"] = [
        {
            "path": DFT_P03,
            "hits": [
                {
                    "code": "CDM",
                    "line": 203,
                    "text": "Only NHL uses radExamBillingCodeOrig for $CDM. NSP/PPS use the tweaked CPT.",
                },
                {
                    "code": "2659",
                    "line": 411,
                    "text": "Extra MUE FT1.7 lines append 2659. That path never runs if the table lookup misses.",
                },
            ],
        },
        {
            "path": MUE_REPORT,
            "hits": [
                {
                    "code": "MUE_EDIT_LOG",
                    "line": 18,
                    "text": "Kickout reads MUE_EDIT_LOG. Empty log → empty report. Do not change this sheet.",
                }
            ],
        },
        {
            "path": NSP_PPS_MAP,
            "hits": [
                {
                    "code": "PROC_CODE__CDM_",
                    "line": 152,
                    "text": "Already maps CDM vs CPT_CODE. Do not change this inbound map.",
                }
            ],
        },
        {
            "path": ADD_MUE,
            "hits": [
                {
                    "code": "SOFTWAREID",
                    "line": 5,
                    "text": "88e fill-down is already on disk. Do not re-do the Excel load XSLT.",
                }
            ],
        },
    ]
    dive["risks"] = [
        "Do not re-apply the DFT when-tests that already include NSP / PPS / HAL / NGP 652.",
        "Do not change HAL or NGP $CDM unless she reports those feeds too.",
        "Do not change the NSP/PPS inbound map or 88e fill-down.",
        "If TEST MUE_EDITS has no 760/761 rows, re-drop New_MUE_Edits_NSP.xlsx and New_MUE_Edits_PPS.xlsx after the XSLT. That is table load, not a second code change.",
        "Proof is NSP/PPS DFT FT1.7 with 2659 on the split lines plus a filled MUE kickout, not the XSLT.",
    ]
    dive["start_work"] = (
        "Use radExamBillingCodeOrig for $CDM on NSP and PPS, same as NHL. "
        "Capture Regression Baseline first. Proof is 2659 on the DFT and the MUE kickout."
    )
    return dive
