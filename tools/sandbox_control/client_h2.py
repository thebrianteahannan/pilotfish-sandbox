"""Read-only viewer for the Med Rec H2 config database."""

from __future__ import annotations

import csv
import re
import subprocess
import tempfile
from pathlib import Path

import clients

JAR = Path(__file__).resolve().parent / ".h2-2.1.214.jar"
IMAGE = "pilotfish-eip:23R1"
JAR_IN = "/usr/local/tomcat/webapps/eip/WEB-INF/lib/h2-2.1.214.jar"
SEED = Path("database") / "medreceivables.mv.db"
LIVE = Path("data") / "database" / "medreceivables.mv.db"
TABLE_OK = re.compile(r"^[A-Z][A-Z0-9_]{0,63}$")
RAW_CAP = 400


def _db_file(root: Path) -> Path:
    return (root / SEED).resolve()


def _db_file_live(root: Path) -> Path:
    live = (root / LIVE).resolve()
    return live if live.is_file() else _db_file(root)


def _ensure_jar() -> Path:
    if JAR.is_file() and JAR.stat().st_size > 10000:
        return JAR
    cid = subprocess.run(["docker", "create", IMAGE], capture_output=True, text=True, timeout=60)
    if cid.returncode != 0:
        raise RuntimeError((cid.stderr or cid.stdout or "Need image pilotfish-eip:23R1 for the H2 driver").strip()[:300])
    name = cid.stdout.strip()
    try:
        JAR.parent.mkdir(parents=True, exist_ok=True)
        cp = subprocess.run(["docker", "cp", f"{name}:{JAR_IN}", str(JAR)], capture_output=True, text=True, timeout=30)
        if cp.returncode != 0 or not JAR.is_file():
            raise RuntimeError("Could not copy H2 driver from the 23R1 image")
    finally:
        subprocess.run(["docker", "rm", name], capture_output=True, timeout=20)
    return JAR


def _url(db: Path) -> str:
    stem = str(db).removesuffix(".mv.db").removesuffix(".h2.db")
    return f"jdbc:h2:file:{stem};ACCESS_MODE_DATA=r;IFEXISTS=TRUE;FILE_LOCK=NO"


def _sql(db: Path, sql: str) -> str:
    jar = _ensure_jar()
    proc = subprocess.run(
        [
            "java",
            "-cp",
            str(jar),
            "org.h2.tools.Shell",
            "-url",
            _url(db),
            "-user",
            "sa",
            "-password",
            "",
            "-sql",
            sql,
        ],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "H2 query failed").strip()[:400])
    return proc.stdout or ""


def _rows(db: Path, select_sql: str) -> list[dict]:
    with tempfile.NamedTemporaryFile(suffix=".csv", delete=False) as tmp:
        out = Path(tmp.name)
    try:
        inner = select_sql.replace("'", "''")
        _sql(db, f"CALL CSVWRITE('{out.as_posix()}', '{inner}')")
        with out.open(newline="", encoding="utf-8") as fh:
            return list(csv.DictReader(fh))
    finally:
        out.unlink(missing_ok=True)


def _tables(db: Path) -> list[str]:
    rows = _rows(db, "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='PUBLIC' ORDER BY TABLE_NAME")
    names = [r.get("TABLE_NAME") or r.get("table_name") or "" for r in rows]
    return [n for n in names if TABLE_OK.match(n)]


def _count(db: Path, table: str) -> int:
    rows = _rows(db, f"SELECT COUNT(*) AS C FROM {table}")
    if not rows:
        return 0
    return int(list(rows[0].values())[0] or 0)


def _by(rows: list[dict], key: str) -> dict[str, list[dict]]:
    out: dict[str, list[dict]] = {}
    for row in rows:
        k = str(row.get(key) or "").strip()
        out.setdefault(k, []).append(row)
    return out


def snapshot(slug: str) -> dict:
    if clients.slug_for(clients.require_root(slug).name) != "med-rec":
        raise ValueError("H2 viewer is only for Med Rec")
    root = clients.require_root(slug)
    db = _db_file(root)
    if not db.is_file():
        return {"ok": False, "error": f"Missing {SEED.as_posix()}", "tables": [], "clients": []}
    names = _tables(db)
    counts = {n: 0 for n in names}
    try:
        for rec in _rows(db, "SELECT TABLE_NAME, ROW_COUNT_ESTIMATE AS C FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='PUBLIC'"):
            n = rec.get("TABLE_NAME") or ""
            if n in counts:
                counts[n] = int(rec.get("C") or 0)
    except RuntimeError:
        for n in names:
            counts[n] = _count(db, n)
    tables = [{"name": n, "count": counts[n]} for n in names]
    splits = _rows(db, "SELECT * FROM CLIENT_SPLITS ORDER BY CLIENTNAME, PARTITION, CLIENT, FACILITY") if "CLIENT_SPLITS" in names else []
    codes = _by(_rows(db, "SELECT * FROM CLIENT_CODES") if "CLIENT_CODES" in names else [], "SOFTWARE_ID")
    strips = _by(_rows(db, "SELECT * FROM STRIP_LOCATIONS") if "STRIP_LOCATIONS" in names else [], "SOFTWARE_ID")
    srules = _rows(db, "SELECT * FROM STRIPPING_RULES") if "STRIPPING_RULES" in names else []
    trules = _rows(db, "SELECT * FROM TWEAKING_RULES") if "TWEAKING_RULES" in names else []
    flg_n = _by(_rows(db, "SELECT SOFTWARE_ID, COUNT(*) AS C FROM FLG_LOCATIONS GROUP BY SOFTWARE_ID") if "FLG_LOCATIONS" in names else [], "SOFTWARE_ID")
    mue_n = _by(_rows(db, "SELECT SOFTWARE_ID, COUNT(*) AS C FROM MUE_EDITS GROUP BY SOFTWARE_ID") if "MUE_EDITS" in names else [], "SOFTWARE_ID")
    grouped: dict[str, dict] = {}
    for row in splits:
        sid = str(row.get("SOFTWAREID") or "").strip()
        part = str(row.get("PARTITION") or "").strip()
        cli = str(row.get("CLIENT") or "").strip()
        key = f"{sid}|{part}|{cli}"
        rec = grouped.get(key)
        if not rec:
            rec = {
                "id": key,
                "software_id": sid,
                "name": str(row.get("CLIENTNAME") or "").strip(),
                "partition": part,
                "client": cli,
                "facilities": [],
                "codes": codes.get(sid, []),
                "strip_locations": strips.get(sid, []),
                "stripping_rules": [r for r in srules if str(r.get("PARTITION")) == part and str(r.get("CLIENT")) == cli],
                "tweaking_rules": [r for r in trules if str(r.get("PARTITION")) == part and str(r.get("CLIENT")) == cli],
                "flg_count": int((flg_n.get(sid) or [{}])[0].get("C") or 0),
                "mue_count": int((mue_n.get(sid) or [{}])[0].get("C") or 0),
            }
            grouped[key] = rec
        rec["facilities"].append(row)
        if row.get("CLIENTNAME") and not rec["name"]:
            rec["name"] = str(row.get("CLIENTNAME")).strip()
    clients_out = sorted(grouped.values(), key=lambda r: ((r.get("name") or "").lower(), r.get("partition") or "", r.get("client") or ""))
    try:
        import client_regression

        cases = client_regression.catalog(root)
        for rec in clients_out:
            rec["regression"] = client_regression.match_h2_client(cases, rec)
    except Exception:
        for rec in clients_out:
            rec.setdefault("regression", [])
    shared = {
        "er_ins_plan_codes": _rows(db, "SELECT * FROM ER_INS_PLAN_CODES ORDER BY CODE") if "ER_INS_PLAN_CODES" in names else [],
        "strip_performing_sites": _rows(db, "SELECT * FROM STRIP_PERFORMING_SITES ORDER BY MNEMONIC") if "STRIP_PERFORMING_SITES" in names else [],
        "bad_group_nums": _rows(db, "SELECT * FROM BAD_GROUP_NUMS") if "BAD_GROUP_NUMS" in names else [],
        "bad_secondary_insurances": _rows(db, "SELECT * FROM BAD_SECONDARY_INSURANCES") if "BAD_SECONDARY_INSURANCES" in names else [],
        "secondary_insurance_company_codes": _rows(db, "SELECT * FROM SECONDARY_INSURANCE_COMPANY_CODES") if "SECONDARY_INSURANCE_COMPANY_CODES" in names else [],
    }
    return {
        "ok": True,
        "path": db.relative_to(clients.ROOT).as_posix(),
        "note": "Read-only view of the repo H2 file. The interface does not write this. Add clients, strips, and flags by editing this database in a change (then copy into Docker if the sandbox is running).",
        "tables": tables,
        "clients": clients_out,
        "shared": shared,
    }


def table_rows(slug: str, name: str) -> dict:
    if clients.slug_for(clients.require_root(slug).name) != "med-rec":
        raise ValueError("H2 viewer is only for Med Rec")
    root = clients.require_root(slug)
    db = _db_file(root)
    name = (name or "").strip().upper()
    if not TABLE_OK.match(name) or name not in _tables(db):
        raise ValueError("Unknown table")
    total = _count(db, name)
    rows = _rows(db, f"SELECT * FROM {name} LIMIT {RAW_CAP}")
    cols = list(rows[0].keys()) if rows else [r.get("COLUMN_NAME") for r in _rows(db, f"SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='PUBLIC' AND TABLE_NAME='{name}' ORDER BY ORDINAL_POSITION")]
    return {"ok": True, "name": name, "count": total, "capped": total > RAW_CAP, "columns": cols, "rows": rows}


def mue_edits(slug: str) -> dict:
    if clients.slug_for(clients.require_root(slug).name) != "med-rec":
        raise ValueError("MUE edits are only for Med Rec")
    root = clients.require_root(slug)
    db = _db_file_live(root)
    if not db.is_file():
        return {"ok": False, "error": f"Missing {LIVE.as_posix()}", "clients": []}
    try:
        names = _tables(db)
    except RuntimeError:
        db = _db_file(root)
        names = _tables(db)
    if "MUE_EDITS" not in names:
        return {"ok": True, "path": db.relative_to(clients.ROOT).as_posix(), "clients": [], "edit_count": 0, "note": "No MUE_EDITS table."}
    rows = _rows(db, "SELECT SOFTWARE_ID, CPT, MAX_VALUE_PER_LINE, CDM FROM MUE_EDITS ORDER BY SOFTWARE_ID, CPT, CDM")
    splits = _rows(db, "SELECT SOFTWAREID, CLIENTNAME, PARTITION, CLIENT FROM CLIENT_SPLITS") if "CLIENT_SPLITS" in names else []
    who: dict[str, dict] = {}
    for row in splits:
        sid = str(row.get("SOFTWAREID") or "").strip()
        if not sid:
            continue
        rec = who.get(sid)
        name = str(row.get("CLIENTNAME") or "").strip()
        part = str(row.get("PARTITION") or "").strip()
        cli = str(row.get("CLIENT") or "").strip()
        if not rec:
            who[sid] = {"software_id": sid, "name": name, "partition": part, "client": cli}
            continue
        if name and not rec["name"]:
            rec["name"] = name
        if part and part != rec["partition"] and part not in rec["partition"]:
            rec["partition"] = f"{rec['partition']}, {part}" if rec["partition"] else part
        if cli and cli != rec["client"] and cli not in rec["client"]:
            rec["client"] = f"{rec['client']}, {cli}" if rec["client"] else cli
    grouped: dict[str, dict] = {}
    for row in rows:
        sid = str(row.get("SOFTWARE_ID") or "").strip()
        rec = grouped.get(sid)
        if not rec:
            meta = who.get(sid) or {"software_id": sid, "name": "", "partition": "", "client": ""}
            rec = {
                "software_id": sid,
                "name": meta.get("name") or f"Software {sid}",
                "partition": meta.get("partition") or "",
                "client": meta.get("client") or "",
                "edits": [],
            }
            grouped[sid] = rec
        rec["edits"].append(
            {
                "CPT": row.get("CPT") or "",
                "MAX_VALUE_PER_LINE": row.get("MAX_VALUE_PER_LINE") or "",
                "CDM": row.get("CDM") or "",
            }
        )
    clients_out = sorted(grouped.values(), key=lambda r: ((r.get("name") or "").lower(), r.get("software_id") or ""))
    return {
        "ok": True,
        "path": db.relative_to(clients.ROOT).as_posix(),
        "note": "MUE_EDITS from the live H2 file when the sandbox is running, otherwise the repo seed.",
        "edit_count": len(rows),
        "client_count": len(clients_out),
        "clients": clients_out,
    }
