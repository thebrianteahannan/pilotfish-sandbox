#!/usr/bin/env python3
"""HL7 / EDI / FHIR analytics demo — inject + SQL / JSON results."""

from __future__ import annotations

import os
import re
import shutil
import socket
import time
import urllib.error
import urllib.request
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8154"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
SNAPSHOT_DIR = Path(os.environ.get("SNAPSHOT_DIR", "/output/snapshots"))
DEBUG_TRACE_DIR = Path(os.environ.get("DEBUG_TRACE_DIR", "/output/debug-trace"))
ANALYTICS_DIR = Path(os.environ.get("ANALYTICS_DIR", "/output/analytics"))
FTP_IN_DIR = Path(os.environ.get("FTP_IN_DIR", "/ftp-in"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://127.0.0.1:8153/eip/")
LLP_HOST = os.environ.get("EIP_LLP_HOST", "127.0.0.1")
LLP_PORT = int(os.environ.get("EIP_LLP_PORT", "10001"))
FHIR_URL = os.environ.get("EIP_FHIR_URL", "http://127.0.0.1:8153/eip/rest/FHIR/Patient")
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "14344"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "AnalyticsDemo")
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "Healthcare_Reporting_Analytics_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get("CAPABILITY_PDF_NAME", "Healthcare_Reporting_Analytics_Capability_Brief.pdf")

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
    if not DEBUG_TRACE_DIR.is_dir():
        return ""
    hits = []
    for path in DEBUG_TRACE_DIR.rglob("*.trace"):
        if path.name.endswith(".attributes.xml"):
            continue
        if all(n.lower() in path.name.lower() for n in needles):
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
            SELECT TOP {int(limit)} ID, LASTNAME, FIRSTNAME, DOB, ADDRESS, CITY, ST,
                   POSTALCODE, MRN
            FROM dbo.PATIENT
            ORDER BY ID DESC
            """
        )
        rows = cur.fetchall()
        for row in rows:
            for key, value in list(row.items()):
                if hasattr(value, "isoformat"):
                    row[key] = value.isoformat()
        return rows


def sample_path(name: str) -> Path | None:
    if not name or not _SAFE_NAME.match(name):
        return None
    path = SAMPLE_DIR / name
    return path if path.is_file() else None


@app.get("/")
def index():
    return render_template(
        "index.html",
        title="HL7, EDI & FHIR Data Integration for Analytics & Reporting",
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
    return jsonify(
        {
            "ok": True,
            "db_ok": db_ok,
            "llp": f"{LLP_HOST}:{LLP_PORT}",
            "fhir": FHIR_URL,
        }
    )


@app.get("/api/samples")
def api_samples():
    return jsonify({"files": list_text_files(SAMPLE_DIR, ("*.hl7", "*.edi", "*.json"))})


@app.post("/api/inject")
def api_inject():
    body = request.get_json(silent=True) or {}
    kind = (body.get("kind") or "hl7").strip().lower()
    sample = (body.get("sample") or "").strip()
    content = body.get("text") or body.get("content")
    if sample and not str(content or "").strip():
        path = sample_path(sample)
        if path is None:
            return jsonify({"error": "unknown sample"}), 400
        content = path.read_text(encoding="utf-8", errors="replace")
    if not str(content or "").strip() and kind != "edi":
        return jsonify({"error": "empty payload"}), 400
    if kind == "hl7":
        try:
            ack = mllp_send(str(content))
        except OSError as exc:
            return jsonify({"error": f"LLP send failed: {exc}"}), 502
        return jsonify({"ok": True, "ack": ack})
    if kind == "edi":
        FTP_IN_DIR.mkdir(parents=True, exist_ok=True)
        name = sample if sample.endswith(".edi") else "837-sample-encounter.edi"
        dest = FTP_IN_DIR / name
        if sample and sample_path(sample):
            shutil.copy2(sample_path(sample), dest)
        else:
            dest.write_text(str(content), encoding="utf-8")
        return jsonify({"ok": True, "dropped": dest.name})
    if kind == "fhir":
        data = str(content).encode("utf-8")
        req = urllib.request.Request(
            FHIR_URL,
            data=data,
            method="POST",
            headers={"Content-Type": "application/fhir+json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                reply = resp.read().decode("utf-8", errors="replace")
                return jsonify({"ok": True, "status": resp.status, "reply": reply})
        except urllib.error.HTTPError as exc:
            return jsonify({"error": exc.read().decode("utf-8", errors="replace") or str(exc)}), 502
        except urllib.error.URLError as exc:
            return jsonify({"error": str(exc.reason or exc)}), 502
    return jsonify({"error": "unknown kind"}), 400


@app.get("/api/results")
def api_results():
    rows = []
    db_error = None
    try:
        rows = patient_rows()
    except Exception as exc:  # noqa: BLE001
        db_error = str(exc)
    analytics = list_text_files(ANALYTICS_DIR, ("*.json",))
    return jsonify(
        {
            "ok": True,
            "patients": rows,
            "db_error": db_error,
            "hl7Xml": latest_trace("HL7 v2.X") or read_file(SNAPSHOT_DIR / "hl7-xml.xml"),
            "patientXml": latest_trace("hl7 to output") or latest_trace("hl7-to-output"),
            "sqlXml": read_file(SNAPSHOT_DIR / "sqlxml.xml") or latest_trace("xml to db"),
            "jsonOut": read_file(SNAPSHOT_DIR / "analytics.json")
            or (analytics[0]["content"] if analytics else ""),
            "analytics": analytics[:5],
        }
    )


@app.get("/api/wait-patient")
def api_wait_patient():
    last = (request.args.get("last") or "").strip().upper()
    after = int(request.args.get("after") or 0)
    deadline = time.time() + min(int(request.args.get("timeout", 90)), 180)
    last_err = None
    while time.time() < deadline:
        try:
            for row in patient_rows(50):
                if after and int(row.get("ID") or 0) <= after:
                    continue
                if last and last not in str(row.get("LASTNAME") or "").upper():
                    continue
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
    hub = (os.environ.get("SANDBOX_HUB_URL") or "http://127.0.0.1:8077/").rstrip("/") + "/"
    urls = [
        {"label": "Sandbox hub", "href": hub, "note": "Admin, speech, demos"},
        {"label": "Local Web UI", "href": f"http://127.0.0.1:{WEBUI_PORT}/"},
    ]
    if lan:
        urls.append({"label": "LAN Web UI", "href": lan})
    urls.append({"label": "EIP", "href": eip})
    urls.append({"label": "HL7 LLP", "value": f"127.0.0.1:{LLP_PORT}", "note": "MLLP ADT from hospital"})
    urls.append({"label": "FTP (claims EDI)", "value": "127.0.0.1:2121", "note": "demo / demo"})
    urls.append({"label": "FHIR REST", "href": "http://127.0.0.1:8153/eip/rest/FHIR/Patient", "note": "POST Patient JSON"})
    urls.append({"label": "Analytics REST", "href": "http://127.0.0.1:7072/aggregationanalytics/restservice", "note": "JSON quality-reporting mock"})
    urls.append({"label": "SQL Server", "value": "127.0.0.1:14344", "note": "sa / PilotFish_Demo1!"})
    return {
        "info_title": "HL7, EDI & FHIR Data Integration for Analytics & Reporting",
        "info_blurb": "Jenny’s HIMSS aggregation route: HL7 over LLP, X12 EDI over FTP, and FHIR JSON over REST, each mapped to a patient canonical, then SQL plus a JSON analytics post. Same beats as the public healthcare reporting demo.",
        "info_note": "Demo only — synthetic ADT / 837 / FHIR Patient. Public page: https://healthcare.pilotfishtechnology.com/videos/healthcare-reporting-analytics-demo",
        "eip_url": eip,
        "lan_hint": lan,
        "info_urls": urls,
        "info_ports": [
            {"label": "Demo Web UI", "value": str(WEBUI_PORT)},
            {"label": "PilotFish EIP", "value": "8153"},
            {"label": "HL7 LLP", "value": str(LLP_PORT)},
            {"label": "FTP", "value": "2121"},
            {"label": "Analytics REST", "value": "7072"},
            {"label": "SQL Server", "value": "14344"},
        ],
        "info_extra_links": [
            {
                "label": "Public analytics demo",
                "href": "https://healthcare.pilotfishtechnology.com/videos/healthcare-reporting-analytics-demo",
            },
            {"label": "YouTube walkthrough (7:24)", "href": "https://www.youtube.com/watch?v=xgJjWRUqHFw"},
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

try:
    from video_review_api import ensure_video_review_api
except ImportError:
    ensure_video_review_api = None  # type: ignore

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
if ensure_video_review_api is not None:
    ensure_video_review_api(app, DOCUMENTS_DIR)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
