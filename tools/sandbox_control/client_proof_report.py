"""Prove strip-locations report behavior and write request/proof samples."""

from __future__ import annotations

import re
from pathlib import Path
from xml.etree import ElementTree as ET

import client_proof as p


def _hal_list(strip: str) -> list[str]:
    m = re.search(r"\$Partition = 'HAL' and \$admLocation = \(([^)]+)\)", strip)
    return re.findall(r"'([^']+)'", m.group(1)) if m else []


def _code_variants(code: str) -> list[str]:
    s = " ".join((code or "").split())
    out = [s]
    compact = s.replace(" ", "")
    if compact != s:
        out.append(compact)
    if len(compact) >= 4 and " " not in s:
        out.append(compact[:-2] + " " + compact[-2:])
    return list(dict.fromkeys(x for x in out if x))


def _flag_xslt(listed: list[str]) -> str:
    names = listed or ["__none__"]
    ors = " or ".join(f"$loc = '{c}'" for c in names)
    return (
        '<?xml version="1.0"?>\n'
        '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">\n'
        '<xsl:param name="Partition">HAL</xsl:param>\n'
        '<xsl:template match="/acct"><xsl:variable name="loc" select="admLocation"/>\n'
        f"<proof><flagged><xsl:value-of select=\"number($Partition = 'HAL' and ({ors}))\"/></flagged></proof>\n"
        "</xsl:template></xsl:stylesheet>\n"
    )


def _excel_count_xslt(xpath: str) -> str:
    return (
        '<?xml version="1.0"?>\n'
        '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">\n'
        f'<xsl:template match="/StripsAndTweaks"><proof><rows><xsl:value-of select="count({xpath})"/></rows></proof></xsl:template>\n'
        "</xsl:stylesheet>\n"
    )


def prove_strip_report(root: Path, dive: dict, folder: Path | None = None) -> list[dict]:
    codes = p.strip_codes(dive)
    strip = (root / p.STRIP_DATA).read_text(encoding="utf-8", errors="replace") if (root / p.STRIP_DATA).is_file() else ""
    excel = (root / p.KICKOUT).read_text(encoding="utf-8", errors="replace") if (root / p.KICKOUT).is_file() else ""
    listed = _hal_list(strip)
    xpath_m = re.search(r'<xsl:for-each select="([^"]+stripped_flagged_locations[^"]+)">', excel)
    xpath = xpath_m.group(1) if xpath_m else ""
    has_sheet = 'name="FLG Location Charges"' in excel and bool(xpath)
    items = [
        p._item(
            "FLG Location Charges includes stripped locations",
            has_sheet,
            "kickout sheet selects stripped_flagged_locations" if has_sheet else "FLG Location Charges is missing the location-strip select",
            [],
            input=p.KICKOUT,
            output='XCSExcelSheet name="FLG Location Charges"',
            before="Location strips were not selected unless they were already in the LOCATION table.",
            after=p._clip(xpath or "(missing for-each)"),
        )
    ]
    old_xslt, new_xslt = _flag_xslt([]), _flag_xslt(listed)
    for code in codes:
        flagged = ""
        sample = after_xml = before_xml = ""
        for variant in _code_variants(code):
            sample = f"<acct><admLocation>{variant}</admLocation></acct>"
            try:
                before_xml = p._run_xslt(old_xslt, sample)
                after_xml = p._run_xslt(new_xslt, sample)
                if p._fields(after_xml).get("flagged") == "1":
                    flagged = variant
                    break
            except (RuntimeError, ET.ParseError):
                continue
        slug = re.sub(r"[^A-Za-z0-9]+", "-", code).strip("-")
        src = p._save(folder, f"{slug}-in.xml", sample or f"<acct><admLocation>{code}</admLocation></acct>")
        dest = p._save(folder, f"{slug}-out.xml", after_xml or "<proof/>")
        ok = bool(flagged) and bool(listed)
        items.append(
            p._item(
                f"{code} lands on the strip locations report",
                ok,
                f"{flagged} sets stripped_flagged_locations" if ok else f"{code} is not flagged as a strip location",
                [f"Rules from {p.STRIP_DATA}"],
                input=src or "sample XML",
                output=dest or "xsltproc stdout",
                input_text=sample or f"<acct><admLocation>{code}</admLocation></acct>",
                output_text=p._clip(after_xml or "<proof/>"),
                before=p._clip(before_xml or "<proof><flagged>0</flagged></proof>"),
                after=p._clip(after_xml or "<proof/>"),
            )
        )
    if xpath:
        reason = "Strip Charge: Strip flagged accounts, flagged locations, F.LAB accounts, F.RLAB accounts"
        sample = (
            "<StripsAndTweaks><Stripped><StrippedCharges>"
            f'<Charge stripped_reason="{reason}" stripped_flagged_locations="true"/>'
            "</StrippedCharges></Stripped></StripsAndTweaks>"
        )
        blank = sample.replace('stripped_flagged_locations="true"', "")
        src = p._save(folder, "flg-location-in.xml", sample)
        try:
            before_xml = p._run_xslt(_excel_count_xslt(xpath), blank)
            after_xml = p._run_xslt(_excel_count_xslt(xpath), sample)
            rows = p._fields(after_xml).get("rows")
            ok = rows == "1"
            detail = "flagged location charge is selected" if ok else f"row count {rows!r}"
        except (RuntimeError, ET.ParseError) as exc:
            ok, detail, before_xml, after_xml = False, str(exc)[:160], "", ""
        dest = p._save(folder, "flg-location-out.xml", after_xml or "<proof/>")
        items.append(
            p._item(
                "Strip locations report selects a flagged location charge",
                ok,
                detail,
                [f"for-each from {p.KICKOUT}"],
                input=src or "sample XML",
                output=dest or "xsltproc stdout",
                input_text=sample,
                output_text=p._clip(after_xml or "<proof/>"),
                before=p._clip(before_xml or "<proof><rows>0</rows></proof>"),
                after=p._clip(after_xml or "<proof/>"),
            )
        )
    return items
