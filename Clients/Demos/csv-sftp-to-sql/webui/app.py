#!/usr/bin/env python3
"""CSV SFTP To SQL — Demo Web UI (inject to SFTP + SQL rows + routes theater)."""

from __future__ import annotations

import os
import re
import time
from datetime import datetime
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8133"))
SFTP_UPLOAD_DIR = Path(os.environ.get("SFTP_UPLOAD_DIR", "/sftp-upload"))
ARCHIVE_DIR = Path(os.environ.get("ARCHIVE_DIR", "/output/archive"))
STAGED_DIR = Path(os.environ.get("STAGED_DIR", "/input/staged"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://localhost:8132/eip/")
SFTP_HINT = os.environ.get("SFTP_HINT", "localhost:2224 demo/demo upload/")

DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "14341"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "CsvSftpDemo")

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
        out.append(
            {
                "id": route_slug(path.parent.name),
                "name": path.parent.name,
                "mtime": path.stat().st_mtime,
            }
        )
    return out


def list_text_files(directory: Path, patterns: tuple[str, ...] = ("*",)):
    if not directory.is_dir():
        return []
    files: list[Path] = []
    for pat in patterns:
        files.extend(directory.glob(pat))
    files = sorted(
        {p for p in files if p.is_file() and not p.name.startswith(".")},
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
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

    return pymssql.connect(
        server=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        login_timeout=5,
    )


@app.get("/")
def index():
    return render_template(
        "index.html",
        title="CSV SFTP To SQL",
        lan_hint=LAN_HINT,
        eip_url=EIP_PUBLIC_URL,
        sftp_hint=SFTP_HINT,
    )


@app.get("/api/health")
def api_health():
    db_ok = False
    db_err = None
    try:
        with db_connect() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
            db_ok = True
    except Exception as exc:  # noqa: BLE001
        db_err = str(exc)
    return jsonify(
        {
            "ok": True,
            "sftp_upload": str(SFTP_UPLOAD_DIR),
            "sftp_exists": SFTP_UPLOAD_DIR.is_dir(),
            "db_ok": db_ok,
            "db_error": db_err,
            "eip_url": EIP_PUBLIC_URL,
            "sftp_hint": SFTP_HINT,
        }
    )


@app.get("/api/samples")
def api_samples():
    return jsonify({"files": list_text_files(SAMPLE_DIR, ("*.csv",))})


@app.post("/api/inject")
def api_inject():
    body = request.get_json(silent=True) or {}
    sample = (body.get("sample") or "").strip()
    content = body.get("content")
    if sample and content is None:
        path = SAMPLE_DIR / sample
        if not path.is_file() or not _SAFE_NAME.match(sample):
            return jsonify({"error": "unknown sample"}), 400
        content = path.read_text(encoding="utf-8", errors="replace")
        name = sample
    else:
        content = content if content is not None else ""
        if not str(content).strip():
            return jsonify({"error": "empty content"}), 400
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        name = f"inject_{stamp}.csv"
    if not name.lower().endswith(".csv"):
        name = f"{name}.csv"
    SFTP_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    dest = SFTP_UPLOAD_DIR / name
    dest.write_text(str(content), encoding="utf-8")
    return jsonify({"ok": True, "file": name, "path": str(dest)})


@app.get("/api/patients")
def api_patients():
    try:
        with db_connect() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                """
                SELECT TOP 50 RowId, PatientId, FirstName, LastName, DateOfBirth,
                       City, StateCode, SourceFile, LoadedAt
                FROM dbo.CsvPatients
                ORDER BY RowId DESC
                """
            )
            rows = cur.fetchall()
            for r in rows:
                for k, v in list(r.items()):
                    if hasattr(v, "isoformat"):
                        r[k] = v.isoformat()
            return jsonify({"ok": True, "rows": rows})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc), "rows": []}), 503


@app.get("/api/archive")
def api_archive():
    return jsonify({"files": list_text_files(ARCHIVE_DIR, ("*.csv", "*"))})


@app.get("/api/staged")
def api_staged():
    return jsonify({"files": list_text_files(STAGED_DIR, ("*.csv",))})


@app.get("/api/wait-patients")
def api_wait_patients():
    timeout = min(int(request.args.get("timeout", 60)), 180)
    before = int(request.args.get("before", 0) or 0)
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with db_connect() as conn:
                cur = conn.cursor(as_dict=True)
                cur.execute(
                    """
                    SELECT TOP 20 RowId, PatientId, FirstName, LastName, City, StateCode, LoadedAt
                    FROM dbo.CsvPatients
                    WHERE RowId > %s
                    ORDER BY RowId DESC
                    """,
                    (before,),
                )
                rows = cur.fetchall()
                if rows:
                    for r in rows:
                        for k, v in list(r.items()):
                            if hasattr(v, "isoformat"):
                                r[k] = v.isoformat()
                    return jsonify({"ok": True, "rows": rows})
        except Exception:
            pass
        time.sleep(1.5)
    return jsonify({"ok": False, "error": "timeout waiting for SQL rows", "rows": []}), 408


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
    ensure_document_routes(app, DOCUMENTS_DIR)
if ensure_build_timing_api is not None:
    ensure_build_timing_api(app, DOCUMENTS_DIR)
if ensure_build_status_api is not None:
    ensure_build_status_api(app, DOCUMENTS_DIR)
if ensure_build_replay_api is not None:
    ensure_build_replay_api(app, DOCUMENTS_DIR)
if ensure_build_experience_api is not None:
    ensure_build_experience_api(app, DOCUMENTS_DIR)


@app.context_processor
def _info_ctx():
    return {
        "info_title": "CSV SFTP To SQL",
        "info_blurb": "Poll a CSV from SFTP, stage locally, parse with CSV→XML, insert rows into SQL Server.",
        "info_note": "Demo inject drops CSV into the SFTP upload folder. EIP polls every ~10s.",
        "eip_url": EIP_PUBLIC_URL,
        "lan_hint": LAN_HINT,
        "info_ports": [
            {"label": "Demo Web UI", "value": str(WEBUI_PORT)},
            {"label": "PilotFish EIP", "value": "8132"},
            {"label": "SFTP", "value": "2224"},
            {"label": "SQL Server", "value": "14341"},
        ],
        "info_extra_links": [
            {
                "href": "/documents/construction-replay.mp4",
                "label": "Construction replay video (MP4)",
            },
            {
                "href": "/documents/construction-replay-transcript.pdf",
                "label": "Construction replay transcript (PDF)",
            },
            {
                "href": "/documents/construction-replay-transcript.txt",
                "label": "Construction replay transcript (plain text)",
            },
        ],
        "info_extra_sections": [],
        "test_results_pdf": None,
    }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
