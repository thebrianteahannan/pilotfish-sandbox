#!/usr/bin/env python3
"""EDI 270/271 Realtime Eligibility — clinic UI (one POST to PilotFish /check)."""

from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path
from urllib.error import URLError
from urllib.request import Request, urlopen
from xml.sax.saxutils import escape

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8121"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/output"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://127.0.0.1:8120/eip/")
EIP_HEALTH_URL = os.environ.get("EIP_HEALTH_URL", "http://pilotfish:8080/eip/")
PF_BASE = os.environ.get("PF_ELIGIBILITY_BASE_URL", "http://pilotfish:8080/eip/rest/eligibility").rstrip("/")
PF_PUBLIC = os.environ.get("PF_PUBLIC_BASE_URL", "http://127.0.0.1:8120/eip/rest/eligibility").rstrip("/")
PAYER_PUBLIC = os.environ.get("MOCK_PAYER_PUBLIC_URL", "http://127.0.0.1:8211/x12/270")
PAYER_HEALTH = os.environ.get("MOCK_PAYER_HEALTH_URL", "http://mock-payer:8210/health")
ROUTE_PDF_NAME = "EDI270_271_Realtime_V2_Route_Diagrams.pdf"
CAPABILITY_PDF_NAME = "EDI270_271_Realtime_Capability_Brief.pdf"
DIFF_PDF_NAME = os.environ.get("DIFF_PDF_NAME", "EDI270_271_Orig_vs_Realtime_Differences.pdf")

_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

PRESETS = [
    {
        "id": "aaa",
        "label": "Jane Doe — FAIL001 (AAA theater)",
        "MemberId": "FAIL001",
        "LastName": "DOE",
        "FirstName": "JANE",
        "BirthDate": "19800115",
        "Gender": "F",
    },
    {
        "id": "success",
        "label": "John Smith — OK001 (active benefits)",
        "MemberId": "OK001",
        "LastName": "SMITH",
        "FirstName": "JOHN",
        "BirthDate": "19800515",
        "Gender": "M",
    },
    {
        "id": "unknown",
        "label": "Pat Lee — UNKNOWN (AAA 75 not found)",
        "MemberId": "UNKNOWN",
        "LastName": "LEE",
        "FirstName": "PAT",
        "BirthDate": "19751201",
        "Gender": "U",
    },
]


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def list_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.glob("*/route.v2.xml")):
        out.append({"id": route_slug(path.parent.name), "name": path.parent.name, "mtime": path.stat().st_mtime})
    return out


def http_call(url: str, body: bytes, content_type: str, timeout: int = 90) -> tuple[int, str]:
    req = Request(url, data=body, method="POST", headers={"Content-Type": content_type})
    try:
        with urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace")
    except URLError as exc:
        return 599, str(exc)


def probe(url: str) -> bool:
    try:
        with urlopen(url, timeout=3) as resp:
            return resp.status < 500
    except Exception:
        return False


def build_request_xml(payload: dict) -> str:
    fields = {
        "MemberId": payload.get("MemberId") or "",
        "LastName": payload.get("LastName") or "",
        "FirstName": payload.get("FirstName") or "",
        "BirthDate": payload.get("BirthDate") or "",
        "Gender": payload.get("Gender") or "",
        "ServiceTypeCode": payload.get("ServiceTypeCode") or "30",
        "TraceNumber": payload.get("TraceNumber") or f"T{int(time.time())}",
        "ServiceDate": payload.get("ServiceDate") or time.strftime("%Y%m%d"),
        "PayerId": payload.get("PayerId") or "MOCKPAYER",
        "PayerName": payload.get("PayerName") or "MOCK PAYER",
        "ProviderNpi": payload.get("ProviderNpi") or "1234567893",
        "ProviderName": payload.get("ProviderName") or "PILOTFISH DEMO CLINIC",
    }
    inner = "".join(f"<{k}>{escape(str(v))}</{k}>" for k, v in fields.items())
    return f"<?xml version='1.0' encoding='UTF-8'?><EligibilityRequest>{inner}</EligibilityRequest>"


def list_recent(subdir: str, patterns: tuple[str, ...]):
    folder = OUTPUT_DIR / subdir
    if not folder.is_dir():
        return []
    files = []
    for pat in patterns:
        files.extend(folder.glob(pat))
    files = sorted({p for p in files if p.is_file()}, key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for path in files[:20]:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        out.append({"name": path.name, "size": path.stat().st_size, "content": text[:8000]})
    return out


def newest_preview(subdir: str, patterns: tuple[str, ...]) -> str:
    items = list_recent(subdir, patterns)
    return items[0]["content"] if items else ""


@app.get("/")
def index():
    return render_template("index.html", title="EDI 270/271 Realtime Eligibility", presets=PRESETS)


@app.get("/api/health")
def api_health():
    eip = probe(EIP_HEALTH_URL)
    payer = probe(PAYER_HEALTH)
    return jsonify({"ok": eip and payer, "eip": eip, "payer": payer})


@app.post("/api/check-eligibility")
def check_eligibility():
    payload = request.get_json(silent=True) or {}
    steps: list[dict] = []
    req_xml = build_request_xml(payload)
    steps.append({"step": "request_xml", "ok": True, "body": req_xml})
    t0 = time.time()
    code, summary_text = http_call(f"{PF_BASE}/check", req_xml.encode("utf-8"), "application/xml; charset=UTF-8")
    elapsed_ms = int((time.time() - t0) * 1000)
    try:
        summary = json.loads(summary_text)
    except json.JSONDecodeError:
        summary = {"raw": summary_text}
    ok = code < 400 and isinstance(summary, dict) and "status" in summary
    steps.append(
        {
            "step": "pf_realtime_check",
            "ok": ok,
            "status": code,
            "elapsedMs": elapsed_ms,
            "endpoint": f"{PF_PUBLIC}/check",
            "body": summary_text[:4000],
            "note": "Single sync REST call; PilotFish posted 270 to payer and parsed 271",
        }
    )
    edi270 = newest_preview("270", ("*.edi",))
    edi271 = newest_preview("271", ("*.edi",))
    if edi270:
        steps.append({"step": "build_270", "ok": True, "body": edi270})
    if edi271:
        steps.append({"step": "payer_271", "ok": True, "body": edi271})
    steps.append({"step": "parse_271", "ok": ok, "body": summary_text[:4000]})
    return jsonify(
        {
            "ok": ok,
            "mode": "realtime",
            "elapsedMs": elapsed_ms,
            "summary": summary,
            "steps": steps,
        }
    )


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


@app.get("/documents/differences.pdf")
def differences_pdf():
    path = DOCUMENTS_DIR / DIFF_PDF_NAME
    if not path.is_file():
        return Response("Differences PDF not found", status=404)
    return send_file(path, mimetype="application/pdf")


@app.context_processor
def _info_tab_standard_context():
    eip = (os.environ.get("EIP_PUBLIC_URL") or EIP_PUBLIC_URL or "http://127.0.0.1:8120/eip/").replace("localhost", "127.0.0.1")
    lan = os.environ.get("LAN_HINT") or LAN_HINT or ""
    urls = [{"label": "Local Web UI", "href": f"http://127.0.0.1:{WEBUI_PORT}/"}]
    if lan:
        urls.append({"label": "LAN Web UI", "href": lan})
    urls.extend(
        [
            {"label": "EIP", "href": eip},
            {"label": "Eligibility check", "href": f"{PF_PUBLIC}/check", "note": "POST EligibilityRequest XML"},
            {"label": "Mock payer", "href": PAYER_PUBLIC, "note": "POST X12 270 → 271"},
        ]
    )
    return {
        "info_title": "EDI 270/271 Realtime Eligibility",
        "info_blurb": "One clinic POST. PilotFish builds the 270, calls the payer, and returns AAA or benefits JSON on the same request.",
        "info_note": "Demo only — canned AAA/EB, no SNIP, no real payer.",
        "eip_url": eip,
        "lan_hint": lan,
        "info_urls": urls,
        "info_ports": [
            {"label": "Demo Web UI", "value": str(WEBUI_PORT)},
            {"label": "PilotFish EIP", "value": "8120"},
            {"label": "Mock payer", "value": "8211"},
        ],
        "info_extra_links": [{"href": "/documents/differences.pdf", "label": "How this differs from edi-270-271-eligibility"}],
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
    ensure_document_routes = None
    ensure_build_timing_api = None
    ensure_build_status_api = None
    ensure_build_replay_api = None
    ensure_build_experience_api = None

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
