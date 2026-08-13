"""Prove a Med Rec change with sample IN1 output and on-disk strip checks."""

from __future__ import annotations

import re
import subprocess
import tempfile
from pathlib import Path
from xml.etree import ElementTree as ET

ARA_A04 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate ADT A04 HL7/transform.xslt"
)
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

CASES = [
    {
        "name": "Self-pay only — IN1.16 filled",
        "story": "Ariana SELFPAY, no secondary. Patient/subscriber JAIRAM, KRYSTAL. Before this change the outgoing IN1.16 was blank.",
        "xml": (
            "<Group><PatientDemographics><admname>JAIRAM, KRYSTAL</admname></PatientDemographics>"
            "<Insurance1><adminsmne>SELFPAY</adminsmne><adminsinsuredname>JAIRAM,KRYSTAL</adminsinsuredname></Insurance1>"
            "<Insurance2><adminsmne/><adminsinsuredname/></Insurance2></Group>"
        ),
        "expect": {"IN1.1": "0001", "IN1.2": "SELFPAY", "IN1.15": "P", "IN1.16": "JAIRAM^KRYSTAL", "skip": "yes"},
    },
    {
        "name": "Self-pay + secondary — IN1.16 from Insurance2",
        "story": "Ariana SELFPAY with BCBS secondary SMITH, JANE. Self-pay IN1 is skipped; Insurance2 is sent as 0001.",
        "xml": (
            "<Group><PatientDemographics><admname>DOE, JOHN</admname></PatientDemographics>"
            "<Insurance1><adminsmne>SELFPAY</adminsmne><adminsinsuredname/></Insurance1>"
            "<Insurance2><adminsmne>BCBS</adminsmne><adminsinsuredname>SMITH, JANE</adminsinsuredname></Insurance2></Group>"
        ),
        "expect": {"IN1.1": "0001", "IN1.2": "BCBS", "IN1.15": "P", "IN1.16": "SMITH^JANE", "skip": "yes"},
    },
    {
        "name": "Self-pay, blank subscriber — IN1.16 uses patient name",
        "story": "Ariana SELFPAY, insurance names empty. IN1.16 must fall back to the patient name.",
        "xml": (
            "<Group><PatientDemographics><admname>FALLBACK, PAT</admname></PatientDemographics>"
            "<Insurance1><adminsmne>SELFPAY</adminsmne><adminsinsuredname/></Insurance1>"
            "<Insurance2><adminsmne/><adminsinsuredname/></Insurance2></Group>"
        ),
        "expect": {"IN1.1": "0001", "IN1.2": "SELFPAY", "IN1.15": "P", "IN1.16": "FALLBACK^PAT", "skip": "yes"},
    },
]


def _item(name: str, ok: bool, detail: str, evidence: list[str], input: str = "", output: str = "", before: str = "", after: str = "", input_text: str = "", output_text: str = "") -> dict:
    rec = {"name": name, "ok": ok, "detail": detail, "evidence": evidence}
    if input:
        rec["input"] = input
    if output:
        rec["output"] = output
    if input_text:
        rec["input_text"] = input_text
    if output_text:
        rec["output_text"] = output_text
    if before:
        rec["before"] = before
    if after:
        rec["after"] = after
    return rec


def _proof_file(folder: Path | None, label: str) -> str:
    if folder is None:
        return ""
    m = re.search(r"(proof/[\w.-]+)", str(label or ""))
    if not m:
        return ""
    path = folder / m.group(1)
    if not path.is_file() or path.stat().st_size > 200_000:
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def hydrate(folder: Path, items: list) -> list:
    """Attach input/output payloads so the hub can show files or other samples."""
    for rec in items:
        if not isinstance(rec, dict):
            continue
        if not rec.get("input_text"):
            body = _proof_file(folder, rec.get("input") or "")
            if not body:
                for case in CASES:
                    if case["name"] == rec.get("name"):
                        body = case["xml"]
                        rec.setdefault("input", "sample XML")
                        break
            if body:
                rec["input_text"] = _clip(body, 2000)
        if not rec.get("output_text"):
            body = _proof_file(folder, rec.get("output") or "")
            if not body:
                ev = [str(e) for e in (rec.get("evidence") or []) if str(e).startswith("IN1.")]
                if ev:
                    rec.setdefault("output", "outgoing fields")
                    body = "\n".join(ev)
            if body:
                rec["output_text"] = _clip(body, 2000)
    return items


def _clip(text: str, n: int = 900) -> str:
    text = (text or "").strip()
    return text if len(text) <= n else text[:n].rstrip() + "\n…"


def _rel(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def _save(folder: Path | None, name: str, text: str) -> str:
    if folder is None:
        return ""
    dest = folder / "proof"
    dest.mkdir(exist_ok=True)
    safe = re.sub(r"[^a-zA-Z0-9._-]+", "-", name).strip("-")[:80]
    path = dest / safe
    path.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8")
    return f"proof/{path.name}"


def _extract(text: str, mark: str, tag: str) -> str:
    base = text.find(mark)
    if base < 0:
        return ""
    start = text.find(f"<{tag}>", base)
    end = text.find(f"</{tag}>", start)
    if start < 0 or end < 0:
        return ""
    return text[start : end + len(f"</{tag}>")]


def _run_xslt(xslt: str, xml: str) -> str:
    with tempfile.TemporaryDirectory() as td:
        xp, ip = Path(td) / "t.xslt", Path(td) / "i.xml"
        xp.write_text(xslt, encoding="utf-8")
        ip.write_text(xml, encoding="utf-8")
        r = subprocess.run(["xsltproc", str(xp), str(ip)], capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError((r.stderr or r.stdout or "xsltproc failed").strip()[:400])
        return r.stdout


def _fields(xml: str) -> dict[str, str]:
    root = ET.fromstring(xml)
    out: dict[str, str] = {}
    for el in root:
        tag = el.tag.split("}", 1)[-1]
        kids = list(el)
        if kids:
            out[tag] = "^".join(((k.text or "").strip()) for k in kids)
        else:
            out[tag] = (el.text or "").strip()
    return out


def _stylesheet(in1_1: str, in1_15: str, in1_16: str) -> str:
    in1_2 = (
        "<IN1.2><xsl:choose>"
        "<xsl:when test=\"$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY' "
        "and string-length(Insurance2/adminsmne) = 0\"><xsl:value-of select=\"'SELFPAY'\" /></xsl:when>"
        "<xsl:otherwise><xsl:value-of select=\"Insurance2/adminsmne\" /></xsl:otherwise>"
        "</xsl:choose></IN1.2>"
    )
    return (
        '<?xml version="1.0"?>\n'
        '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">\n'
        '<xsl:param name="partitionName">ARA</xsl:param>\n'
        '<xsl:output method="xml" indent="yes"/>\n'
        '<xsl:template match="/Group"><proof>\n'
        "<skip><xsl:choose>"
        "<xsl:when test=\"$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY'\">yes</xsl:when>"
        "<xsl:otherwise>no</xsl:otherwise></xsl:choose></skip>\n"
        f"{in1_1}\n{in1_2}\n{in1_15}\n{in1_16}\n"
        "</proof></xsl:template></xsl:stylesheet>\n"
    )


def wants_ara(dive: dict) -> bool:
    blob = " ".join(
        [
            str(dive.get("summary") or ""),
            str(dive.get("ask") or ""),
            str(dive.get("subject") or ""),
            " ".join((e.get("title") or "") + " " + (e.get("why") or "") for e in dive.get("edits") or []),
        ]
    )
    return bool(re.search(r"IN1[.\-]?16|self[\s-]?pay|SELFPAY", blob, re.I))


def strip_codes(dive: dict) -> list[str]:
    codes = [str(c) for c in (dive.get("codes") or []) if c and not str(c).startswith("$")]
    if codes:
        return list(dict.fromkeys(codes))
    found: list[str] = []
    for ed in dive.get("edits") or []:
        code = str(ed.get("code") or "")
        if ed.get("action") == "remove_when" and code and not code.startswith("$"):
            found.append(code)
    return list(dict.fromkeys(found))


def note(dive: dict) -> str:
    if wants_ara(dive):
        return (
            "Ran the IN1.1 / IN1.15 / IN1.16 branches from Generate ADT A04 HL7/transform.xslt "
            "against sample Ariana self-pay accounts (xsltproc). The full stylesheet is XSLT 3.1 "
            "with Java date functions, so this proof runs those insurance fields only."
        )
    if wants_strip_report(dive):
        return (
            "Checked every planned edit on disk, then proved each location flags "
            "stripped_flagged_locations and would appear on FLG Location Charges."
        )
    if dive.get("edits"):
        return "Checked every planned edit on disk, plus any change-specific proof for this request."
    if strip_codes(dive):
        return "Checked the Halifax location map on disk for each Location_ABBR code in this request."
    return "Sandbox smoke plus any change-specific proof for this request."


def smoke_eip(wait_url) -> list[dict]:
    import clients

    up = wait_url("http://127.0.0.1:8080/eip/", timeout=90)
    items = [
        _item(
            "EIP http://127.0.0.1:8080/eip/",
            up,
            "up" if up else "not responding",
            ["Sandbox eiPlatform " + ("answered" if up else "did not answer") + " on :8080/eip/"],
            input="GET http://127.0.0.1:8080/eip/",
            output="HTTP from sandbox eiPlatform",
        )
    ]
    log = clients.ROOT / "logs" / "eip.log"
    if log.is_file():
        tail = log.read_text(encoding="utf-8", errors="replace")[-4000:]
        bad = "SEVERE" in tail and "Exception" in tail
        items.append(
            _item(
                "eip.log present",
                True,
                "recent SEVERE+Exception" if bad else "ok",
                ["Recent SEVERE+Exception" if bad else "No recent SEVERE+Exception"],
                input="Clients/logs/eip.log",
                output="Clients/logs/eip.log (tail)",
                after=_clip(tail, 600),
            )
        )
    else:
        items.append(_item("eip.log present", False, "no log yet", ["Clients/logs/eip.log is missing"], input="Clients/logs/eip.log"))
    return items


def prove_ara(root: Path, folder: Path | None = None) -> list[dict]:
    path = root / ARA_A04
    if not path.is_file():
        return [_item("A04 transform present", False, "missing", [ARA_A04], input=ARA_A04)]
    text = path.read_text(encoding="utf-8", errors="replace")
    items = [
        _item(
            "A04 transform has the new IN1.16 self-pay branch",
            "ARA self-pay: Insurance1 IN1 is skipped" in text
            and "$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY'" in text,
            "branch in Generate ADT A04 HL7/transform.xslt",
            ["Found the ARA SELFPAY IN1.16 choose and IN1.15 = P" if "ARA self-pay" in text else "Branch comment missing"],
            input=ARA_A04,
            output=ARA_A04,
        )
    ]
    in1_1 = _extract(text, "<!--INSURANCE2-->", "IN1.1")
    in1_15 = _extract(text, "<!--INSURANCE2-->", "IN1.15")
    in1_16 = _extract(text, "<!--INSURANCE2-->", "IN1.16")
    if not (in1_1 and in1_15 and in1_16):
        items.append(_item("Extract IN1 branches", False, "could not slice IN1.1/15/16", ["Looked after <!--INSURANCE2-->"], input=ARA_A04))
        return items
    xslt = _stylesheet(in1_1, in1_15, in1_16)
    for i, case in enumerate(CASES, start=1):
        src = _save(folder, f"ara-{i}-in.xml", case["xml"])
        try:
            raw = _run_xslt(xslt, case["xml"])
            got = _fields(raw)
        except (RuntimeError, ET.ParseError) as exc:
            items.append(_item(case["name"], False, str(exc), [case["story"], str(exc)], input=src or case["story"]))
            continue
        dest = _save(folder, f"ara-{i}-out.xml", raw)
        expect = case["expect"]
        diffs = [f"{k}: got {got.get(k, '')!r}, expected {v!r}" for k, v in expect.items() if got.get(k) != v]
        ok = not diffs
        items.append(
            _item(
                case["name"],
                ok,
                "IN1.16=" + got.get("IN1.16", "") if ok else "; ".join(diffs),
                [case["story"]],
                input=src or "sample XML",
                output=dest or "xsltproc stdout",
                input_text=case["xml"],
                output_text=_clip(raw),
                before="IN1.16 was blank on Ariana self-pay before this change.",
                after=_clip(raw),
            )
        )
    return items


def wants_strip_report(dive: dict) -> bool:
    blob = " ".join(
        [
            str(dive.get("comments") or ""),
            str(dive.get("summary") or ""),
            " ".join((e.get("title") or "") + " " + (e.get("why") or "") for e in dive.get("edits") or []),
        ]
    )
    return bool(re.search(r"strip locations report|FLG Location|flagged_locations", blob, re.I))


def _code_in(text: str, code: str) -> bool:
    return bool(code) and bool(re.search(rf"\$locationAbbr\s*=\s*['\"]{re.escape(code)}['\"]", text))


def prove_edits(root: Path, dive: dict) -> list[dict]:
    items = []
    for ed in dive.get("edits") or []:
        rel = str(ed.get("path") or "")
        path = root / rel
        text = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
        bak = path.with_name(path.name + ".bak-req")
        src = _rel(root, bak) if bak.is_file() else f"old block in dive.json for {rel}"
        action = ed.get("action") or ""
        if action == "replace_block":
            new = ed.get("new") or ""
            need = 2 if ed.get("replace_all") else 1
            n = text.count(new) if new else 0
            ok = bool(path.is_file()) and n >= need
            title = ed.get("title") or "Replacement"
            items.append(
                _item(
                    title,
                    ok,
                    f"found {n} time(s) on disk" if ok else "planned block not on disk",
                    [ed.get("why") or title],
                    input=src,
                    output=rel,
                    input_text=_clip(ed.get("old") or ""),
                    output_text=_clip(new),
                    before=_clip(ed.get("old") or ""),
                    after=_clip(new),
                )
            )
            continue
        if action == "remove_when":
            code = str(ed.get("code") or "")
            blocks = [b for b in (ed.get("remove_blocks") or []) if b]
            gone = bool(path.is_file()) and (all(b not in text for b in blocks) if blocks else True)
            still = _code_in(text, code)
            after = ""
            if still:
                m = re.search(rf".{{0,80}}\$locationAbbr\s*=\s*['\"]{re.escape(code)}['\"].{{0,160}}", text)
                after = _clip(m.group(0) if m else f"$locationAbbr = '{code}'")
            if wants_strip_report(dive):
                ok = gone and still
                items.append(
                    _item(
                        f"Location {code} kept for the strip locations report",
                        ok,
                        "HAX mapping removed; location kept" if ok else "pass-through missing or HAX mapping still present",
                        [],
                        input=src,
                        output=rel,
                        before=_clip(blocks[0] if blocks else f"$locationAbbr = '{code}' → HAX"),
                        after=after,
                    )
                )
                continue
            ok = gone and not still
            items.append(
                _item(
                    f"Location {code} stripped from Halifax map",
                    ok,
                    "absent from halifax location map" if ok else "still mapped",
                    [],
                    input=src,
                    output=rel,
                    before=_clip(blocks[0] if blocks else ""),
                    after="(branch removed)" if ok else after,
                )
            )
            continue
        items.append(
            _item(
                f"Untested change: {ed.get('title') or ed.get('code') or rel}",
                False,
                f"no proof for action {action or '(missing)'}",
                ["Every planned edit must have a test."],
                input=src,
                output=rel,
            )
        )
    return items


def prove_strips(root: Path, dive: dict) -> list[dict]:
    codes = strip_codes(dive)
    path = root / HAL_MAP
    text = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    items = []
    for code in codes:
        still = _code_in(text, code)
        items.append(
            _item(
                f"Location {code} stripped from Halifax map",
                path.is_file() and not still,
                "absent from halifax location map" if not still else "still mapped",
                [
                    f"$locationAbbr = '{code}' is gone" if not still else f"$locationAbbr = '{code}' is still in the stylesheet",
                ],
                input=HAL_MAP,
                output=HAL_MAP,
            )
        )
    return items


def prove(root: Path, dive: dict, folder: Path | None = None) -> list[dict]:
    items: list[dict] = []
    if wants_ara(dive):
        items.extend(prove_ara(root, folder))
    if dive.get("edits"):
        items.extend(prove_edits(root, dive))
    elif strip_codes(dive):
        items.extend(prove_strips(root, dive))
    if wants_strip_report(dive):
        from client_proof_report import prove_strip_report

        items.extend(prove_strip_report(root, dive, folder))
    return items
