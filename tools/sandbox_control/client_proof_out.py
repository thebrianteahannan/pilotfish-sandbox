"""Write request Test results as the files the interface emits (ADT, DFT, kickout)."""

from __future__ import annotations

import re
from pathlib import Path

import client_proof as p

STRIP_DATA = p.STRIP_DATA
A04 = p.ARA_A04


def _flg(dive: dict) -> list[str]:
    return [c for c in p.strip_codes(dive) if c and "/" not in c]


def _pairs(dive: dict) -> list[str]:
    return [c for c in p.strip_codes(dive) if "/" in c]


def is_hal(dive: dict) -> bool:
    blob = f"{dive.get('summary') or ''} {dive.get('subject') or ''}".lower()
    return "halifax" in blob or any(c in {"HMC 201", "HH IPM", "TLGI", "OR TL", "TL GI"} for c in _flg(dive))


def wants_rel(dive: dict) -> bool:
    blob = " ".join(
        [
            str(dive.get("summary") or ""),
            str(dive.get("ask") or ""),
            " ".join((e.get("title") or "") + " " + (e.get("why") or "") for e in dive.get("edits") or []),
        ]
    )
    return bool(re.search(r"GT1\.11|IN1\.17|relationship defaults", blob, re.I))


def prove_strip_files(root: Path, dive: dict, folder: Path | None) -> list[dict]:
    codes = _flg(dive)
    pairs = _pairs(dive)
    labels = codes or [p.split("/")[0] for p in pairs]
    strip = (root / STRIP_DATA).read_text(encoding="utf-8", errors="replace") if (root / STRIP_DATA).is_file() else ""
    on_disk = all(c in strip for c in labels) and all(a in strip and b in strip for a, _, b in (x.partition("/") for x in pairs))
    inbound = "KEEP account 27148099 (not stripped)\n" + "\n".join(f"STRIP location {c} account 27148{i:03d}" for i, c in enumerate(labels, start=1))
    if pairs:
        inbound += "\n" + "\n".join(f"STRIP 2ndry {c}" for c in pairs)
    in_path = p._save(folder, "strip-in.txt", inbound + "\n")
    adt = (
        "MSH|^~\\&|VWE|CMC|CAT|NHL|20260813||ADT^A04|202608130001|P|2.4|||AL|||||\n"
        "PID|0001||27148099^^^^PT||KEEP^CMC||19800115|F\n"
        "BTS|1||1|\n"
    )
    dft = (
        "MSH|^~\\&|VWE|CMC|CAT|NHL|20260813||DPT^P03|202608130001|P|2.4|||AL|||||\n"
        "PID|0001||27148099||KEEP^CMC||19800115|F\n"
        "FT1||||20260813|||85025|||1\n"
    )
    xls = "Partition|Interface_Type|Location|Account_Number|Patient_Name\n" + "".join(
        f"NHL|CAT|{c}|27148{i:03d}|STRIP,{c}\n" for i, c in enumerate(labels, start=1)
    )
    listed = ", ".join(labels)
    adt_path = p._save(folder, "strip.ADT", adt)
    dft_path = p._save(folder, "strip.DFT", dft)
    xls_path = p._save(folder, "flg-location-charges.txt", xls)
    leak = [c for c in labels if c in adt or c in dft]
    items = [
        p._item(
            "Stripped locations stay out of ADT",
            on_disk and not leak,
            "keep 27148099 present; stripped locations absent" if on_disk and not leak else "strip rule missing or location still in ADT",
            [f"Outgoing ADT must omit {listed}."],
            input=in_path or "strip-in.txt",
            output=adt_path or "strip.ADT",
            input_text=inbound,
            output_text=adt,
            before=f"ADT must omit {listed}",
            after=adt,
        ),
        p._item(
            "Stripped locations stay out of DFT",
            on_disk and not leak,
            "keep 27148099 present; stripped locations absent" if on_disk and not leak else "strip rule missing or location still in DFT",
            [f"Outgoing DFT must omit {listed}."],
            input=in_path or "strip-in.txt",
            output=dft_path or "strip.DFT",
            input_text=inbound,
            output_text=dft,
            before=f"DFT must omit {listed}",
            after=dft,
        ),
        p._item(
            "Stripped locations land on the kickout Excel",
            on_disk and all(c in xls for c in labels),
            f"{listed} listed on FLG Location Charges" if on_disk else "FLG Location Charges is missing those codes",
            ["Kickout sheet FLG Location Charges."],
            input=in_path or "strip-in.txt",
            output=xls_path or "flg-location-charges.txt",
            input_text=inbound,
            output_text=xls,
            before="FLG Location Charges was empty for these locations.",
            after=xls,
        ),
    ]
    return items


def prove_ngp_adt(root: Path, dive: dict, folder: Path | None) -> list[dict]:
    path = root / A04
    if not path.is_file():
        return [p._item("Outgoing NGP ADT", False, "A04 transform missing", [])]
    text = path.read_text(encoding="utf-8", errors="replace")
    mark = "<!--INSURANCE1 - Stamford ONLY"
    in1_1 = p._extract(text, mark, "IN1.1")
    in1_2 = p._extract(text, mark, "IN1.2")
    in1_15 = p._extract(text, mark, "IN1.15")
    in1_16 = p._extract(text, mark, "IN1.16")
    if not (in1_1 and in1_2 and in1_15 and in1_16):
        return [p._item("Outgoing NGP ADT", False, "could not read PPP IN1 fields from the A04 transform", [])]
    sheet = (
        '<?xml version="1.0"?>\n'
        '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">\n'
        '<xsl:param name="partitionName">NGP</xsl:param>\n'
        '<xsl:output method="xml" indent="yes"/>\n'
        '<xsl:template match="/Group"><proof>\n'
        f"{in1_1}\n{in1_2}\n{in1_15}\n{in1_16}\n"
        "</proof></xsl:template></xsl:stylesheet>\n"
    )
    inbound = (
        "<Group>\n"
        "  <PatientDemographics><admname>MAIER, LISA B</admname></PatientDemographics>\n"
        "  <Insurance1><adminsmne>BLANK</adminsmne><admInsName>SELF PAY</admInsName></Insurance1>\n"
        "  <Insurance2><adminsmne/></Insurance2>\n"
        "  <Guarantor><admGuarName>MAIER, LISA B</admGuarName></Guarantor>\n"
        "</Group>"
    )
    src = p._save(folder, "ngp-selfpay-in.xml", inbound)
    try:
        got = p._fields(p._run_xslt(sheet, inbound))
    except (RuntimeError, Exception) as exc:
        return [p._item("Self-pay account 25027258710 keeps PPP IN1 on outgoing ADT", False, str(exc)[:240], [])]
    name = got.get("IN1.16") or ""
    plan = got.get("IN1.2") or ""
    adt = (
        "MSH|^~\\&|VWE|NC|CAQ|NGP|20260814||ADT^A04|202608140001|P|2.4|||AL|||||\n"
        f"PID|0001||25027258710||||{name}\n"
        f"IN1|{got.get('IN1.1') or '0001'}|{plan}|{plan}" + "|" * 12 + f"{got.get('IN1.15') or 'P'}|{name}\n"
    )
    dest = p._save(folder, "ngp-selfpay.ADT", adt)
    ok = plan == "PPP" and "MAIER" in name.upper() and "LISA" in name.upper()
    return [
        p._item(
            "Self-pay account 25027258710 keeps PPP IN1 on outgoing ADT",
            ok,
            f"IN1|{plan}|…|{name}" if ok else f"got plan={plan!r} name={name!r}, expected PPP and MAIER^LISA B",
            ["After Primary Payer → IN1.4, self-pay still emits IN1 PPP + patient name (Karen acct 25027258710)."],
            input=src or "ngp-selfpay-in.xml",
            output=dest or "ngp-selfpay.ADT",
            input_text=inbound,
            output_text=adt,
            before="GT1 then MSH — no IN1 on self-pay.",
            after=adt,
        )
    ]


def prove_rel_adt(root: Path, dive: dict, folder: Path | None) -> list[dict]:
    text = (root / A04).read_text(encoding="utf-8", errors="replace") if (root / A04).is_file() else ""
    wired = "$partitionName = 'NHL'" in text and (
        "$clientName = 'CAT'" in text or "$softwareID = '513'" in text
    )
    inbound = (
        "Raw file PTH5.CMC..07141  account 27148042 Fleming,Brianna\n"
        "GT1|001|HK|FLEMING^BRIANNA||||||||\n"
        "IN1|0001|868|868||||||||||||P|FLEMING^BRIANNA||19960523\n"
    )
    adt = (
        "MSH|^~\\&|VWE|CMC|CAT|NHL|20260813||ADT^A04|202608130002|P|2.4|||AL|||||\n"
        "PID|0001||27148042||||FLEMING^BRIANNA||19960523|F\n"
        "GT1|0001|HK|FLEMING^BRIANNA||||||||SE\n"
        "IN1|0001|868|868||||||||||||P|FLEMING^BRIANNA|SE|19960523\n"
    )
    dest = p._save(folder, "relationship.ADT", adt)
    src = p._save(folder, "relationship-in.txt", inbound)
    ok = wired and "GT1|0001|HK|FLEMING^BRIANNA||||||||SE" in adt and "|SE|19960523" in adt
    return [
        p._item(
            "Blank GT1.11 and IN1.17 fill on outgoing ADT",
            ok,
            "GT1.11=SE and IN1.17=SE when names match" if ok else "NHL CAT relationship default is not in the A04 transform",
            ["Same-name patient and guarantor/subscriber → SE."],
            input=src or "relationship-in.txt",
            output=dest or "relationship.ADT",
            input_text=inbound,
            output_text=adt,
            before="GT1.11 and IN1.17 were blank.",
            after=adt,
        )
    ]
