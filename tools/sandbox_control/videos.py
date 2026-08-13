"""Kick off construction-replay.mp4 via the host worker and read job progress."""

from __future__ import annotations

import json
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOOLS = HERE.parent
ROOT = TOOLS.parent
WORKER_PORT = 8764
WORKER_BASE = f"http://127.0.0.1:{WORKER_PORT}"

if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from construction_video_job import load_job, update_job, utc_now  # noqa: E402

_q_lock = threading.Lock()
_queue: list[str] = []
_active: str | None = None
_pumping = False


def size_label(kb: int) -> str:
    n = int(kb or 0)
    if n >= 1024:
        return f"{n / 1024:.1f} MB"
    if n > 0:
        return f"{n} KB"
    return ""


def worker_status() -> dict:
    try:
        with urllib.request.urlopen(f"{WORKER_BASE}/status", timeout=1.5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        if not isinstance(data, dict):
            return {"up": True, "status": "idle"}
        data["up"] = True
        return data
    except (OSError, urllib.error.URLError, json.JSONDecodeError, TimeoutError):
        return {"up": False, "status": "down", "message": "Video worker is not running"}


def ensure_worker() -> tuple[bool, str]:
    st = worker_status()
    if st.get("up"):
        return True, ""
    try:
        subprocess.Popen(
            [sys.executable, str(TOOLS / "construction_video_worker.py")],
            cwd=str(ROOT),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as exc:
        return False, f"Could not start video worker: {exc}"
    for _ in range(12):
        time.sleep(0.25)
        st = worker_status()
        if st.get("up"):
            return True, ""
    return False, "Video worker did not come up on port 8764."


def queue_snapshot() -> dict:
    with _q_lock:
        return {"active": _active, "queue": list(_queue)}


def snapshot(root: Path, worker: dict | None = None) -> dict:
    job = load_job(root)
    mp4 = root / "documents" / "construction-replay.mp4"
    ready = mp4.is_file()
    kb = mp4.stat().st_size // 1024 if ready else 0
    w = worker if isinstance(worker, dict) else {}
    hub = queue_snapshot()
    slug = root.name
    queued_here = slug in (hub.get("queue") or [])
    active_here = hub.get("active") == slug
    if job.get("status") == "queued":
        if queued_here or active_here:
            pass
        else:
            job = dict(job)
            job["status"] = "error"
            job["message"] = job.get("message") or "Queue cleared"
            job["stale"] = True
    elif job.get("status") == "running":
        live = (w.get("up") and w.get("status") == "running" and w.get("slug") == slug) or active_here
        if not live:
            job = dict(job)
            job["status"] = "error"
            job["message"] = job.get("message") or "Recording stopped"
            job["stale"] = True
    return {
        "ready": ready,
        "size_kb": kb,
        "size_label": size_label(kb),
        "status": (job or {}).get("status") or ("done" if ready else "idle"),
        "job": job or None,
        "behind": ((job or {}).get("behind") or "") if queued_here else "",
        "queue_position": (job or {}).get("queue_position") or 0,
    }


def wait_webui(base_url: str, timeout: float = 90.0) -> bool:
    root = (base_url or "").rstrip("/") + "/"
    css = root + "static/app.css"
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(root, timeout=3) as resp:
                if getattr(resp, "status", 200) < 400:
                    with urllib.request.urlopen(css, timeout=3) as css_resp:
                        if getattr(css_resp, "status", 200) < 400:
                            return True
        except (OSError, urllib.error.URLError, TimeoutError):
            pass
        time.sleep(2)
    return False


def _demo_running(root: Path) -> bool:
    import demos

    rel = root.relative_to(demos.ROOT).as_posix()
    if rel in demos.running_demo_dirs():
        return True
    return any(c.get("running") for c in demos.pf_containers(root.name))


def _post_run(slug: str) -> tuple[int, dict]:
    body = json.dumps({"slug": slug}).encode("utf-8")
    req = urllib.request.Request(
        f"{WORKER_BASE}/run",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
            return resp.status, payload if isinstance(payload, dict) else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = {"error": raw[-400:]}
        return exc.code, payload if isinstance(payload, dict) else {}
    except (OSError, urllib.error.URLError, TimeoutError) as exc:
        return 503, {"error": str(exc)}


def _wait_compose_idle(timeout: float = 180) -> None:
    import demos

    deadline = time.time() + timeout
    while time.time() < deadline:
        if not demos.job_snapshot().get("busy"):
            return
        time.sleep(0.4)
    raise RuntimeError("Timed out waiting for a demo start/stop to finish.")


def _wait_worker_idle(*, except_slug: str | None = None, timeout: float = 2400) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        w = worker_status()
        if w.get("status") != "running":
            return
        if except_slug and w.get("slug") == except_slug:
            return
        time.sleep(2)
    raise RuntimeError("Timed out waiting for the current construction video to finish.")


def _wait_job_done(slug: str, timeout: float = 2400) -> None:
    import demos

    root = demos.require_root(slug)
    deadline = time.time() + timeout
    while time.time() < deadline:
        w = worker_status()
        job = load_job(root)
        running_this = w.get("status") == "running" and w.get("slug") == slug
        st = (job or {}).get("status")
        if st in {"done", "error"} and not running_this:
            return
        time.sleep(2)
    raise RuntimeError(f"Timed out waiting for {slug} video export.")


def _refresh_queue_messages() -> None:
    with _q_lock:
        active = _active
        waiting = list(_queue)
    import demos

    total = len(waiting)
    for i, slug in enumerate(waiting, start=1):
        try:
            root = demos.require_root(slug)
        except ValueError:
            continue
        update_job(
            root,
            status="queued",
            phase="queued",
            slug=slug,
            message=f"Queued behind {active} ({i} of {total})",
            queue_position=i,
            behind=active,
        )


def _advance() -> str | None:
    global _active
    with _q_lock:
        _active = _queue.pop(0) if _queue else None
        nxt = _active
    _refresh_queue_messages()
    return nxt


def _pump() -> None:
    global _pumping, _active
    try:
        while True:
            with _q_lock:
                if not _active and _queue:
                    _active = _queue.pop(0)
                slug = _active
            if not slug:
                break
            import demos

            try:
                root = demos.require_root(slug)
                prepare_and_start(root)
                _wait_job_done(slug)
            except Exception as exc:
                try:
                    root = demos.require_root(slug)
                    update_job(
                        root,
                        status="error",
                        phase="error",
                        slug=slug,
                        message="Video export failed",
                        error=str(exc)[:800],
                    )
                except Exception:
                    pass
            _advance()
    finally:
        restart = False
        with _q_lock:
            _pumping = False
            if _active or _queue:
                _pumping = True
                restart = True
        if restart:
            threading.Thread(target=_pump, daemon=True).start()


def enqueue_slug(slug: str) -> dict:
    import demos

    return enqueue(demos.require_root(slug))


def enqueue(root: Path) -> dict:
    """Queue a construction video. One export at a time; next starts when the current finishes."""
    global _active, _pumping
    slug = root.name
    ok, err = ensure_worker()
    if not ok:
        raise RuntimeError(err)
    start_pump = False
    with _q_lock:
        if _active == slug:
            return {"ok": True, "status": "running", "slug": slug, "message": "Already recording"}
        if slug in _queue:
            pos = _queue.index(slug) + 1
            return {
                "ok": True,
                "status": "queued",
                "slug": slug,
                "position": pos,
                "behind": _active,
                "message": f"Already queued behind {_active}",
            }
        if _active:
            _queue.append(slug)
            pos = len(_queue)
            behind = _active
        else:
            _active = slug
            behind = None
            pos = 0
            if not _pumping:
                _pumping = True
                start_pump = True
    if behind:
        update_job(
            root,
            reset=True,
            status="queued",
            phase="queued",
            slug=slug,
            message=f"Queued behind {behind}",
            queue_position=pos,
            behind=behind,
            started_at=utc_now(),
            log=[],
        )
        _refresh_queue_messages()
        return {
            "ok": True,
            "status": "queued",
            "slug": slug,
            "position": pos,
            "behind": behind,
            "message": f"Queued behind {behind}",
        }
    w = worker_status()
    other = w.get("slug") if w.get("status") == "running" and w.get("slug") != slug else None
    if other:
        update_job(
            root,
            reset=True,
            status="queued",
            phase="queued",
            slug=slug,
            message=f"Queued behind {other}",
            queue_position=1,
            behind=other,
            started_at=utc_now(),
            log=[],
        )
    if start_pump:
        threading.Thread(target=_pump, daemon=True).start()
    return {
        "ok": True,
        "status": "queued" if other else "running",
        "slug": slug,
        "behind": other,
        "message": f"Queued behind {other}" if other else f"Starting {slug}",
    }


def prepare_and_start(root: Path) -> None:
    """Start the demo stack if needed, then POST the host video worker."""
    import demos

    ok, err = ensure_worker()
    if not ok:
        raise RuntimeError(err)

    w = worker_status()
    if w.get("status") == "running" and w.get("slug") == root.name:
        return
    if w.get("status") == "running":
        other = w.get("slug") or "another demo"
        update_job(root, status="queued", phase="queued", slug=root.name, message=f"Waiting for {other} to finish…", behind=other)
        _wait_worker_idle()

    _wait_compose_idle()
    text = (root / "docker-compose.yml").read_text(encoding="utf-8", errors="replace")
    port = demos.webui_port(text)
    if not _demo_running(root):
        update_job(
            root,
            reset=True,
            status="running",
            phase="starting",
            slug=root.name,
            message="Starting the demo stack…",
            started_at=utc_now(),
            log=[],
        )
        demos._set_job(message=f"Stopping other Clients/ stacks, then starting {root.name}…")
        demos.stop_other_clients_stacks(keep=root)
        demos._set_job(message=f"Starting {root.name} for construction video…")
        demos.start_demo(root)
        url = f"http://127.0.0.1:{port}/" if port else ""
        update_job(root, message="Waiting for the Web UI…")
        demos._set_job(message=f"Waiting for {root.name} Web UI…")
        if not url or not wait_webui(url, timeout=90):
            update_job(
                root,
                status="error",
                phase="error",
                message="Web UI did not come up",
                error="Start the demo from the hub and retry Create video.",
            )
            raise RuntimeError("Web UI did not come up — start the demo and retry.")

    code, payload = _post_run(root.name)
    if code == 409:
        other = payload.get("slug") or "another demo"
        update_job(root, message=f"Waiting for {other} to finish…")
        _wait_worker_idle(except_slug=root.name)
        code, payload = _post_run(root.name)
    if code not in {200, 202} or not payload.get("ok"):
        raise RuntimeError(payload.get("error") or payload.get("message") or f"Worker HTTP {code}")
