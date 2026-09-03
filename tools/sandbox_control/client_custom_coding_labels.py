"""Stable names and short descriptions for Med Rec custom-coding hits."""

from __future__ import annotations

import html
import re

# First matching (file, name, text) pattern wins. Same id is reused for every client.
RULES: list[tuple[str, str, str, str]] = [
    (
        r"set partition and client|setpartition",
        "set-partition-client",
        "Set partition and client",
        "Stamp Partition and Client on the transaction so later routes know which feed this is.",
    ),
    (
        r"xml to ged|ged xml",
        "xml-to-ged",
        "XML to GED",
        "Run this client's XML-to-GED map so charges and demographics land in the canonical shape.",
    ),
    (
        r"filenamerestriction|directory listener|incoming raw file",
        "inbound-filename",
        "Inbound filename listener",
        "Only pick up files whose names match this feed's directory-listener pattern.",
    ),
    (
        r"strip_data|strip locations|flg_locations|r\.eh|r\.labnd",
        "hard-coded-strip-locations",
        "Hard-coded strip locations",
        "Treat extra location codes as stripped even when they are not (only) in the H2 FLG/STRIP tables.",
    ),
    (
        r"strip charges if radexam|date_range",
        "strip-before-date-range",
        "Strip charges before date range",
        "Drop charges whose service date is before the DATE_RANGE value from the database.",
    ),
    (
        r"admguarrel|gt1\.11|guarantor/admguarrel",
        "blank-gt1-relationship",
        "Blank GT1 relationship",
        "When GT1.11 is blank, set SE / CH / UN from whether the guarantor name matches the patient.",
    ),
    (
        r"adminsinsuredrel|in1\.17|insuredrel",
        "blank-in1-relationship",
        "Blank IN1 relationship",
        "When IN1.17 is blank, set SE / CH / UN from whether the subscriber name matches the patient.",
    ),
    (
        r"mue_edits|isMUE|max_value_per_line|medically unlikely",
        "mue-split",
        "MUE charge split",
        "Split FT1 lines using the MUE_EDITS table (CDM or CPT) and max value per line.",
    ),
    (
        r"\$admlocation|admLocation|facilityname\s*=",
        "facility-or-location",
        "Facility / location branch",
        "Map a facility code or location mnemonic to a split, report, or HL7 variant.",
    ),
    (
        r"admpatienttype|patient type",
        "patient-type",
        "Patient type",
        "Branch on patient type (for example NA) for this feed.",
    ),
    (
        r"admmaritalstatus|marital",
        "marital-status",
        "Marital status default",
        "Fill or force marital status when the inbound value is blank or this feed always sends a code.",
    ),
    (
        r"apply stripping|specific clients only.*site|site locations",
        "apply-stripping-specific-clients",
        "Apply stripping (specific clients)",
        "Run the site-location strip processor only for the clients listed in this OGNL gate.",
    ),
    (
        r"append patienttype to cdm|patienttype to cdm",
        "append-patient-type-cdm",
        "Append patient type to CDM",
        "Suffix the patient type onto the CDM before MUE/CDM lookup (FPS pattern).",
    ),
    (
        r"tweak ins plans|group numbers",
        "tweak-ins-plans",
        "Tweak insurance plans / group numbers",
        "Rewrite plan or group numbers for this feed before they hit HL7.",
    ),
    (
        r"patientacctnum|acctnumnoalpha",
        "account-number-format",
        "Account number format",
        "Strip letters from the account number (or keep them) for this partition/facility.",
    ),
    (
        r"accession",
        "accession-report",
        "Accession report",
        "Only build the accession kickout/log report for the feeds listed in this condition.",
    ),
    (
        r"transform flat file to xml|flatfilexml|flat file to xml",
        "flat-file-to-xml",
        "Flat file to XML",
        "Choose which CSV/flat-file-to-XML transform runs for this client.",
    ),
    (
        r"stripped",
        "empty-after-strip",
        "Empty after strip",
        "If every charge was stripped, skip or alter downstream HL7 for this partition.",
    ),
    (
        r"uninsured|selfpay|self-pay|adminsmne",
        "self-pay-or-uninsured",
        "Self-pay / uninsured",
        "Special IN1 or coverage handling when the payer mnemonic is self-pay or uninsured.",
    ),
    (
        r"processor11|incoming flat files by partition",
        "incoming-route-gate",
        "Incoming route gate",
        "Skip or run a step on the incoming-files route only for the listed partitions or clients.",
    ),
    (
        r"generate dft|dpt p03",
        "dft-map",
        "DFT map branch",
        "A when-test in the DFT (FT1) stylesheet that only applies to this feed.",
    ),
    (
        r"generate adt|a04",
        "adt-map",
        "ADT map branch",
        "A when-test in the ADT stylesheet that only applies to this feed.",
    ),
]


def describe(file: str, name: str, text: str, kind: str) -> dict:
    blob = f"{file} {html.unescape(name or '')} {html.unescape(text or '')}".lower()
    for pat, rid, title, about in RULES:
        if re.search(pat, blob, re.I):
            return {"rule_id": rid, "title": title, "about": about}
    nice = html.unescape(name or "")
    nice = re.sub(r"[-_][A-Z]{2,4}(?:[-_][A-Z0-9]{2,6})+$", "", nice).strip()
    if len(nice) > 4 and nice.lower() not in {"condition", "processor"}:
        return {
            "rule_id": "named-" + re.sub(r"[^a-z0-9]+", "-", nice.lower()).strip("-")[:48],
            "title": nice,
            "about": f"Processor “{nice}” is gated to this feed ({kind}).",
        }
    return {
        "rule_id": "other-condition",
        "title": "Other feed condition",
        "about": "A partition, client, or software-id test that did not match a named pattern.",
    }


def tally(groups: list[dict]) -> list[dict]:
    bag: dict[str, dict] = {}
    for g in groups:
        who = f"{g.get('partition') or ''} / {g.get('client') or ''} · {g.get('title') or ''}".strip(" ·")
        seen_ids: set[str] = set()
        for r in g.get("rules") or []:
            rid = r.get("rule_id") or "other-condition"
            rec = bag.setdefault(
                rid,
                {
                    "rule_id": rid,
                    "title": r.get("title") or rid,
                    "about": r.get("about") or "",
                    "instances": 0,
                    "clients": [],
                    "kinds": {},
                },
            )
            rec["instances"] += 1
            rec["kinds"][r.get("kind") or ""] = rec["kinds"].get(r.get("kind") or "", 0) + 1
            if rid not in seen_ids:
                seen_ids.add(rid)
                rec["clients"].append(who)
    out = list(bag.values())
    out.sort(key=lambda x: (-int(x["instances"]), x.get("title") or ""))
    for rec in out:
        rec["client_count"] = len(rec["clients"])
    return out
