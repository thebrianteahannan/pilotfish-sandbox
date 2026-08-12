"""EDI 270/271 Realtime demo — clinic UI posts once; PilotFish owns payer round-trip."""
from __future__ import annotations

import json
import os
import re
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/output"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "EDI270_271_Realtime_V2_Route_Diagrams.pdf")
DIFF_PDF_NAME = os.environ.get("DIFF_PDF_NAME", "EDI270_271_Orig_vs_Realtime_Differences.pdf")
CAPABILITY_PDF_NAME = os.environ.get(
    "CAPABILITY_PDF_NAME", "EDI270_271_Realtime_Capability_Brief.pdf"
)
ENV_SETTINGS_FILE = Path(os.environ.get("ENV_SETTINGS_FILE", "/environment-settings.conf"))
WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8121"))
LAN_HINT = os.environ.get("LAN_HINT", "")
PF_BASE = os.environ.get(
    "PF_ELIGIBILITY_BASE_URL", "http://pilotfish:8080/eip/rest/eligibility"
).rstrip("/")
PF_PUBLIC = os.environ.get(
    "PF_PUBLIC_BASE_URL", "http://192.168.68.52:8120/eip/rest/eligibility"
).rstrip("/")
PAYER_PUBLIC = os.environ.get("MOCK_PAYER_PUBLIC_URL", "http://192.168.68.52:8211/x12/270")

_XSLT_SUFFIXES = {".xsl", ".xslt"}
_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
_SENSITIVE_ENV = re.compile(
    r"(password|secret|token|apikey|api[_-]?key|private[_-]?key|passphrase|credential)",
    re.I,
)

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
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip()).strip("-").lower()


def list_v2_routes() -> list[dict]:
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.iterdir()):
        if path.is_dir() and (path / "route.v2.xml").is_file():
            out.append({"id": route_slug(path.name), "dir": path.name, "name": path.name})
    return out


def find_route_dir(route_id: str) -> Path | None:
    for meta in list_v2_routes():
        if meta["id"] == route_id:
            return ROUTES_DIR / meta["dir"]
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


def http_call(url: str, data: bytes, content_type: str, timeout: int = 60) -> tuple[int, str, dict]:
    req = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={"Content-Type": content_type, "Accept": "*/*"},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            headers = {k: v for k, v in resp.headers.items()}
            return resp.status, body, headers
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        return exc.code, body, {}
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError(str(exc)) from exc


def build_request_xml(payload: dict) -> str:
    root = ET.Element("EligibilityRequest")
    fields = [
        "MemberId",
        "LastName",
        "FirstName",
        "BirthDate",
        "Gender",
        "PayerId",
        "PayerName",
        "ProviderNpi",
        "ProviderName",
        "ServiceTypeCode",
        "ServiceDate",
        "TraceNumber",
    ]
    defaults = {
        "PayerId": "MOCKPAYER",
        "PayerName": "MOCK PAYER",
        "ProviderNpi": "1234567893",
        "ProviderName": "PILOTFISH DEMO CLINIC",
        "ServiceTypeCode": "30",
        "ServiceDate": time.strftime("%Y%m%d"),
        "TraceNumber": f"T{int(time.time())}",
    }
    for key in fields:
        val = (payload.get(key) or defaults.get(key) or "").strip()
        ET.SubElement(root, key).text = val
    return ET.tostring(root, encoding="unicode")


def list_recent(subdir: str, patterns: tuple[str, ...], limit: int = 12) -> list[dict]:
    base = OUTPUT_DIR / subdir
    if not base.is_dir():
        return []
    files: list[Path] = []
    for pat in patterns:
        files.extend(base.glob(pat))
    files = sorted([f for f in files if f.is_file()], key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for f in files[:limit]:
        try:
            preview = f.read_text(encoding="utf-8", errors="replace")[:600]
        except OSError:
            preview = ""
        out.append(
            {
                "name": f.name,
                "bytes": f.stat().st_size,
                "mtime": int(f.stat().st_mtime),
                "preview": preview,
            }
        )
    return out


def newest_preview(subdir: str, patterns: tuple[str, ...]) -> str:
    items = list_recent(subdir, patterns, limit=1)
    if not items:
        return ""
    path = OUTPUT_DIR / subdir / items[0]["name"]
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return items[0].get("preview") or ""


@app.get("/")
def index():
    return render_template(
        "index.html",
        lan_hint=LAN_HINT,
        pf_public=PF_PUBLIC,
        payer_public=PAYER_PUBLIC,
        presets=PRESETS,
        has_xslt=bool(discover_xslt_files()),
        route_pdf=ROUTE_PDF_NAME,
        diff_pdf=DIFF_PDF_NAME,
    )


@app.get("/api/status")
def status():
    return jsonify(
        {
            "ok": True,
            "mode": "realtime",
            "pf": PF_PUBLIC,
            "payer": PAYER_PUBLIC,
            "check": f"{PF_PUBLIC}/check",
            "requests": list_recent("requests", ("*.dat", "*.xml")),
            "edi270": list_recent("270", ("*.edi", "*.xml")),
            "edi271": list_recent("271", ("*.edi", "*.xml")),
            "responses": list_recent("responses", ("*.json",)),
        }
    )


@app.post("/api/check-eligibility")
def check_eligibility():
    """One clinic POST → PilotFish /eligibility/check (build + payer + parse)."""
    payload = request.get_json(force=True, silent=True) or {}
    steps: list[dict] = []
    try:
        req_xml = build_request_xml(payload)
        steps.append({"step": "request_xml", "ok": True, "body": req_xml})

        t0 = time.time()
        code, summary_text, _ = http_call(
            f"{PF_BASE}/check",
            req_xml.encode("utf-8"),
            "application/xml; charset=UTF-8",
            timeout=90,
        )
        elapsed_ms = int((time.time() - t0) * 1000)

        summary = None
        try:
            summary = json.loads(summary_text)
        except Exception:
            summary = {"raw": summary_text}

        ok = code < 400 and isinstance(summary, dict) and "status" in summary
        steps.append(
            {
                "step": "pf_realtime_check",
                "ok": ok,
                "status": code,
                "elapsedMs": elapsed_ms,
                "endpoint": f"{PF_PUBLIC}/check",
                "body": summary_text if len(summary_text) < 4000 else summary_text[:4000],
                "note": "Single sync REST call; PilotFish posted 270 to payer and parsed 271",
            }
        )

        # Wire artifacts written by the route (for Gary’s “show the X12” narrative)
        edi270 = newest_preview("270", ("*.edi",))
        edi271 = newest_preview("271", ("*.edi",))
        if edi270:
            steps.append({"step": "build_270", "ok": True, "body": edi270, "source": "output/270"})
        if edi271:
            steps.append({"step": "payer_271", "ok": True, "body": edi271, "source": "output/271"})
        steps.append(
            {
                "step": "parse_271",
                "ok": ok,
                "status": code,
                "body": summary_text if len(summary_text) < 4000 else summary_text[:4000],
            }
        )

        return jsonify(
            {
                "ok": ok,
                "mode": "realtime",
                "elapsedMs": elapsed_ms,
                "summary": summary,
                "steps": steps,
                "endpoints": {
                    "check": f"{PF_PUBLIC}/check",
                    "payer_internal": "http://mock-payer:8210/x12/270",
                    "payer_public": PAYER_PUBLIC,
                },
            }
        )
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc), "steps": steps}), 500


@app.get("/api/v2/routes")
def api_v2_routes():
    return jsonify({"ok": True, "routes": list_v2_routes()})


@app.get("/api/v2/routes/<route_id>/route.v2.xml")
def api_v2_route_xml(route_id: str):
    d = find_route_dir(route_id)
    if not d:
        return Response("Not found", status=404)
    return send_file(d / "route.v2.xml", mimetype="application/xml")


@app.get("/api/v2/routes/<route_id>/diagram-groups.json")
def api_v2_diagram_groups(route_id: str):
    d = find_route_dir(route_id)
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
        return Response("Bad module id", status=400)
    d = find_route_dir(route_id)
    if not d:
        return Response("Not found", status=404)
    path = d / "modules" / f"{module_id}.xml"
    if not path.is_file():
        return Response("Not found", status=404)
    return send_file(path, mimetype="application/xml")


@app.get("/api/v2/xslt")
def api_v2_xslt():
    return jsonify({"ok": True, "files": discover_xslt_files()})


@app.get("/api/v2/xslt/content")
def api_v2_xslt_content():
    path = resolve_xslt_path(request.args.get("path") or "")
    if not path:
        return Response("Not found", status=404)
    return Response(path.read_text(encoding="utf-8", errors="replace"), mimetype="text/plain")


@app.get("/api/v2/environment-settings")
def api_env_settings():
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
def route_diagrams_alias():
    path = DOCUMENTS_DIR / ROUTE_PDF_NAME
    if path.is_file():
        return send_file(path)
    return Response("Route PDF not generated yet", status=404)


@app.get("/documents/differences.pdf")
def differences_alias():
    path = DOCUMENTS_DIR / DIFF_PDF_NAME
    if path.is_file():
        return send_file(path)
    return Response("Differences PDF not generated yet", status=404)



# INFO_TAB_STANDARD_BOOTSTRAP
try:
    from document_routes import ensure_document_routes
except ImportError:
    ensure_document_routes = None  # type: ignore

_INFO_TAB_CTX = {
    "info_title": 'Realtime eligibility — PilotFish owns the 270/271 round-trip',
    "info_blurb": 'Clinic posts <code>EligibilityRequest</code> once to PilotFish. Maps to X12 270, posts to the mock payer, parses the 271, and returns clinic JSON on the same HTTP request.',
    "info_note": 'Demo only — realtime 270/271 round-trip on eiPlatform.',
    "eip_url": 'http://localhost:8120/eip/',
    "lan_hint": "",
    "info_ports": [
        {"label": "Mock payer", "value": "8211"},
        {"label": "PilotFish EIP", "value": "8120"},
        {"label": "Demo Web UI", "value": "8121"}
    ],
    "info_extra_links": [{'href': '/documents/differences.pdf', 'label': 'How this differs from edi-270-271-eligibility'}],
    "info_extra_sections": [],
    "test_results_pdf": None,
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
        route_pdf_name='EDI270_271_Realtime_V2_Route_Diagrams.pdf',
        capability_pdf_name='EDI270_271_Realtime_Capability_Brief.pdf',
        test_plan_pdf_name=None,
        test_results_pdf_name=None,
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
