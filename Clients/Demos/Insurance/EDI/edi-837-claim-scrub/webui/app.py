#!/usr/bin/env python3
"""EDI 837 Claim Scrub — Demo Web UI (SQL claims, kickouts, 837, SNIP)."""

from __future__ import annotations

import os
import re
from datetime import datetime
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8115"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/output"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://127.0.0.1:8114/eip/")
EIP_HEALTH_URL = os.environ.get("EIP_HEALTH_URL", "http://pilotfish:8080/eip/")
SQL_PUBLIC = os.environ.get("SQL_PUBLIC", "127.0.0.1:14341")
DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "Edi837ClaimScrub")
ROUTE_PDF_NAME = "EDI837_Claim_Scrub_V2_Route_Diagrams.pdf"
CAPABILITY_PDF_NAME = "EDI837_Claim_Scrub_Capability_Brief.pdf"

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
        out.append({"name": path.name, "mtime": datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds"), "content": text, "size": path.stat().st_size})
    return out


def db_connect():
    import pymssql  # type: ignore

    return pymssql.connect(server=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASSWORD, database=DB_NAME, login_timeout=5)


def probe(url: str) -> bool:
    try:
        with urlopen(url, timeout=2) as resp:
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


def rows_as_dicts(cur) -> list[dict]:
    cols = [d[0] for d in (cur.description or [])]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


@app.get("/")
def index():
    return render_template("index.html", title="EDI 837 Claim Scrub")


@app.get("/api/health")
def api_health():
    return jsonify({"ok": True, "eip": probe(EIP_HEALTH_URL), "sql": sql_up()})


@app.get("/api/claims")
def api_claims():
    try:
        with db_connect() as conn:
            cur = conn.cursor()
            cur.execute("SELECT ClaimId, ClaimNumber, PayerId, PlaceOfService, ReferringNpi, Status FROM dbo.Claims ORDER BY ClaimId")
            return jsonify({"ok": True, "rows": rows_as_dicts(cur)})
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc), "rows": []}), 503


@app.get("/api/payer-rules")
def api_payer_rules():
    try:
        with db_connect() as conn:
            cur = conn.cursor()
            cur.execute("SELECT RuleId, PayerId, PayerName, RuleCode, Message, AllowedPosList FROM dbo.PayerEditRules ORDER BY RuleId")
            return jsonify({"ok": True, "rows": rows_as_dicts(cur)})
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc), "rows": []}), 503


@app.get("/api/kickouts")
def api_kickouts():
    return jsonify({"ok": True, "files": list_text_files(OUTPUT_DIR / "kickouts", ("*.xml",))})


@app.get("/api/edi")
def api_edi():
    return jsonify({"ok": True, "files": list_text_files(OUTPUT_DIR / "edi", ("*.edi",))})


@app.get("/api/snip")
def api_snip():
    return jsonify({"ok": True, "files": list_text_files(OUTPUT_DIR / "snip", ("*.xml",))})


@app.get("/api/results")
def api_results():
    return jsonify(
        {
            "ok": True,
            "kickouts": list_text_files(OUTPUT_DIR / "kickouts", ("*.xml",)),
            "edi": list_text_files(OUTPUT_DIR / "edi", ("*.edi",)),
            "snip": list_text_files(OUTPUT_DIR / "snip", ("*.xml",)),
            "bi": list_text_files(OUTPUT_DIR / "bi", ("*.xml",)),
        }
    )


@app.get("/api/snip-report")
def api_snip_report():
    name = (request.args.get("name") or "").strip()
    if not name or not _SAFE_NAME.match(name):
        return Response("bad name", status=400)
    snip_path = OUTPUT_DIR / "snip" / name
    if not snip_path.is_file():
        return Response("not found", status=404)
    edi_name = name.replace("_snip.xml", ".edi")
    edi_path = OUTPUT_DIR / "edi" / edi_name
    snip_xml = snip_path.read_text(encoding="utf-8", errors="replace")
    edi_text = edi_path.read_text(encoding="utf-8", errors="replace") if edi_path.is_file() else ""
    try:
        from snip_report import build_snip_html, fallback_html
    except ImportError:
        return Response("<html><body>SNIP report helper missing</body></html>", mimetype="text/html")
    try:
        html = build_snip_html(snip_xml, edi_text)
    except Exception as exc:
        html = fallback_html(str(exc))
    return Response(html, mimetype="text/html")


@app.post("/api/inject")
def api_inject():
    try:
        with db_connect() as conn:
            cur = conn.cursor()
            cur.execute("UPDATE dbo.Claims SET Status = N'PENDING'")
            conn.commit()
        return jsonify({"ok": True, "reset": "PENDING"})
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc)}), 503


@app.post("/api/reset")
def api_reset():
    clear_dir(OUTPUT_DIR / "kickouts", ("*.xml",))
    clear_dir(OUTPUT_DIR / "edi", ("*.edi",))
    clear_dir(OUTPUT_DIR / "snip", ("*.xml",))
    clear_dir(OUTPUT_DIR / "bi", ("*.xml",))
    clear_dir(OUTPUT_DIR / "claims", ("*.xml",))
    return api_inject()


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
    eip = (os.environ.get("EIP_PUBLIC_URL") or EIP_PUBLIC_URL or "http://127.0.0.1:8114/eip/").replace("localhost", "127.0.0.1")
    lan = os.environ.get("LAN_HINT") or LAN_HINT or ""
    urls = [{"label": "Local Web UI", "href": f"http://127.0.0.1:{WEBUI_PORT}/"}]
    if lan:
        urls.append({"label": "LAN Web UI", "href": lan})
    urls.extend(
        [
            {"label": "EIP", "href": eip},
            {"label": "SQL Server", "value": SQL_PUBLIC, "note": "sa / PilotFish_Demo1! · Edi837ClaimScrub"},
        ]
    )
    return {
        "info_title": "EDI 837 Claim Scrub",
        "info_blurb": "SQL claims through payer edits, then a kickout work queue or clean 837 plus SNIP.",
        "info_note": "Synthetic payer rules. SNIP runs on the clean path only.",
        "eip_url": eip,
        "lan_hint": lan,
        "info_urls": urls,
        "info_ports": [
            {"label": "Demo Web UI", "value": str(WEBUI_PORT)},
            {"label": "PilotFish EIP", "value": "8114"},
            {"label": "SQL Server", "value": "14341"},
        ],
        "info_extra_links": [],
        "info_extra_sections": [],
        "test_results_pdf": "test-results.pdf",
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
