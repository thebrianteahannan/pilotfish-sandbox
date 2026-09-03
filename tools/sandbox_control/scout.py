"""Healthcare Buzz Scout (Reddit idea finder) — start/stop via Compose."""

from __future__ import annotations

import threading

import demos

CONTAINER = "pf-healthcare-buzz-scout"
PORT = 8130
ROOT = demos.TOOLS / "healthcare-buzz-scout"

_lock = threading.Lock()
_job = {"busy": False, "action": "", "message": "", "error": ""}


def job_snapshot() -> dict:
    with _lock:
        return dict(_job)


def _set(**fields) -> None:
    with _lock:
        _job.update(fields)


def _compose() -> list[str]:
    yml = ROOT / "docker-compose.yml"
    return [
        "docker",
        "compose",
        "-f",
        str(yml),
        "--project-directory",
        str(ROOT),
        "-p",
        "healthcare-buzz-scout",
    ]


def running() -> bool:
    code, out = demos.run(["docker", "inspect", "-f", "{{.State.Running}}", CONTAINER], timeout=15)
    return code == 0 and out.strip().lower() == "true"


def status() -> dict:
    on = running()
    lan = demos.lan_ip()
    return {
        "ok": True,
        "running": on,
        "port": PORT,
        "container": CONTAINER,
        "title": "Healthcare Buzz Scout",
        "kind": "docker",
        "blurb": "Docker container · Find work, companies, market, search rankings, and ads from the buzz",
        "local_url": f"http://127.0.0.1:{PORT}/",
        "lan_url": f"http://{lan}:{PORT}/",
        "job": job_snapshot(),
    }


def start() -> str:
    if not (ROOT / "docker-compose.yml").is_file():
        raise FileNotFoundError(f"missing {ROOT / 'docker-compose.yml'}")
    (ROOT / "data").mkdir(parents=True, exist_ok=True)
    cmd = _compose() + ["up", "-d"]
    code, out = demos.run(cmd, cwd=ROOT, timeout=180)
    if code != 0:
        cmd = _compose() + ["up", "-d", "--build"]
        code, out = demos.run(cmd, cwd=ROOT, timeout=300)
        if code != 0:
            raise RuntimeError(out or f"compose up exit {code}")
    return out or "started"


def stop() -> str:
    code, out = demos.run(_compose() + ["down"], cwd=ROOT, timeout=120)
    if running():
        demos.run(["docker", "stop", CONTAINER], timeout=40)
        demos.run(["docker", "rm", CONTAINER], timeout=40)
    if code != 0 and running():
        raise RuntimeError(out or f"compose down exit {code}")
    return out or "stopped"


def run_action(action: str) -> None:
    _set(busy=True, action=action, message=f"{action} scout…", error="")
    try:
        if action == "start":
            start()
            _set(message="Scout is up")
        elif action == "stop":
            stop()
            _set(message="Scout stopped")
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
            return {"ok": False, "error": "Scout start/stop already running."}
        _job.update({"busy": True, "action": action, "message": "Queued", "error": ""})
    threading.Thread(target=run_action, args=(action,), daemon=True).start()
    return {"ok": True, "action": action}
