#!/usr/bin/env python3
"""EDI 278 Prior Auth demo web UI."""

from __future__ import annotations

import json
import os
import re
import time
from datetime import datetime
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8121"))
INBOUND_DIR = Path(os.environ.get("INBOUND_DIR", "/inbound"))
APPROVED_DIR = Path(os.environ.get("APPROVED_DIR", "/output/approved"))
DENIED_DIR = Path(os.environ.get("DENIED_DIR", "/output/denied"))
INCOMPLETE_DIR = Path(os.environ.get("INCOMPLETE_DIR", "/output/incomplete"))
PENDED_DIR = Path(os.environ.get("PENDED_DIR", "/output/pended"))
RESPONSE_DIR = Path(os.environ.get("RESPONSE_DIR", "/output/responses"))
EHR_NOTICE_DIR = Path(os.environ.get("EHR_NOTICE_DIR", "/output/ehr-notices"))
ARCHIVE_DIR = Path(os.environ.get("ARCHIVE_DIR", "/output/archive"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
ROUTES_DIR = Path(
    os.environ.get(
        "ROUTES_DIR",
        str(
            Path(__file__).resolve().parent.parent
            / "eip-root"
            / "interfaces"
            / "EDI 278 Prior Auth"
            / "routes"
        ),
    )
)
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "EDI278_Prior_Auth_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get(
    "CAPABILITY_PDF_NAME", "EDI278_Prior_Auth_Capability_Brief.pdf"
)
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://localhost:8120/eip/")

DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "14340"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "Edi278PriorAuth")

_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
_SENSITIVE_ENV = re.compile(
    r"(password|secret|token|apikey|api[_-]?key|private[_-]?key|passphrase|credential)",
    re.I,
)
_XSLT_SUFFIXES = {".xsl", ".xslt"}
_SAFE_EDI_NAME = re.compile(r"^[A-Za-z0-9._-]+\.(edi|278|txt)$", re.I)


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


def _env_settings_candidates() -> list[Path]:
    demo = Path(__file__).resolve().parent.parent
    paths = [
        Path(os.environ.get("ENV_SETTINGS_FILE", "/environment-settings.conf")),
        demo / "pilotfish" / "demo-eip-root" / "environment-settings.conf",
    ]
    try:
        paths.append(ROUTES_DIR.parent / "environment-settings.conf")
    except Exception:
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
            settings[key.strip()] = val.strip().replace(r"\:", ":").replace(r"\=", "=")
        return path, settings
    return None, {}


def fetch_auth_requests() -> list[dict]:
    try:
        import pymssql  # type: ignore
    except ImportError:
        return []
    try:
        with pymssql.connect(
            server=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            login_timeout=5,
            timeout=10,
        ) as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                "SELECT AuthTraceNumber, MemberId, PatientLastName, PatientFirstName, "
                "ProcedureCode, DiagnosisCode, AttachmentFlag, Status, Notes, UpdatedAt "
                "FROM dbo.AuthRequest ORDER BY AuthTraceNumber"
            )
            rows = []
            for row in cur.fetchall():
                item = {}
                for col, val in row.items():
                    if hasattr(val, "isoformat"):
                        val = val.isoformat(sep=" ", timespec="seconds")
                    elif val is not None and not isinstance(val, (str, int, float)):
                        val = str(val)
                    item[col] = val
                rows.append(item)
            return rows
    except Exception:
        return []


@app.get("/")
def index():
    return render_template(
        "index.html",
        lan_hint=os.environ.get("LAN_HINT", ""),
        eip_url=EIP_PUBLIC_URL,
        has_xslt=bool(discover_xslt_files()),
    )


@app.get("/api/health")
def api_health():
    return jsonify(
        {
            "ok": True,
            "inbound": INBOUND_DIR.exists(),
            "approvedDir": APPROVED_DIR.exists(),
            "deniedDir": DENIED_DIR.exists(),
            "incompleteDir": INCOMPLETE_DIR.exists(),
            "pendedDir": PENDED_DIR.exists(),
            "responseDir": RESPONSE_DIR.exists(),
            "ehrNoticeDir": EHR_NOTICE_DIR.exists(),
        }
    )


@app.get("/api/samples")
def api_samples():
    files = (
        list_text_files(SAMPLE_DIR, "*.edi")
        + list_text_files(SAMPLE_DIR, "*.278")
        + list_text_files(SAMPLE_DIR, "*.txt")
    )
    return jsonify({"ok": True, "files": [{"name": f["name"], "content": f["content"]} for f in files]})


@app.post("/api/inject")
def api_inject():
    payload = request.get_json(force=True, silent=True) or {}
    sample = (payload.get("sample") or "").strip()
    raw = (payload.get("edi") or payload.get("csv") or "").strip()
    name = (payload.get("fileName") or "").strip()

    if sample:
        if not _SAFE_EDI_NAME.match(sample):
            return jsonify({"ok": False, "error": "Invalid sample name"}), 400
        path = SAMPLE_DIR / sample
        if not path.is_file():
            return jsonify({"ok": False, "error": "Unknown sample"}), 400
        raw = path.read_text(encoding="utf-8", errors="replace")
        name = sample

    if not raw:
        return jsonify({"ok": False, "error": "No EDI content"}), 400

    if not name or not _SAFE_EDI_NAME.match(name):
        stamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
        name = f"CUSTOM_{stamp}.edi"

    INBOUND_DIR.mkdir(parents=True, exist_ok=True)
    dest = INBOUND_DIR / name
    dest.write_text(raw if raw.endswith("\n") else raw + "\n", encoding="utf-8")
    return jsonify({"ok": True, "file": dest.name})


@app.get("/api/approved")
def api_approved():
    return jsonify({"ok": True, "files": list_text_files(APPROVED_DIR, "*.xml")})


@app.get("/api/denied")
def api_denied():
    return jsonify({"ok": True, "files": list_text_files(DENIED_DIR, "*.xml")})


@app.get("/api/incomplete")
def api_incomplete():
    return jsonify({"ok": True, "files": list_text_files(INCOMPLETE_DIR, "*.xml")})


@app.get("/api/pended")
def api_pended():
    return jsonify({"ok": True, "files": list_text_files(PENDED_DIR, "*.xml")})


@app.get("/api/responses")
def api_responses():
    return jsonify({"ok": True, "files": list_text_files(RESPONSE_DIR, "*.edi")})


@app.get("/api/ehr-notices")
def api_ehr_notices():
    return jsonify({"ok": True, "files": list_text_files(EHR_NOTICE_DIR, "*.hl7")})


@app.get("/api/archive")
def api_archive():
    return jsonify({"ok": True, "files": list_text_files(ARCHIVE_DIR, "*")})


@app.get("/api/auth-requests")
def api_auth_requests():
    rows = fetch_auth_requests()
    return jsonify({"ok": True, "rows": rows, "count": len(rows)})


@app.get("/api/wait-results")
def api_wait_results():
    timeout = float(request.args.get("timeout", "90"))
    min_total = int(request.args.get("total", "4"))
    deadline = time.time() + timeout
    while time.time() < deadline:
        approved = list_text_files(APPROVED_DIR, "*.xml")
        denied = list_text_files(DENIED_DIR, "*.xml")
        incomplete = list_text_files(INCOMPLETE_DIR, "*.xml")
        pended = list_text_files(PENDED_DIR, "*.xml")
        responses = list_text_files(RESPONSE_DIR, "*.edi")
        notices = list_text_files(EHR_NOTICE_DIR, "*.hl7")
        total = len(approved) + len(denied) + len(incomplete) + len(pended)
        if total >= min_total and len(responses) >= min_total and len(notices) >= min_total:
            return jsonify(
                {
                    "ok": True,
                    "approved": approved[:10],
                    "denied": denied[:10],
                    "incomplete": incomplete[:10],
                    "pended": pended[:10],
                    "responses": responses[:10],
                    "ehrNotices": notices[:10],
                }
            )
        time.sleep(1.0)
    return jsonify({"ok": False, "error": "Timed out waiting for prior-auth outputs"}), 504


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
            "Route design PDF not found. Run: python3 tools/export_route_diagrams.py --config compact",
            404,
        )
    return send_file(path, mimetype="application/pdf", as_attachment=False, download_name=ROUTE_PDF_NAME)


@app.get("/documents/capability-brief.pdf")
def capability_pdf_alias():
    path = DOCUMENTS_DIR / CAPABILITY_PDF_NAME
    if path.is_file():
        return send_file(path)
    return Response(
        "Capability brief not generated yet. Run: python3 tools/export_stakeholder_brief.py",
        status=404,
    )


@app.get("/documents/<path:name>")
def documents_file(name: str):
    if ".." in name or name.startswith("/"):
        return Response("Bad path", status=400)
    path = DOCUMENTS_DIR / name
    if not path.is_file():
        return Response("Not found", status=404)
    mime = "application/pdf" if path.suffix.lower() == ".pdf" else "application/octet-stream"
    return send_file(path, mimetype=mime, as_attachment=False, download_name=path.name)



# INFO_TAB_STANDARD_BOOTSTRAP
try:
    from document_routes import ensure_document_routes
except ImportError:
    ensure_document_routes = None  # type: ignore

_INFO_TAB_CTX = {
    "info_title": 'EDI 278 prior authorization',
    "info_blurb": 'Synthetic 278 intake with SQL completeness / disposition theater and file-drop ORU (no LLP).',
    "info_note": 'Demo only — synthetic 278, SQL completeness / disposition theater, file-drop ORU (no LLP).',
    "eip_url": 'http://localhost:8120/eip/',
    "lan_hint": "",
    "info_ports": [
        {"label": "SQL Server", "value": "14340"},
        {"label": "PilotFish EIP", "value": "8120"},
        {"label": "Demo Web UI", "value": "8121"}
    ],
    "info_extra_links": [],
    "info_extra_sections": [],
    "test_results_pdf": 'EDI278_Prior_Auth_Test_Results.pdf',
}

@app.context_processor
def _info_tab_standard_context():
    import os as _os
    ctx = dict(_INFO_TAB_CTX)
    eip = _os.environ.get("EIP_PUBLIC_URL")
    if eip:
        ctx["eip_url"] = eip
    lan = _os.environ.get("LAN_HINT", "")
    if lan:
        ctx["lan_hint"] = lan
    return ctx

if ensure_document_routes is not None:
    from pathlib import Path as _Path
    import os as _os
    _docs_dir = _Path(_os.environ.get("DOCUMENTS_DIR", "/documents"))
    ensure_document_routes(
        app,
        _docs_dir,
        route_pdf_name='EDI278_Prior_Auth_V2_Route_Diagrams.pdf',
        capability_pdf_name='EDI278_Prior_Auth_Capability_Brief.pdf',
        test_plan_pdf_name=None,
        test_results_pdf_name='EDI278_Prior_Auth_Test_Results.pdf',
    )
# END INFO_TAB_STANDARD_BOOTSTRAP


# TIMING_TAB_API_BOOTSTRAP
try:
    from document_routes import ensure_build_status_api, ensure_build_timing_api
except ImportError:
    ensure_build_timing_api = None  # type: ignore
    ensure_build_status_api = None  # type: ignore
if ensure_build_timing_api is not None:
    from pathlib import Path as _PathTiming
    import os as _os_timing

    _docs_dir = _PathTiming(_os_timing.environ.get("DOCUMENTS_DIR", "/documents"))
    ensure_build_timing_api(app, _docs_dir)
if ensure_build_status_api is not None:
    from pathlib import Path as _PathTiming2
    import os as _os_timing2

    ensure_build_status_api(
        app,
        _PathTiming2(_os_timing2.environ.get("DOCUMENTS_DIR", "/documents")),
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
