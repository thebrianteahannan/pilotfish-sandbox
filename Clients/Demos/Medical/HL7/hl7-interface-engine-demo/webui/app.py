#!/usr/bin/env python3
"""HL7 Interface Engine demo — LLP inject, stage XML, SQL rows."""

from __future__ import annotations

import os
import re
import socket
import time
from datetime import datetime
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8142"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
SNAPSHOT_DIR = Path(os.environ.get("SNAPSHOT_DIR", "/output/snapshots"))
DEBUG_TRACE_DIR = Path(os.environ.get("DEBUG_TRACE_DIR", "/output/debug-trace"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://127.0.0.1:8141/eip/")
LLP_HOST = os.environ.get("EIP_LLP_HOST", "127.0.0.1")
LLP_PORT = int(os.environ.get("EIP_LLP_PORT", "2578"))
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "14342"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "Hl7MeasuresDemo")
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "HL7_Interface_Engine_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get("CAPABILITY_PDF_NAME", "HL7_Interface_Engine_Capability_Brief.pdf")

START = b"\x0b"
END = b"\x1c\x0d"
_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
_SAFE_NAME = re.compile(r"^[A-Za-z0-9._-]+$")


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def list_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.glob("*/route.v2.xml")):
        out.append({"id": route_slug(path.parent.name), "name": path.parent.name, "mtime": path.stat().st_mtime})
    return out


def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""


def latest_trace(*needles: str) -> str:
    """Newest EIP debug-trace payload whose name contains every needle."""
    if not DEBUG_TRACE_DIR.is_dir():
        return ""
    hits = []
    for path in DEBUG_TRACE_DIR.rglob("*.trace"):
        name = path.name
        if name.endswith(".attributes.xml"):
            continue
        if all(n.lower() in name.lower() for n in needles):
            hits.append(path)
    if not hits:
        return ""
    hits.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return read_file(hits[0])


def list_text_files(directory: Path, patterns: tuple[str, ...] = ("*",)):
    if not directory.is_dir():
        return []
    files: list[Path] = []
    for pat in patterns:
        files.extend(directory.glob(pat))
    out = []
    for path in sorted({p for p in files if p.is_file()}, key=lambda p: p.stat().st_mtime, reverse=True)[:20]:
        out.append({"name": path.name, "content": read_file(path), "mtime": path.stat().st_mtime})
    return out


def mllp_send(payload: str, timeout: float = 20.0) -> str:
    text = payload.replace("\r\n", "\r").replace("\n", "\r")
    if not text.endswith("\r"):
        text += "\r"
    framed = START + text.encode("utf-8") + END
    with socket.create_connection((LLP_HOST, LLP_PORT), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(framed)
        buf = b""
        while END not in buf:
            chunk = sock.recv(4096)
            if not chunk:
                break
            buf += chunk
    if START in buf and END in buf:
        body = buf[buf.find(START) + 1 : buf.find(END)]
    else:
        body = buf
    return body.decode("utf-8", errors="replace")


def db_connect():
    import pymssql  # type: ignore

    return pymssql.connect(
        server=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        login_timeout=5,
    )


def patient_rows(limit: int = 20):
    with db_connect() as conn:
        cur = conn.cursor(as_dict=True)
        cur.execute(
            f"""
            SELECT TOP {int(limit)} RowId, PatientId, LastName, FirstName, DateOfBirth,
                   MessageControlId, LoadedAt
            FROM dbo.Patients
            ORDER BY RowId DESC
            """
        )
        rows = cur.fetchall()
        for row in rows:
            for key, value in list(row.items()):
                if hasattr(value, "isoformat"):
                    row[key] = value.isoformat()
        return rows


@app.get("/")
def index():
    return render_template(
        "index.html",
        title="eiConsole for Healthcare – HL7 Demo",
        lan_hint=LAN_HINT,
        eip_url=EIP_PUBLIC_URL,
    )


@app.get("/api/health")
def api_health():
    db_ok = False
    try:
        with db_connect() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
            db_ok = True
    except Exception:
        db_ok = False
    return jsonify({"ok": True, "db_ok": db_ok, "llp": f"{LLP_HOST}:{LLP_PORT}"})


@app.get("/api/samples")
def api_samples():
    return jsonify({"files": list_text_files(SAMPLE_DIR, ("*.hl7",))})


@app.post("/api/inject")
def api_inject():
    body = request.get_json(silent=True) or {}
    sample = (body.get("sample") or "").strip()
    content = body.get("text") or body.get("content")
    if sample and not str(content or "").strip():
        path = SAMPLE_DIR / sample
        if not path.is_file() or not _SAFE_NAME.match(sample):
            return jsonify({"error": "unknown sample"}), 400
        content = path.read_text(encoding="utf-8", errors="replace")
    if not str(content or "").strip():
        return jsonify({"error": "empty HL7"}), 400
    ack = mllp_send(str(content))
    return jsonify({"ok": True, "ack": ack})


@app.get("/api/results")
def api_results():
    rows = []
    db_error = None
    try:
        rows = patient_rows()
    except Exception as exc:  # noqa: BLE001
        db_error = str(exc)
    return jsonify(
        {
            "ok": True,
            "patients": rows,
            "db_error": db_error,
            "hl7Xml": latest_trace("HL7 v2.X") or read_file(SNAPSHOT_DIR / "hl7-xml.xml"),
            "patientXml": latest_trace("hl7-xml-to-patient") or read_file(SNAPSHOT_DIR / "patient.xml"),
            "sqlXml": read_file(SNAPSHOT_DIR / "sqlxml.xml") or latest_trace("patient-to-sqlxml"),
        }
    )


@app.get("/api/wait-patient")
def api_wait_patient():
    control = (request.args.get("control") or "HOSP-ADT-001").strip()
    after = int(request.args.get("after") or 0)
    deadline = time.time() + min(int(request.args.get("timeout", 90)), 180)
    last_err = None
    while time.time() < deadline:
        try:
            for row in patient_rows(50):
                if after and int(row.get("RowId") or 0) <= after:
                    continue
                if str(row.get("MessageControlId") or "") == control or str(row.get("LastName") or "") == "SMITH":
                    return jsonify({"ok": True, "row": row})
        except Exception as exc:  # noqa: BLE001
            last_err = str(exc)
        time.sleep(1.5)
    return jsonify({"ok": False, "error": last_err or "timeout waiting for SQL row"}), 408


@app.get("/api/v2/routes")
def api_routes():
    return jsonify({"routes": list_v2_routes()})


@app.get("/api/v2/routes/<route_id>/route.v2.xml")
def api_route_xml(route_id: str):
    if not _ROUTE_SLUG.match(route_id):
        return Response("bad route", status=400)
    for path in ROUTES_DIR.glob("*/route.v2.xml"):
        if route_slug(path.parent.name) == route_id:
            return send_file(path, mimetype="application/xml")
    return Response("not found", status=404)


@app.get("/api/v2/routes/<route_id>/diagram-groups.json")
def api_route_groups(route_id: str):
    if not _ROUTE_SLUG.match(route_id):
        return Response("bad route", status=400)
    for path in ROUTES_DIR.glob("*/diagram-groups.json"):
        if route_slug(path.parent.name) == route_id:
            return send_file(path, mimetype="application/json")
    return jsonify({"groups": []})


@app.get("/api/v2/routes/<route_id>/modules/<module_id>.xml")
def api_module_xml(route_id: str, module_id: str):
    if not _ROUTE_SLUG.match(route_id) or not _MODULE_ID.match(module_id):
        return Response("bad id", status=400)
    for route_dir in ROUTES_DIR.iterdir():
        if not route_dir.is_dir() or route_slug(route_dir.name) != route_id:
            continue
        path = route_dir / "modules" / f"{module_id}.xml"
        if path.is_file():
            return send_file(path, mimetype="application/xml")
    return Response("not found", status=404)


@app.context_processor
def _info_tab_standard_context():
    eip = (os.environ.get("EIP_PUBLIC_URL") or EIP_PUBLIC_URL).replace("localhost", "127.0.0.1")
    lan = os.environ.get("LAN_HINT") or LAN_HINT or ""
    urls = [{"label": "Local Web UI", "href": f"http://127.0.0.1:{WEBUI_PORT}/"}]
    if lan:
        urls.append({"label": "LAN Web UI", "href": lan})
    urls.append({"label": "EIP", "href": eip})
    urls.append({"label": "HL7 LLP", "value": f"127.0.0.1:{LLP_PORT}", "note": "MLLP ADT from hospital"})
    urls.append({"label": "SQL Server", "value": f"127.0.0.1:14342", "note": "sa / PilotFish_Demo1!"})
    return {
        "info_title": "eiConsole for Healthcare – HL7 Demo",
        "info_blurb": "Hospital HL7 over LLP becomes XML, a Data Mapper keeps last name, first name, and date of birth (PID.7 yyyyMMdd to yyyy-MM-dd), then the same map writes a SQL insert. Same beats as the public HL7 interface-engine demo.",
        "info_note": "Demo only — synthetic ADT. Public page: https://cms.pilotfishtechnology.com/hl7-interface-engine-demo/",
        "eip_url": eip,
        "lan_hint": lan,
        "info_urls": urls,
        "info_ports": [
            {"label": "Demo Web UI", "value": str(WEBUI_PORT)},
            {"label": "PilotFish EIP", "value": "8141"},
            {"label": "HL7 LLP", "value": str(LLP_PORT)},
            {"label": "SQL Server", "value": "14342"},
        ],
        "info_extra_links": [
            {"label": "Public HL7 demo", "href": "https://cms.pilotfishtechnology.com/hl7-interface-engine-demo/"},
            {"label": "YouTube walkthrough (5:15)", "href": "https://www.youtube.com/watch?v=RaaR2TcQQHQ"},
        ],
        "info_extra_sections": [],
        "test_results_pdf": None,
    }


try:
    from document_routes import (
        ensure_build_experience_api,
        ensure_build_replay_api,
        ensure_build_status_api,
        ensure_build_timing_api,
        ensure_document_routes,
    )
except ImportError:
    ensure_document_routes = None  # type: ignore
    ensure_build_timing_api = None  # type: ignore
    ensure_build_status_api = None  # type: ignore
    ensure_build_replay_api = None  # type: ignore
    ensure_build_experience_api = None  # type: ignore

if ensure_document_routes is not None:
    ensure_document_routes(
        app,
        DOCUMENTS_DIR,
        route_pdf_name=ROUTE_PDF_NAME,
        capability_pdf_name=CAPABILITY_PDF_NAME,
    )
if ensure_build_timing_api is not None:
    ensure_build_timing_api(app, DOCUMENTS_DIR)
if ensure_build_status_api is not None:
    ensure_build_status_api(app, DOCUMENTS_DIR)
if ensure_build_replay_api is not None:
    ensure_build_replay_api(app, DOCUMENTS_DIR)
if ensure_build_experience_api is not None:
    ensure_build_experience_api(app, DOCUMENTS_DIR)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
