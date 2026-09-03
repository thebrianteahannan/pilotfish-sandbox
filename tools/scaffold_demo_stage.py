#!/usr/bin/env python3
"""Scaffold a progressive-build demo stage (Web UI early, docs early, live Routes).

Creates Clients/Demos/<slug>/ and (by default) immediately starts the stage Web UI
so stakeholders see something in the first minute — before DESIGN / routes / EIP.

Creates:
  - DESIGN.md stub, README.md
  - documents/build-timing.json + build-status.json (active)
  - Minimal stage Web UI (Routes / Timing / Info) with build-live polling
  - docker-compose.yml with profile `stage` (webui-only) and full stack stubs

Usage:
  python3 tools/scaffold_demo_stage.py --slug my-new-demo --title "My New Demo" --port 8120
  # folder created + docker compose --profile stage up -d --build (default)

  python3 tools/scaffold_demo_stage.py --slug my-new-demo --port 8120 --no-up
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import socket
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from demo_paths import DEMOS, infer_category, require_demo

ROOT = Path(__file__).resolve().parents[1]
SHARED = DEMOS / "_shared" / "webui"
# Prefer shared replay-capable viewer; fall back to a known good demo copy.
REF_VIEWER = (
    (SHARED / "static" / "route-viewer")
    if (SHARED / "static" / "route-viewer" / "route-viewer.js").is_file()
    else require_demo("edi-999-ta1-ack-triage") / "webui" / "static" / "route-viewer"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def slugify(text: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", text.strip().lower()).strip("-")
    return s or "new-demo"


def lan_hint(port: int) -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
    except OSError:
        ip = "127.0.0.1"
    return f"http://{ip}:{port}/"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def copy_shared_static(webui: Path) -> None:
    static = webui / "static"
    static.mkdir(parents=True, exist_ok=True)
    for name in ("pf-theme.css", "build-live.js", "build-live.css", "build-stage.js", "timing-tab.js", "timing-tab.css", "code-highlight.js", "code-highlight.css", "pilotfish-logo.jpg", "construction-video.js", "sandbox-home.js"):
        src = SHARED / "static" / name
        if not src.is_file():
            # timing/code live either under static/ or directly under shared
            alt = SHARED / name
            src = alt if alt.is_file() else src
        if src.is_file():
            shutil.copy2(src, static / name)
    # document_routes + partials
    shutil.copy2(SHARED / "document_routes.py", webui / "document_routes.py")
    partials = webui / "templates" / "partials"
    partials.mkdir(parents=True, exist_ok=True)
    for name in ("timing_tab.html", "info_tab.html"):
        src = SHARED / "templates" / "partials" / name
        if src.is_file():
            shutil.copy2(src, partials / name)
    # route viewer from reference demo
    dest_viewer = static / "route-viewer"
    if REF_VIEWER.is_dir():
        if dest_viewer.exists():
            shutil.rmtree(dest_viewer)
        shutil.copytree(REF_VIEWER, dest_viewer)


APP_PY = '''#!/usr/bin/env python3
"""Progressive build stage Web UI for {title}."""

from __future__ import annotations

import os
import re
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, send_file

app = Flask(__name__)

WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "{port}"))
ROUTES_DIR = Path(os.environ.get("ROUTES_DIR", "/routes"))
DOCUMENTS_DIR = Path(os.environ.get("DOCUMENTS_DIR", "/documents"))
LAN_HINT = os.environ.get("LAN_HINT", "")
EIP_PUBLIC_URL = os.environ.get("EIP_PUBLIC_URL", "")

_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{{8}}-[0-9a-fA-F]{{4}}-[0-9a-fA-F]{{4}}-[0-9a-fA-F]{{4}}-[0-9a-fA-F]{{12}}$"
)
_ROUTE_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def route_slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name.strip().lower()).strip("-")


def list_v2_routes():
    if not ROUTES_DIR.is_dir():
        return []
    out = []
    for path in sorted(ROUTES_DIR.glob("*/route.v2.xml")):
        out.append(
            {{
                "id": route_slug(path.parent.name),
                "name": path.parent.name,
                "mtime": path.stat().st_mtime,
            }}
        )
    return out


@app.get("/")
def index():
    return render_template(
        "index.html",
        title="{title}",
        lan_hint=LAN_HINT,
        eip_url=EIP_PUBLIC_URL,
    )


@app.get("/api/v2/routes")
def api_routes():
    return jsonify({{"routes": list_v2_routes()}})


@app.get("/api/v2/routes/<route_id>/route.v2.xml")
def api_route_xml(route_id: str):
    if not _ROUTE_SLUG.match(route_id):
        return Response("bad route", status=400)
    for path in ROUTES_DIR.glob("*/route.v2.xml"):
        if route_slug(path.parent.name) == route_id:
            return send_file(path, mimetype="application/xml")
    return Response("not found", status=404)


@app.get("/api/v2/routes/<route_id>/diagram-groups.json")
def api_route_groups(route_id: str):
    if not _ROUTE_SLUG.match(route_id):
        return Response("bad route", status=400)
    for path in ROUTES_DIR.glob("*/diagram-groups.json"):
        if route_slug(path.parent.name) == route_id:
            return send_file(path, mimetype="application/json")
    return jsonify({{"groups": []}})


@app.get("/api/v2/routes/<route_id>/modules/<module_id>.xml")
def api_module_xml(route_id: str, module_id: str):
    if not _ROUTE_SLUG.match(route_id) or not _MODULE_ID.match(module_id):
        return Response("bad id", status=400)
    for route_dir in ROUTES_DIR.iterdir():
        if not route_dir.is_dir() or route_slug(route_dir.name) != route_id:
            continue
        path = route_dir / "modules" / f"{{module_id}}.xml"
        if path.is_file():
            return send_file(path, mimetype="application/xml")
    return Response("not found", status=404)


try:
    from document_routes import ensure_build_replay_api, ensure_build_status_api, ensure_build_timing_api, ensure_document_routes
except ImportError:
    ensure_document_routes = None  # type: ignore
    ensure_build_timing_api = None  # type: ignore
    ensure_build_status_api = None  # type: ignore
    ensure_build_replay_api = None  # type: ignore

if ensure_document_routes is not None:
    ensure_document_routes(app, DOCUMENTS_DIR)
if ensure_build_timing_api is not None:
    ensure_build_timing_api(app, DOCUMENTS_DIR)
if ensure_build_status_api is not None:
    ensure_build_status_api(app, DOCUMENTS_DIR)
if ensure_build_replay_api is not None:
    ensure_build_replay_api(app, DOCUMENTS_DIR)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=WEBUI_PORT, debug=False)
'''

INDEX_HTML = '''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{{ title }} — Build Stage</title>
  <link rel="stylesheet" href="/static/pf-theme.css" />
  <link rel="stylesheet" href="/static/app.css" />
  <link rel="stylesheet" href="/static/timing-tab.css" />
  <link rel="stylesheet" href="/static/build-live.css" />
</head>
<body>
  <header>
    <div class="app-bar">
      <p class="brand">PilotFish · {{ title }}</p>
      <div class="main-tabs" role="tablist">
        <button type="button" class="main-tab active" data-main-tab="routes">Routes</button>
        <button type="button" class="main-tab" data-main-tab="timing">Timing</button>
        <button type="button" class="main-tab" data-main-tab="info">Info</button>
      </div>
    </div>
  </header>

  <div id="tab-routes">
    <section class="panel routes-panel">
      <div class="row-head">
        <h2>Routes</h2>
        <select id="route-select"></select>
        <span id="routes-status" class="muted">Live construction</span>
      </div>
      <iframe id="route-viewer-frame" title="Route viewer" src="about:blank"></iframe>
    </section>
  </div>

  <div id="tab-timing" hidden>
    {% include "partials/timing_tab.html" %}
  </div>
  <div id="tab-info" hidden>
    {% include "partials/info_tab.html" %}
  </div>

  <script src="/static/timing-tab.js"></script>
  <script src="/static/build-stage.js"></script>
  <script src="/static/build-live.js"></script>
  <script src="/static/construction-video.js"></script>
  <script src="/static/sandbox-home.js"></script>
  <script src="/static/app.js"></script>
</body>
</html>
'''

APP_CSS = '''
:root {
  --pf-blue: #0797f7;
  --pf-blue-deep: #007cba;
  --ink: #3b3b3b;
  --muted: #6b6b6b;
  --line: #d5e0ea;
  --bg: #f5f8fb;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
  color: var(--ink);
  background: var(--bg);
}
header { background: #fff; border-bottom: 1px solid var(--line); }
.app-bar {
  display: flex; justify-content: space-between; align-items: center;
  gap: 1rem; padding: 0.75rem 1.25rem; flex-wrap: wrap;
}
.brand { margin: 0; font-weight: 700; color: var(--pf-blue-deep); }
.main-tabs { display: flex; gap: 0.35rem; }
.main-tab {
  border: 1px solid var(--line); background: #fff; border-radius: 6px;
  padding: 0.4rem 0.75rem; cursor: pointer; font: inherit;
}
.main-tab.active { background: var(--pf-blue); color: #fff; border-color: var(--pf-blue); }
.panel { margin: 1rem 1.25rem; background: #fff; border: 1px solid var(--line); border-radius: 10px; padding: 0.85rem; }
.row-head { display: flex; gap: 0.75rem; align-items: center; flex-wrap: wrap; margin-bottom: 0.5rem; }
.row-head h2 { margin: 0; font-size: 1.1rem; }
.muted { color: var(--muted); font-size: 0.85rem; }
#route-viewer-frame {
  width: 100%; min-height: 70vh; border: 1px solid var(--line); border-radius: 8px; background: #fff;
}
select { font: inherit; padding: 0.35rem 0.5rem; border-radius: 6px; border: 1px solid var(--line); }
'''

APP_JS = '''
document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.mainTab;
    document.querySelectorAll(".main-tab").forEach((b) => {
      b.classList.toggle("active", b === btn);
    });
    const routes = document.getElementById("tab-routes");
    const timing = document.getElementById("tab-timing");
    const info = document.getElementById("tab-info");
    if (routes) routes.hidden = tab !== "routes";
    if (timing) timing.hidden = tab !== "timing";
    if (info) info.hidden = tab !== "info";
  });
});
'''

DOCKERFILE = '''FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENV WEBUI_PORT={port} PYTHONUNBUFFERED=1
EXPOSE {port}
CMD ["python", "app.py"]
'''

COMPOSE = '''services:
  webui:
    profiles: ["stage", "full"]
    build:
      context: ./webui
    image: pilotfish-{slug}-webui:latest
    container_name: pf-{slug_short}-webui
    restart: unless-stopped
    environment:
      WEBUI_PORT: "{port}"
      DEMO_SLUG: "{slug}"
      ROUTES_DIR: /routes
      DOCUMENTS_DIR: /documents
      LAN_HINT: "{lan}"
      EIP_PUBLIC_URL: "http://localhost:{eip_port}/eip/"
    ports:
      - "{port}:{port}"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./documents:/documents:ro
      # Prefer demo-eip-root (no spaces). Paths with spaces often mount empty on Docker Desktop.
      - ./pilotfish/demo-eip-root/routes:/routes:ro
      - ./webui/static:/app/static:ro
      - ./webui/templates:/app/templates:ro
      - ./webui/app.py:/app/app.py:ro
      - ./webui/document_routes.py:/app/document_routes.py:ro

  # Add pilotfish (+ deps) under profile "full" when runtime is ready.
  # pilotfish:
  #   profiles: ["full"]
  #   ...
'''


def wait_for_webui(port: int, timeout: float = 90.0) -> bool:
    deadline = time.time() + timeout
    url = f"http://127.0.0.1:{port}/"
    while time.time() < deadline:
        try:
            with urlopen(url, timeout=2) as resp:
                if 200 <= getattr(resp, "status", 200) < 500:
                    return True
        except (URLError, OSError, TimeoutError):
            time.sleep(1.5)
    return False


def start_stage_webui(demo: Path, port: int) -> None:
    """Bring up profile stage so the user sees the UI immediately."""
    print(f"Starting stage Web UI (docker compose --profile stage)…", flush=True)
    proc = subprocess.run(
        ["docker", "compose", "--profile", "stage", "up", "-d", "--build"],
        cwd=demo,
        check=False,
    )
    if proc.returncode != 0:
        print(
            f"WARNING: docker compose failed (exit {proc.returncode}). "
            f"Start manually:\n  cd {demo}\n  docker compose --profile stage up -d --build",
            file=sys.stderr,
        )
        return
    if wait_for_webui(port):
        print(f"Web UI ready: http://localhost:{port}/", flush=True)
        # Do not `open` the URL — that launches the host browser (Chrome).
        # Agents open it in Cursor's IDE browser (MCP browser_navigate, position active).
    else:
        print(
            f"Compose started but http://localhost:{port}/ not responding yet — check docker logs.",
            file=sys.stderr,
        )
    worker = ROOT / "tools" / "construction_video_worker.py"
    if worker.is_file():
        subprocess.Popen(
            [sys.executable, str(worker)],
            cwd=str(ROOT),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )


def scaffold(slug: str, title: str, port: int, *, category: str | None = None) -> Path:
    dest_cat = (category or infer_category(slug)).strip().strip("/")
    demo = DEMOS / dest_cat / slug
    if demo.exists():
        raise SystemExit(f"Already exists: {demo}")

    iface = title
    short = slug[:20].rstrip("-")
    eip_port = port - 1 if port > 1024 else port + 1
    lan = lan_hint(port)
    now = utc_now()

    webui = demo / "webui"
    routes = demo / "eip-root" / "interfaces" / iface / "routes"
    routes.mkdir(parents=True)
    # Stage UI mounts this path (no spaces) so Docker Desktop bind mounts work.
    (demo / "pilotfish" / "demo-eip-root" / "routes").mkdir(parents=True)
    (demo / "documents" / "module-docs").mkdir(parents=True)
    (demo / "input").mkdir(parents=True)
    (demo / "output").mkdir(parents=True)
    (demo / "logs").mkdir(parents=True)
    (demo / "tests").mkdir(parents=True)

    copy_shared_static(webui)
    write(webui / "app.py", APP_PY.format(title=title, port=port))
    write(webui / "templates" / "index.html", INDEX_HTML)
    write(webui / "static" / "app.css", APP_CSS)
    write(webui / "static" / "app.js", APP_JS)
    write(webui / "requirements.txt", "flask>=3.0,<4\n")
    write(webui / "Dockerfile", DOCKERFILE.format(port=port))

    write(
        demo / "docker-compose.yml",
        COMPOSE.format(
            slug=slug,
            slug_short=short.replace("_", "-"),
            port=port,
            eip_port=eip_port,
            lan=lan,
            iface=iface,
        ),
    )

    write(
        demo / "DESIGN.md",
        f"# {title}\n\nStatus: **IN PROGRESS** (progressive build stage)\n\n## 1. Purpose\n- TBD\n\n## 10. Ops\n- Web UI: http://localhost:{port}/\n- LAN: {lan}\n- Compose profile `stage` = Web UI only (routes + docs theater)\n",
    )
    write(
        demo / "README.md",
        f"# {title}\n\n## Progressive stage (Web UI early)\n\n`tools/scaffold_demo_stage.py` creates this folder and starts the stage UI by default.\n\n```bash\ncd {demo.relative_to(ROOT)}\n# if UI is not already up:\ndocker compose --profile stage up -d --build\n# Web UI: http://localhost:{port}/  (open in Cursor, not Chrome)\n```\n\nUpdate build theater:\n\n```bash\npython3 tools/update_build_status.py --root {slug} --phase routes --message \"…\" --add-route 01-listen --active\n```\n\nWhen done:\n\n```bash\npython3 tools/update_build_status.py --root {slug} --complete\n```\n",
    )

    timing = {
        "version": 1,
        "interface": title,
        "slug": slug,
        "path": str(demo.relative_to(ROOT)),
        "requested_by": "user",
        "started_at": now,
        "completed_at": None,
        "completed_by": None,
        "duration_minutes": None,
        "compose_project": slug,
        "phases": [
            {
                "id": "webui_early",
                "name": "Stage Web UI + docs scaffold",
                "started_at": now,
                "ended_at": None,
                "duration_minutes": None,
                "notes": "Progressive build visibility",
            }
        ],
        "slowest_phases": [],
        "bottlenecks": [],
        "speedup_ideas": [],
    }
    write(demo / "documents" / "build-timing.json", json.dumps(timing, indent=2) + "\n")
    status = {
        "version": 1,
        "active": True,
        "phase": "scaffold",
        "current_route": "",
        "message": "Web UI is up. The route diagram will grow here as modules are published.",
        "routes_ready": [],
        "updated_at": now,
    }
    write(demo / "documents" / "build-status.json", json.dumps(status, indent=2) + "\n")
    write(demo / "tests" / "plan.json", json.dumps({"version": 1, "cases": []}, indent=2) + "\n")
    return demo


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--slug", required=True, help="Folder name (slug) for the demo")
    ap.add_argument(
        "--category",
        help="Clients/Demos/<category>/… (default: inferred from slug: Insurance/EDI, Medical/HL7, Medical/FHIR, Other)",
    )
    ap.add_argument("--title", help="Human title (default: slug prettified)")
    ap.add_argument("--port", type=int, default=8120, help="Web UI host port")
    ap.add_argument(
        "--up",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="After creating the folder, start docker compose --profile stage (default: true)",
    )
    args = ap.parse_args()
    slug = slugify(args.slug)
    title = args.title or slug.replace("-", " ").title()
    demo = scaffold(slug, title, args.port, category=args.category)
    lan = lan_hint(args.port)
    print(f"Created {demo}")
    print(f"Local: http://localhost:{args.port}/")
    print(f"LAN:   {lan}")
    if args.up:
        start_stage_webui(demo, args.port)
    else:
        print("Skipped --up. When ready:")
        print(f"  cd {demo.relative_to(ROOT)}")
        print("  docker compose --profile stage up -d --build")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
