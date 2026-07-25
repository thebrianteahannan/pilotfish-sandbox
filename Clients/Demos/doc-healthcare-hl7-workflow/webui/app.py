#!/usr/bin/env python3
"""DOC Healthcare HL7 workflow demo UI — route visuals + live event injector."""

from __future__ import annotations

import os
import re
import time
from datetime import datetime
from pathlib import Path

import pymssql
from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "DocHealthcare")
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

EVENT_PRESETS = [
    {"type": "ADMIT", "source": "ORACLE_OMS", "children": "", "notes": "UI-injected admission"},
    {"type": "TRANSFER", "source": "SQLSERVER_HOUSING", "children": "", "notes": "UI-injected transfer"},
    {"type": "BED_ASSIGN", "source": "SQLSERVER_HOUSING", "children": "", "notes": "UI-injected bed assign"},
    {"type": "DEMO_UPDATE", "source": "ORACLE_OMS", "children": "", "notes": "UI-injected demographic update"},
    {"type": "DISCHARGE", "source": "ORACLE_OMS", "children": "", "notes": "UI-injected discharge"},
    {
        "type": "MULTI",
        "source": "ORACLE_OMS",
        "children": "ADMIT,BED_ASSIGN,DEMO_UPDATE",
        "notes": "UI-injected MULTI intake package",
    },
    {
        "type": "MULTI",
        "source": "SQLSERVER_HOUSING",
        "children": "TRANSFER,BED_ASSIGN",
        "notes": "UI-injected MULTI transfer package",
    },
]


def db():
    return pymssql.connect(
        server=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        login_timeout=10,
        timeout=30,
    )


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


@app.get("/")
def index():
    return render_template(
        "index.html",
        patients=PATIENTS,
        presets=EVENT_PRESETS,
        lan_hint=os.environ.get("LAN_HINT", ""),
    )


@app.get("/api/events")
def api_events():
    with db() as conn:
        cur = conn.cursor(as_dict=True)
        cur.execute(
            """
            SELECT TOP 50
              e.EventId, e.SourceSystem, e.EventType, e.ChildEventTypes,
              e.OffenderId, p.LastName, p.FirstName, e.FacilityCode, e.UnitCode,
              e.BedCode, e.Status, CONVERT(VARCHAR(19), e.EventTimestamp, 126) AS EventTimestamp,
              e.Notes
            FROM dbo.OperationalEvents e
            INNER JOIN dbo.Patients p ON p.OffenderId = e.OffenderId
            ORDER BY e.EventId DESC
            """
        )
        rows = cur.fetchall()
    return jsonify({"events": rows})


@app.get("/api/hl7")
def api_hl7():
    prefix = request.args.get("prefix")
    return jsonify({"files": list_hl7(prefix)})


@app.get("/api/expanded")
def api_expanded():
    path = EVENTS_DIR / "expanded_events.xml"
    if not path.exists():
        return jsonify({"exists": False, "content": ""})
    return jsonify({"exists": True, "content": path.read_text(encoding="utf-8", errors="replace")})


@app.post("/api/events")
def api_add_event():
    payload = request.get_json(force=True, silent=True) or {}
    offender_id = payload.get("offenderId") or "OFF-10021"
    event_type = (payload.get("eventType") or "ADMIT").upper()
    source = payload.get("sourceSystem") or (
        "SQLSERVER_HOUSING" if event_type in {"TRANSFER", "BED_ASSIGN"} else "ORACLE_OMS"
    )
    children = payload.get("childEventTypes") or ""
    if event_type == "MULTI" and not children:
        children = "ADMIT,BED_ASSIGN,DEMO_UPDATE"
    notes = payload.get("notes") or f"UI-injected {event_type}"
    patient = PATIENTS.get(offender_id) or PATIENTS["OFF-10021"]
    facility = payload.get("facilityCode") or patient["facility"]
    unit = payload.get("unitCode") or patient["unit"]
    bed = payload.get("bedCode") or patient["bed"]

    with db() as conn:
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

    expected = expected_hl7_names(event_id, event_type, children)
    return jsonify(
        {
            "ok": True,
            "eventId": event_id,
            "eventType": event_type,
            "childEventTypes": children,
            "offenderId": offender_id,
            "expectedFiles": expected,
            "pollHintSeconds": 20,
        }
    )


@app.get("/api/wait-hl7/<int:event_id>")
def api_wait_hl7(event_id: int):
    """Poll HL7 output until matching files appear or timeout."""
    timeout = min(int(request.args.get("timeout", "45")), 90)
    prefix = str(event_id)
    deadline = time.time() + timeout
    while time.time() < deadline:
        files = list_hl7(prefix)
        # Also match MULTI children like 2001-1_
        extras = [f for f in list_hl7() if re.match(rf"^{event_id}([-_])", f["name"])]
        merged = {f["name"]: f for f in files + extras}
        if merged:
            return jsonify({"ready": True, "files": list(merged.values())})
        time.sleep(1.5)
    return jsonify({"ready": False, "files": list_hl7(prefix)})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8092")), debug=False)
