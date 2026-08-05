"""Medical Device HL7 → EHR demo Web UI."""
from __future__ import annotations

import os
import re
import socket
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

app = Flask(__name__)

LLP_HOST = os.environ.get("EIP_LLP_HOST", "127.0.0.1")
LLP_PORT = int(os.environ.get("EIP_LLP_PORT", "2580"))
INBOUND_DIR = Path(os.environ.get("INBOUND_DIR", "/output/inbound"))
OUTBOUND_DIR = Path(os.environ.get("OUTBOUND_DIR", "/output/ehr-outbound"))
RECEIVED_DIR = Path(os.environ.get("RECEIVED_DIR", "/output/ehr-received"))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", "/samples"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
ROUTE_PDF_NAME = os.environ.get("ROUTE_PDF_NAME", "DeviceHL7EHR_V2_Route_Diagrams.pdf")
CAPABILITY_PDF_NAME = os.environ.get("CAPABILITY_PDF_NAME", "DeviceHL7EHR_Capability_Brief.pdf")

START = b"\x0b"
END = b"\x1c\x0d"

DEVICES = {
    "vitals": {
        "id": "vitals",
        "name": "Bedside Vital Signs Monitor",
        "sendingApp": "VITALMON",
        "sample": "VITALS_ORU_panel.hl7",
        "blurb": "HR, SpO2, NIBP as ORU^R01",
    },
    "cgm": {
        "id": "cgm",
        "name": "Continuous Glucose Monitor",
        "sendingApp": "CGM01",
        "sample": "CGM_ORU_glucose.hl7",
        "blurb": "Interstitial glucose as ORU^R01",
    },
}


def list_hl7(dir_path: Path, limit: int = 20) -> list[dict]:
    if not dir_path.is_dir():
        return []
    files = sorted(dir_path.glob("*.hl7"), key=lambda p: p.stat().st_mtime, reverse=True)
    out = []
    for f in files[:limit]:
        text = f.read_text(encoding="utf-8", errors="replace")
        msh = text.splitlines()[0] if text else ""
        parts = msh.split("|")
        out.append(
            {
                "name": f.name,
                "mtime": int(f.stat().st_mtime),
                "controlId": parts[9] if len(parts) > 9 else "",
                "device": parts[2] if len(parts) > 2 else "",
                "preview": text[:400],
            }
        )
    return out


def mllp_send(payload: str, timeout: float = 60.0) -> str:
    text = payload.replace("\r\n", "\r").replace("\n", "\r")
    if not text.endswith("\r"):
        text += "\r"
    framed = START + text.encode("utf-8") + END
    with socket.create_connection((LLP_HOST, LLP_PORT), timeout=timeout) as s:
        s.settimeout(timeout)
        s.sendall(framed)
        buf = b""
        while END not in buf:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
    if START in buf and END in buf:
        body = buf[buf.find(START) + 1 : buf.find(END)]
    else:
        body = buf
    return body.decode("utf-8", errors="replace")


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


@app.get("/")
def index():
    samples = sorted(p.name for p in SAMPLE_DIR.glob("*.hl7")) if SAMPLE_DIR.is_dir() else []
    return render_template(
        "index.html",
        devices=list(DEVICES.values()),
        samples=samples,
        llp=f"{LLP_HOST}:{LLP_PORT}",
        has_xslt=bool(discover_xslt_files()),
    )


@app.get("/api/status")
def status():
    return jsonify(
        {
            "ok": True,
            "llp": f"{LLP_HOST}:{LLP_PORT}",
            "devices": list(DEVICES.values()),
            "inbound": list_hl7(INBOUND_DIR),
            "outbound": list_hl7(OUTBOUND_DIR),
            "ehrReceived": list_hl7(RECEIVED_DIR),
        }
    )


@app.post("/api/simulate-device")
def simulate_device():
    data = request.get_json(force=True, silent=True) or {}
    device_id = (data.get("device") or "").strip()
    device = DEVICES.get(device_id)
    if not device:
        return jsonify({"ok": False, "error": f"Unknown device {device_id}"}), 400
    path = SAMPLE_DIR / device["sample"]
    if not path.is_file():
        return jsonify({"ok": False, "error": f"Missing sample {device['sample']}"}), 400
    hl7 = path.read_text(encoding="utf-8", errors="replace")
    try:
        ack = mllp_send(hl7)
        return jsonify({"ok": True, "device": device, "ack": ack})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 500


@app.post("/api/send-llp")
def send_llp():
    data = request.get_json(force=True, silent=True) or {}
    sample = (data.get("sample") or "").strip()
    hl7 = (data.get("hl7") or "").strip()
    if sample:
        path = SAMPLE_DIR / sample
        if not path.is_file():
            return jsonify({"ok": False, "error": f"Unknown sample {sample}"}), 400
        hl7 = path.read_text(encoding="utf-8", errors="replace")
    if not hl7.strip():
        return jsonify({"ok": False, "error": "Provide hl7 text or sample name"}), 400
    try:
        return jsonify({"ok": True, "ack": mllp_send(hl7)})
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
        return send_file(path)
    return Response(
        "Capability brief not generated yet. Run: python3 tools/export_stakeholder_brief.py",
        status=404,
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8101, debug=False)
