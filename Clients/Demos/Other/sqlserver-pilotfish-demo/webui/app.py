#!/usr/bin/env python3
"""SQL Server → XML file demo Web UI — Captures table, live export, routes theater."""

from __future__ import annotations

import os
import re
from datetime import datetime
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8137"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
OUTPUT_XML = Path(os.environ.get("OUTPUT_XML", "/output/captures_export.xml"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://localhost:8136/eip/")
EIP_HEALTH_URL = os.environ.get("EIP_HEALTH_URL", "http://pilotfish:8080/eip/")
SQL_PUBLIC = os.environ.get("SQL_PUBLIC", "127.0.0.1:14342")
DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "PilotFishDemo")
ROUTE_PDF_NAME = "SQL_Server_PilotFish_XML_Export_V2_Route_Diagrams.pdf"
CAPABILITY_PDF_NAME = "SQL_Server_PilotFish_XML_Export_Capability_Brief.pdf"

_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def list_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.glob("*/route.v2.xml")):
        out.append(
            {
                "id": route_slug(path.parent.name),
                "name": path.parent.name,
                "mtime": path.stat().st_mtime,
            }
        )
    return out


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


def eip_up() -> bool:
    try:
        with urlopen(EIP_HEALTH_URL, timeout=2) as resp:
            return 200 <= resp.status < 500
    except (URLError, OSError, TimeoutError):
        return False


def sql_up() -> bool:
    try:
        with db_connect() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
        return True
    except Exception:
        return False


def xml_payload() -> dict:
    if not OUTPUT_XML.is_file():
        return {"ok": False, "content": "", "bytes": 0, "mtime": None}
    text = OUTPUT_XML.read_text(encoding="utf-8", errors="replace")
    mtime = datetime.fromtimestamp(OUTPUT_XML.stat().st_mtime).isoformat(timespec="seconds")
    return {"ok": True, "content": text, "bytes": len(text.encode("utf-8")), "mtime": mtime}


@app.get("/")
def index():
    return render_template("index.html", title="SQL Server PilotFish XML Export")


@app.get("/api/health")
def api_health():
    xml = xml_payload()
    sql = sql_up()
    eip = eip_up()
    return jsonify({"ok": True, "sql": sql, "eip": eip, "xml": bool(xml.get("ok"))})


@app.get("/api/captures")
def api_captures():
    try:
        with db_connect() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                "SELECT CaptureId, ClientName, DocumentType, Status, CapturePayload, CreatedAt "
                "FROM dbo.Captures ORDER BY CaptureId"
            )
            rows = []
            for row in cur.fetchall() or []:
                created = row.get("CreatedAt")
                rows.append(
                    {
                        "CaptureId": row.get("CaptureId"),
                        "ClientName": row.get("ClientName"),
                        "DocumentType": row.get("DocumentType"),
                        "Status": row.get("Status"),
                        "CapturePayload": row.get("CapturePayload"),
                        "CreatedAt": created.isoformat(timespec="seconds") if hasattr(created, "isoformat") else str(created or ""),
                    }
                )
        return jsonify({"ok": True, "count": len(rows), "rows": rows})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "count": 0, "rows": [], "error": str(exc)}), 503


@app.post("/api/insert")
def api_insert():
    body = request.get_json(silent=True) or {}
    client = str(body.get("clientName") or request.form.get("clientName") or "Demo Client").strip()[:120]
    doc_type = str(body.get("documentType") or request.form.get("documentType") or "ACORD 121").strip()[:80]
    status = str(body.get("status") or request.form.get("status") or "PENDING").strip()[:40]
    payload = str(body.get("payload") or request.form.get("payload") or "Inserted from Demo tab").strip()[:400]
    try:
        with db_connect() as conn:
            cur = conn.cursor()
            cur.execute("SELECT ISNULL(MAX(CaptureId), 1000) + 1 FROM dbo.Captures")
            next_id = int(cur.fetchone()[0])
            cur.execute(
                "INSERT INTO dbo.Captures (CaptureId, ClientName, DocumentType, Status, CapturePayload, CreatedAt) "
                "VALUES (%s, %s, %s, %s, %s, SYSUTCDATETIME())",
                (next_id, client, doc_type, status, payload),
            )
            conn.commit()
        return jsonify({"ok": True, "captureId": next_id})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 500


@app.get("/api/xml")
def api_xml():
    data = xml_payload()
    data["ok"] = True
    return jsonify(data)


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


_INFO_TAB_CTX = {
    "info_title": "SQL Server PilotFish XML Export",
    "info_blurb": "Poll dbo.Captures every 15 seconds and overwrite captures_export.xml.",
    "info_note": "Demo only — SA login, encrypt + trustServerCertificate, file overwrite each poll.",
    "eip_url": EIP_PUBLIC_URL,
    "lan_hint": LAN_HINT,
    "info_ports": [
        {"label": "PilotFish EIP", "value": "8136"},
        {"label": "Demo Web UI", "value": "8137"},
        {"label": "SQL Server", "value": "14342"},
    ],
    "info_extra_links": [],
    "info_extra_sections": [],
    "test_results_pdf": None,
}


@app.context_processor
def _info_tab_standard_context():
    ctx = dict(_INFO_TAB_CTX)
    eip = (os.environ.get("EIP_PUBLIC_URL") or ctx.get("eip_url") or "http://127.0.0.1:8136/eip/").replace(
        "localhost", "127.0.0.1"
    )
    lan = os.environ.get("LAN_HINT") or ctx.get("lan_hint") or ""
    ctx["eip_url"] = eip
    ctx["lan_hint"] = lan
    urls = [{"label": "Local Web UI", "href": f"http://127.0.0.1:{WEBUI_PORT}/"}]
    if lan:
        urls.append({"label": "LAN Web UI", "href": lan})
    urls.extend(
        [
            {"label": "EIP", "href": eip},
            {
                "label": "SQL Server",
                "value": SQL_PUBLIC,
                "note": "sa / PilotFish_Demo1! · PilotFishDemo",
            },
        ]
    )
    ctx["info_urls"] = urls
    return ctx


try:
    from document_routes import (
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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
