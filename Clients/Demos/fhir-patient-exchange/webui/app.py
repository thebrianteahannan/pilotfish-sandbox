#!/usr/bin/env python3
"""FHIR Patient Exchange demo web UI."""

from __future__ import annotations

import json
import os
import re
import time
import uuid
from datetime import datetime
from pathlib import Path
from xml.sax.saxutils import escape as xml_escape

import pymssql
from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "FhirPatientExchangeDemo")
INBOUND_DIR = Path(os.environ.get("INBOUND_DIR", "/inbound"))
FHIR_STORE_DIR = Path(os.environ.get("FHIR_STORE_DIR", "/output/fhir-store"))
VALIDATION_DIR = Path(os.environ.get("VALIDATION_DIR", "/output/validation"))
KICKOUT_DIR = Path(os.environ.get("KICKOUT_DIR", "/output/kickout"))
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
WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8103"))

_MODULE_ID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

SOURCES = {
    "EHR-01": "Metro General EHR",
    "EHR-02": "Riverside FHIR Gateway",
    "EHR-03": "Lakeside Patient Access API",
}


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


def _name_from_human(name_obj: dict) -> str:
    family = (name_obj.get("family") or "").strip()
    given = name_obj.get("given") or []
    if isinstance(given, list):
        given_s = " ".join(str(g) for g in given if g)
    else:
        given_s = str(given)
    if family and given_s:
        return f"{family}^{given_s.replace(' ', '^')}"
    return family or given_s or ""


def parse_fhir(raw: str) -> dict:
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError("FHIR payload must be a JSON object")
    resource_type = str(data.get("resourceType") or "")
    is_bundle = resource_type == "Bundle"
    resource_id = str(data.get("id") or "")
    patient = data
    if is_bundle:
        entries = data.get("entry") or []
        for entry in entries:
            res = (entry or {}).get("resource") or {}
            if res.get("resourceType") == "Patient":
                patient = res
                if not resource_id:
                    resource_id = str(data.get("id") or res.get("id") or "")
                break
    patient_id = ""
    for ident in patient.get("identifier") or []:
        if isinstance(ident, dict) and ident.get("value"):
            patient_id = str(ident["value"])
            break
    patient_name = ""
    names = patient.get("name") or []
    if names and isinstance(names[0], dict):
        patient_name = _name_from_human(names[0])
    if not resource_id:
        resource_id = f"gen-{uuid.uuid4().hex[:10]}"
    return {
        "isBundle": is_bundle,
        "resourceType": resource_type or "Unknown",
        "resourceId": resource_id,
        "patientId": patient_id,
        "patientName": patient_name,
        "sourceCode": "EHR-01",
        "rawFhir": raw.strip(),
    }


def build_envelope(meta: dict, file_name: str, source_code: str | None = None) -> str:
    src = source_code or meta["sourceCode"]
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<FhirMessage>
  <SourceCode>{xml_escape(src)}</SourceCode>
  <FileName>{xml_escape(file_name)}</FileName>
  <IsBundle>{"true" if meta["isBundle"] else "false"}</IsBundle>
  <ResourceType>{xml_escape(meta["resourceType"])}</ResourceType>
  <ResourceId>{xml_escape(meta["resourceId"])}</ResourceId>
  <PatientId>{xml_escape(meta["patientId"])}</PatientId>
  <PatientName>{xml_escape(meta["patientName"])}</PatientName>
  <RawFhir><![CDATA[{meta["rawFhir"]}]]></RawFhir>
</FhirMessage>
"""


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
            base = ROUTES_DIR.resolve()
            try:
                candidate.relative_to(base)
            except ValueError:
                return None
            if (candidate / "route.v2.xml").is_file():
                return candidate
    return None


@app.get("/")
def index():
    return render_template(
        "index.html",
        sources=SOURCES,
        lan_hint=os.environ.get("LAN_HINT", ""),
        case_study_url="https://healthcare.pilotfishtechnology.com/fhir-integration-cms-0057-f-compliance/",
        has_xslt=bool(discover_xslt_files()),
        eip_url="http://localhost:8102/eip/",
    )


@app.get("/api/health")
def api_health():
    try:
        with db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
        return jsonify({"ok": True, "sqlserver": "up"})
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.get("/api/messages")
def api_messages():
    try:
        with db() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                """
                SELECT TOP 50
                  ResourceRowId, SourceCode, ResourceType, ResourceId, PatientId, PatientName,
                  IsBundle, ValidationStatus, SourceFile,
                  CONVERT(VARCHAR(19), ReceivedAt, 126) AS ReceivedAt
                FROM dbo.FhirResources
                ORDER BY ResourceRowId DESC
                """
            )
            return jsonify({"ok": True, "messages": cur.fetchall()})
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.get("/api/samples")
def api_samples():
    files = list_text_files(SAMPLE_DIR, "*.json")
    return jsonify({"ok": True, "files": [{"name": f["name"], "content": f["content"]} for f in files]})


@app.post("/api/inject")
def api_inject():
    payload = request.get_json(force=True, silent=True) or {}
    sample = (payload.get("sample") or "").strip()
    raw = (payload.get("fhir") or "").strip()
    source = (payload.get("sourceCode") or "").strip()
    if sample:
        path = SAMPLE_DIR / sample
        if not path.is_file() or path.suffix.lower() != ".json":
            return jsonify({"ok": False, "error": "Unknown sample"}), 400
        raw = path.read_text(encoding="utf-8", errors="replace")
        for code in SOURCES:
            if sample.startswith(code):
                source = code
                break
    if not raw:
        return jsonify({"ok": False, "error": "No FHIR content"}), 400
    try:
        meta = parse_fhir(raw)
    except (json.JSONDecodeError, ValueError) as exc:
        return jsonify({"ok": False, "error": f"Invalid FHIR JSON: {exc}"}), 400
    if source in SOURCES:
        meta["sourceCode"] = source
    stamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    safe_type = re.sub(r"[^A-Za-z0-9_-]+", "_", meta["resourceType"]) or "Resource"
    base = f"{meta['sourceCode']}_{safe_type}_{stamp}"
    INBOUND_DIR.mkdir(parents=True, exist_ok=True)
    dest = INBOUND_DIR / f"{base}.xml"
    dest.write_text(build_envelope(meta, base, meta["sourceCode"]), encoding="utf-8")
    return jsonify(
        {
            "ok": True,
            "file": dest.name,
            "meta": {k: meta[k] for k in meta if k != "rawFhir"},
        }
    )


@app.get("/api/fhir-store")
def api_fhir_store():
    return jsonify({"ok": True, "files": list_text_files(FHIR_STORE_DIR, "*.json")})


@app.get("/api/validation")
def api_validation():
    return jsonify({"ok": True, "files": list_text_files(VALIDATION_DIR, "*.xml")})


@app.get("/api/kickout")
def api_kickout():
    return jsonify({"ok": True, "files": list_text_files(KICKOUT_DIR, "*.xml")})


@app.get("/api/wait-message")
def api_wait_message():
    resource_id = (request.args.get("resourceId") or "").strip()
    timeout = float(request.args.get("timeout", "45"))
    deadline = time.time() + timeout
    while time.time() < deadline:
        store = list_text_files(FHIR_STORE_DIR, "*.json")
        ko = list_text_files(KICKOUT_DIR, "*.xml")
        try:
            with db() as conn:
                cur = conn.cursor(as_dict=True)
                if resource_id:
                    cur.execute(
                        """
                        SELECT TOP 1 ResourceRowId, ResourceId, ValidationStatus, SourceFile
                        FROM dbo.FhirResources WHERE ResourceId = %s ORDER BY ResourceRowId DESC
                        """,
                        (resource_id,),
                    )
                else:
                    cur.execute(
                        """
                        SELECT TOP 1 ResourceRowId, ResourceId, ValidationStatus, SourceFile
                        FROM dbo.FhirResources ORDER BY ResourceRowId DESC
                        """
                    )
                row = cur.fetchone()
                if row:
                    return jsonify({"ok": True, "message": row, "fhirStore": store[:3], "kickout": ko[:3]})
        except Exception:
            pass
        if ko:
            return jsonify({"ok": True, "message": None, "kickout": ko[:1], "fhirStore": store[:3]})
        time.sleep(1.5)
    return jsonify({"ok": False, "error": "Timed out waiting for processing"}), 504


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


_SENSITIVE_ENV = re.compile(
    r"(password|secret|token|apikey|api[_-]?key|private[_-]?key|passphrase|credential)",
    re.I,
)

_XSLT_SUFFIXES = {".xsl", ".xslt"}


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
    paths = [
        Path(os.environ.get("ENV_SETTINGS_FILE", "/environment-settings.conf")),
        demo / "pilotfish" / "demo-eip-root" / "environment-settings.conf",
        demo / "eip-root" / "environment-settings.conf",
    ]
    try:
        paths.append(ROUTES_DIR.parent / "environment-settings.conf")
        paths.append(ROUTES_DIR.parent.parent / "environment-settings.conf")
    except NameError:
        pass
    seen: set[str] = set()
    out: list[Path] = []
    for p in paths:
        key = str(p)
        if key in seen:
            continue
        seen.add(key)
        out.append(p)
    return out


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
            key = key.strip()
            val = val.strip().replace(r"\:", ":").replace(r"\=", "=")
            settings[key] = val
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
    return jsonify(
        {
            "ok": True,
            "path": str(path) if path else None,
            "settings": safe,
            "redacted": redacted,
        }
    )


def _route_pdf_path() -> Path | None:
    for base in (DOCUMENTS_DIR, Path(__file__).resolve().parent.parent / "documents"):
        path = base / ROUTE_PDF_NAME
        if path.is_file():
            return path
    return None


@app.get("/documents/route-diagrams.pdf")
def route_diagrams_pdf():
    path = _route_pdf_path()
    if not path:
        return (
            "Route design PDF not found. Run: python3 tools/export_route_diagrams.py --config changed",
            404,
        )
    return send_file(path, mimetype="application/pdf", as_attachment=False, download_name=ROUTE_PDF_NAME)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
