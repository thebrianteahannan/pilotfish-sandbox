#!/usr/bin/env python3
"""Host-side HTTP helper so the demo Web UI can create construction-replay.mp4.

Playwright / ffmpeg / edge-tts live on the Mac, not in the slim webui image.
The Info tab POSTs /api/construction-video; Flask proxies here.

  python3 tools/construction_video_worker.py
  # listens on 127.0.0.1:8764
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent
PORT = int(os.environ.get("CONSTRUCTION_VIDEO_WORKER_PORT", "8764"))
VENV_PY = TOOLS / ".venv-video" / "bin" / "python"
LOG = TOOLS / ".construction-video-worker.log"

_lock = threading.Lock()
_job: dict = {"status": "idle", "slug": None, "message": "Idle"}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def resolve_demo(payload: dict) -> Path | None:
    sys.path.insert(0, str(TOOLS))
    from demo_paths import resolve_demo as find_demo

    raw = str(payload.get("root") or "").strip()
    if raw:
        found = find_demo(raw)
        if found is not None:
            return found
    slug = str(payload.get("slug") or "").strip().strip("/")
    if not slug or slug.startswith("."):
        return None
    return find_demo(Path(slug).name)


def write_job(demo: Path, data: dict) -> None:
    docs = demo / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    payload = dict(data)
    payload["updated_at"] = utc_now()
    (docs / "construction-video-job.json").write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8"
    )
    global _job
    with _lock:
        _job = dict(payload)


def run_export(demo: Path) -> None:
    slug = demo.name
    py = str(VENV_PY) if VENV_PY.is_file() else sys.executable
    script = TOOLS / "export_construction_video.py"
    env = os.environ.copy()
    env["CONSTRUCTION_VIDEO_DEMO"] = str(demo)
    env["PYTHONUNBUFFERED"] = "1"
    proc = subprocess.run(
        [py, str(script), "--root", str(demo)],
        cwd=str(ROOT),
        capture_output=True,
        text=True,
        env=env,
    )
    mp4 = demo / "documents" / "construction-replay.mp4"
    if proc.returncode == 0 and mp4.is_file():
        write_job(
            demo,
            {
                "status": "done",
                "slug": slug,
                "message": "Construction video ready",
                "started_at": _job.get("started_at"),
                "size_kb": mp4.stat().st_size // 1024,
            },
        )
        return
    err = (proc.stderr or proc.stdout or f"exit {proc.returncode}").strip()[-800:]
    write_job(
        demo,
        {
            "status": "error",
            "slug": slug,
            "message": "Video export failed",
            "error": err,
            "started_at": _job.get("started_at"),
        },
    )


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        line = f"{utc_now()} {self.address_string()} {fmt % args}\n"
        try:
            with LOG.open("a", encoding="utf-8") as fh:
                fh.write(line)
        except OSError:
            pass

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, code: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path in {"/health", "/"}:
            self._json(200, {"ok": True, "service": "construction-video-worker", "port": PORT})
            return
        if path == "/status":
            with _lock:
                self._json(200, {"ok": True, **_job})
            return
        self._json(404, {"ok": False, "error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        if urlparse(self.path).path != "/run":
            self._json(404, {"ok": False, "error": "not found"})
            return
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            self._json(400, {"ok": False, "error": "invalid json"})
            return
        if not isinstance(payload, dict):
            self._json(400, {"ok": False, "error": "expected object"})
            return
        demo = resolve_demo(payload)
        if demo is None:
            self._json(400, {"ok": False, "error": "unknown demo"})
            return
        with _lock:
            if _job.get("status") == "running":
                self._json(
                    409,
                    {
                        "ok": False,
                        "status": "running",
                        "slug": _job.get("slug"),
                        "message": _job.get("message") or "Already recording",
                    },
                )
                return
        write_job(
            demo,
            {
                "status": "running",
                "slug": demo.name,
                "message": "Starting construction video…",
                "started_at": utc_now(),
            },
        )
        threading.Thread(target=run_export, args=(demo,), daemon=True).start()
        self._json(
            202,
            {"ok": True, "status": "running", "slug": demo.name, "message": "Starting construction video…"},
        )


def main() -> int:
    try:
        server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    except OSError as exc:
        if getattr(exc, "errno", None) in {48, 98}:  # EADDRINUSE mac/linux
            print(f"construction-video-worker already on 127.0.0.1:{PORT}")
            return 0
        raise
    print(f"construction-video-worker http://127.0.0.1:{PORT}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
