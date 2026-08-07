"""EDI 835 → OCI Object Storage demo Web UI."""
from __future__ import annotations

import json

import os
import re
import shutil
import time
from pathlib import Path

import oci
from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

# Shared with atmoz/sftp upload dir — PilotFish still polls via real SFTP.
SFTP_UPLOAD_DIR = Path(os.environ.get("SFTP_UPLOAD_DIR", "/sftp-upload"))
ARCHIVE_DIR = Path(os.environ.get("ARCHIVE_DIR", "/output/archive"))
STAGED_DIR = Path(os.environ.get("STAGED_DIR", "/output/staged"))
JSON_DIR = Path(os.environ.get("JSON_DIR", "/output/json"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "EDI835_OCI_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get("CAPABILITY_PDF_NAME", "EDI835_OCI_Capability_Brief.pdf")
GAPS_PDF_NAME = os.environ.get(
    "GAPS_PDF_NAME", "PilotFish_EDI835_OCI_Gaps_And_Custom_Modules.pdf"
)
OCI_ENDPOINT = os.environ.get("OCI_ENDPOINT", "http://floci-oci:4599")
OCI_NAMESPACE = os.environ.get("OCI_NAMESPACE", "floci-local")
OCI_BUCKET = os.environ.get("OCI_BUCKET", "edi-835-payments")
OCI_CONFIG_FILE = os.environ.get("OCI_CONFIG_FILE", "/oci-config/config")
LAN_HINT = os.environ.get("LAN_HINT", "")
SFTP_HINT = os.environ.get("SFTP_HINT", "sftp:22/upload")


def list_floci_objects(limit: int = 30) -> dict:
    try:
        config = oci.config.from_file(OCI_CONFIG_FILE, "DEFAULT")
        client = oci.object_storage.ObjectStorageClient(
            config, service_endpoint=OCI_ENDPOINT
        )
        resp = client.list_objects(OCI_NAMESPACE, OCI_BUCKET)
        objects = []
        for obj in sorted(
            resp.data.objects or [],
            key=lambda o: o.time_created or o.name,
            reverse=True,
        )[:limit]:
            preview = ""
            try:
                got = client.get_object(OCI_NAMESPACE, OCI_BUCKET, obj.name)
                preview = got.data.content.decode("utf-8", errors="replace")[:400]
            except Exception:
                preview = ""
            objects.append(
                {
                    "name": obj.name,
                    "bytes": obj.size or 0,
                    "mtime": int(obj.time_created.timestamp()) if obj.time_created else 0,
                    "preview": preview,
                }
            )
        return {
            "ok": True,
            "endpoint": OCI_ENDPOINT,
            "namespace": OCI_NAMESPACE,
            "bucket": OCI_BUCKET,
            "objects": objects,
        }
    except Exception as exc:  # noqa: BLE001
        return {
            "ok": False,
            "error": str(exc),
            "endpoint": OCI_ENDPOINT,
            "namespace": OCI_NAMESPACE,
            "bucket": OCI_BUCKET,
            "objects": [],
        }


def list_files(dir_path: Path, patterns: tuple[str, ...] = ("*",), limit: int = 30) -> list[dict]:
    if not dir_path.is_dir():
        return []
    files: list[Path] = []
    for pat in patterns:
        files.extend(dir_path.rglob(pat))
    files = [p for p in files if p.is_file() and not p.name.endswith(".meta.json")]
    files = sorted(files, key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for f in files[:limit]:
        text = ""
        try:
            if f.suffix.lower() in {".json", ".edi", ".txt", ".xml", ".835"}:
                text = f.read_text(encoding="utf-8", errors="replace")[:500]
        except Exception:
            text = ""
        out.append(
            {
                "name": str(f.relative_to(dir_path)).replace("\\", "/"),
                "mtime": int(f.stat().st_mtime),
                "bytes": f.stat().st_size,
                "preview": text,
            }
        )
    return out


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


@app.get("/")
def index():
    samples = sorted(p.name for p in SAMPLE_DIR.glob("*.edi")) if SAMPLE_DIR.is_dir() else []
    return render_template(
        "index.html",
        samples=samples,
        lan_hint=LAN_HINT,
        sftp=SFTP_HINT,
        has_xslt=bool(discover_xslt_files()),
        gaps_pdf=GAPS_PDF_NAME,
    )


@app.get("/api/status")
def status():
    floci = list_floci_objects()
    return jsonify(
        {
            "ok": True,
            "sftp": SFTP_HINT,
            "archive": list_files(ARCHIVE_DIR, ("*.edi", "*.835", "*.txt")),
            "staged": list_files(STAGED_DIR, ("*.edi", "*.835", "*.txt")),
            "json": list_files(JSON_DIR, ("*.json",)),
            "ociFiles": floci.get("objects") or [],
            "ociApi": floci,
        }
    )


@app.post("/api/upload-sftp")
def upload_sftp():
    """Drop a sample into the SFTP upload directory (same volume as atmoz/sftp)."""
    data = request.get_json(force=True, silent=True) or {}
    sample = (data.get("sample") or "").strip()
    if not sample:
        return jsonify({"ok": False, "error": "Provide sample name"}), 400
    path = SAMPLE_DIR / sample
    if not path.is_file():
        return jsonify({"ok": False, "error": f"Unknown sample {sample}"}), 400
    SFTP_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    remote_name = f"ui_{int(time.time())}_{sample}"
    dest = SFTP_UPLOAD_DIR / remote_name
    try:
        shutil.copyfile(path, dest)
        # Ensure SFTP sees a finished write
        os.utime(dest, None)
        return jsonify(
            {
                "ok": True,
                "remote": f"upload/{remote_name}",
                "bytes": dest.stat().st_size,
                "note": "Wrote shared SFTP upload volume; PilotFish polls via FTPListener/SFTP",
            }
        )
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 500


@app.get("/api/v2/routes")
def v2_routes():
    return jsonify({"ok": True, "routes": list_v2_routes(), "routesDir": str(ROUTES_DIR)})


@app.get("/api/v2/routes/<route_id>/route.v2.xml")
def v2_route_xml(route_id: str):
    rd = find_route_dir(route_id)
    if not rd:
        return "Not found", 404
    return (rd / "route.v2.xml").read_text(encoding="utf-8", errors="replace"), 200, {
        "Content-Type": "application/xml; charset=utf-8"
    }


@app.get("/api/v2/routes/<route_id>/diagram-groups.json")
def api_v2_diagram_groups(route_id: str):
    """Optional docs-only Processor Group definitions for route diagrams."""
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
def v2_module_xml(route_id: str, module_id: str):
    rd = find_route_dir(route_id)
    if not rd:
        return "Not found", 404
    path = rd / "modules" / f"{module_id}.xml"
    if not path.is_file():
        return "Not found", 404
    return path.read_text(encoding="utf-8", errors="replace"), 200, {
        "Content-Type": "application/xml; charset=utf-8"
    }


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


@app.get("/documents/<path:name>")
def documents(name: str):
    path = DOCUMENTS_DIR / name
    if not path.is_file():
        return "Not found", 404
    return send_file(path)


@app.get("/documents/capability-brief.pdf")
def capability_pdf_alias():
    path = DOCUMENTS_DIR / CAPABILITY_PDF_NAME
    if not path.is_file():
        return Response(
            "Capability brief not generated yet. Run: python3 tools/export_stakeholder_brief.py",
            status=404,
        )
    return send_file(path)


@app.get("/documents/route-diagrams.pdf")
def route_pdf_alias():
    path = DOCUMENTS_DIR / ROUTE_PDF_NAME
    if not path.is_file():
        return "Not found", 404
    return send_file(path)



# INFO_TAB_STANDARD_BOOTSTRAP
try:
    from document_routes import ensure_document_routes
except ImportError:
    ensure_document_routes = None  # type: ignore

_INFO_TAB_CTX = {
    "info_title": 'SFTP 835 → ST split → JSON → OCI',
    "info_blurb": 'Boss pattern: SFTP poll · fork each ST/Transaction · JSON · Object Storage REST (HTTP until OCI Transport exists).',
    "info_note": 'Demo only — SFTP 835 to JSON Object Storage path.',
    "eip_url": 'http://localhost:8104/eip/',
    "lan_hint": "",
    "info_ports": [
        {"label": "SFTP", "value": "2222"},
        {"label": "Mock OCI", "value": "4599"},
        {"label": "PilotFish EIP", "value": "8104"},
        {"label": "Demo Web UI", "value": "8105"}
    ],
    "info_extra_links": [{'href': '/documents/Connect_OciObjectStorageTransport_To_Real_Oracle_OCI.pdf', 'label': 'Connect OCI transport (guide PDF)'}, {'href': '/documents/PilotFish_EDI835_OCI_Gaps_And_Custom_Modules.pdf', 'label': 'Gaps and custom modules PDF'}],
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
        route_pdf_name='EDI835_OCI_V2_Route_Diagrams.pdf',
        capability_pdf_name='EDI835_OCI_Capability_Brief.pdf',
        test_plan_pdf_name=None,
        test_results_pdf_name=None,
    )
# END INFO_TAB_STANDARD_BOOTSTRAP


# TIMING_TAB_API_BOOTSTRAP
try:
    from document_routes import ensure_build_timing_api
except ImportError:
    ensure_build_timing_api = None  # type: ignore
if ensure_build_timing_api is not None:
    from pathlib import Path as _PathTiming
    import os as _os_timing
    ensure_build_timing_api(
        app,
        _PathTiming(_os_timing.environ.get("DOCUMENTS_DIR", "/documents")),
    )
# END TIMING_TAB_API_BOOTSTRAP

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8105")))
