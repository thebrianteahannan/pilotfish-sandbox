#!/usr/bin/env python3
"""EDI 837 + SNIP SQL Server demo web UI."""

from __future__ import annotations

import json

import os
import re
import time
from datetime import datetime
from pathlib import Path

import pymssql
from flask import Flask, Response, jsonify, render_template, request, send_file

from snip_report import build_snip_html, fallback_html

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "Edi837Demo")
EDI_DIR = Path(os.environ.get("EDI_DIR", "/output/edi"))
SNIP_DIR = Path(os.environ.get("SNIP_DIR", "/output/snip"))
CLAIMS_DIR = Path(os.environ.get("CLAIMS_DIR", "/output/claims"))
ROUTES_DIR = Path(
    os.environ.get(
        "ROUTES_DIR",
        str(Path(__file__).resolve().parent.parent / "eip-root" / "interfaces" / "EDI 837 SNIP SQL Server" / "routes"),
    )
)
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "EDI837_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get("CAPABILITY_PDF_NAME", "EDI837_Capability_Brief.pdf")
TEST_PLAN_PDF_NAME = os.environ.get("TEST_PLAN_PDF_NAME", "EDI837_Test_Plan.pdf")
TEST_RESULTS_PDF_NAME = os.environ.get("TEST_RESULTS_PDF_NAME", "EDI837_Test_Results.pdf")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "http://localhost:8093/eip/")

PATIENTS = {
    "PAT-1001": {"label": "CUNNINGHAM, BOB (PAT-1001)", "provider": "PRV-01"},
    "PAT-1002": {"label": "NUNEZ, FRANCIS (PAT-1002)", "provider": "PRV-02"},
    "PAT-1003": {"label": "PATEL, RIYA (PAT-1003)", "provider": "PRV-01"},
}

_SAFE_NAME = re.compile(r"^[\w.\-]+\.xml$")
_MODULE_ID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def route_slug(name: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")
    return slug


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
            if base in candidate.parents or candidate == base:
                if (candidate / "route.v2.xml").is_file():
                    return candidate
    return None


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


def list_files(directory: Path, pattern: str):
    if not directory.exists():
        return []
    files = sorted(directory.glob(pattern), key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for path in files:
        # Ignore junk forks from empty SQL polls (_.edi, __snip.xml, etc.)
        if path.name.startswith("_") or path.name.startswith("."):
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


def edi_for_snip(snip_name: str) -> Path | None:
    # 5001_CLM-5001_snip.xml -> 5001_CLM-5001.edi
    base = snip_name
    if base.endswith("_snip.xml"):
        base = base[: -len("_snip.xml")]
    elif base.endswith(".xml"):
        base = base[: -len(".xml")]
    candidate = EDI_DIR / f"{base}.edi"
    return candidate if candidate.is_file() else None


@app.get("/")
def index():
    return render_template(
        "index.html",
        patients=PATIENTS,
        lan_hint=os.environ.get("LAN_HINT", ""),
        eip_url=EIP_PUBLIC_URL,
        has_xslt=bool(discover_xslt_files()),
        test_results_pdf=TEST_RESULTS_PDF_NAME,
    )


@app.get("/api/health")
def api_health():
    try:
        with db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
        return jsonify({"ok": True, "sqlserver": "up", "ediDir": str(EDI_DIR)})
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.get("/api/claims")
def api_claims():
    try:
        with db() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                """
                SELECT
                  c.ClaimId, c.ClaimNumber, c.PatientId, p.LastName, p.FirstName,
                  c.ClaimAmount, c.DiagnosisCode, c.Status,
                  CONVERT(VARCHAR(19), c.CreatedAt, 126) AS CreatedAt, c.Notes
                FROM dbo.Claims c
                INNER JOIN dbo.Patients p ON p.PatientId = c.PatientId
                ORDER BY c.ClaimId DESC
                """
            )
            return jsonify({"ok": True, "claims": cur.fetchall()})
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.post("/api/claims")
def api_create_claim():
    payload = request.get_json(force=True, silent=True) or {}
    patient_id = (payload.get("patientId") or "PAT-1001").strip()
    if patient_id not in PATIENTS:
        return jsonify({"ok": False, "error": "Unknown patientId"}), 400
    proc = (payload.get("procedureCode") or "99213").strip()
    amount = float(payload.get("claimAmount") or 125.00)
    dx = (payload.get("diagnosisCode") or "J06.9").strip()
    notes = (payload.get("notes") or "Injected from demo UI").strip()
    provider = PATIENTS[patient_id]["provider"]
    try:
        with db() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute("SELECT ISNULL(MAX(ClaimId), 5000) + 1 AS NextId FROM dbo.Claims")
            claim_id = int(cur.fetchone()["NextId"])
            claim_number = f"CLM-{claim_id}"
            svc = datetime.utcnow().strftime("%Y-%m-%d")
            cur.execute(
                """
                INSERT INTO dbo.Claims (
                  ClaimId, PatientId, BillingProviderId, PayerId, PayerName, ClaimNumber,
                  ServiceDate, ClaimAmount, PlaceOfService, DiagnosisCode, Status, Notes
                ) VALUES (
                  %s, %s, %s, N'66783JJT', N'AHLIC', %s,
                  %s, %s, N'11', %s, N'PENDING', %s
                )
                """,
                (claim_id, patient_id, provider, claim_number, svc, amount, dx, notes),
            )
            cur.execute("SELECT ISNULL(MAX(ClaimLineId), 0) + 1 AS NextLine FROM dbo.ClaimLines")
            line_id = int(cur.fetchone()["NextLine"])
            cur.execute(
                """
                INSERT INTO dbo.ClaimLines (
                  ClaimLineId, ClaimId, LineNumber, ProcedureCode, Modifier1, ChargeAmount, Units, ServiceDate
                ) VALUES (%s, %s, 1, %s, NULL, %s, 1, %s)
                """,
                (line_id, claim_id, proc, amount, svc),
            )
            conn.commit()
        return jsonify(
            {
                "ok": True,
                "claimId": claim_id,
                "claimNumber": claim_number,
                "expectedEdi": f"{claim_id}_{claim_number}.edi",
                "expectedSnip": f"{claim_id}_{claim_number}_snip.xml",
            }
        )
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.get("/api/edi")
def api_edi():
    prefix = request.args.get("prefix")
    files = list_files(EDI_DIR, "*.edi")
    if prefix:
        files = [f for f in files if f["name"].startswith(prefix)]
    return jsonify({"ok": True, "files": files})


@app.get("/api/snip")
def api_snip():
    prefix = request.args.get("prefix")
    files = list_files(SNIP_DIR, "*.xml")
    if prefix:
        files = [f for f in files if f["name"].startswith(prefix)]
    return jsonify({"ok": True, "files": files})


@app.get("/api/snip-report")
def api_snip_report():
    """HTML report via the 14a EDI SNIP Validations Report XSLT pipeline."""
    name = (request.args.get("name") or "").strip()
    if not name or not _SAFE_NAME.match(name) or name.startswith("_"):
        return Response(fallback_html("Invalid SNIP file name."), mimetype="text/html; charset=utf-8", status=400)
    snip_path = SNIP_DIR / name
    if not snip_path.is_file():
        return Response(
            fallback_html(f"SNIP file not found: {name}"),
            mimetype="text/html; charset=utf-8",
            status=404,
        )
    try:
        snip_xml = snip_path.read_text(encoding="utf-8", errors="replace")
        edi_path = edi_for_snip(name)
        if not edi_path:
            return Response(
                fallback_html(f"Matching EDI file not found for {name}."),
                mimetype="text/html; charset=utf-8",
                status=404,
            )
        edi_text = edi_path.read_text(encoding="utf-8", errors="replace")
        html = build_snip_html(snip_xml, edi_text)
        return Response(html, mimetype="text/html; charset=utf-8")
    except Exception as exc:  # noqa: BLE001
        return Response(
            fallback_html(f"Report failed: {exc}"),
            mimetype="text/html; charset=utf-8",
            status=500,
        )


@app.get("/api/v2/routes")
def api_v2_routes():
    routes = discover_v2_routes()
    return jsonify({"ok": True, "routes": routes, "routesDir": str(ROUTES_DIR)})


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
    return Response(
        path.read_text(encoding="utf-8", errors="replace"),
        mimetype="application/xml; charset=utf-8",
    )


@app.get("/api/wait-edi/<int:claim_id>")
def api_wait_edi(claim_id: int):
    timeout = float(request.args.get("timeout", "90"))
    deadline = time.time() + timeout
    prefix = f"{claim_id}_"
    while time.time() < deadline:
        edi = [f for f in list_files(EDI_DIR, "*.edi") if f["name"].startswith(prefix)]
        snip = [f for f in list_files(SNIP_DIR, "*.xml") if f["name"].startswith(prefix)]
        if edi:
            return jsonify({"ok": True, "edi": edi[0], "snip": snip[0] if snip else None})
        names = []
        if EDI_DIR.exists():
            names = [p.name for p in EDI_DIR.glob(f"{prefix}*.edi") if not p.name.startswith("_")]
        if names:
            time.sleep(1)
            continue
        time.sleep(2)
    return jsonify({"ok": False, "error": "Timed out waiting for EDI output"}), 504



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
            # Unescape common Java properties escapes used in JDBC URLs
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



@app.get("/documents/capability-brief.pdf")
def capability_pdf_alias():
    path = DOCUMENTS_DIR / CAPABILITY_PDF_NAME
    if path.is_file():
        return send_file(path, mimetype="application/pdf", as_attachment=False)
    local = Path(__file__).resolve().parent.parent / "documents" / CAPABILITY_PDF_NAME
    if local.is_file():
        return send_file(local, mimetype="application/pdf", as_attachment=False)
    return Response(
        "Capability brief not generated yet. Run: python3 tools/export_stakeholder_brief.py",
        status=404,
    )


@app.get("/documents/test-plan.pdf")
def test_plan_pdf_alias():
    for base in (DOCUMENTS_DIR, Path(__file__).resolve().parent.parent / "documents"):
        path = base / TEST_PLAN_PDF_NAME
        if path.is_file():
            return send_file(path, mimetype="application/pdf", as_attachment=False)
    return Response(
        "Test plan PDF not found. Run: python3 tools/export_test_plan_pdf.py",
        status=404,
    )


@app.get("/documents/test-results.pdf")
def test_results_pdf_alias():
    for base in (DOCUMENTS_DIR, Path(__file__).resolve().parent.parent / "documents"):
        for name in (TEST_RESULTS_PDF_NAME, "test-results.pdf"):
            path = base / name
            if path.is_file():
                return send_file(
                    path, mimetype="application/pdf", as_attachment=False, download_name=name
                )
    return Response(
        "Test results PDF not found yet. Run: python3 tools/run_interface_tests.py --wait",
        status=404,
    )


@app.get("/documents/<path:name>")
def documents_file(name: str):
    safe = Path(name).name
    if safe != name or ".." in name or "/" in name or "\\" in name:
        return Response("Invalid document name", status=400)
    for base in (DOCUMENTS_DIR, Path(__file__).resolve().parent.parent / "documents"):
        path = base / safe
        if path.is_file():
            return send_file(path, as_attachment=False)
    return Response(f"Document not found: {safe}", status=404)



# INFO_TAB_STANDARD_BOOTSTRAP
try:
    from document_routes import ensure_document_routes
except ImportError:
    ensure_document_routes = None  # type: ignore

_INFO_TAB_CTX = {
    "info_title": 'SQL Server claims → 837P + SNIP',
    "info_blurb": 'Poll PENDING claims, map to EDI XML, convert with the <strong>EDI Transformation Module</strong>, validate with <strong>EdiSNIPValidationProcessor</strong> (Types 1–3 at runtime), and view the SNIP HTML report in the UI.',
    "info_note": 'Demo only — SQL → 837P + SNIP Types 1–3. Types 4–7 + <code>snip7-demo-rules.xml</code> are ready when <code>EDISNIP</code> is licensed.',
    "eip_url": 'http://localhost:8093/eip/',
    "lan_hint": "",
    "info_ports": [
        {"label": "SQL Server", "value": "14335"},
        {"label": "PilotFish EIP", "value": "8093"},
        {"label": "Demo Web UI", "value": "8095"}
    ],
    "info_extra_links": [],
    "info_extra_sections": [{'title': 'SNIP levels (this demo)', 'items': ['Types 1–3 — <strong>on</strong> (integrity, HIPAA requirements, balancing)', 'Type 4 — off until <code>EDISNIP</code> (inter-segment)', 'Type 5 — off until <code>EDISNIP</code> (external code sets)', 'Types 6–7 — off until <code>EDISNIP</code>; rule file <code>snip7-demo-rules.xml</code> (demo: POS ≠ 99)'], 'note': 'Sandbox <code>pflicense.key</code> lacks <code>EDISNIP</code>. Enabling Types 4–7 aborts SNIP and leaves reports empty — so runtime stays on Types 1–3.'}],
    "test_results_pdf": 'EDI837_Test_Results.pdf',
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
        route_pdf_name='EDI837_V2_Route_Diagrams.pdf',
        capability_pdf_name='EDI837_Capability_Brief.pdf',
        test_plan_pdf_name='EDI837_Test_Plan.pdf',
        test_results_pdf_name='EDI837_Test_Results.pdf',
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
    app.run(host="0.0.0.0", port=8095, debug=False)
