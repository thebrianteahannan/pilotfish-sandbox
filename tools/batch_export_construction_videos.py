#!/usr/bin/env python3
"""Generate construction-replay.mp4 for every eligible Clients/Demos demo.

One demo at a time (per demo-docker-one-at-a-time):
  1. docker compose down all Clients/ demo stacks
  2. prepare webui (shared document_routes + route-viewer + build-replay API)
  3. record_module_replay (if routes exist)
  4. docker compose up webui (stage profile when present)
  5. export_construction_video
  6. docker compose down that demo
  7. next demo

Usage (repo root):
  python3 tools/batch_export_construction_videos.py
  python3 tools/batch_export_construction_videos.py --only csv-to-json,edi-999-ta1-ack-triage
  python3 tools/batch_export_construction_videos.py --skip-existing
  python3 tools/batch_export_construction_videos.py --force-rerecord
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

from demo_paths import DEMOS, iter_demo_roots  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SHARED = DEMOS / "_shared" / "webui"
VENV_PY = ROOT / "tools" / ".venv-video" / "bin" / "python"

SKIP_ALWAYS = {
    "xml-to-edi-834",  # no compose/webui
}


def run(
    cmd: list[str],
    *,
    cwd: Path | None = None,
    check: bool = False,
    timeout: int | None = None,
) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(cmd), flush=True)
    return subprocess.run(
        cmd,
        cwd=str(cwd or ROOT),
        text=True,
        capture_output=True,
        check=check,
        timeout=timeout,
    )


def compose_ls_clients() -> list[dict]:
    raw = run(["docker", "compose", "ls", "--format", "json"]).stdout or ""
    if not raw.strip():
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return []
    out = []
    clients = (ROOT / "Clients").resolve()
    for row in data if isinstance(data, list) else []:
        cfg = str(row.get("ConfigFiles") or "")
        for part in cfg.split(","):
            p = Path(part.strip()).resolve()
            try:
                p.relative_to(clients)
                out.append(row)
                break
            except ValueError:
                continue
    return out


def down_all_client_demos() -> None:
    """Stop every Compose project under Clients/ (no -v)."""
    for row in compose_ls_clients():
        name = str(row.get("Name") or "").strip()
        cfg = str(row.get("ConfigFiles") or "").split(",")[0].strip()
        print(f"Stopping {name or cfg} …", flush=True)
        if name:
            run(["docker", "compose", "-p", name, "down", "--timeout", "20"])
        elif cfg:
            run(
                ["docker", "compose", "down", "--timeout", "20"],
                cwd=Path(cfg).parent,
            )
    ps = run(["docker", "ps", "--format", "{{.Names}}"]).stdout or ""
    for cname in ps.splitlines():
        cname = cname.strip()
        if not cname.startswith("pf-"):
            continue
        if "buzz-scout" in cname:
            continue
        print(f"Stopping container {cname} …", flush=True)
        run(["docker", "stop", "-t", "15", cname])


def detect_webui_port(demo: Path) -> int | None:
    compose = demo / "docker-compose.yml"
    if not compose.is_file():
        return None
    text = compose.read_text(encoding="utf-8", errors="replace")
    m = re.search(r'WEBUI_PORT:\s*"?(\d+)"?', text)
    if m:
        return int(m.group(1))
    # Prefer ports under the webui service block
    wm = re.search(
        r"(?ms)^  webui:\n(?:.*?\n)*?    ports:\n((?:      - .*\n)+)",
        text,
    )
    block = wm.group(1) if wm else text
    ports = re.findall(r'"(\d+):\1"', block)
    if ports:
        return int(ports[0])
    ports = re.findall(r"- ['\"]?(\d+):(\d+)", block)
    if ports:
        return int(ports[0][0])
    return None


def find_route_v2(demo: Path) -> list[Path]:
    demo_routes = demo / "pilotfish" / "demo-eip-root" / "routes"
    found: list[Path] = []
    if demo_routes.is_dir():
        found = [p for p in demo_routes.iterdir() if (p / "route.v2.xml").is_file()]
    if not found:
        found = [
            p
            for p in demo.glob("eip-root/interfaces/*/routes/*")
            if (p / "route.v2.xml").is_file()
        ]
    return sorted(found)


def eligible_demos(only: set[str] | None) -> list[Path]:
    out: list[Path] = []
    for p in iter_demo_roots():
        if p.name.startswith("_") or p.name in SKIP_ALWAYS:
            continue
        if only and p.name not in only:
            continue
        if not (p / "docker-compose.yml").is_file():
            continue
        if not (p / "webui").is_dir():
            continue
        if not find_route_v2(p):
            print(f"SKIP {p.name}: no route.v2.xml", flush=True)
            continue
        if detect_webui_port(p) is None:
            print(f"SKIP {p.name}: could not detect Web UI port", flush=True)
            continue
        out.append(p)
    return out


def copy_tree(src: Path, dest: Path) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(src, dest)


def prepare_webui(demo: Path) -> None:
    """Ensure shared construction-video assets + build-replay API wiring."""
    webui = demo / "webui"
    static = webui / "static"
    static.mkdir(parents=True, exist_ok=True)
    # document_routes + build-live + route-viewer + logo
    shutil.copy2(SHARED / "document_routes.py", webui / "document_routes.py")
    for name in ("pf-theme.css", "build-live.js", "build-live.css", "build-stage.js", "pilotfish-logo.jpg", "construction-video.js"):
        src = SHARED / "static" / name
        if src.is_file():
            shutil.copy2(src, static / name)
    rv_src = SHARED / "static" / "route-viewer"
    if rv_src.is_dir():
        copy_tree(rv_src, static / "route-viewer")

    app = webui / "app.py"
    if not app.is_file():
        return
    text = app.read_text(encoding="utf-8")
    orig = text
    if "ensure_build_replay_api" not in text:
        # Extend existing document_routes import if present
        if "from document_routes import" in text and "ensure_build_status_api" in text:
            text = text.replace(
                "ensure_build_status_api, ensure_build_timing_api",
                "ensure_build_replay_api, ensure_build_status_api, ensure_build_timing_api",
            )
            text = text.replace(
                "ensure_build_status_api, ensure_build_timing_api, ensure_document_routes",
                "ensure_build_replay_api, ensure_build_status_api, ensure_build_timing_api, ensure_document_routes",
            )
            if "ensure_build_status_api = None" in text and "ensure_build_replay_api = None" not in text:
                text = text.replace(
                    "ensure_build_status_api = None",
                    "ensure_build_replay_api = None  # type: ignore\n    ensure_build_status_api = None",
                )
            if "ensure_build_status_api(app" in text and "ensure_build_replay_api(app" not in text:
                text = re.sub(
                    r"(if ensure_build_status_api is not None:\n(?:.*\n)*?    ensure_build_status_api\([^\)]*\))",
                    r"\1\nif ensure_build_replay_api is not None:\n    ensure_build_replay_api(app, DOCUMENTS_DIR)",
                    text,
                    count=1,
                )
                # Fallback simpler insert after first ensure_build_status_api(app call
                if "ensure_build_replay_api(app" not in text:
                    text = text.replace(
                        "ensure_build_status_api(app, DOCUMENTS_DIR)",
                        "ensure_build_status_api(app, DOCUMENTS_DIR)\n"
                        "if ensure_build_replay_api is not None:\n"
                        "    ensure_build_replay_api(app, DOCUMENTS_DIR)",
                        1,
                    )
        else:
            # Append a small bootstrap block
            text += (
                "\n\ntry:\n"
                "    from document_routes import ensure_build_replay_api\n"
                "except ImportError:\n"
                "    ensure_build_replay_api = None  # type: ignore\n"
                "if ensure_build_replay_api is not None:\n"
                "    from pathlib import Path as _PathDocs\n"
                "    import os as _os_docs\n"
                '    _docs = _PathDocs(_os_docs.environ.get("DOCUMENTS_DIR", "/documents"))\n'
                "    ensure_build_replay_api(app, _docs)\n"
            )
    if text != orig:
        app.write_text(text, encoding="utf-8")
        print(f"  patched {app.relative_to(ROOT)} for build-replay API", flush=True)


def compose_up_webui(demo: Path) -> None:
    compose = demo / "docker-compose.yml"
    text = compose.read_text(encoding="utf-8", errors="replace")
    cmd = ["docker", "compose", "-p", demo.name, "--project-directory", str(demo)]
    if 'profiles: ["stage"' in text or "profiles: ['stage'" in text or '"stage"' in text:
        # Prefer stage when webui is behind a profile
        if re.search(r"webui:[\s\S]*?profiles:.*?stage", text):
            cmd += ["--profile", "stage"]
    cmd += ["up", "-d", "--build", "webui"]
    proc = run(cmd, cwd=demo, timeout=600)
    if proc.returncode != 0:
        # Some demos name the service differently or need full stack
        print(proc.stderr[-2000:] if proc.stderr else proc.stdout[-1000:], flush=True)
        # Retry without --build / with full profile
        alt = [
            "docker",
            "compose",
            "-p",
            demo.name,
            "--project-directory",
            str(demo),
            "up",
            "-d",
            "webui",
        ]
        proc2 = run(alt, cwd=demo, timeout=600)
        if proc2.returncode != 0:
            raise RuntimeError(f"compose up webui failed for {demo.name}")


def compose_up_runtime(demo: Path) -> None:
    """Bring EIP + backing services so live Demo-tab inject can show results."""
    compose = demo / "docker-compose.yml"
    if not compose.is_file():
        return
    text = compose.read_text(encoding="utf-8", errors="replace")
    if not re.search(r'profiles:\s*\[[^\]]*[\'"]full[\'"]', text):
        return
    print("Starting full stack for live demo tests…", flush=True)
    proc = run(
        [
            "docker",
            "compose",
            "-p",
            demo.name,
            "--project-directory",
            str(demo),
            "--profile",
            "full",
            "up",
            "-d",
        ],
        cwd=demo,
        timeout=600,
    )
    if proc.returncode != 0:
        print(proc.stderr[-2000:] if proc.stderr else proc.stdout[-1000:], flush=True)


def compose_down(demo: Path) -> None:
    run(
        [
            "docker",
            "compose",
            "-p",
            demo.name,
            "--project-directory",
            str(demo),
            "down",
            "--timeout",
            "20",
        ]
    )


def wait_url(url: str, timeout: float = 90.0) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urlopen(url, timeout=3) as resp:
                if 200 <= getattr(resp, "status", 200) < 500:
                    return True
        except (URLError, OSError, TimeoutError):
            time.sleep(2.0)
    return False


def record_replay(demo: Path) -> None:
    proc = run(
        [sys.executable, str(ROOT / "tools" / "record_module_replay.py"), "--root", str(demo)],
        timeout=300,
    )
    print(proc.stdout[-1500:] if proc.stdout else "", flush=True)
    if proc.returncode != 0:
        print(proc.stderr[-2000:] if proc.stderr else "", file=sys.stderr, flush=True)
        raise RuntimeError(f"record_module_replay failed for {demo.name}")


def export_video(demo: Path, url: str) -> None:
    py = str(VENV_PY if VENV_PY.is_file() else sys.executable)
    cmd = [
        py,
        str(ROOT / "tools" / "export_construction_video.py"),
        "--root",
        str(demo),
        "--url",
        url,
        "--engine",
        "edge",
        "--voice",
        "en-US-AvaNeural",
        "--no-intro",
    ]
    proc = run(cmd, timeout=1200)
    print(proc.stdout[-2500:] if proc.stdout else "", flush=True)
    if proc.returncode != 0:
        print(proc.stderr[-3000:] if proc.stderr else "", file=sys.stderr, flush=True)
        raise RuntimeError(f"export_construction_video failed for {demo.name}")


def process_demo(
    demo: Path,
    *,
    force_rerecord: bool,
    skip_existing: bool,
    leave_up: bool = False,
) -> str:
    video = demo / "documents" / "construction-replay.mp4"
    if skip_existing and video.is_file() and video.stat().st_size > 100_000:
        print(f"SKIP {demo.name}: video already exists ({video.stat().st_size // 1024} KB)", flush=True)
        return "skipped-existing"

    port = detect_webui_port(demo)
    assert port is not None
    url = f"http://127.0.0.1:{port}/"

    print(f"\n======== {demo.name} (port {port}) ========", flush=True)
    down_all_client_demos()
    prepare_webui(demo)

    # Always re-copy shared document_routes after prepare; ensure replay API is importable
    app = demo / "webui" / "app.py"
    if app.is_file() and "ensure_build_replay_api(app" not in app.read_text(encoding="utf-8", errors="replace"):
        app.write_text(
            app.read_text(encoding="utf-8")
            + "\n\ntry:\n"
            "    from document_routes import ensure_build_replay_api as _ensure_build_replay_api\n"
            "except ImportError:\n"
            "    _ensure_build_replay_api = None\n"
            "if _ensure_build_replay_api is not None:\n"
            "    import os as _os_br\n"
            "    from pathlib import Path as _PathBr\n"
            '    _ensure_build_replay_api(app, _PathBr(_os_br.environ.get("DOCUMENTS_DIR", str((_PathBr(__file__).resolve().parent.parent / "documents")))))\n',
            encoding="utf-8",
        )
        print(f"  appended build-replay bootstrap to {app.name}", flush=True)

    manifest = demo / "documents" / "build-replay" / "manifest.json"
    if force_rerecord or not manifest.is_file():
        record_replay(demo)
    else:
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
            steps = data.get("steps") or []
        except json.JSONDecodeError:
            steps = []
        if not steps:
            record_replay(demo)

    compose_up_webui(demo)
    compose_up_runtime(demo)
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "tools" / "update_build_status.py"),
            "--root",
            str(demo),
            "--active",
            "--phase",
            "construction_video",
            "--message",
            "Stack is up — next is the construction video",
            "--log",
            "Docker stack is running",
        ],
        cwd=str(ROOT),
        check=False,
        capture_output=True,
    )
    try:
        if not wait_url(url, timeout=180):
            raise RuntimeError(f"Web UI not reachable at {url}")
        if not wait_url(url + "static/app.css", timeout=60):
            # Restart once — Docker bind mounts sometimes go stale
            print("CSS 404 — restarting webui once", flush=True)
            run(
                [
                    "docker",
                    "compose",
                    "-p",
                    demo.name,
                    "--project-directory",
                    str(demo),
                    "restart",
                    "webui",
                ]
            )
            if not wait_url(url + "static/app.css", timeout=60):
                raise RuntimeError(f"CSS missing at {url}static/app.css")
        export_video(demo, url)
    finally:
        if not leave_up:
            compose_down(demo)

    if not video.is_file() or video.stat().st_size < 50_000:
        raise RuntimeError(f"Video missing or too small for {demo.name}")
    return "ok"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--only", help="Comma-separated demo slugs")
    ap.add_argument(
        "--skip-existing",
        action="store_true",
        help="Skip demos that already have construction-replay.mp4",
    )
    ap.add_argument(
        "--force-rerecord",
        action="store_true",
        help="Always re-run record_module_replay before export",
    )
    args = ap.parse_args()
    only = {s.strip() for s in (args.only or "").split(",") if s.strip()} or None

    if not VENV_PY.is_file():
        print(f"Missing {VENV_PY} — create tools/.venv-video first", file=sys.stderr)
        return 2

    demos = eligible_demos(only)
    print(f"Eligible demos: {len(demos)}", flush=True)
    for d in demos:
        print(f"  - {d.name}", flush=True)

    results: dict[str, str] = {}
    for demo in demos:
        try:
            results[demo.name] = process_demo(
                demo,
                force_rerecord=args.force_rerecord,
                skip_existing=args.skip_existing,
            )
        except Exception as exc:
            results[demo.name] = f"FAIL: {exc}"
            print(f"FAIL {demo.name}: {exc}", file=sys.stderr, flush=True)
            try:
                compose_down(demo)
            except Exception:
                pass

    print("\n======== SUMMARY ========", flush=True)
    ok = 0
    for name, status in results.items():
        print(f"  {name}: {status}", flush=True)
        if status in {"ok", "skipped-existing"}:
            ok += 1
    print(f"{ok}/{len(results)} succeeded or skipped", flush=True)
    return 0 if ok == len(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
