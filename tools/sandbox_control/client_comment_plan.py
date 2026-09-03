"""Refine a change plan from comments without re-searching eip-root from scratch."""

from __future__ import annotations

import re
from pathlib import Path

import client_dive
import client_halifax_strip_followup_plan
import client_ngp_accession_plan
import client_nsp_pps_mue_plan

HAL_MAP = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/1 - Incoming Flat Files by Partition and Client/"
    "transform-halifax-flatfilexml-to-canconicalxml.xslt"
)
STRIP_DATA = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/strip_data.xslt"
)
KICKOUT = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate Stripping And Tweaking Excel/transform.xslt"
)
REPORT_ASK = re.compile(r"strip locations? report|kickout report|locations report", re.I)
HAL_LOCS = "('HMC 201','HH IPM','TL GI','TLGI','OR TL')"


def _listed(codes: list[str]) -> str:
    codes = [c for c in codes if c]
    if len(codes) <= 1:
        return codes[0] if codes else "these codes"
    if len(codes) == 2:
        return f"{codes[0]} and {codes[1]}"
    return ", ".join(codes[:-1]) + ", and " + codes[-1]


def recover_map_strips(root: Path, dive: dict) -> None:
    codes = [str(c) for c in (dive.get("codes") or []) if c and not str(c).startswith("$")]
    if not codes:
        return
    bak = (root / HAL_MAP).with_name(Path(HAL_MAP).name + ".bak-req")
    if not bak.is_file():
        return
    text = bak.read_text(encoding="utf-8", errors="replace")
    edits = list(dive.get("edits") or [])
    have = {(e.get("path"), e.get("code")) for e in edits}
    hits: list[dict] = []
    for code in codes:
        for needle in client_dive.variants(code):
            for hit in client_dive.find_whens(text, needle):
                if (HAL_MAP, needle) in have:
                    continue
                have.add((HAL_MAP, needle))
                hits.append({"code": needle, **{k: hit[k] for k in ("line", "text", "maps_to")}})
                edits.append(
                    {
                        "path": HAL_MAP,
                        "action": "remove_when",
                        "code": needle,
                        "line": hit["line"],
                        "maps_to": hit["maps_to"],
                        "remove_blocks": [hit["block"]],
                        "already_applied": True,
                    }
                )
    dive["edits"] = edits
    if hits:
        files = [f for f in (dive.get("files") or []) if f.get("path") != HAL_MAP]
        files.insert(0, {"path": HAL_MAP, "hits": hits})
        dive["files"] = files[:8]


def propose_strip_report(root: Path, codes: list[str]) -> list[dict]:
    out: list[dict] = []
    loc_old = (
        "                <xsl:when test=\"$locationAbbr = 'PO FSED XR'\">\n"
        "                  <xsl:value-of select=\"'PXE'\" />\n"
        "                </xsl:when>\n"
        "                <xsl:otherwise>\n"
        "                  <xsl:value-of select=\"'HAX'\" />\n"
        "                </xsl:otherwise>"
    )
    loc_new = (
        "                <xsl:when test=\"$locationAbbr = 'PO FSED XR'\">\n"
        "                  <xsl:value-of select=\"'PXE'\" />\n"
        "                </xsl:when>\n"
        "                <xsl:when test=\"$locationAbbr = 'HMC 201' or $locationAbbr = 'HH IPM' "
        "or $locationAbbr = 'TL GI' or $locationAbbr = 'TLGI' or $locationAbbr = 'OR TL'\">\n"
        "                  <xsl:value-of select=\"$locationAbbr\" />\n"
        "                </xsl:when>\n"
        "                <xsl:otherwise>\n"
        "                  <xsl:value-of select=\"'HAX'\" />\n"
        "                </xsl:otherwise>"
    )
    map_path = root / HAL_MAP
    if map_path.is_file():
        rec = client_dive._replace_ed(
            HAL_MAP,
            "Keep the stripped Halifax locations identifiable",
            "Those four codes currently fall through to HAX, so the kickout report cannot tell them apart. "
            "Keep the original location abbreviation on the account.",
            loc_old,
            loc_new,
            map_path.read_text(encoding="utf-8", errors="replace"),
        )
        if rec:
            out.append(rec)
    add = (
        " + (if ($Partition = 'HAL' and $admLocation = "
        + HAL_LOCS
        + ") then 1 else 0)"
    )
    count_old = (
        'select="count(/XCSData/query_results/LOCATION/LOCATION'
        '[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID])"'
    )
    count_new = count_old[:-1] + add + '"'
    strip_path = root / STRIP_DATA
    if strip_path.is_file():
        text = strip_path.read_text(encoding="utf-8", errors="replace")
        rec = client_dive._replace_ed(
            STRIP_DATA,
            "Send those Halifax locations to the strip locations report",
            "Flag HMC 201, HH IPM, TL GI, and OR TL as stripped locations for Halifax "
            "so they land on the FLG Location Charges kickout sheet.",
            count_old,
            count_new,
            text,
        )
        if rec:
            rec["replace_all"] = True
            out.append(rec)
    return out


def refine(root: Path, dive: dict, comments: str, prev: dict | None = None) -> dict:
    ask = str(dive.get("ask") or "")
    subj = str(dive.get("subject") or "")
    if (
        not client_halifax_strip_followup_plan.is_ask(ask, subj)
        and not client_ngp_accession_plan.is_ask(ask, subj)
        and not client_nsp_pps_mue_plan.is_ask(ask, subj)
        and not client_dive.is_hal_strip_bug_ask(ask, subj)
        and not client_dive.is_mue_bug_ask(ask, subj)
        and not client_dive.is_ntx_pv12_pos24_ask(ask, subj)
        and not client_dive.is_nhl_cat_bug_ask(ask, subj)
        and not client_dive.is_nhl_cat_lc_dft_ask(ask, subj)
        and not client_dive.is_nhl_cat_guarantor_ask(ask, subj)
        and not client_dive.is_hal_flg_change_ask(ask, subj)
    ):
        recover_map_strips(root, dive)
    note = (comments or "").strip()
    if not note:
        return dive
    codes = [str(c) for c in (dive.get("codes") or []) if c and not str(c).startswith("$")]
    if REPORT_ASK.search(note) and codes:
        extra = propose_strip_report(root, codes)
        dive["edits"] = list(dive.get("edits") or []) + extra
        files = list(dive.get("files") or [])
        for rel in (STRIP_DATA, KICKOUT):
            if (root / rel).is_file() and not any(f.get("path") == rel for f in files):
                files.append({"path": rel, "hits": [{"code": "FLG Location Charges", "line": 0, "text": "strip locations kickout report"}]})
        loc_needles = set()
        for code in codes:
            loc_needles.update(client_dive.variants(code))
        keep = {HAL_MAP, STRIP_DATA, KICKOUT}
        files = [
            rec
            for rec in files
            if rec.get("path") in keep
            or any((h.get("code") or "") in loc_needles for h in rec.get("hits") or [])
        ]
        dive["files"] = files[:8]
        dive["summary"] = (
            f"Strip Halifax location codes {_listed(codes)} and show those strips on the "
            "strip locations kickout report (FLG Location Charges)."
        )
        risks = list(dive.get("risks") or [])
        risks = [r for r in risks if "No xsl:when" not in r]
        risks.append(
            "The kickout sheet lists charges flagged stripped_flagged_locations. "
            "These four codes must stay as themselves (not HAX) or they will not match the strip."
        )
        dive["risks"] = risks
    return dive


def human_delta(prev: dict, cur: dict) -> list[str]:
    notes: list[str] = []
    comment = (cur.get("comments") or "").strip()
    old = {(e.get("action"), e.get("path"), e.get("code") or e.get("title")) for e in (prev.get("edits") or [])}
    for ed in cur.get("edits") or []:
        key = (ed.get("action"), ed.get("path"), ed.get("code") or ed.get("title"))
        if key not in old:
            ed["from_comment"] = True
    codes = [str(c) for c in (cur.get("codes") or []) if c and not str(c).startswith("$")]
    if comment and REPORT_ASK.search(comment):
        notes.append(
            "Your comment asked that these location strips also show on the strip locations "
            "kickout report at the end of the process."
        )
        notes.append(
            f"The plan still strips {_listed(codes) if codes else 'those location codes'}. "
            "It now also keeps those location names on the account and flags them so they "
            "appear on FLG Location Charges."
        )
        return notes
    if comment:
        notes.append("Rebuilt the plan from your comments.")
    for ed in cur.get("edits") or []:
        if ed.get("from_comment"):
            notes.append("Added: " + (ed.get("title") or ed.get("code") or "a new edit") + ".")
    return notes
