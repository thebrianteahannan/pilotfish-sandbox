"""Generate a request-demo.mp4 for a client change request."""

from __future__ import annotations

import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import client_requests as reqs
import clients
import videos

HERE = Path(__file__).resolve().parent
TOOLS = HERE.parent
ROOT = TOOLS.parent
VENV_PY = TOOLS / ".venv-video" / "bin" / "python"
SCRIPT = TOOLS / "export_request_video.py"
MP4_NAME = "request-demo.mp4"


def job_path(folder: Path) -> Path:
    return folder / "request-video-job.json"


def load_job(folder: Path) -> dict:
    path = job_path(folder)
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_job(folder: Path, **fields) -> dict:
    reset = bool(fields.pop("reset", False))
    log_line = fields.pop("log_line", None)
    data = {} if reset else load_job(folder)
    if log_line:
        log = list(data.get("log") or [])
        text = str(log_line).strip()
        if text:
            log.append({"at": utc_now(), "text": text})
        fields["log"] = log[-12:]
    data.update(fields)
    data["updated_at"] = utc_now()
    tmp = job_path(folder).with_name(job_path(folder).name + ".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    tmp.replace(job_path(folder))
    return data


def snapshot(folder: Path, slug: str, req_id: str) -> dict:
    mp4 = folder / MP4_NAME
    ready = mp4.is_file()
    job = load_job(folder)
    kb = mp4.stat().st_size // 1024 if ready else 0
    rel = (folder.relative_to(clients.ROOT) / MP4_NAME).as_posix()
    return {
        "ready": ready,
        "url": f"/api/clients/{slug}/requests/{req_id}/video/file" if ready else "",
        "path": rel,
        "status": job.get("status") or ("done" if ready else "idle"),
        "message": job.get("message") or "",
        "error": job.get("error") or "",
        "size_kb": kb,
        "phase": job.get("phase") or "",
        "step": job.get("step") or 0,
        "step_total": job.get("step_total") or 0,
        "started_at": job.get("started_at") or "",
        "remaining_sec": job.get("remaining_sec"),
        "log": job.get("log") or [],
        "job": job,
    }


def _tests_ok(folder: Path, meta: dict) -> bool:
    path = folder / "tests.json"
    if path.is_file():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict) and "ok" in data:
                return bool(data.get("ok"))
        except (OSError, json.JSONDecodeError):
            pass
    tests = meta.get("tests") if isinstance(meta.get("tests"), dict) else {}
    return bool(tests.get("ok"))


def wait_for_construction_slot(folder: Path, set_job, timeout: float = 1800.0) -> None:
    deadline = time.time() + timeout
    noted = False
    while time.time() < deadline:
        st = videos.worker_status()
        q = videos.queue_snapshot()
        if st.get("status") != "running" and not q.get("active"):
            return
        fields = {
            "status": "running",
            "phase": "queued",
            "message": "Waiting for the current construction video to finish…",
        }
        if not noted:
            fields["log_line"] = "Waiting for construction video"
            noted = True
        write_job(folder, **fields)
        set_job(message="Waiting for the current construction video to finish…")
        time.sleep(3)
    raise RuntimeError("Timed out waiting for the construction video to finish.")


def run(slug: str, req_id: str, set_job) -> None:
    root = clients.require_root(slug)
    folder = reqs.request_path(root, req_id)
    meta = reqs.load_meta(folder)
    if not meta:
        set_job(error="Unknown request", message="Video not started")
        return
    if meta.get("status") not in {"tested", "ready", "error"}:
        set_job(error="Finish Start work before generating a demo video.", message="Video not ready")
        return
    if not _tests_ok(folder, meta):
        set_job(error="Tests must pass before generating a demo video.", message="Video not ready")
        return
    py = VENV_PY if VENV_PY.is_file() else Path(sys.executable)
    if not SCRIPT.is_file():
        set_job(error="Missing export_request_video.py", message="Video failed")
        return
    try:
        write_job(
            folder,
            reset=True,
            status="running",
            phase="starting",
            message="Starting request demo video…",
            error="",
            started_at=utc_now(),
            step=0,
            step_total=0,
            log=[],
        )
        wait_for_construction_slot(folder, set_job)
        write_job(folder, status="running", phase="tts", message="Writing narration…", log_line="Starting request demo video")
        set_job(message="Recording request demo video…")
        proc = subprocess.run(
            [str(py), str(SCRIPT), "--folder", str(folder)],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
        )
        mp4 = folder / MP4_NAME
        if proc.returncode != 0 or not mp4.is_file():
            err = (proc.stderr or proc.stdout or f"exit {proc.returncode}").strip()[-800:]
            write_job(folder, status="error", message="Video export failed", error=err)
            set_job(error=err, message="Video failed")
            reqs.append_log(folder, f"Demo video failed: {err}")
            return
        kb = mp4.stat().st_size // 1024
        rel = (folder.relative_to(clients.ROOT) / MP4_NAME).as_posix()
        write_job(folder, status="done", message=f"Demo video ready: {rel}", error="", size_kb=kb, path=rel)
        reqs.append_log(folder, f"Demo video saved to {rel} ({kb} KB)")
        set_job(message=f"Demo video saved to {rel} ({kb} KB)")
    except Exception as exc:
        write_job(folder, status="error", message="Video export failed", error=str(exc)[:800])
        set_job(error=str(exc)[:800], message="Video failed")
        reqs.append_log(folder, f"Demo video failed: {exc}")
