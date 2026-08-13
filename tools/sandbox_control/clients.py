"""Inventory real Clients/ folders (not Demos) and start/stop their sandboxes."""

from __future__ import annotations

import re
import threading
from pathlib import Path

import demos

ROOT = demos.ROOT
CLIENTS = demos.CLIENTS
SKIP_NAMES = {"Demos", "_shared", "_incoming"}

_job_lock = threading.Lock()
_job: dict = {"busy": False, "action": "", "slug": "", "message": "Idle", "error": ""}


def job_snapshot() -> dict:
    with _job_lock:
        return dict(_job)


def _set_job(**fields) -> None:
    with _job_lock:
        _job.update(fields)


def slug_for(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", (name or "").strip().lower()).strip("-") or "client"


def iter_client_roots() -> list[Path]:
    if not CLIENTS.is_dir():
        return []
    roots = []
    for path in sorted(CLIENTS.iterdir(), key=lambda p: p.name.lower()):
        if not path.is_dir() or path.name.startswith(".") or path.name in SKIP_NAMES:
            continue
        if (path / "eip-root").is_dir() or (path / "README.md").is_file() or (path / "sandbox").is_dir():
            roots.append(path)
    return roots


def require_root(slug: str) -> Path:
    slug = (slug or "").strip().lower()
    for root in iter_client_roots():
        if slug_for(root.name) == slug:
            return root
    raise ValueError(f"Unknown client {slug!r}")


def client_title(root: Path) -> str:
    readme = root / "README.md"
    if readme.is_file():
        for line in readme.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("# "):
                return line[2:].strip()
    return root.name


def _compose_sandbox(root: Path) -> Path | None:
    yml = root / "sandbox" / "docker-compose.yml"
    return yml if yml.is_file() else None


def _webui_port(root: Path) -> int | None:
    yml = _compose_sandbox(root)
    if yml:
        text = yml.read_text(encoding="utf-8", errors="replace")
        m = re.search(r'"(\d+):\d+"', text) or re.search(r"(\d+):\d+", text)
        if m:
            return int(m.group(1))
    if slug_for(root.name) == "med-rec":
        return 8080
    return None


def _crl_running() -> bool:
    code, out = demos.run(["docker", "ps", "--format", "{{.Names}}"], timeout=15)
    if code != 0:
        return False
    return any(n.strip() == "pf-crlplus-ail-sandbox" for n in out.splitlines())


def _medrec_running() -> bool:
    code, out = demos.run(["docker", "ps", "--format", "{{.Names}}"], timeout=15)
    if code != 0:
        return False
    return any(n.strip() == "pilotfish-eip" for n in out.splitlines())


def is_running(root: Path) -> bool:
    slug = slug_for(root.name)
    if slug == "crl-plus":
        return _crl_running()
    if slug == "med-rec":
        return _medrec_running()
    yml = _compose_sandbox(root)
    if not yml:
        return False
    code, out = demos.run(
        ["docker", "compose", "-f", str(yml), "--project-directory", str(yml.parent), "-p", slug, "ps", "--status", "running", "-q"],
        timeout=20,
    )
    return code == 0 and bool(out.strip())


def list_clients() -> list[dict]:
    from client_requests import list_requests

    lan = demos.lan_ip()
    rows = []
    for root in iter_client_roots():
        slug = slug_for(root.name)
        port = _webui_port(root)
        running = is_running(root)
        reqs = list_requests(slug)
        latest = reqs[0] if reqs else None
        local = ""
        if port:
            local = f"http://127.0.0.1:{port}/eip/" if slug == "med-rec" else f"http://127.0.0.1:{port}/"
        rows.append(
            {
                "slug": slug,
                "name": root.name,
                "title": client_title(root),
                "path": root.relative_to(ROOT).as_posix(),
                "running": running,
                "webui_port": port,
                "local_url": local,
                "lan_url": local.replace("127.0.0.1", lan) if local else "",
                "has_sandbox": bool(_compose_sandbox(root)) or slug == "med-rec",
                "request_count": len(reqs),
                "latest_request": latest,
            }
        )
    return rows


def stop_demo_stacks() -> list[str]:
    """Stop Clients/Demos compose projects so a client sandbox has RAM. Never down -v."""
    stopped: list[str] = []
    demos_root = (CLIENTS / "Demos").resolve()
    seen: set[Path] = set()
    for row in demos.compose_ls():
        for part in (row.get("ConfigFiles") or "").split(","):
            part = part.strip()
            if not part:
                continue
            yml = Path(part).resolve()
            try:
                yml.relative_to(demos_root)
            except ValueError:
                continue
            root = yml.parent
            if root in seen:
                continue
            seen.add(root)
            if (root / "docker-compose.yml").is_file():
                demos.stop_demo(root)
                stopped.append(root.name)
    return stopped


def push_eip_files(root: Path, rels: list[str]) -> int:
    """Copy changed eip-root files into Med Rec EIP (image is not bind-mounted)."""
    if slug_for(root.name) != "med-rec" or not rels:
        return 0
    if not _medrec_running():
        start_client(root)
    n = 0
    eip = "/usr/local/tomcat/webapps/eip/eip-root"
    for rel in rels:
        src = root / rel
        if not src.is_file():
            continue
        inner = rel.split("eip-root/", 1)[-1] if "eip-root/" in rel else rel
        dest = f"{eip}/{inner}"
        demos.run(["docker", "exec", "pilotfish-eip", "mkdir", "-p", str(Path(dest).parent)], timeout=20)
        code, _ = demos.run(["docker", "cp", str(src), f"pilotfish-eip:{dest}"], timeout=60)
        if code == 0:
            n += 1
    if n:
        demos.run(["docker", "restart", "pilotfish-eip"], timeout=120)
    return n


def start_client(root: Path) -> str:
    slug = slug_for(root.name)
    stop_demo_stacks()
    if slug == "med-rec":
        script = ROOT / "docker-run.sh"
        code, out = demos.run(["bash", str(script), "start"], cwd=ROOT, timeout=180)
        if code != 0:
            raise RuntimeError(out or "docker-run.sh start failed")
        return out or "started Med Rec EIP"
    yml = _compose_sandbox(root)
    if not yml:
        raise RuntimeError(f"{root.name} has no sandbox compose")
    cmd = [
        "docker",
        "compose",
        "-f",
        str(yml),
        "--project-directory",
        str(yml.parent),
        "-p",
        slug,
        "up",
        "-d",
        "--build",
    ]
    code, out = demos.run(cmd, cwd=yml.parent, timeout=240)
    if code != 0:
        raise RuntimeError(out or "compose up failed")
    return out or f"started {slug}"


def stop_client(root: Path) -> str:
    slug = slug_for(root.name)
    if slug == "med-rec":
        script = ROOT / "docker-run.sh"
        code, out = demos.run(["bash", str(script), "stop"], cwd=ROOT, timeout=120)
        return out or f"stop exit {code}"
    yml = _compose_sandbox(root)
    if not yml:
        return "no sandbox"
    cmd = [
        "docker",
        "compose",
        "-f",
        str(yml),
        "--project-directory",
        str(yml.parent),
        "-p",
        slug,
        "down",
    ]
    code, out = demos.run(cmd, cwd=yml.parent, timeout=180)
    return out or f"compose down exit {code}"


def run_action(action: str, slug: str) -> None:
    _set_job(busy=True, action=action, slug=slug, message=f"{action} {slug}…", error="")
    try:
        root = require_root(slug)
        if action == "stop":
            stop_client(root)
            _set_job(message=f"Stopped {root.name}")
        elif action == "start":
            _set_job(message=f"Starting {root.name} sandbox…")
            start_client(root)
            _set_job(message=f"Started {root.name}")
        elif action == "restart":
            stop_client(root)
            start_client(root)
            _set_job(message=f"Restarted {root.name}")
        else:
            raise ValueError(f"Unknown action {action}")
    except Exception as exc:
        _set_job(error=str(exc)[:800], message=f"{action} failed")
    finally:
        _set_job(busy=False)


def enqueue(action: str, slug: str) -> dict:
    with _job_lock:
        if _job.get("busy"):
            return {"ok": False, "error": "Busy — wait for the current client start/stop to finish."}
        _job.update({"busy": True, "action": action, "slug": slug, "message": "Queued", "error": ""})
    threading.Thread(target=run_action, args=(action, slug), daemon=True).start()
    return {"ok": True, "action": action, "slug": slug}
