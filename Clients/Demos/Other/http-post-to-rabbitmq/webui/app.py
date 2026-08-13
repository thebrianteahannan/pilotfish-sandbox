#!/usr/bin/env python3
"""HTTP POST → RabbitMQ demo web UI — inject a body, peek the queue, view routes."""

from __future__ import annotations

import json
import os
import re
from base64 import b64encode
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8135"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://localhost:8134/eip/")
EIP_POST_URL = os.environ.get("EIP_POST_URL", "http://pilotfish:8080/eip/http-post/ingress")
EIP_HEALTH_URL = os.environ.get("EIP_HEALTH_URL", "http://pilotfish:8080/eip/")
RABBITMQ_MGMT_URL = os.environ.get("RABBITMQ_MGMT_URL", "http://rabbitmq:15672").rstrip("/")
RABBITMQ_USER = os.environ.get("RABBITMQ_USER", "demo")
RABBITMQ_PASSWORD = os.environ.get("RABBITMQ_PASSWORD", "demo")
RABBITMQ_VHOST = os.environ.get("RABBITMQ_VHOST", "/")
RABBITMQ_QUEUE = os.environ.get("RABBITMQ_QUEUE", "demo.http.ingress")
ENV_SETTINGS_FILE = Path(os.environ.get("ENV_SETTINGS_FILE", "/environment-settings.conf"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "HTTP_POST_To_RabbitMQ_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get("CAPABILITY_PDF_NAME", "HTTP_POST_To_RabbitMQ_Capability_Brief.pdf")

_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
_SAFE_SAMPLE = re.compile(r"^[A-Za-z0-9._-]+\.json$", re.I)
_SENSITIVE_ENV = re.compile(
    r"(password|secret|token|apikey|api[_-]?key|private[_-]?key|passphrase|credential)",
    re.I,
)


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def list_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.glob("*/route.v2.xml")):
        name = path.parent.name
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
            m = re.search(r'<Route[^>]*\bname="([^"]+)"', text)
            if m:
                name = m.group(1)
        except OSError:
            pass
        out.append(
            {
                "id": route_slug(path.parent.name),
                "dir": path.parent.name,
                "name": name,
                "mtime": path.stat().st_mtime,
            }
        )
    return out


def resolve_route_dir(route_id: str) -> Path | None:
    if not route_id or not _ROUTE_SLUG.match(route_id):
        return None
    for meta in list_v2_routes():
        if meta["id"] == route_id:
            candidate = (ROUTES_DIR / meta["dir"]).resolve()
            try:
                candidate.relative_to(ROUTES_DIR.resolve())
            except ValueError:
                return None
            if (candidate / "route.v2.xml").is_file():
                return candidate
    return None


def rabbit_request(method: str, path: str, body: dict | None = None):
    url = RABBITMQ_MGMT_URL + path
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = Request(url, data=data, method=method)
    token = b64encode(f"{RABBITMQ_USER}:{RABBITMQ_PASSWORD}".encode()).decode("ascii")
    req.add_header("Authorization", f"Basic {token}")
    if body is not None:
        req.add_header("Content-Type", "application/json")
    with urlopen(req, timeout=8) as resp:
        raw = resp.read().decode("utf-8", errors="replace")
        return json.loads(raw) if raw.strip() else {}


def vhost_enc() -> str:
    return quote(RABBITMQ_VHOST or "/", safe="")


@app.get("/")
def index():
    return render_template(
        "index.html",
        title="HTTP POST To RabbitMQ",
        lan_hint=LAN_HINT,
        eip_url=EIP_PUBLIC_URL,
    )


@app.get("/api/health")
def api_health():
    eip = False
    try:
        with urlopen(EIP_HEALTH_URL, timeout=3) as resp:
            eip = 200 <= resp.status < 500
    except (URLError, OSError, TimeoutError):
        eip = False
    rabbit = False
    try:
        rabbit_request("GET", "/api/overview")
        rabbit = True
    except (URLError, OSError, TimeoutError, HTTPError, json.JSONDecodeError):
        rabbit = False
    return jsonify({"ok": True, "eip": eip, "rabbitmq": rabbit, "queue": RABBITMQ_QUEUE})


@app.get("/api/samples")
def api_samples():
    files = []
    if SAMPLE_DIR.is_dir():
        for path in sorted(SAMPLE_DIR.glob("*.json")):
            if not path.is_file() or path.name.startswith("."):
                continue
            files.append(
                {
                    "name": path.name,
                    "content": path.read_text(encoding="utf-8", errors="replace"),
                    "size": path.stat().st_size,
                }
            )
    return jsonify({"ok": True, "files": files})


@app.post("/api/inject")
def api_inject():
    payload = request.get_json(silent=True) or {}
    body = payload.get("body")
    sample = str(payload.get("sample") or "")
    if not body and sample and _SAFE_SAMPLE.match(sample):
        path = SAMPLE_DIR / sample
        if path.is_file():
            body = path.read_text(encoding="utf-8")
    if body is None:
        return jsonify({"ok": False, "error": "No body"}), 400
    data = body.encode("utf-8") if isinstance(body, str) else body
    req = Request(EIP_POST_URL, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    try:
        with urlopen(req, timeout=70) as resp:
            status = resp.status
            reply = resp.read().decode("utf-8", errors="replace")
    except HTTPError as e:
        reply = e.read().decode("utf-8", errors="replace") if e.fp else ""
        return jsonify({"ok": False, "error": f"EIP HTTP {e.code}", "response": reply[:2000]}), 502
    except (URLError, TimeoutError, OSError) as e:
        return jsonify({"ok": False, "error": f"EIP unreachable: {e}"}), 503
    return jsonify({"ok": True, "status": status, "response": reply[:2000], "bytes": len(data)})


@app.get("/api/queue")
def api_queue():
    try:
        info = rabbit_request("GET", f"/api/queues/{vhost_enc()}/{RABBITMQ_QUEUE}")
        messages = rabbit_request(
            "POST",
            f"/api/queues/{vhost_enc()}/{RABBITMQ_QUEUE}/get",
            {
                "count": 10,
                "ackmode": "ack_requeue_true",
                "encoding": "auto",
                "truncate": 20000,
            },
        )
    except HTTPError as e:
        if e.code == 404:
            return jsonify({"ok": True, "ready": False, "messages": [], "messageCount": 0})
        return jsonify({"ok": False, "error": f"RabbitMQ HTTP {e.code}"}), 502
    except (URLError, TimeoutError, OSError, json.JSONDecodeError) as e:
        return jsonify({"ok": False, "error": str(e)}), 503
    rows = []
    for item in messages or []:
        payload = item.get("payload") or ""
        rows.append(
            {
                "name": f"msg-{item.get('message_count', len(rows))}",
                "content": payload,
                "size": len(payload),
            }
        )
    rows.sort(key=lambda r: int(str(r.get("name") or "msg-0").rsplit("-", 1)[-1] or 0))
    return jsonify(
        {
            "ok": True,
            "ready": True,
            "queue": RABBITMQ_QUEUE,
            "messageCount": info.get("messages", 0) if isinstance(info, dict) else 0,
            "messages": rows,
            "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
    )


@app.get("/api/v2/routes")
def api_routes():
    return jsonify({"routes": list_v2_routes()})


@app.get("/api/v2/routes/<route_id>/route.v2.xml")
def api_route_xml(route_id: str):
    route_dir = resolve_route_dir(route_id)
    if not route_dir:
        return Response("not found", status=404)
    return send_file(route_dir / "route.v2.xml", mimetype="application/xml")


@app.get("/api/v2/routes/<route_id>/diagram-groups.json")
def api_route_groups(route_id: str):
    route_dir = resolve_route_dir(route_id)
    if not route_dir:
        return jsonify({"groups": []})
    path = route_dir / "diagram-groups.json"
    if path.is_file():
        return send_file(path, mimetype="application/json")
    return jsonify({"groups": []})


@app.get("/api/v2/routes/<route_id>/modules/<module_id>.xml")
def api_module_xml(route_id: str, module_id: str):
    if not _MODULE_ID.match(module_id):
        return Response("bad id", status=400)
    route_dir = resolve_route_dir(route_id)
    if not route_dir:
        return Response("not found", status=404)
    path = route_dir / "modules" / f"{module_id}.xml"
    if path.is_file():
        return send_file(path, mimetype="application/xml")
    return Response("not found", status=404)


@app.get("/api/v2/environment-settings")
def api_environment_settings():
    settings: dict[str, str] = {}
    if ENV_SETTINGS_FILE.is_file():
        for line in ENV_SETTINGS_FILE.read_text(encoding="utf-8", errors="replace").splitlines():
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, val = line.split("=", 1)
            settings[key.strip()] = val.strip()
    safe = {}
    for key, val in settings.items():
        safe[key] = "••••••••" if _SENSITIVE_ENV.search(key) else val
    return jsonify({"ok": True, "settings": safe})


_INFO_TAB_CTX = {
    "info_title": "HTTP POST To RabbitMQ",
    "info_blurb": "POST a payload to PilotFish. The route publishes the same bytes to a RabbitMQ queue.",
    "info_note": "Demo only — no HTTP auth, no TLS, demo/demo on RabbitMQ.",
    "eip_url": EIP_PUBLIC_URL,
    "lan_hint": LAN_HINT,
    "info_ports": [
        {"label": "PilotFish EIP", "value": "8134"},
        {"label": "Demo Web UI", "value": "8135"},
        {"label": "RabbitMQ AMQP", "value": "5673"},
        {"label": "RabbitMQ management", "value": "15673"},
    ],
    "info_extra_links": [],
    "info_extra_sections": [],
    "test_results_pdf": None,
}


@app.context_processor
def _info_tab_standard_context():
    ctx = dict(_INFO_TAB_CTX)
    eip = (os.environ.get("EIP_PUBLIC_URL") or ctx.get("eip_url") or "http://127.0.0.1:8134/eip/").replace(
        "localhost", "127.0.0.1"
    )
    lan = os.environ.get("LAN_HINT") or ctx.get("lan_hint") or ""
    ctx["eip_url"] = eip
    ctx["lan_hint"] = lan
    urls = [
        {"label": "Local Web UI", "href": f"http://127.0.0.1:{WEBUI_PORT}/"},
    ]
    if lan:
        urls.append({"label": "LAN Web UI", "href": lan})
    urls.extend(
        [
            {"label": "EIP", "href": eip},
            {
                "label": "HTTP POST",
                "href": "http://127.0.0.1:8134/eip/http-post/ingress",
            },
            {
                "label": "RabbitMQ management",
                "href": "http://127.0.0.1:15673/",
                "note": "demo / demo",
            },
            {
                "label": "RabbitMQ AMQP",
                "value": "127.0.0.1:5673",
                "note": "demo / demo",
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
