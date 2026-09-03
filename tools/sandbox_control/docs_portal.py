"""PilotFish documentation portal (docs-search) — start/stop a local HTTP server."""

from __future__ import annotations

import os
import signal
import socket
import subprocess
import sys
import threading
import time
from pathlib import Path

import demos

PORT = 8765
LOC_FILE = demos.ROOT / "PilotFish_Documentation" / "DOCUMENTATION_LOCATION.txt"
PID_FILE = demos.HERE / "data" / "docs-portal.pid"

_lock = threading.Lock()
_job = {"busy": False, "action": "", "message": "", "error": ""}


def job_snapshot() -> dict:
    with _lock:
        return dict(_job)


def _set(**fields) -> None:
    with _lock:
        _job.update(fields)


def docs_root() -> Path:
    text = LOC_FILE.read_text(encoding="utf-8", errors="replace") if LOC_FILE.is_file() else ""
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("/") and Path(line).is_dir():
            return Path(line)
    return Path.home() / "Documents" / "PilotFish Documentation"


def _pid() -> int:
    try:
        return int(PID_FILE.read_text(encoding="utf-8").strip())
    except (OSError, ValueError):
        return 0


def _alive(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _port_up() -> bool:
    try:
        with socket.create_connection(("127.0.0.1", PORT), timeout=0.4):
            return True
    except OSError:
        return False


def running() -> bool:
    return _alive(_pid()) or _port_up()


def status() -> dict:
    on = running()
    lan = demos.lan_ip()
    root = docs_root()
    return {
        "ok": True,
        "running": on,
        "port": PORT,
        "title": "Documentation portal",
        "kind": "host",
        "blurb": "Host process (python -m http.server) — not a Docker container. Search PilotFish module PDFs.",
        "local_url": f"http://127.0.0.1:{PORT}/docs-search/",
        "lan_url": f"http://{lan}:{PORT}/docs-search/",
        "root": str(root),
        "job": job_snapshot(),
    }


def start() -> str:
    root = docs_root()
    if not (root / "docs-search" / "index.html").is_file():
        raise FileNotFoundError(f"docs-search not found under {root}")
    if running():
        return "already running"
    PID_FILE.parent.mkdir(parents=True, exist_ok=True)
    log = PID_FILE.with_suffix(".log")
    with log.open("ab") as fh:
        proc = subprocess.Popen(
            [sys.executable, "-m", "http.server", str(PORT), "--bind", "0.0.0.0"],
            cwd=str(root),
            stdout=fh,
            stderr=fh,
            start_new_session=True,
        )
    PID_FILE.write_text(str(proc.pid), encoding="utf-8")
    for _ in range(20):
        if _port_up():
            return "started"
        time.sleep(0.15)
    raise RuntimeError("docs portal did not open on port " + str(PORT))


def stop() -> str:
    pid = _pid()
    if _alive(pid):
        os.kill(pid, signal.SIGTERM)
        for _ in range(20):
            if not _alive(pid):
                break
            time.sleep(0.1)
        if _alive(pid):
            os.kill(pid, signal.SIGKILL)
    if PID_FILE.is_file():
        PID_FILE.unlink(missing_ok=True)
    if running():
        demos.run(["sh", "-c", f"lsof -tiTCP:{PORT} -sTCP:LISTEN | xargs kill"], timeout=15)
    return "stopped"


def run_action(action: str) -> None:
    _set(busy=True, action=action, message=f"{action} docs portal…", error="")
    try:
        if action == "start":
            start()
            _set(message="Docs portal is up")
        elif action == "stop":
            stop()
            _set(message="Docs portal stopped")
        else:
            raise ValueError(action)
    except Exception as exc:
        _set(error=str(exc)[:800], message=f"{action} failed")
    finally:
        _set(busy=False)


def enqueue(action: str) -> dict:
    action = (action or "").strip().lower()
    if action not in {"start", "stop"}:
        return {"ok": False, "error": "action must be start or stop"}
    with _lock:
        if _job.get("busy"):
            return {"ok": False, "error": "Docs portal start/stop already running."}
        _job.update({"busy": True, "action": action, "message": "Queued", "error": ""})
    threading.Thread(target=run_action, args=(action,), daemon=True).start()
    return {"ok": True, "action": action}
