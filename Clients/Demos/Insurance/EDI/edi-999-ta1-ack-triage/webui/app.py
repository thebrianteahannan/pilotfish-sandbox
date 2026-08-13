#!/usr/bin/env python3
"""EDI 999 / TA1 Ack Triage — full demo Web UI (inject + buckets + routes theater)."""

from __future__ import annotations

import os
import re
import time
from datetime import datetime
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8129"))
INBOUND_DIR = Path(os.environ.get("INBOUND_DIR", "/inbound"))
ACCEPTED_DIR = Path(os.environ.get("ACCEPTED_DIR", "/output/accepted"))
REJECTED_DIR = Path(os.environ.get("REJECTED_DIR", "/output/rejected"))
ERROR_DIR = Path(os.environ.get("ERROR_DIR", "/output/error"))
REPORTS_DIR = Path(os.environ.get("REPORTS_DIR", "/output/reports"))
ARCHIVE_DIR = Path(os.environ.get("ARCHIVE_DIR", "/output/archive"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://localhost:8128/eip/")

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


@app.get("/")
def index():
    return render_template(
        "index.html",
        title="EDI 999 TA1 Ack Triage",
        lan_hint=LAN_HINT,
        eip_url=EIP_PUBLIC_URL,
    )


@app.get("/api/health")
def api_health():
    return jsonify(
        {
            "ok": True,
            "inbound": str(INBOUND_DIR),
            "inbound_exists": INBOUND_DIR.is_dir(),
            "buckets": {
                "accepted": ACCEPTED_DIR.is_dir(),
                "rejected": REJECTED_DIR.is_dir(),
                "error": ERROR_DIR.is_dir(),
                "reports": REPORTS_DIR.is_dir(),
            },
            "eip_url": EIP_PUBLIC_URL,
            "note": "Inject drops files into inbound. EIP must be running (compose profile full) to process them.",
        }
    )


@app.get("/api/samples")
def api_samples():
    files = list_text_files(SAMPLE_DIR, ("*.edi", "*.txt", "*.999", "*.ta1"))
    return jsonify({"files": files})


@app.post("/api/inject")
def api_inject():
    body = request.get_json(silent=True) or {}
    sample = (body.get("sample") or "").strip()
    content = body.get("content")
    if sample and not content:
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
        name = f"inject_{stamp}.edi"
    INBOUND_DIR.mkdir(parents=True, exist_ok=True)
    dest = INBOUND_DIR / name
    dest.write_text(str(content), encoding="utf-8")
    return jsonify({"ok": True, "file": name, "path": str(dest)})


@app.get("/api/accepted")
def api_accepted():
    return jsonify({"files": list_text_files(ACCEPTED_DIR)})


@app.get("/api/rejected")
def api_rejected():
    return jsonify({"files": list_text_files(REJECTED_DIR)})


@app.get("/api/error")
def api_error():
    return jsonify({"files": list_text_files(ERROR_DIR)})


@app.get("/api/reports")
def api_reports():
    return jsonify({"files": list_text_files(REPORTS_DIR)})


@app.get("/api/archive")
def api_archive():
    return jsonify({"files": list_text_files(ARCHIVE_DIR)})


@app.get("/api/wait-results")
def api_wait_results():
    """Poll buckets until any new file appears or timeout."""
    timeout = min(int(request.args.get("timeout", 60)), 180)
    before = float(request.args.get("since", 0) or 0)
    deadline = time.time() + timeout
    dirs = {
        "accepted": ACCEPTED_DIR,
        "rejected": REJECTED_DIR,
        "error": ERROR_DIR,
        "reports": REPORTS_DIR,
    }
    while time.time() < deadline:
        hits = []
        for label, d in dirs.items():
            for f in list_text_files(d):
                try:
                    mtime = Path(d / f["name"]).stat().st_mtime
                except OSError:
                    continue
                if mtime >= before:
                    hits.append({"bucket": label, **f})
        if hits:
            return jsonify({"ok": True, "files": hits})
        time.sleep(1.0)
    return jsonify({"ok": False, "error": "timeout waiting for bucket output", "files": []}), 408


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
        "info_title": "EDI 999 / TA1 Acknowledgment Triage",
        "info_blurb": "Ingest clearinghouse 999 and TA1 acknowledgments, classify accept vs reject vs error, and bucket results with an ops report.",
        "info_note": "Demo inject drops files into input/. Bring EIP up with compose profile full to process through the routes.",
        "eip_url": EIP_PUBLIC_URL,
        "lan_hint": LAN_HINT,
        "info_ports": [
            {"label": "Demo Web UI", "value": str(WEBUI_PORT)},
            {"label": "PilotFish EIP (planned)", "value": "8128"},
        ],
        "info_extra_links": [],
        "info_extra_sections": [],
        "test_results_pdf": None,
    }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
