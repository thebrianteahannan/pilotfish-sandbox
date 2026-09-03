"""Inventory Clients/Demos stacks and start/stop Compose (never down -v)."""

from __future__ import annotations

import json
import re
import socket
import subprocess
import sys
import threading
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOOLS = HERE.parent
ROOT = TOOLS.parent
CLIENTS = ROOT / "Clients"

if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from demo_paths import DEMOS, infer_category, iter_demo_roots, resolve_demo  # noqa: E402

_job_lock = threading.Lock()
_job: dict = {"busy": False, "action": "", "slug": "", "message": "Idle", "error": ""}


def job_snapshot() -> dict:
    with _job_lock:
        return dict(_job)


def _set_job(**fields) -> None:
    with _job_lock:
        _job.update(fields)


def run(cmd: list[str], *, cwd: Path | None = None, timeout: int = 120, env: dict | None = None) -> tuple[int, str]:
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError) as exc:
        return 1, str(exc)
    out = ((proc.stdout or "") + (proc.stderr or "")).strip()
    return proc.returncode, out[-4000:]


def lan_ip() -> str:
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.connect(("8.8.8.8", 80))
        ip = sock.getsockname()[0]
        sock.close()
        return ip
    except OSError:
        return "127.0.0.1"


def webui_port(compose_text: str) -> int | None:
    m = re.search(r'WEBUI_PORT:\s*"?(\d+)"?', compose_text)
    if m:
        return int(m.group(1))
    return None


def has_compose_profiles(compose_text: str) -> bool:
    return bool(re.search(r"^\s*profiles:", compose_text, flags=re.M))


def design_title(root: Path) -> str:
    path = root / "DESIGN.md"
    if path.is_file():
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("# "):
                name = re.sub(r"\s*[—\-–]\s*Design\s*$", "", line[2:].strip(), flags=re.I)
                if name:
                    return name
    return root.name.replace("-", " ")


def compose_ls() -> list[dict]:
    code, out = run(["docker", "compose", "ls", "--format", "json"], timeout=20)
    if code != 0 or not out.strip():
        return []
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


def under_clients(config_files: str | None) -> bool:
    if not config_files:
        return False
    for part in config_files.split(","):
        p = Path(part.strip()).resolve()
        try:
            p.relative_to(CLIENTS.resolve())
            return True
        except ValueError:
            continue
    return False


def running_demo_dirs() -> set[str]:
    found: set[str] = set()
    for row in compose_ls():
        if not under_clients(row.get("ConfigFiles")):
            continue
        for part in (row.get("ConfigFiles") or "").split(","):
            part = part.strip()
            if not part:
                continue
            try:
                found.add(Path(part).resolve().parent.relative_to(ROOT).as_posix())
            except ValueError:
                pass
    return found


def pf_containers_by_slug(slugs: set[str]) -> dict[str, list[dict]]:
    code, out = run(["docker", "ps", "-a", "--filter", "name=pf-", "--format", "{{json .}}"], timeout=20)
    grouped: dict[str, list[dict]] = {s: [] for s in slugs}
    if code != 0:
        return grouped
    ordered = sorted(slugs, key=len, reverse=True)
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        name = row.get("Names") or ""
        rec = {
            "name": name,
            "status": row.get("Status") or "",
            "running": str(row.get("State") or "").lower() == "running"
            or str(row.get("Status") or "").lower().startswith("up"),
        }
        for slug in ordered:
            if name.startswith(f"pf-{slug}"):
                grouped.setdefault(slug, []).append(rec)
                break
    return grouped


def pf_containers(slug: str) -> list[dict]:
    return pf_containers_by_slug({slug}).get(slug) or []


CAT_ORDER = ("Insurance/EDI", "Medical/HL7", "Medical/FHIR", "Other")


def category_sort_key(category: str) -> tuple:
    try:
        return (CAT_ORDER.index(category), category)
    except ValueError:
        return (99, category)


def list_demos() -> list[dict]:
    from videos import snapshot, worker_status

    running = running_demo_dirs()
    lan = lan_ip()
    wjob = worker_status()
    roots = [r for r in iter_demo_roots() if (r / "docker-compose.yml").is_file()]
    by_slug = pf_containers_by_slug({r.name for r in roots})
    demos = []
    for root in roots:
        compose = root / "docker-compose.yml"
        text = compose.read_text(encoding="utf-8", errors="replace")
        port = webui_port(text)
        rel = root.relative_to(ROOT).as_posix()
        slug = root.name
        containers = by_slug.get(slug) or []
        is_running = rel in running or any(c.get("running") for c in containers)
        try:
            category = root.relative_to(DEMOS).parent.as_posix()
            if category == ".":
                category = infer_category(slug)
        except ValueError:
            category = infer_category(slug)
        family = category.split("/")[0] if category else "Other"
        demos.append(
            {
                "slug": slug,
                "title": design_title(root),
                "category": category,
                "family": family,
                "path": rel,
                "running": is_running,
                "webui_port": port,
                "local_url": f"http://127.0.0.1:{port}/" if port else "",
                "lan_url": f"http://{lan}:{port}/" if port else "",
                "has_profiles": has_compose_profiles(text),
                "containers": containers,
                "video": snapshot(root, wjob),
            }
        )
    demos.sort(key=lambda d: (*category_sort_key(d["category"]), d["slug"]))
    return demos


def _compose_base(root: Path) -> list[str]:
    yml = root / "docker-compose.yml"
    return [
        "docker",
        "compose",
        "-f",
        str(yml),
        "--project-directory",
        str(root),
        "-p",
        root.name,
    ]


def stop_demo(root: Path) -> str:
    notes: list[str] = []
    code, out = run(_compose_base(root) + ["down"], cwd=root, timeout=180)
    notes.append(out or f"compose down exit {code}")
    slug = root.name
    for row in pf_containers(slug):
        name = row.get("name") or ""
        if not name:
            continue
        run(["docker", "stop", name], timeout=40)
        run(["docker", "rm", name], timeout=40)
        notes.append(f"removed {name}")
    run(["docker", "compose", "-p", slug, "down"], timeout=60)
    return "; ".join(n for n in notes if n)[:1500]


def stop_other_clients_stacks(keep: Path | None = None) -> list[str]:
    stopped: list[str] = []
    keep_res = keep.resolve() if keep else None
    seen: set[Path] = set()
    for row in compose_ls():
        if not under_clients(row.get("ConfigFiles")):
            continue
        for part in (row.get("ConfigFiles") or "").split(","):
            part = part.strip()
            if not part:
                continue
            root = Path(part).resolve().parent
            if keep_res and root == keep_res:
                continue
            if root in seen:
                continue
            seen.add(root)
            if (root / "docker-compose.yml").is_file():
                stop_demo(root)
                stopped.append(root.name)
    # Orphan pf-* containers whose compose ls missed them
    code, out = run(["docker", "ps", "--format", "{{json .}}"], timeout=20)
    if code == 0:
        keep_slug = keep.name if keep else ""
        for line in out.splitlines():
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            name = str(row.get("Names") or "")
            if not name.startswith("pf-"):
                continue
            if name == "pf-healthcare-buzz-scout":
                continue
            if keep_slug and f"pf-{keep_slug}" in name:
                continue
            run(["docker", "stop", name], timeout=40)
            run(["docker", "rm", name], timeout=40)
            stopped.append(name)
    return stopped


def start_demo(root: Path) -> str:
    text = (root / "docker-compose.yml").read_text(encoding="utf-8", errors="replace")
    cmd = _compose_base(root) + ["up", "-d"]
    if has_compose_profiles(text):
        cmd = _compose_base(root) + ["--profile", "full", "up", "-d"]
    code, out = run(cmd, cwd=root, timeout=240)
    if code != 0:
        raise RuntimeError(out or f"compose up exit {code}")
    return out or "started"


def require_root(slug: str) -> Path:
    found = resolve_demo(slug)
    if found is None or not (found / "docker-compose.yml").is_file():
        raise ValueError(f"Unknown demo {slug!r}")
    return found


def run_action(action: str, slug: str) -> None:
    _set_job(busy=True, action=action, slug=slug, message=f"{action} {slug}…", error="")
    try:
        root = require_root(slug)
        if action == "stop":
            _set_job(message=f"Stopping {slug}…")
            stop_demo(root)
            _set_job(message=f"Stopped {slug}")
        elif action == "start":
            _set_job(message="Stopping other Clients/ stacks…")
            others = stop_other_clients_stacks(keep=root)
            if others:
                _set_job(message=f"Stopped {', '.join(others[:6])}; starting {slug}…")
            else:
                _set_job(message=f"Starting {slug}…")
            start_demo(root)
            _set_job(message=f"Started {slug}")
        elif action == "restart":
            _set_job(message=f"Restarting {slug}…")
            stop_demo(root)
            others = stop_other_clients_stacks(keep=root)
            if others:
                _set_job(message=f"Stopped extras; starting {slug}…")
            start_demo(root)
            _set_job(message=f"Restarted {slug}")
        elif action == "video":
            import videos

            _set_job(message=f"Preparing construction video for {slug}…")
            videos.prepare_and_start(root)
            _set_job(message=f"Recording construction video for {slug}…")
        else:
            raise ValueError(f"Unknown action {action}")
    except Exception as exc:
        _set_job(error=str(exc)[:800], message=f"{action} failed")
    finally:
        _set_job(busy=False)


def enqueue(action: str, slug: str) -> dict:
    if action == "video":
        import videos

        try:
            return videos.enqueue(require_root(slug))
        except Exception as exc:
            return {"ok": False, "error": str(exc)[:800]}
    with _job_lock:
        if _job.get("busy"):
            return {"ok": False, "error": "Busy — wait for the current start/stop to finish."}
        _job.update({"busy": True, "action": action, "slug": slug, "message": "Queued", "error": ""})
    threading.Thread(target=run_action, args=(action, slug), daemon=True).start()
    return {"ok": True, "action": action, "slug": slug}
