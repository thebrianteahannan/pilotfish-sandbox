"""Drop Halifax files through EIP and prove the real ADT, DFT, and kickout Excel."""

from __future__ import annotations

import re
import shutil
import time
from pathlib import Path
from xml.etree import ElementTree as ET

import client_proof as p
import clients

KEEP = ("9000001999", "KEEP,HMC", "HMC")
CHARGE_HEAD = (
    "HSP_CSN|HSP_ACCOUNT_NAME|CPT_Code|QUANTITY|PROC_CODE (CDM)|SERVICE_DATE|"
    "PATH_NPI|PATH_NAME|IS_LATE_CHARGE|RESULT_DX|UCLID"
)
WAIT_SEC = 240


def _demo_head() -> str:
    sample = (
        clients.ROOT
        / "Clients/Med Rec/data/Karen-Requests-Aug7th2026/New mapping/Halifax/"
        "mock-hax-mis-split/MedReceivables_Demographic_20260807_MockLocCrosswalk.txt"
    )
    if sample.is_file():
        return sample.read_text(encoding="utf-8", errors="replace").splitlines()[0]
    return (
        "HSP_CSN|ADM_DATE|DISCH_DATE_TIME|ACCT_FIN_CLASS|HSP_ACCOUNT_NAME|Pat_SSN|"
        "Pat_Sex|Pat_Race|Pat_DOB|Pat_Marital_Stat|Pat_Street|Pat_Street_2|Pat_City|"
        "Pat_State|Pat_Zip|Pat_Home_Phone|PAT_CLASS_ID|Pat_Class|LOCATION_ABBR|"
        "Guar_Name|GUAR_REL_TO_PAT_ID|Guar_Relation|Guar_Street|Guar_Street_2|"
        "Guar_City|Guar_State|Guar_Zip|Guar_Home_Phone|Guar_DOB|Guar_SSN|"
        "PRIMARY_PAYOR_ID|PRIM_PAYOR_NAME|PRIMARY_PLAN_ID|PRIM_COV_SUBSCR_NAME|"
        "PRIM_COV_SUBSCR_DOB|PRIM_COV_SUBSCR_GENDER|PRIM_COV_REL_TO_SUB_ID|"
        "PRIM_COV_REL_TO_SUB|PRIM_COV_SUBSCR_ADDRESS|PRIM_COV_SUBSCR_CITY|"
        "PRIM_COV_SUBSCR_STATE|PRIM_COV_SUBSCR_ZIP|PRIM_COV_SUBSCR_POLICY_NUM|"
        "PRIM_COV_GROUP_NUM|Prim_Cov_Street|Prim_Cov_City|Prim_Cov_State|"
        "Prim_Cov_Zip|Prim_Cov_Phone|SEC_PAYOR_ID|SEC_PAYOR_NAME|SEC_PLAN_ID|"
        "SEC_COV_SUBSCR_NAME|SEC_COV_SUBSCR_DOB|SEC_COV_SUBSCR_GENDER|"
        "SEC_COV_REL_TO_SUB_ID|SEC_COV_REL_TO_SUB|SEC_COV_SUBSCR_ADDRESS|"
        "SEC_COV_SUBSCR_CITY|SEC_COV_SUBSCR_STATE|SEC_COV_SUBSCR_ZIP|"
        "SEC_COV_SUBSCR_NUM|SEC_COV_GROUP_NUM|Sec_Cov_Street|Sec_Cov_City|"
        "Sec_Cov_State|Sec_Cov_Zip|Sec_Cov_Phone|ADM_PROV_NPI|Admit_Prov_Name|"
        "ATTENDING_PROV_NPI|Attend_Prov_Name|REFERRING_PROV_NPI|Referring_Prov_Name|"
        "PRIM_DIAGNOSIS_CODE|SECONDARY DIAG CODE 1|SECONDARY DIAG CODE 2|"
        "SECONDARY DIAG CODE 3|SECONDARY DIAG CODE 4|SECONDARY DIAG CODE 5|"
        "SECONDARY DIAG CODE 6|SECONDARY DIAG CODE 7|SECONDARY DIAG CODE 8|"
        "DEPARTMENT_ABBR|AUTHORIZATION NUMBER"
    )


def _row(head: str, values: dict[str, str]) -> str:
    return "|".join(values.get(col, "") for col in head.split("|"))


def _demo_row(head: str, acct: str, name: str, loc: str) -> str:
    return _row(
        head,
        {
            "HSP_CSN": acct,
            "ADM_DATE": "08/13/2026",
            "DISCH_DATE_TIME": "08/13/2026",
            "HSP_ACCOUNT_NAME": name,
            "Pat_SSN": "000-00-" + acct[-4:],
            "Pat_Sex": "Female",
            "Pat_Race": "White",
            "Pat_DOB": "01/15/1980",
            "Pat_Marital_Stat": "Married",
            "Pat_Street": "101 PROOF STREET",
            "Pat_City": "DAYTONA BEACH",
            "Pat_State": "FL",
            "Pat_Zip": "32114",
            "Pat_Home_Phone": "3865550100",
            "LOCATION_ABBR": loc,
            "Guar_Name": name,
            "Guar_Relation": "Self",
            "PRIM_PAYOR_NAME": "MOCK PAYOR",
            "PRIMARY_PLAN_ID": "MOCKPLAN",
            "PRIM_COV_SUBSCR_NAME": name,
            "PRIM_DIAGNOSIS_CODE": "R69",
            "DEPARTMENT_ABBR": "HMC LAB",
        },
    )


def _charge_row(acct: str, name: str, i: int) -> str:
    return _row(
        CHARGE_HEAD,
        {
            "HSP_CSN": acct,
            "HSP_ACCOUNT_NAME": name,
            "CPT_Code": "85025",
            "QUANTITY": "1.00",
            "PROC_CODE (CDM)": "3018502501",
            "SERVICE_DATE": "08/13/2026",
            "IS_LATE_CHARGE": "0",
            "UCLID": str(1700000 + i),
        },
    )


def _has(blob: bytes | str, token: str) -> bool:
    if not token:
        return False
    if isinstance(blob, str):
        return token in blob
    raw = blob
    return token.encode("ascii", "ignore") in raw or token.encode("utf-16le") in raw


def _newer(folder: Path, pattern: str, since: float) -> Path | None:
    hits = [f for f in folder.glob(pattern) if f.is_file() and f.stat().st_mtime >= since - 1]
    return max(hits, key=lambda f: f.stat().st_mtime) if hits else None


def _copy(folder: Path | None, src: Path, name: str = "") -> str:
    if folder is None or not src.is_file():
        return ""
    dest = folder / "proof"
    dest.mkdir(exist_ok=True)
    raw = name or src.name
    stem, ext = Path(raw).stem, Path(raw).suffix
    safe = re.sub(r"[^a-zA-Z0-9._-]+", "-", stem).strip("-")[:60] + ext
    target = dest / safe
    shutil.copy2(src, target)
    return f"proof/{target.name}"


def _flg_text(xml_path: Path | None, xls_path: Path | None, codes: list[str]) -> str:
    lines = ["Partition|Interface_Type|Location|Account_Number|Patient_Name"]
    if xml_path and xml_path.is_file():
        try:
            root = ET.fromstring(xml_path.read_text(encoding="utf-8", errors="replace"))
        except ET.ParseError:
            root = None
        if root is not None:
            for charge in root.findall(".//StrippedCharges/Charge"):
                if charge.get("stripped_flagged_locations") != "true":
                    continue
                demo = charge.find("PatientDemographics")
                if demo is None:
                    continue
                loc = (demo.findtext("admLocationAbbr") or demo.findtext("admLocation") or "").strip()
                acct = (demo.findtext("admAcctNum") or "").strip()
                name = (demo.findtext("admname") or "").strip()
                lines.append(f"HAL|HAX|{loc}|{acct}|{name}")
    if len(lines) == 1 and xls_path and xls_path.is_file():
        raw = xls_path.read_bytes()
        found = [c for c in codes if _has(raw, c)]
        lines.append("Found in kickout Excel: " + (", ".join(found) if found else "(none)"))
    return "\n".join(lines) + "\n"


def _wait(out: Path, since: float) -> tuple[Path | None, Path | None, Path | None, Path | None]:
    adt = dft = xls = xml = None
    deadline = time.time() + WAIT_SEC
    while time.time() < deadline:
        adt = adt or _newer(out, "HAX*a.ADT", since)
        dft = dft or _newer(out, "HAX*d.DFT", since)
        xls = xls or _newer(out, "*StrippingAndTweaking*.xls", since)
        xml = xml or _newer(out, "*StrippingAndTweaking_[0-9]*.xml", since)
        if adt and dft and xls:
            time.sleep(1)
            break
        time.sleep(2)
    return adt, dft, xls, xml


def _hl7_check(text: str, keep: str, strip_accts: list[str]) -> tuple[bool, str]:
    if not text.strip():
        return False, "file is empty"
    if keep not in text:
        return False, f"keep account {keep} is missing"
    hit = [a for a in strip_accts if a in text]
    if hit:
        return False, f"stripped account(s) still present: {', '.join(hit)}"
    return True, f"keep {keep} present; stripped accounts absent"


def prove_live_strip(root: Path, dive: dict, folder: Path | None = None) -> list[dict]:
    codes = p.strip_codes(dive)
    if not codes:
        return [p._item("Live Halifax strip", False, "no location codes on the request", [])]
    incoming = clients.ROOT / "data" / "in"
    outgoing = clients.ROOT / "data" / "out"
    incoming.mkdir(parents=True, exist_ok=True)
    outgoing.mkdir(parents=True, exist_ok=True)
    head = _demo_head()
    rows = [KEEP] + [(f"9000002{i:03d}", f"STRIP,{code}", code) for i, code in enumerate(codes, start=1)]
    demo_body = head + "\n" + "\n".join(_demo_row(head, a, n, loc) for a, n, loc in rows) + "\n"
    charge_body = CHARGE_HEAD + "\n" + "\n".join(_charge_row(a, n, i) for i, (a, n, _loc) in enumerate(rows, start=1)) + "\n"
    stamp = time.strftime("%Y%m%d_%H%M%S")
    charge_name = f"MedReceivables_Charges_{stamp}_StripProof.txt"
    demo_name = f"MedReceivables_Demographic_{stamp}_StripProof.txt"
    in_label = p._save(folder, charge_name, charge_body)
    p._save(folder, demo_name, demo_body)
    incoming_text = f"{demo_name}\n{demo_body}\n{charge_name}\n{charge_body}"
    since = time.time()
    (incoming / demo_name).write_text(demo_body, encoding="utf-8")
    (incoming / charge_name).write_text(charge_body, encoding="utf-8")
    adt, dft, xls, xml = _wait(outgoing, since)
    strip_accts = [a for a, _n, _loc in rows[1:]]
    keep_acct = KEEP[0]
    items = []
    for kind, path, ext in (("ADT", adt, "ADT"), ("DFT", dft, "DFT")):
        label = _copy(folder, path, path.name) if path else f"(no {ext} written)"
        text = path.read_text(encoding="utf-8", errors="replace") if path and path.is_file() else ""
        ok, detail = _hl7_check(text, keep_acct, strip_accts) if text else (False, f"EIP did not write HAX*.{ext} within {WAIT_SEC}s")
        items.append(
            p._item(
                f"Stripped Halifax locations stay out of {ext}",
                ok,
                detail,
                [f"Dropped {charge_name} + {demo_name} into data/in"],
                input=in_label or charge_name,
                output=label,
                input_text=incoming_text,
                output_text=p._clip(text, 2000),
                before=f"{ext} must omit {', '.join(codes)}",
                after=p._clip(text, 900),
            )
        )
    xls_label = _copy(folder, xls, "StrippingAndTweaking.xls") if xls else "(no kickout Excel written)"
    if xml:
        _copy(folder, xml, xml.name)
    flg = _flg_text(xml, xls, codes)
    xls_ok = bool(xls and xls.is_file())
    missing = [c for c in codes if not (_has(xls.read_bytes() if xls and xls.is_file() else b"", c) or c in flg)]
    if not xls_ok:
        x_detail = f"EIP did not write *StrippingAndTweaking*.xls within {WAIT_SEC}s"
        xls_ok = False
    elif missing:
        x_detail = f"missing from kickout Excel: {', '.join(missing)}"
        xls_ok = False
    else:
        x_detail = f"{', '.join(codes)} listed on FLG Location Charges"
    items.append(
        p._item(
            "Stripped Halifax locations land on the kickout Excel",
            xls_ok,
            x_detail,
            [f"Dropped {charge_name} + {demo_name} into data/in"],
            input=in_label or charge_name,
            output=xls_label,
            input_text=incoming_text,
            output_text=flg,
            before="FLG Location Charges was empty for these Halifax locations.",
            after=flg,
        )
    )
    return items
