"""FHIR R4 Expandable Platform — Web UI (FHIR client + proxy + outbound trigger)."""
from __future__ import annotations

import json
import os
import re
import time
import urllib.error
import urllib.parse
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
DB_NAME = os.environ.get("DB_NAME", "FhirR4PlatformDemo")
FHIR_STORE_DIR = Path(os.environ.get("FHIR_STORE_DIR", "/output/fhir-store"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
OUTBOUND_DIR = Path(os.environ.get("OUTBOUND_DIR", "/input/outbound"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "FHIR_R4_Platform_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get(
    "CAPABILITY_PDF_NAME", "FHIR_R4_Platform_Capability_Brief.pdf"
)
TEST_PLAN_PDF_NAME = os.environ.get("TEST_PLAN_PDF_NAME", "FHIR_R4_Platform_Test_Plan.pdf")
TEST_RESULTS_NAME = os.environ.get("TEST_RESULTS_NAME", "test-results.json")
WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8111"))
LAN_HINT = os.environ.get("LAN_HINT", "")
FHIR_BASE_URL = os.environ.get("FHIR_BASE_URL", "http://pilotfish:8080/eip/rest/fhir").rstrip("/")
FHIR_PUBLIC_BASE_URL = os.environ.get(
    "FHIR_PUBLIC_BASE_URL", "http://192.168.68.52:8110/eip/rest/fhir"
).rstrip("/")
FHIR_REMOTE_BASE_URL = os.environ.get(
    "FHIR_REMOTE_BASE_URL", "https://hapi.fhir.org/baseR4"
).rstrip("/")
OAUTH_TOKEN_URL = os.environ.get(
    "OAUTH_TOKEN_URL", "http://keycloak:8080/realms/fhir-demo/protocol/openid-connect/token"
)
OAUTH_PUBLIC_TOKEN_URL = os.environ.get(
    "OAUTH_PUBLIC_TOKEN_URL", "http://localhost:8112/realms/fhir-demo/protocol/openid-connect/token"
)
OAUTH_AUTHORIZE_URL = os.environ.get(
    "OAUTH_AUTHORIZE_URL", "http://localhost:8112/realms/fhir-demo/protocol/openid-connect/auth"
)
OAUTH_CLIENT_ID = os.environ.get("OAUTH_CLIENT_ID", "fhir-r4-platform")
OAUTH_CLIENT_SECRET = os.environ.get("OAUTH_CLIENT_SECRET", "fhir-demo-secret")
OAUTH_USERNAME = os.environ.get("OAUTH_USERNAME", "fhiruser")
OAUTH_PASSWORD = os.environ.get("OAUTH_PASSWORD", "FhirDemo1!")


RESOURCE_TYPES = [
    "Patient", "Practitioner", "PractitionerRole", "Organization", "Location",
    "Encounter", "Observation", "Condition", "Procedure", "AllergyIntolerance",
    "MedicationRequest", "Medication", "Immunization", "DiagnosticReport",
    "DocumentReference", "CarePlan", "CareTeam", "Goal", "ServiceRequest",
    "Coverage", "Claim", "ExplanationOfBenefit", "Appointment", "Schedule",
    "Slot", "RelatedPerson", "Person", "EpisodeOfCare", "Binary", "Bundle",
    "Parameters",
]

_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
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


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def discover_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.iterdir(), key=lambda p: p.name.lower()):
        if path.is_dir() and (path / "route.v2.xml").is_file():
            out.append({"id": route_slug(path.name), "dir": path.name, "name": path.name})
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
                "content": text[:8000],
                "size": path.stat().st_size,
            }
        )
    return out


def http_json(
    method: str,
    url: str,
    body: str | None = None,
    timeout: int = 45,
    authorization: str | None = None,
) -> dict:
    data = None if body is None else body.encode("utf-8")
    headers = {"Accept": "application/fhir+json"}
    if body is not None:
        headers["Content-Type"] = "application/fhir+json"
    if authorization:
        headers["Authorization"] = authorization
    req = urllib.request.Request(url, data=data, method=method.upper(), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            return {"ok": 200 <= resp.status < 300, "status": resp.status, "body": raw, "url": url}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        return {"ok": False, "status": exc.code, "body": raw, "url": url, "error": str(exc)}
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "status": 0, "body": "", "url": url, "error": str(exc)}


def call_fhir(
    method: str,
    path: str,
    body: str | None = None,
    proxy: bool = False,
    bearer: str | None = None,
) -> dict:
    path = path.lstrip("/")
    if proxy:
        url = f"{FHIR_REMOTE_BASE_URL}/{path}"
    else:
        url = f"{FHIR_BASE_URL}/{path}"
    auth = None
    if bearer:
        token = bearer.strip()
        auth = token if token.lower().startswith("bearer ") else f"Bearer {token}"
    return http_json(method, url, body, authorization=auth)


@app.get("/")
def index():
    return render_template(
        "index.html",
        lan_hint=LAN_HINT,
        fhir_public_base=FHIR_PUBLIC_BASE_URL,
        fhir_remote_base=FHIR_REMOTE_BASE_URL,
        oauth_authorize_url=OAUTH_AUTHORIZE_URL,
        oauth_token_url=OAUTH_PUBLIC_TOKEN_URL,
        resource_types=RESOURCE_TYPES,
        has_xslt=bool(discover_xslt_files()),
        route_pdf=ROUTE_PDF_NAME,
    )


@app.get("/api/health")
def api_health():
    try:
        with db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
        return jsonify(
            {
                "ok": True,
                "sqlserver": "up",
                "fhirBase": FHIR_PUBLIC_BASE_URL,
                "remoteBase": FHIR_REMOTE_BASE_URL,
            }
        )
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 503


@app.get("/api/samples")
def api_samples():
    return jsonify({"ok": True, "files": list_text_files(SAMPLE_DIR, "*.json")})


@app.get("/api/resources")
def api_resources():
    try:
        with db() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                """
                SELECT TOP 50 ResourceRowId, ResourceType, ResourceId, Source, ValidationStatus,
                  CONVERT(VARCHAR(19), ReceivedAt, 126) AS ReceivedAt,
                  CONVERT(VARCHAR(19), UpdatedAt, 126) AS UpdatedAt,
                  CASE WHEN DeletedAt IS NULL THEN 0 ELSE 1 END AS Deleted
                FROM dbo.FhirResources
                ORDER BY ResourceRowId DESC
                """
            )
            return jsonify({"ok": True, "messages": cur.fetchall()})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 503


@app.post("/api/fhir/invoke")
def api_fhir_invoke():
    payload = request.get_json(force=True, silent=True) or {}
    method = (payload.get("method") or "GET").upper()
    rtype = (payload.get("resourceType") or "Patient").strip()
    rid = (payload.get("id") or "").strip()
    query = (payload.get("query") or "").strip().lstrip("?")
    proxy = bool(payload.get("proxy"))
    sample = (payload.get("sample") or "").strip()
    raw = (payload.get("body") or "").strip()
    if sample:
        path = SAMPLE_DIR / sample
        if not path.is_file():
            return jsonify({"ok": False, "error": "Unknown sample"}), 400
        raw = path.read_text(encoding="utf-8", errors="replace")
    if method in {"POST", "PUT"} and raw:
        try:
            json.loads(raw)
        except json.JSONDecodeError as exc:
            return jsonify({"ok": False, "error": f"Invalid JSON: {exc}"}), 400
    if rtype == "metadata":
        path = "metadata"
    elif method == "GET" and not rid:
        path = f"{rtype}?{query}" if query else rtype
    elif rid:
        path = f"{rtype}/{rid}"
        if query and method == "GET":
            path = f"{path}?{query}"
    else:
        path = rtype
    bearer = (payload.get("bearer") or payload.get("token") or "").strip()
    result = call_fhir(
        method, path, raw if method in {"POST", "PUT"} else None, proxy=proxy, bearer=bearer or None
    )
    return jsonify(result), (200 if result.get("status") else 502)


@app.post("/api/oauth/token")
def api_oauth_token():
    """Fetch a demo access token via client_credentials (Keycloak)."""
    form = urllib.parse.urlencode(
        {
            "grant_type": "client_credentials",
            "client_id": OAUTH_CLIENT_ID,
            "client_secret": OAUTH_CLIENT_SECRET,
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        OAUTH_TOKEN_URL,
        data=form,
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            data = json.loads(raw)
            return jsonify({"ok": True, "token": data.get("access_token"), "raw": data})
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        return jsonify({"ok": False, "status": exc.code, "error": raw}), 502
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 502


@app.post("/api/outbound/enqueue")
def api_outbound_enqueue():
    payload = request.get_json(force=True, silent=True) or {}
    url = (payload.get("url") or "").strip()
    if not url:
        url = f"{FHIR_REMOTE_BASE_URL}/metadata"
    OUTBOUND_DIR.mkdir(parents=True, exist_ok=True)
    name = f"out_{int(time.time())}.json"
    path = OUTBOUND_DIR / name
    path.write_text(json.dumps({"url": url}, indent=2), encoding="utf-8")
    return jsonify({"ok": True, "file": name, "url": url})


@app.get("/api/v2/routes")
def api_v2_routes():
    return jsonify({"ok": True, "routes": discover_v2_routes()})


@app.get("/api/v2/routes/<route_id>/route.v2.xml")
def api_v2_route_xml(route_id: str):
    d = resolve_route_dir(route_id)
    if not d:
        return Response("Not found", status=404)
    return Response((d / "route.v2.xml").read_text(encoding="utf-8", errors="replace"), mimetype="application/xml")


@app.get("/api/v2/routes/<route_id>/modules/<module_id>.xml")
def api_v2_module_xml(route_id: str, module_id: str):
    if not _MODULE_ID.match(module_id):
        return Response("Bad id", status=400)
    d = resolve_route_dir(route_id)
    if not d:
        return Response("Not found", status=404)
    path = d / "modules" / f"{module_id}.xml"
    if not path.is_file():
        return Response("Not found", status=404)
    return Response(path.read_text(encoding="utf-8", errors="replace"), mimetype="application/xml")


@app.get("/api/v2/xslt")
def api_xslt():
    return jsonify({"ok": True, "files": discover_xslt_files()})


@app.get("/api/v2/xslt/content")
def api_xslt_content():
    path = resolve_xslt_path(request.args.get("path") or "")
    if not path:
        return Response("Not found", status=404)
    return Response(path.read_text(encoding="utf-8", errors="replace"), mimetype="text/plain")


@app.get("/api/v2/environment-settings")
def api_env():
    if not ENV_SETTINGS_FILE.is_file():
        return jsonify({"ok": True, "entries": []})
    entries = []
    for line in ENV_SETTINGS_FILE.read_text(encoding="utf-8", errors="replace").splitlines():
        raw = line.strip()
        if not raw or raw.startswith("#") or "=" not in raw:
            continue
        k, v = raw.split("=", 1)
        if _SENSITIVE_ENV.search(k):
            v = "••••••••"
        entries.append({"name": k, "value": v})
    return jsonify({"ok": True, "entries": entries})


@app.get("/documents/<path:name>")
def documents(name: str):
    path = (DOCUMENTS_DIR / name).resolve()
    try:
        path.relative_to(DOCUMENTS_DIR.resolve())
    except ValueError:
        return Response("Not found", status=404)
    if not path.is_file():
        return Response("Not found", status=404)
    return send_file(path)


@app.get("/documents/route-diagrams.pdf")
def route_pdf_alias():
    path = DOCUMENTS_DIR / ROUTE_PDF_NAME
    if path.is_file():
        return send_file(path)
    return Response("PDF not generated yet", status=404)


@app.get("/documents/capability-brief.pdf")
def capability_pdf_alias():
    path = DOCUMENTS_DIR / CAPABILITY_PDF_NAME
    if path.is_file():
        return send_file(path)
    return Response(
        "Capability brief not generated yet. Run: python3 tools/export_stakeholder_brief.py",
        status=404,
    )


@app.get("/documents/test-plan.pdf")
def test_plan_pdf_alias():
    path = DOCUMENTS_DIR / TEST_PLAN_PDF_NAME
    if path.is_file():
        return send_file(path)
    return Response(
        "Test plan PDF not generated yet. Run: python3 tools/export_test_plan_pdf.py",
        status=404,
    )


@app.get("/api/v2/tests/results")
def tests_results():
    path = DOCUMENTS_DIR / TEST_RESULTS_NAME
    if not path.is_file():
        return jsonify(
            {
                "ok": False,
                "message": "No results yet. On the host run: python3 tools/run_interface_tests.py --wait",
            }
        )
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return jsonify({"ok": False, "message": "test-results.json is invalid JSON"}), 500
    data["ok"] = True
    return jsonify(data)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
