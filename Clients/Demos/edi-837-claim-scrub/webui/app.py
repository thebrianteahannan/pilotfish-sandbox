#!/usr/bin/env python3
"""EDI 837 Claim Scrub (pre-clearinghouse) demo web UI."""

from __future__ import annotations

import json
import os
import re
import time
from datetime import datetime
from pathlib import Path

import pymssql
from flask import Flask, Response, jsonify, render_template, request, send_file

from docs_and_v2 import discover_xslt_files, register_docs_and_v2
from snip_report import build_snip_html, fallback_html

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "sqlserver")
DB_PORT = int(os.environ.get("DB_PORT", "1433"))
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "PilotFish_Demo1!")
DB_NAME = os.environ.get("DB_NAME", "Edi837ClaimScrub")
EDI_DIR = Path(os.environ.get("EDI_DIR", "/output/edi"))
SNIP_DIR = Path(os.environ.get("SNIP_DIR", "/output/snip"))
CLAIMS_DIR = Path(os.environ.get("CLAIMS_DIR", "/output/claims"))
KICKOUT_DIR = Path(os.environ.get("KICKOUT_DIR", "/output/kickouts"))
BI_DIR = Path(os.environ.get("BI_DIR", "/output/bi"))
ROUTES_DIR = Path(
    os.environ.get(
        "ROUTES_DIR",
        str(
            Path(__file__).resolve().parent.parent
            / "eip-root"
            / "interfaces"
            / "EDI 837 Claim Scrub"
            / "routes"
        ),
    )
)
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "EDI837_Claim_Scrub_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get(
    "CAPABILITY_PDF_NAME", "EDI837_Claim_Scrub_Capability_Brief.pdf"
)
TEST_RESULTS_PDF_NAME = os.environ.get(
    "TEST_RESULTS_PDF_NAME", "EDI837_Claim_Scrub_Test_Results.pdf"
)
TEST_PLAN_PDF_NAME = os.environ.get("TEST_PLAN_PDF_NAME", "EDI837_Claim_Scrub_Test_Plan.pdf")

PATIENTS = {
    "PAT-1001": {"label": "CUNNINGHAM, BOB (PAT-1001)", "provider": "PRV-01"},
    "PAT-1002": {"label": "NUNEZ, FRANCIS (PAT-1002)", "provider": "PRV-02"},
    "PAT-1003": {"label": "PATEL, RIYA (PAT-1003)", "provider": "PRV-01"},
}

_SAFE_NAME = re.compile(r"^[\w.\-]+\.xml$")
_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def discover_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.iterdir(), key=lambda p: p.name.lower()):
        if not path.is_dir() or not (path / "route.v2.xml").is_file():
            continue
        name = path.name
        try:
            text = (path / "route.v2.xml").read_text(encoding="utf-8", errors="replace")
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
            if ROUTES_DIR.resolve() in candidate.parents or candidate == ROUTES_DIR.resolve():
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


def db_error(exc: Exception):
    return jsonify({"ok": False, "error": str(exc)}), 503


def list_files(directory: Path, pattern: str):
    if not directory.exists():
        return []
    files = sorted(directory.glob(pattern), key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for path in files:
        if path.name.startswith(".") or path.name.startswith("_"):
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


def snip_to_edi_path(snip_name: str) -> Path | None:
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
        eip_url=os.environ.get("EIP_PUBLIC_URL", "http://localhost:8114/eip/"),
        test_results_pdf=TEST_RESULTS_PDF_NAME,
        has_xslt=bool(discover_xslt_files(ROUTES_DIR)),
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
                  c.PayerId, c.PayerName, c.PlaceOfService, c.ReferringNpi,
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
    pos = (payload.get("placeOfService") or "11").strip()[:2]
    ref_npi = (payload.get("referringNpi") or "").strip() or None
    payer_id = (payload.get("payerId") or "66783JJT").strip()
    payer_name = (
        "AHLIC" if payer_id == "66783JJT" else ("MEDICAID MD" if payer_id == "MDCAID01" else payer_id)
    )
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
                  ServiceDate, ClaimAmount, PlaceOfService, ReferringNpi, DiagnosisCode, Status, Notes
                ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,N'PENDING',%s)
                """,
                (
                    claim_id, patient_id, provider, payer_id, payer_name, claim_number,
                    svc, amount, pos, ref_npi, dx, notes,
                ),
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
                "expectedKickout": f"{claim_id}_{claim_number}_kickout.xml",
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
    return jsonify({"ok": True, "files": list_files(SNIP_DIR, "*.xml")})


@app.get("/api/kickouts")
def api_kickouts():
    prefix = request.args.get("prefix")
    files = list_files(KICKOUT_DIR, "*.xml")
    if prefix:
        files = [f for f in files if f["name"].startswith(prefix)]
    return jsonify({"ok": True, "files": files})


@app.get("/api/bi-outcomes")
def api_bi_outcomes():
    return jsonify({"ok": True, "files": list_files(BI_DIR, "*.xml")})


@app.get("/api/payer-rules")
def api_payer_rules():
    try:
        with db() as conn:
            cur = conn.cursor(as_dict=True)
            cur.execute(
                """
                SELECT RuleId, PayerId, PayerName, RuleCode, Severity, Message,
                       RequireReferringNpi, AllowedPosList
                FROM dbo.PayerEditRules ORDER BY PayerId, RuleId
                """
            )
            return jsonify({"ok": True, "rules": cur.fetchall()})
    except Exception as exc:  # noqa: BLE001
        return db_error(exc)


@app.get("/api/snip-report")
def api_snip_report():
    """HTML report via the 14a EDI SNIP Validations Report XSLT pipeline."""
    name = (request.args.get("name") or "").strip()
    if not name or not _SAFE_NAME.match(name) or name.startswith("_"):
        return Response(
            fallback_html("Invalid SNIP file name."),
            mimetype="text/html; charset=utf-8",
            status=400,
        )
    snip_path = SNIP_DIR / name
    if not snip_path.is_file():
        return Response(
            fallback_html(f"SNIP file not found: {name}"),
            mimetype="text/html; charset=utf-8",
            status=404,
        )
    try:
        snip_xml = snip_path.read_text(encoding="utf-8", errors="replace")
        edi_path = snip_to_edi_path(name)
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
    return jsonify({"ok": True, "routes": discover_v2_routes()})


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
    route_dir = resolve_route_dir(route_id)
    if not route_dir:
        return jsonify({"ok": False, "error": "not found"}), 404
    path = route_dir / "diagram-groups.json"
    if not path.is_file():
        return jsonify({"ok": True, "groups": []})
    return send_file(path, mimetype="application/json")


@app.get("/api/v2/routes/<route_id>/modules/<module_id>.xml")
def api_v2_module_xml(route_id: str, module_id: str):
    if not _MODULE_ID.match(module_id):
        return Response("Invalid module id", status=400)
    route_dir = resolve_route_dir(route_id)
    if not route_dir:
        return Response("Route not found", status=404)
    path = route_dir / "modules" / f"{module_id}.xml"
    if not path.is_file():
        return Response("Module not found", status=404)
    return Response(path.read_text(encoding="utf-8", errors="replace"), mimetype="application/xml")


@app.get("/api/wait-edi/<int:claim_id>")
def api_wait_edi(claim_id: int):
    """Wait for clean EDI (PASS) or kickout decision (KICKOUT)."""
    timeout = float(request.args.get("timeout", "120"))
    deadline = time.time() + timeout
    prefix = f"{claim_id}_"
    while time.time() < deadline:
        edi = [f for f in list_files(EDI_DIR, "*.edi") if f["name"].startswith(prefix)]
        snip = [f for f in list_files(SNIP_DIR, "*.xml") if f["name"].startswith(prefix)]
        kick = [f for f in list_files(KICKOUT_DIR, "*.xml") if f["name"].startswith(prefix)]
        if kick:
            return jsonify({"ok": True, "bucket": "kickout", "kickout": kick[0], "edi": None})
        if edi:
            return jsonify(
                {"ok": True, "bucket": "clean", "edi": edi[0], "snip": snip[0] if snip else None}
            )
        time.sleep(2)
    return jsonify({"ok": False, "error": "Timed out waiting for scrub result"}), 504


@app.get("/api/build-timing")
def api_build_timing():
    """Serve documents/build-timing.json for the Timing tab."""
    for base in (DOCUMENTS_DIR, Path(__file__).resolve().parent.parent / "documents"):
        path = base / "build-timing.json"
        if path.is_file():
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except Exception as exc:  # noqa: BLE001
                return jsonify({"ok": False, "error": f"Invalid JSON: {exc}"}), 500
            return jsonify({"ok": True, "path": str(path), "timing": data})
    return jsonify({"ok": False, "error": "documents/build-timing.json not found"}), 404


register_docs_and_v2(
    app,
    routes_dir=ROUTES_DIR,
    documents_dir=DOCUMENTS_DIR,
    route_pdf_name=ROUTE_PDF_NAME,
    capability_pdf_name=CAPABILITY_PDF_NAME,
    test_results_pdf_name=TEST_RESULTS_PDF_NAME,
    test_plan_pdf_name=TEST_PLAN_PDF_NAME,
)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8115, debug=False)
