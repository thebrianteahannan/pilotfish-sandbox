"""NGP Healthfirst accession-log SpecimenNo / Pathologist plan."""

from __future__ import annotations

import re
from pathlib import Path

from client_dive import NGP_HF, _replace_ed

ACC_LOG = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate Accession Log Report/transform.xslt"
)

OLD = (
    "              <misOrderingPhyAddr />\n"
    "            </Charge>"
)
NEW = (
    "              <misOrderingPhyAddr />\n"
    "              <specimenNo>\n"
    "                <xsl:value-of select=\"normalize-space(ACCESSION_NUMBER)\" />\n"
    "              </specimenNo>\n"
    "              <pathologist>\n"
    "                <xsl:value-of select=\"normalize-space(REFERRING_PROVIDER)\" />\n"
    "              </pathologist>\n"
    "            </Charge>"
)


def is_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if not re.search(r"NGP|Health\s*First|Healthfirst", blob, re.I):
        return False
    if not re.search(r"accession", blob, re.I):
        return False
    return bool(re.search(r"specimen|pathologist", blob, re.I))


def propose(root: Path) -> list[dict]:
    path = root / NGP_HF
    if not path.is_file():
        return []
    rec = _replace_ed(
        NGP_HF,
        "Copy Accession Number and Referring Provider onto the accession log fields",
        "The log reads Charge/specimenNo and Charge/pathologist. The NGP Healthfirst map never writes those, so both columns stay blank.",
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
        "NGP Healthfirst accession log is blank for Specimen number and Pathologist because the CAQ map "
        "never writes specimenNo / pathologist. Map Accession Number and Referring Provider like Karen’s header table."
    )
    dive["ask"] = (
        "NGP Health First accession log: SpecimenNo = Accession Number, Pathologist = Referring Provider, "
        "Pathologist NPI = Referring Provider NPI (CER). Software 652 CAQ. New Mapping/NGP HF."
    )
    dive["intent"] = "change"
    dive["codes"] = ["SpecimenNo", "Pathologist"]
    dive["feed"] = {
        "partition": "NGP",
        "name": "NGP Healthfirst",
        "software_id": "652",
        "xslt": NGP_HF,
    }
    dive["files"] = [
        {
            "path": NGP_HF,
            "hits": [
                {
                    "code": "specimenNo",
                    "line": 257,
                    "text": "Charge ends without specimenNo / pathologist; accession log reads those two nodes.",
                }
            ],
        },
        {
            "path": ACC_LOG,
            "hits": [
                {
                    "code": "SpecimenNo",
                    "line": 49,
                    "text": "Already Charge/specimenNo and Charge/pathologist. Do not change this sheet.",
                }
            ],
        },
    ]
    dive["risks"] = [
        "Do not remap Billing Provider. That already feeds ordering-physician fields. Karen’s table is Referring Provider for Pathologist.",
        "Do not change NGP AP (software 651) or PPA/HAL/PPS/NSP accession maps.",
        "Route 4a6 already runs for NGP CAQ. The hole is the canonical Charge fields, not the trigger.",
        "The Excel only has SpecimenNo and Pathologist. Pathologist NPI stays off the sheet unless she asks to add a column.",
        "Proof is the NGP HF Accession_Log spreadsheet with those two columns filled, not the XSLT.",
    ]
    dive["start_work"] = (
        "Add specimenNo from ACCESSION_NUMBER and pathologist from REFERRING_PROVIDER on the NGP Healthfirst Charge. "
        "Capture Regression Baseline first. Proof is the accession log, not ADT/DFT."
    )
    return dive
