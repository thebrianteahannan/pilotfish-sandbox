#!/usr/bin/env python3
"""FHIR Patient Exchange demo — Web UI acts as a FHIR REST client."""

from __future__ import annotations

import json
import os
import re
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

import pymssql
from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "FhirPatientExchangeDemo")
FHIR_STORE_DIR = Path(os.environ.get("FHIR_STORE_DIR", "/output/fhir-store"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
ROUTES_DIR = Path(
    os.environ.get(
        "ROUTES_DIR",
        str(
            Path(__file__).resolve().parent.parent
            / "eip-root"
            / "interfaces"
            / "FHIR Patient Exchange"
            / "routes"
        ),
    )
)
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "FHIR_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get("CAPABILITY_PDF_NAME", "FHIR_Capability_Brief.pdf")
RESEARCH_PDF_NAME = os.environ.get("RESEARCH_PDF_NAME", "FHIR_REST_Interface_Research.pdf")
WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8103"))
# In-compose PilotFish base for server-side proxy calls
FHIR_BASE_URL = os.environ.get("FHIR_BASE_URL", "http://pilotfish:8080/eip/rest/fhir").rstrip("/")
# Shown to users (LAN / localhost EIP publish)
FHIR_PUBLIC_BASE_URL = os.environ.get(
    "FHIR_PUBLIC_BASE_URL", "http://192.168.68.52:8102/eip/rest/fhir"
).rstrip("/")

_MODULE_ID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
_SENSITIVE_ENV = re.compile(
    r"(password|secret|token|apikey|api[_-]?key|private[_-]?key|passphrase|credential)",
    re.I,
)
_XSLT_SUFFIXES = {".xsl", ".xslt"}


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


def db_error(exc: Exception, status: int = 503):
    msg = str(exc)
    if "Adaptive Server is unavailable" in msg or "20009" in msg:
        msg = "SQL Server is unavailable. Wait a few seconds and try again."
    return jsonify({"ok": False, "error": msg}), status


def list_text_files(directory: Path, pattern: str):
    if not directory.exists():
        return []
    files = sorted(directory.glob(pattern), key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for path in files:
        if path.name.startswith("."):
            continue
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


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def discover_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.iterdir(), key=lambda p: p.name.lower()):
        if not path.is_dir():
            continue
        v2 = path / "route.v2.xml"
        if not v2.is_file():
            continue
        name = path.name
        try:
            text = v2.read_text(encoding="utf-8", errors="replace")
            m = re.search(r'<Route[^>]*\bname="([^"]+)"', text)
            if m:
                name = m.group(1)
        except OSError:
            pass
        out.append({"id": route_slug(path.name), "dir": path.name, "name": name})
    return out


def resolve_route_dir(route_id: str) -> Path | None:
    if not route_id or not _ROUTE_SLUG.match(route_id):
        return None
    for meta in discover_v2_routes():
        if meta["id"] == route_id:
            candidate = (ROUTES_DIR / meta["dir"]).resolve()
            try:
                candidate.relative_to(ROUTES_DIR.resolve())
            except ValueError:
                return None
            if (candidate / "route.v2.xml").is_file():
                return candidate
    return None


def discover_xslt_files() -> list[dict]:
    if not ROUTES_DIR.is_dir():
        return []
    out: list[dict] = []
    root = ROUTES_DIR.resolve()
    for path in sorted(ROUTES_DIR.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in _XSLT_SUFFIXES:
            continue
        try:
            rel = path.resolve().relative_to(root).as_posix()
        except ValueError:
            continue
        out.append(
            {
                "path": rel,
                "name": path.name,
                "route": path.parent.name if path.parent != ROUTES_DIR else "",
                "bytes": path.stat().st_size,
            }
        )
    return out


def resolve_xslt_path(rel: str) -> Path | None:
    if not rel or Path(rel).is_absolute() or ".." in Path(rel).parts:
        return None
    candidate = (ROUTES_DIR / rel).resolve()
    try:
        candidate.relative_to(ROUTES_DIR.resolve())
    except ValueError:
        return None
    if candidate.is_file() and candidate.suffix.lower() in _XSLT_SUFFIXES:
        return candidate
    return None


def call_fhir(method: str, path: str, body: str | None = None) -> dict:
    url = f"{FHIR_BASE_URL}/{path.lstrip('/')}"
    data = None if body is None else body.encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        method=method.upper(),
        headers={
            "Accept": "application/fhir+json",
            "Content-Type": "application/fhir+json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            return {
                "ok": 200 <= resp.status < 300,
                "status": resp.status,
                "headers": {k: v for k, v in resp.headers.items()},
                "body": raw,
                "url": url,
            }
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        return {
            "ok": False,
            "status": exc.code,
            "headers": {k: v for k, v in exc.headers.items()} if exc.headers else {},
            "body": raw,
            "url": url,
            "error": str(exc),
        }
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "status": 0, "headers": {}, "body": "", "url": url, "error": str(exc)}


@app.get("/")
def index():
    return render_template(
        "index.html",
        lan_hint=os.environ.get("LAN_HINT", ""),
        eip_url="http://localhost:8102/eip/",
        fhir_public_base=FHIR_PUBLIC_BASE_URL,
        case_study_url="https://healthcare.pilotfishtechnology.com/fhir-integration-cms-0057-f-compliance/",
        has_xslt=bool(discover_xslt_files()),
    )


@app.get("/api/health")
def api_health():
    try:
        with db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
        return jsonify({"ok": True, "sqlserver": "up", "fhirBase": FHIR_PUBLIC_BASE_URL})
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.get("/api/samples")
def api_samples():
    files = list_text_files(SAMPLE_DIR, "*.json")
    return jsonify({"ok": True, "files": [{"name": f["name"], "content": f["content"]} for f in files]})


@app.get("/api/resources")
def api_resources():
    try:
        with db() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                """
                SELECT TOP 50
                  ResourceRowId, SourceCode, ResourceType, ResourceId, PatientId, PatientName,
                  ValidationStatus, SourceFile,
                  CONVERT(VARCHAR(19), ReceivedAt, 126) AS ReceivedAt
                FROM dbo.FhirResources
                ORDER BY ResourceRowId DESC
                """
            )
            return jsonify({"ok": True, "messages": cur.fetchall()})
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.get("/api/fhir-store")
def api_fhir_store():
    return jsonify({"ok": True, "files": list_text_files(FHIR_STORE_DIR, "*.json")})


@app.post("/api/fhir/create")
def api_fhir_create():
    payload = request.get_json(force=True, silent=True) or {}
    sample = (payload.get("sample") or "").strip()
    raw = (payload.get("fhir") or "").strip()
    if sample:
        path = SAMPLE_DIR / sample
        if not path.is_file() or path.suffix.lower() != ".json":
            return jsonify({"ok": False, "error": "Unknown sample"}), 400
        raw = path.read_text(encoding="utf-8", errors="replace")
    if not raw:
        return jsonify({"ok": False, "error": "No FHIR content"}), 400
    try:
        json.loads(raw)
    except json.JSONDecodeError as exc:
        return jsonify({"ok": False, "error": f"Invalid JSON: {exc}"}), 400
    result = call_fhir("POST", "Patient", raw)
    return jsonify(result), (200 if result.get("status") else 502)


@app.get("/api/fhir/read/<path:resource_id>")
def api_fhir_read(resource_id: str):
    rid = (resource_id or "").strip()
    if not rid or "/" in rid or ".." in rid:
        return jsonify({"ok": False, "error": "Invalid resource id"}), 400
    result = call_fhir("GET", f"Patient/{rid}")
    return jsonify(result), (200 if result.get("status") else 502)


@app.get("/api/v2/routes")
def api_v2_routes():
    return jsonify({"ok": True, "routes": discover_v2_routes(), "routesDir": str(ROUTES_DIR)})


@app.get("/api/v2/routes/<route_id>/route.v2.xml")
def api_v2_route_xml(route_id: str):
    route_dir = resolve_route_dir(route_id)
    if not route_dir:
        return Response("Route not found", status=404, mimetype="text/plain")
    return Response(
        (route_dir / "route.v2.xml").read_text(encoding="utf-8", errors="replace"),
        mimetype="application/xml; charset=utf-8",
    )


@app.get("/api/v2/routes/<route_id>/diagram-groups.json")
def api_v2_diagram_groups(route_id: str):
    """Optional docs-only Processor Group definitions for route diagrams."""
    d = resolve_route_dir(route_id)
    if not d:
        return Response("Not found", status=404)
    path = d / "diagram-groups.json"
    if not path.is_file():
        return jsonify({"ok": True, "groups": []})
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return jsonify({"ok": False, "groups": [], "message": "Invalid diagram-groups.json"}), 500
    if not isinstance(data, dict):
        data = {"groups": data if isinstance(data, list) else []}
    data.setdefault("ok", True)
    data.setdefault("groups", [])
    return jsonify(data)


@app.get("/api/v2/routes/<route_id>/modules/<module_id>.xml")
def api_v2_module_xml(route_id: str, module_id: str):
    if not _MODULE_ID.match(module_id):
        return Response("Invalid module id", status=400, mimetype="text/plain")
    route_dir = resolve_route_dir(route_id)
    if not route_dir:
        return Response("Route not found", status=404, mimetype="text/plain")
    path = route_dir / "modules" / f"{module_id}.xml"
    if not path.is_file():
        return Response("Module not found", status=404, mimetype="text/plain")
    return Response(path.read_text(encoding="utf-8", errors="replace"), mimetype="application/xml; charset=utf-8")


@app.get("/api/v2/xslt")
def api_xslt_list():
    return jsonify({"ok": True, "files": discover_xslt_files()})


@app.get("/api/v2/xslt/content")
def api_xslt_content():
    rel = (request.args.get("path") or "").strip()
    path = resolve_xslt_path(rel)
    if not path:
        return Response("XSLT not found", status=404, mimetype="text/plain")
    return Response(
        path.read_text(encoding="utf-8", errors="replace"),
        mimetype="application/xml; charset=utf-8",
    )


def _env_settings_candidates() -> list[Path]:
    demo = Path(__file__).resolve().parent.parent
    return [
        Path(os.environ.get("ENV_SETTINGS_FILE", "/environment-settings.conf")),
        demo / "pilotfish" / "demo-eip-root" / "environment-settings.conf",
    ]


def load_environment_settings() -> tuple[Path | None, dict[str, str]]:
    for path in _env_settings_candidates():
        if not path.is_file():
            continue
        settings: dict[str, str] = {}
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            s = line.strip()
            if not s or s.startswith("#") or "=" not in s:
                continue
            key, val = s.split("=", 1)
            settings[key.strip()] = val.strip().replace(r"\:", ":").replace(r"\=", "=")
        return path, settings
    return None, {}


@app.get("/api/v2/environment-settings")
def api_environment_settings():
    path, settings = load_environment_settings()
    safe: dict[str, str] = {}
    redacted: list[str] = []
    for key, val in settings.items():
        if _SENSITIVE_ENV.search(key):
            safe[key] = "••••••••"
            redacted.append(key)
        else:
            safe[key] = val
    return jsonify({"ok": True, "path": str(path) if path else None, "settings": safe, "redacted": redacted})


def _doc_path(name: str) -> Path | None:
    for base in (DOCUMENTS_DIR, Path(__file__).resolve().parent.parent / "documents"):
        path = base / name
        if path.is_file():
            return path
    return None


@app.get("/documents/route-diagrams.pdf")
def route_diagrams_pdf():
    path = _doc_path(ROUTE_PDF_NAME)
    if not path:
        return ("Route design PDF not found.", 404)
    return send_file(path, mimetype="application/pdf", as_attachment=False, download_name=ROUTE_PDF_NAME)


@app.get("/documents/fhir-rest-research.pdf")
def fhir_rest_research_pdf():
    path = _doc_path(RESEARCH_PDF_NAME)
    if not path:
        return ("FHIR REST research PDF not found.", 404)
    return send_file(path, mimetype="application/pdf", as_attachment=False, download_name=RESEARCH_PDF_NAME)


@app.get("/documents/<path:name>")
def documents_file(name: str):
    if not name or name.startswith(".") or "/" in name or "\\" in name or ".." in name:
        return ("Not found", 404)
    path = _doc_path(name)
    if not path:
        return ("Not found", 404)
    mime = "application/pdf" if path.suffix.lower() == ".pdf" else "application/octet-stream"
    return send_file(path, mimetype=mime, as_attachment=False, download_name=path.name)



@app.get("/documents/capability-brief.pdf")
def capability_pdf_alias():
    path = DOCUMENTS_DIR / CAPABILITY_PDF_NAME
    if path.is_file():
        return send_file(path)
    return Response(
        "Capability brief not generated yet. Run: python3 tools/export_stakeholder_brief.py",
        status=404,
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
