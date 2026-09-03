"""Turn a strip-locations email into strip_data.xslt edits (not map deletes)."""

from __future__ import annotations

import re
from pathlib import Path

import client_dive

STRIP_DATA = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/strip_data.xslt"
)
KICKOUT = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate Stripping And Tweaking Excel/transform.xslt"
)
A04 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate ADT A04 HL7/transform.xslt"
)
INCLUDE_REL = re.compile(r"same email|second request|ok to do|all good|include (the )?(relationship|second)", re.I)
GT1_OLD = (
    "($partitionName = 'NGP' or $partitionName = 'SPG' or $partitionName = 'GLF' or "
    "($partitionName = 'IRL' and $softwareID = ('517','514','515','516','518','519','520','521','522','523')) or "
    "($partitionName = 'FPS' and $softwareID = ('314','315','316','317','318','319','320')) or $softwareID = ('524') )"
)
GT1_NEW = GT1_OLD[:-1] + " or ($partitionName = 'NHL' and $softwareID = '513'))"
IN1_OLD = "($partitionName = 'SPG' or $partitionName = 'NGP' or $partitionName = 'HAL')"
IN1_NEW = "($partitionName = 'SPG' or $partitionName = 'NGP' or $partitionName = 'HAL' or ($partitionName = 'NHL' and $softwareID = '513'))"
SW = re.compile(r"\b(\d{3})\s+(NHL|HAL|ARA|FPS|PPA|NGP)\s+([A-Z]{3})\b")
LOC2_OK = re.compile(r"^[A-Z]{2,8}$")
SKIP2 = {"EMPLOYEE", "HEALTH", "DAME", "PAV", "LABORATORY", "NOTRE", "CODE", "FLG"}
COUNT_LOC = re.compile(
    r'select="count\(/XCSData/query_results/LOCATION/LOCATION'
    r'\[LOC_MNEMONIC = \$admLocation and SOFTWARE_ID = \$SoftwareID\]\)[^"]*"'
)
COUNT_BOTH = re.compile(
    r'select="count\(/XCSData/query_results/STRIP_LOCATIONS/STRIP_LOCATIONS'
    r'\[\(string-length\(\$location1\) != 0 and string-length\(\$location2\) != 0 and '
    r'LOCATION = \$location1 and LOCATION2 = \$location2\) and SOFTWARE_ID = \$SoftwareID\]\)[^"]*"'
)


def _listed(codes: list[str]) -> str:
    codes = [c for c in codes if c]
    if len(codes) <= 1:
        return codes[0] if codes else "these codes"
    if len(codes) == 2:
        return f"{codes[0]} and {codes[1]}"
    return ", ".join(codes[:-1]) + ", and " + codes[-1]


def _xq(codes: list[str]) -> str:
    return "(" + ",".join(f"'{c}'" for c in codes) + ")"


def parse_tables(email: str, subject: str = "") -> dict:
    flg: list[str] = []
    pairs: list[tuple[str, str]] = []
    software, partition, facility = "", "", ""
    section = "flg"
    blob = f"{subject}\n{email}"
    if re.search(r"\bNHL\b", blob):
        partition = "NHL"
    elif re.search(r"\bhalifax\b|\bHAL\b", blob, re.I):
        partition = "HAL"
    for raw in (email or "").splitlines():
        line = raw.strip()
        if re.search(r"2ndry|LOCATION2", line, re.I):
            section = "2ndry"
            continue
        found = SW.search(line)
        if found:
            software, partition, facility = found.group(1), found.group(2), found.group(3)
        m = client_dive.LOC_HEAD.match(client_dive.FACILITY_TAIL.sub("", line).strip())
        if not m:
            continue
        code = m.group(1)
        if code.upper() in client_dive.LOC_SKIP or all(p in client_dive.LOC_SKIP for p in code.upper().split()):
            continue
        rest = client_dive.FACILITY_TAIL.sub("", line).strip()[len(code) :].strip().split()
        loc2 = rest[0] if rest else ""
        if section == "2ndry" and LOC2_OK.match(loc2) and loc2 not in SKIP2:
            pairs.append((code, loc2))
        else:
            flg.append(code)
    if not software and partition == "NHL" and re.search(r"\b513\b", blob):
        software = "513"
    def uniq(items):
        out = []
        for item in items:
            if item not in out:
                out.append(item)
        return out
    return {
        "flg": uniq(flg),
        "pairs": uniq(pairs),
        "software": software,
        "partition": partition,
        "facility": facility,
    }


def _add_to_select(text: str, pat: re.Pattern[str], add: str, rel: str, title: str, why: str) -> dict | None:
    m = pat.search(text)
    if not m:
        return None
    old = m.group(0)
    if add in old:
        new = old
        applied = True
    else:
        new = old[:-1] + add + '"'
        applied = False
    rec = client_dive._replace_ed(rel, title, why, old, new, text)
    if rec:
        rec["replace_all"] = text.count(old) > 1
        rec["already_applied"] = applied
    return rec


def wants_relationship(comments: str) -> bool:
    return bool(INCLUDE_REL.search(comments or ""))


def add_relationship(root: Path, dive: dict) -> dict:
    path = root / A04
    if not path.is_file():
        return dive
    text = path.read_text(encoding="utf-8", errors="replace")
    edits = list(dive.get("edits") or [])
    have = {e.get("title") for e in edits}
    for title, why, old, new, all_hits in (
        (
            "Fill blank GT1.11 on NHL CAT",
            "Same SE / CH / UN default other partitions already use, when the guarantor relationship is blank.",
            GT1_OLD,
            GT1_NEW,
            False,
        ),
        (
            "Fill blank IN1.17 on NHL CAT",
            "Same name-vs-patient default for subscriber relationship (IN1.17) when it is blank on NHL CAT (software 513).",
            IN1_OLD,
            IN1_NEW,
            True,
        ),
    ):
        if title in have:
            continue
        rec = client_dive._replace_ed(A04, title, why, old, new, text)
        if rec:
            rec["replace_all"] = all_hits
            edits.append(rec)
    dive["edits"] = edits
    files = [f for f in (dive.get("files") or []) if f.get("path") != A04]
    files.append({"path": A04, "hits": [{"code": "GT1.11 / IN1.17", "line": 0, "text": "SE / CH / UN when relationship is blank"}]})
    dive["files"] = files[:8]
    extra = " Also fill blank GT1.11 and IN1.17 on NHL CAT with SE, CH, or UN from the patient vs guarantor name."
    if extra.strip() not in (dive.get("summary") or ""):
        dive["summary"] = ((dive.get("summary") or "").rstrip(".") + "." + extra).strip()
        dive["ask"] = ((dive.get("ask") or "").rstrip(".") + extra).strip()
    dive["risks"] = [
        r
        for r in (dive.get("risks") or [])
        if "separate HL7" not in r and "IN1.17 relationship defaults" not in r
    ]
    return dive


def apply(root: Path, dive: dict, email: str = "", comments: str = "") -> dict:
    if client_dive.is_hal_strip_bug_ask(email, str(dive.get("subject") or "")):
        return dive
    import client_halifax_strip_followup_plan

    if client_halifax_strip_followup_plan.is_ask(email, str(dive.get("subject") or "")):
        return dive
    import client_ngp_accession_plan

    import client_irl_expanse_g3_plan

    if client_irl_expanse_g3_plan.is_ask(email, str(dive.get("subject") or "")):
        return dive
    if client_ngp_accession_plan.is_ask(email, str(dive.get("subject") or "")):
        return dive
    import client_nsp_pps_mue_plan

    if client_nsp_pps_mue_plan.is_ask(email, str(dive.get("subject") or "")):
        return dive
    if client_dive.is_mue_bug_ask(email, str(dive.get("subject") or "")):
        return dive
    if client_dive.is_ntx_pv12_pos24_ask(email, str(dive.get("subject") or "")):
        return dive
    if client_dive.is_nhl_cat_bug_ask(email, str(dive.get("subject") or "")):
        return dive
    if client_dive.is_nhl_cat_lc_dft_ask(email, str(dive.get("subject") or "")):
        return dive
    if client_dive.is_nhl_cat_guarantor_ask(email, str(dive.get("subject") or "")):
        return dive
    if client_dive.is_hal_flg_change_ask(email, str(dive.get("subject") or "")):
        return dive
    if dive.get("intent") != "strip":
        return dive
    info = parse_tables(email, str(dive.get("subject") or ""))
    flg = info["flg"] or [str(c) for c in (dive.get("codes") or []) if c and not str(c).startswith("$")]
    pairs = info["pairs"]
    if not flg and not pairs:
        return dive
    path = root / STRIP_DATA
    if not path.is_file():
        return dive
    text = path.read_text(encoding="utf-8", errors="replace")
    edits = [e for e in (dive.get("edits") or []) if e.get("action") != "remove_when"]
    files: list[dict] = []
    sw = info["software"] or "513"
    part = info["partition"] or "NHL"
    if flg and part == "NHL":
        add = f" + (if ($Partition = 'NHL' and $SoftwareID = '{sw}' and $admLocation = {_xq(flg)}) then 1 else 0)"
        rec = _add_to_select(
            text,
            COUNT_LOC,
            add,
            STRIP_DATA,
            "Mark those NHL CAT locations as stripped",
            f"In the stripping route, mark NHL CAT ({sw}) records with {_listed(flg)} as stripped "
            "so they are left out of ADT and DFT and land on FLG Location Charges.",
        )
        if rec:
            edits.append(rec)
            files.append({"path": STRIP_DATA, "hits": [{"code": ", ".join(flg), "line": 0, "text": "mark NHL CAT FLG locations stripped"}]})
    if pairs and part == "NHL":
        ors = " or ".join(f"($location1 = '{a}' and $location2 = '{b}')" for a, b in pairs)
        add = f" + (if ($SoftwareID = '{sw}' and ({ors})) then 1 else 0)"
        rec = _add_to_select(
            text,
            COUNT_BOTH,
            add,
            STRIP_DATA,
            "Strip the NHL CAT secondary location pairs",
            "When LOCATION and LOCATION2 are "
            + _listed([f"{a}/{b}" for a, b in pairs])
            + f" for software {sw}, mark the record stripped (2ndry strip table).",
        )
        if rec:
            edits.append(rec)
            files.append({"path": STRIP_DATA, "hits": [{"code": "2ndry", "line": 0, "text": "STRIP_LOCATIONS location + location2"}]})
    if (root / KICKOUT).is_file() and flg:
        files.append({"path": KICKOUT, "hits": [{"code": "FLG Location Charges", "line": 0, "text": "strip locations kickout report"}]})
    labels = list(flg) + [f"{a}/{b}" for a, b in pairs]
    dive["codes"] = labels
    dive["edits"] = edits
    dive["files"] = files[:8]
    where = "NHL CAT" if part == "NHL" else part
    dive["summary"] = (
        f"Strip {where} records with {_listed(flg)}"
        + (f" and secondary pairs {_listed([f'{a}/{b}' for a, b in pairs])}" if pairs else "")
        + " so they are not sent in ADT or DFT, and list the FLG codes on FLG Location Charges."
    )
    dive["ask"] = (
        f"Add {_listed(flg)} to the NHL CAT strip locations (software {sw})"
        + (f", plus 2ndry pairs {_listed([f'{a}/{b}' for a, b in pairs])}" if pairs else "")
        + "."
    )
    risks = [r for r in (dive.get("risks") or []) if "xsl:when" not in r and "when-branches" not in r]
    if wants_relationship(comments):
        dive["risks"] = risks
        return add_relationship(root, dive)
    if re.search(r"IN1\.17|GT1\.11|relationship", email or "", re.I):
        risks.append(
            "The same email also asks for GT1.11 / IN1.17 relationship defaults when the account is "
            "Huggins, Monadnock, or employee. That is a separate HL7 change, not this location strip."
        )
    dive["risks"] = risks
    return dive
