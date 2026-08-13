#!/usr/bin/env python3
"""EDI 837 NCCI PTP — Demo Web UI (drop 837P, PTP catalog, pass/kickout)."""

from __future__ import annotations

import os
import re
import time
from datetime import datetime
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8133"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
INBOUND_DIR = Path(os.environ.get("INBOUND_DIR", "/input/inbound"))
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/output"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://127.0.0.1:8132/eip/")
EIP_HEALTH_URL = os.environ.get("EIP_HEALTH_URL", "http://pilotfish:8080/eip/")
SQL_PUBLIC = os.environ.get("SQL_PUBLIC", "127.0.0.1:14343")
DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "Edi837NcciPtp")
ROUTE_PDF_NAME = "EDI837_NCCI_PTP_V2_Route_Diagrams.pdf"
CAPABILITY_PDF_NAME = "EDI837_NCCI_PTP_Capability_Brief.pdf"

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


def list_text_files(directory: Path, patterns: tuple[str, ...] = ("*",)):
    if not directory.is_dir():
        return []
    files: list[Path] = []
    for pat in patterns:
        files.extend(directory.glob(pat))
    files = sorted({p for p in files if p.is_file() and not p.name.startswith(".")}, key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for path in files[:40]:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
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


def db_connect():
    import pymssql  # type: ignore

    return pymssql.connect(server=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASSWORD, database=DB_NAME, login_timeout=5)


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


def clear_dir(directory: Path, patterns: tuple[str, ...]):
    if not directory.is_dir():
        return
    for pat in patterns:
        for path in directory.glob(pat):
            if path.is_file() and not path.name.startswith("."):
                path.unlink()


@app.get("/")
def index():
    return render_template("index.html", title="EDI 837 NCCI PTP")


@app.get("/api/health")
def api_health():
    return jsonify({"ok": True, "sql": sql_up(), "eip": eip_up()})


@app.get("/api/samples")
def api_samples():
    return jsonify({"files": list_text_files(SAMPLE_DIR, ("*.edi", "*.837", "*.txt"))})


@app.post("/api/inject")
def api_inject():
    body = request.get_json(silent=True) or {}
    sample = (body.get("sample") or "").strip()
    content = body.get("content")
    if sample and content is None:
        path = SAMPLE_DIR / sample
        if not path.is_file() or not _SAFE_NAME.match(sample):
            return jsonify({"ok": False, "error": "unknown sample"}), 400
        content = path.read_text(encoding="utf-8", errors="replace")
        name = sample
    else:
        content = content if content is not None else ""
        if not str(content).strip():
            return jsonify({"ok": False, "error": "empty content"}), 400
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        name = f"inject_{stamp}.edi"
    if not name.lower().endswith((".edi", ".837", ".txt")):
        name = f"{name}.edi"
    INBOUND_DIR.mkdir(parents=True, exist_ok=True)
    dest = INBOUND_DIR / name
    dest.write_text(str(content), encoding="utf-8")
    return jsonify({"ok": True, "file": name, "path": str(dest)})


@app.get("/api/ptp-edits")
def api_mue_edits():
    try:
        with db_connect() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute("SELECT Column1, Column2, ModifierIndicator, Description FROM dbo.PtpEdits ORDER BY Column1, Column2")
            rows = []
            for row in cur.fetchall() or []:
                rows.append(
                    {
                        "Column1": row.get("Column1"),
                        "Column2": row.get("Column2"),
                        "ModifierIndicator": row.get("ModifierIndicator"),
                        "Description": row.get("Description") or "",
                    }
                )
        return jsonify({"ok": True, "rows": rows})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "rows": [], "error": str(exc)}), 503


@app.get("/api/results")
def api_results():
    return jsonify(
        {
            "ok": True,
            "pass": list_text_files(OUTPUT_DIR / "pass", ("*.xml",)),
            "kickout": list_text_files(OUTPUT_DIR / "kickout", ("*.xml",)),
        }
    )


@app.get("/api/wait-results")
def api_wait_results():
    needle = (request.args.get("contains") or "PTPCLM001_pass.xml").strip()
    timeout = min(int(request.args.get("timeout", 90)), 180)
    deadline = time.time() + timeout
    while time.time() < deadline:
        blob = ""
        for folder, pats in ((OUTPUT_DIR / "pass", ("*.xml",)), (OUTPUT_DIR / "kickout", ("*.xml",))):
            for item in list_text_files(folder, pats):
                blob += item.get("name") or ""
                blob += "\n"
                blob += item.get("content") or ""
        if needle and needle in blob:
            return jsonify({"ok": True, "found": needle})
        time.sleep(1.5)
    return jsonify({"ok": False, "error": f"timeout waiting for {needle}"}), 408


@app.post("/api/reset")
def api_reset():
    clear_dir(OUTPUT_DIR / "pass", ("*.xml",))
    clear_dir(OUTPUT_DIR / "kickout", ("*.xml",))
    clear_dir(OUTPUT_DIR / "debug", ("*.xml",))
    clear_dir(OUTPUT_DIR / "staged-decisions", ("*.xml",))
    clear_dir(OUTPUT_DIR / "archive", ("*.edi", "*.837", "*.txt"))
    return jsonify({"ok": True})


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
    eip = (os.environ.get("EIP_PUBLIC_URL") or EIP_PUBLIC_URL or "http://127.0.0.1:8132/eip/").replace(
        "localhost", "127.0.0.1"
    )
    lan = os.environ.get("LAN_HINT") or LAN_HINT or ""
    urls = [{"label": "Local Web UI", "href": f"http://127.0.0.1:{WEBUI_PORT}/"}]
    if lan:
        urls.append({"label": "LAN Web UI", "href": lan})
    urls.extend(
        [
            {"label": "EIP", "href": eip},
            {
                "label": "SQL Server",
                "value": SQL_PUBLIC,
                "note": "sa / PilotFish_Demo1! · Edi837NcciPtp",
            },
        ]
    )
    return {
        "info_title": "EDI 837 NCCI PTP",
        "info_blurb": "Drop an 837P, look up CPT pairs against a CMS-shaped PTP catalog, and bucket pass vs kickout.",
        "info_note": "Demo only - synthetic PTP table (not official CMS quarterly files). No SNIP. No stock NCCI module. Sibling demo edi-837-ncci-mue covers units.",
        "eip_url": eip,
        "lan_hint": lan,
        "info_urls": urls,
        "info_ports": [
            {"label": "Demo Web UI", "value": str(WEBUI_PORT)},
            {"label": "PilotFish EIP", "value": "8132"},
            {"label": "SQL Server", "value": "14343"},
        ],
        "info_extra_links": [],
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
    ensure_document_routes(app, DOCUMENTS_DIR, route_pdf_name=ROUTE_PDF_NAME, capability_pdf_name=CAPABILITY_PDF_NAME)
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
