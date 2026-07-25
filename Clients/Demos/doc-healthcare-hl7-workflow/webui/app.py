#!/usr/bin/env python3
"""DOC Healthcare HL7 workflow demo UI — dual DB (Oracle OMS + SQL Server Housing)."""

from __future__ import annotations

import os
import re
import time
from datetime import datetime
from pathlib import Path

import oracledb
import pymssql
from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "DocHealthcare")
ORACLE_USER = os.environ.get("ORACLE_USER", "docoms")
ORACLE_PASSWORD = os.environ.get("ORACLE_PASSWORD", "PilotFish_O1")
ORACLE_DSN = os.environ.get("ORACLE_DSN", "oracle:1521/XEPDB1")
HL7_DIR = Path(os.environ.get("HL7_DIR", "/output/hl7"))
EVENTS_DIR = Path(os.environ.get("EVENTS_DIR", "/output/events"))

PATIENTS = {
    "OFF-10021": {
        "label": "GARCIA, MIGUEL (OFF-10021)",
        "facility": "NORTH",
        "unit": "A-WING",
        "bed": "101",
        "npi": "1234567890",
        "attending": "SMITH^JANE^MD",
    },
    "OFF-10044": {
        "label": "JOHNSON, DEANDRE (OFF-10044)",
        "facility": "NORTH",
        "unit": "B-WING",
        "bed": "214",
        "npi": "1234567890",
        "attending": "SMITH^JANE^MD",
    },
    "OFF-10057": {
        "label": "WILLIAMS, ASHLEY (OFF-10057)",
        "facility": "SOUTH",
        "unit": "D-WING",
        "bed": "012",
        "npi": "1987654321",
        "attending": "LEE^DAVID^MD",
    },
    "OFF-10063": {
        "label": "BROWN, TYRONE (OFF-10063)",
        "facility": "EAST",
        "unit": "E-WING",
        "bed": "401",
        "npi": "1122334455",
        "attending": "PATEL^RINA^MD",
    },
}


def sqlserver_db():
    return pymssql.connect(
        server=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        login_timeout=10,
        timeout=30,
    )


def oracle_db():
    return oracledb.connect(user=ORACLE_USER, password=ORACLE_PASSWORD, dsn=ORACLE_DSN)


def db_error_response(exc: Exception, status: int = 503):
    msg = str(exc)
    if "Adaptive Server is unavailable" in msg or "20009" in msg:
        msg = "SQL Server is unavailable. It may have restarted — wait a few seconds and try again."
    elif "ORA-" in msg or "DPY-" in msg:
        msg = f"Oracle is unavailable or rejected the request: {msg}"
    return jsonify({"ok": False, "error": msg}), status


def source_for_event_type(event_type: str, explicit: str | None = None) -> str:
    if explicit:
        return explicit
    if event_type in {"TRANSFER", "BED_ASSIGN"}:
        return "SQLSERVER_HOUSING"
    if event_type == "MULTI":
        return "ORACLE_OMS"
    return "ORACLE_OMS"


def decode_hl7(path: Path) -> str:
    raw = path.read_bytes()
    return raw.replace(b"\r", b"\n").decode("utf-8", errors="replace").strip()


def list_hl7(prefix: str | None = None):
    if not HL7_DIR.exists():
        return []
    files = sorted(HL7_DIR.glob("*.hl7"), key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for path in files:
        if prefix and not path.name.startswith(prefix):
            continue
        try:
            text = decode_hl7(path)
        except OSError:
            continue
        out.append(
            {
                "name": path.name,
                "mtime": datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds"),
                "content": text,
                "size": path.stat().st_size,
            }
        )
    return out


def expected_hl7_names(event_id: int, event_type: str, children: str) -> list[str]:
    trigger = {
        "ADMIT": "A01",
        "TRANSFER": "A02",
        "BED_ASSIGN": "A02",
        "DISCHARGE": "A03",
        "DEMO_UPDATE": "A08",
    }
    if event_type == "MULTI" and children:
        names = []
        for i, child in enumerate([c.strip() for c in children.split(",") if c.strip()], start=1):
            names.append(f"{event_id}-{i}_{child}_{trigger.get(child, 'A08')}.hl7")
        return names
    return [f"{event_id}_{event_type}_{trigger.get(event_type, 'A08')}.hl7"]


def fetch_sqlserver_events():
    with sqlserver_db() as conn:
        cur = conn.cursor(as_dict=True)
        cur.execute(
            """
            SELECT
              e.EventId, e.SourceSystem, e.EventType, e.ChildEventTypes,
              e.OffenderId, p.LastName, p.FirstName, e.FacilityCode, e.UnitCode,
              e.BedCode, e.Status, CONVERT(VARCHAR(19), e.EventTimestamp, 126) AS EventTimestamp,
              e.Notes, 'SQL Server' AS DbEngine
            FROM dbo.OperationalEvents e
            INNER JOIN dbo.Patients p ON p.OffenderId = e.OffenderId
            ORDER BY e.EventId DESC
            """
        )
        return cur.fetchall()


def fetch_oracle_events():
    with oracle_db() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT
              e.event_id, e.source_system, e.event_type, e.child_event_types,
              e.offender_id, p.last_name, p.first_name, e.facility_code, e.unit_code,
              e.bed_code, e.status,
              TO_CHAR(e.event_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS'),
              e.notes
            FROM operational_events e
            INNER JOIN patients p ON p.offender_id = e.offender_id
            ORDER BY e.event_id DESC
            """
        )
        rows = []
        for r in cur.fetchall():
            rows.append(
                {
                    "EventId": int(r[0]),
                    "SourceSystem": r[1],
                    "EventType": r[2],
                    "ChildEventTypes": r[3],
                    "OffenderId": r[4],
                    "LastName": r[5],
                    "FirstName": r[6],
                    "FacilityCode": r[7],
                    "UnitCode": r[8],
                    "BedCode": r[9],
                    "Status": r[10],
                    "EventTimestamp": r[11],
                    "Notes": r[12],
                    "DbEngine": "Oracle",
                }
            )
        return rows


def insert_sqlserver_event(event_type, source, children, offender_id, patient, facility, unit, bed, notes, payload):
    with sqlserver_db() as conn:
        cur = conn.cursor(as_dict=True)
        cur.execute("SELECT ISNULL(MAX(EventId), 1000) + 1 AS NextId FROM dbo.OperationalEvents")
        event_id = int(cur.fetchone()["NextId"])
        cur.execute(
            """
            INSERT INTO dbo.OperationalEvents (
              EventId, SourceSystem, EventType, ChildEventTypes, OffenderId,
              FacilityCode, UnitCode, BedCode, PriorFacilityCode, PriorUnitCode, PriorBedCode,
              AttendingNpi, AttendingName, EventTimestamp, Status, Notes
            ) VALUES (
              %s, %s, %s, %s, %s,
              %s, %s, %s, %s, %s, %s,
              %s, %s, %s, N'PENDING', %s
            )
            """,
            (
                event_id,
                source,
                event_type,
                children or None,
                offender_id,
                facility,
                unit,
                bed,
                payload.get("priorFacilityCode"),
                payload.get("priorUnitCode"),
                payload.get("priorBedCode"),
                patient["npi"],
                patient["attending"],
                datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S"),
                notes,
            ),
        )
        conn.commit()
        return event_id


def insert_oracle_event(event_type, source, children, offender_id, patient, facility, unit, bed, notes, payload):
    with oracle_db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT NVL(MAX(event_id), 2000) + 1 FROM operational_events")
        event_id = int(cur.fetchone()[0])
        cur.execute(
            """
            INSERT INTO operational_events (
              event_id, source_system, event_type, child_event_types, offender_id,
              facility_code, unit_code, bed_code, prior_facility_code, prior_unit_code, prior_bed_code,
              attending_npi, attending_name, event_timestamp, status, notes
            ) VALUES (
              :id, :src, :etype, :children, :oid,
              :fac, :unit, :bed, :pfac, :punit, :pbed,
              :npi, :aname, SYSTIMESTAMP, 'PENDING', :notes
            )
            """,
            {
                "id": event_id,
                "src": source,
                "etype": event_type,
                "children": children or None,
                "oid": offender_id,
                "fac": facility,
                "unit": unit,
                "bed": bed,
                "pfac": payload.get("priorFacilityCode"),
                "punit": payload.get("priorUnitCode"),
                "pbed": payload.get("priorBedCode"),
                "npi": patient["npi"],
                "aname": patient["attending"],
                "notes": notes,
            },
        )
        conn.commit()
        return event_id


@app.get("/")
def index():
    return render_template(
        "index.html",
        patients=PATIENTS,
        lan_hint=os.environ.get("LAN_HINT", ""),
    )


@app.get("/api/health")
def api_health():
    sql_ok = False
    ora_ok = False
    errors = []
    try:
        with sqlserver_db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
        sql_ok = True
    except Exception as exc:  # noqa: BLE001
        errors.append(f"sqlserver: {exc}")
    try:
        with oracle_db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1 FROM dual")
            cur.fetchone()
        ora_ok = True
    except Exception as exc:  # noqa: BLE001
        errors.append(f"oracle: {exc}")
    ok = sql_ok and ora_ok
    return jsonify(
        {
            "ok": ok,
            "sqlserver": "up" if sql_ok else "down",
            "oracle": "up" if ora_ok else "down",
            "error": "; ".join(errors) if errors else None,
            "hl7Dir": str(HL7_DIR),
        }
    ), (200 if ok else 503)


@app.get("/api/events")
def api_events():
    try:
        rows = fetch_sqlserver_events() + fetch_oracle_events()
        rows.sort(key=lambda r: int(r["EventId"]), reverse=True)
        return jsonify({"ok": True, "events": rows[:80]})
    except Exception as exc:  # noqa: BLE001
        return db_error_response(exc)


@app.get("/api/hl7")
def api_hl7():
    prefix = request.args.get("prefix")
    return jsonify({"files": list_hl7(prefix)})


@app.post("/api/events")
def api_add_event():
    payload = request.get_json(force=True, silent=True) or {}
    offender_id = payload.get("offenderId") or "OFF-10021"
    event_type = (payload.get("eventType") or "ADMIT").upper()
    # MULTI children decide source when MULTI is chosen from housing package
    children = payload.get("childEventTypes") or ""
    if event_type == "MULTI" and not children:
        children = "ADMIT,BED_ASSIGN,DEMO_UPDATE"
    if event_type == "MULTI" and "TRANSFER" in children.upper():
        source = "SQLSERVER_HOUSING"
    else:
        source = source_for_event_type(event_type, payload.get("sourceSystem"))
    notes = payload.get("notes") or f"UI-injected {event_type}"
    patient = PATIENTS.get(offender_id) or PATIENTS["OFF-10021"]
    facility = payload.get("facilityCode") or patient["facility"]
    unit = payload.get("unitCode") or patient["unit"]
    bed = payload.get("bedCode") or patient["bed"]

    try:
        if source == "SQLSERVER_HOUSING":
            event_id = insert_sqlserver_event(
                event_type, source, children, offender_id, patient, facility, unit, bed, notes, payload
            )
            db_engine = "SQL Server"
        else:
            event_id = insert_oracle_event(
                event_type, source, children, offender_id, patient, facility, unit, bed, notes, payload
            )
            db_engine = "Oracle"
    except Exception as exc:  # noqa: BLE001
        return db_error_response(exc)

    return jsonify(
        {
            "ok": True,
            "eventId": event_id,
            "eventType": event_type,
            "childEventTypes": children,
            "offenderId": offender_id,
            "sourceSystem": source,
            "dbEngine": db_engine,
            "expectedFiles": expected_hl7_names(event_id, event_type, children),
            "pollHintSeconds": 20,
        }
    )


@app.get("/api/wait-hl7/<int:event_id>")
def api_wait_hl7(event_id: int):
    timeout = min(int(request.args.get("timeout", "45")), 90)
    prefix = str(event_id)
    deadline = time.time() + timeout
    while time.time() < deadline:
        files = list_hl7(prefix)
        extras = [f for f in list_hl7() if re.match(rf"^{event_id}([-_])", f["name"])]
        merged = {f["name"]: f for f in files + extras}
        if merged:
            return jsonify({"ready": True, "files": list(merged.values())})
        time.sleep(1.5)
    return jsonify({"ready": False, "files": list_hl7(prefix)})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8092")), debug=False)
