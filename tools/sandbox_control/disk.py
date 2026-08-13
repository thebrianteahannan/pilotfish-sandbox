"""Repo disk scan and allowlisted deletes for regenerable demo junk."""

from __future__ import annotations

import os
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DEMOS = ROOT / "Clients" / "Demos"

SKIP_DESCEND = {".git", "node_modules", "__pycache__", ".mypy_cache"}
SKIP_PREFIX = (".venv",)

_cache_lock = threading.Lock()
_cache: dict = {"at": 0.0, "payload": None}
CACHE_SEC = 20.0


def fmt_bytes(n: int) -> str:
    val = float(max(0, int(n)))
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if val < 1024 or unit == "TB":
            if unit == "B":
                return f"{int(val)} {unit}"
            return f"{val:.1f} {unit}"
        val /= 1024
    return f"{int(n)} B"


def _skip_dir_name(name: str) -> bool:
    if name in SKIP_DESCEND:
        return True
    return any(name.startswith(p) for p in SKIP_PREFIX)


def dir_size(path: Path) -> int:
    total = 0
    try:
        with os.scandir(path) as it:
            for ent in it:
                try:
                    if ent.is_symlink():
                        continue
                    if ent.is_file(follow_symlinks=False):
                        total += ent.stat(follow_symlinks=False).st_size
                    elif ent.is_dir(follow_symlinks=False):
                        total += dir_size(Path(ent.path))
                except OSError:
                    continue
    except OSError:
        return total
    return total


def _rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return str(path)


def is_allowed_delete(path: Path) -> bool:
    try:
        resolved = path.resolve()
        resolved.relative_to(ROOT.resolve())
    except ValueError:
        return False
    if not resolved.exists():
        return False
    rel = _rel(resolved)
    name = resolved.name
    if name == ".gitkeep":
        return False
    if rel.endswith("documents/construction-replay.mp4") or name == "construction-replay.mp4":
        try:
            resolved.relative_to(DEMOS.resolve())
            return True
        except ValueError:
            return name == "construction-replay.mp4" and "documents" in resolved.parts
    try:
        resolved.relative_to(DEMOS.resolve())
    except ValueError:
        return False
    parts = resolved.parts
    if "logs" in parts:
        return True
    if "output" in parts:
        return True
    return False


def delete_path(path: Path) -> dict:
    resolved = path.resolve()
    if not is_allowed_delete(resolved):
        return {"ok": False, "error": "Not on the allowlist (routes, samples, PDFs, and source stay)."}
    freed = 0
    removed = 0
    if resolved.is_file():
        freed = resolved.stat().st_size
        resolved.unlink()
        removed = 1
    elif resolved.is_dir():
        for dirpath, dirnames, filenames in os.walk(resolved, topdown=False):
            dp = Path(dirpath)
            for fn in filenames:
                fp = dp / fn
                if fn == ".gitkeep" or not is_allowed_delete(fp):
                    continue
                try:
                    freed += fp.stat().st_size
                    fp.unlink()
                    removed += 1
                except OSError:
                    continue
            for dn in dirnames:
                d = dp / dn
                try:
                    if not any(d.iterdir()):
                        d.rmdir()
                except OSError:
                    continue
        try:
            if resolved.exists() and not any(resolved.iterdir()):
                resolved.rmdir()
        except OSError:
            pass
    else:
        return {"ok": False, "error": "Not found"}
    invalidate()
    return {"ok": True, "freed": freed, "freed_label": fmt_bytes(freed), "removed": removed, "path": _rel(resolved)}


def construction_videos() -> list[Path]:
    hits: list[Path] = []
    if not DEMOS.is_dir():
        return hits
    for p in DEMOS.rglob("construction-replay.mp4"):
        if p.is_file() and "documents" in p.parts:
            hits.append(p)
    return hits


def delete_all_construction_videos() -> dict:
    freed = 0
    removed = 0
    errors: list[str] = []
    for p in construction_videos():
        result = delete_path(p)
        if result.get("ok"):
            freed += int(result.get("freed") or 0)
            removed += int(result.get("removed") or 0)
        else:
            errors.append(str(result.get("error") or p))
    invalidate()
    return {
        "ok": not errors,
        "freed": freed,
        "freed_label": fmt_bytes(freed),
        "removed": removed,
        "errors": errors[:8],
    }


def invalidate() -> None:
    with _cache_lock:
        _cache["at"] = 0.0
        _cache["payload"] = None


def _scan() -> dict:
    top: list[dict] = []
    if ROOT.is_dir():
        git = ROOT / ".git"
        if git.is_dir():
            top.append({"path": ".git", "bytes": dir_size(git), "note": "git history (not deletable here)"})
        for ent in sorted(ROOT.iterdir(), key=lambda p: p.name.lower()):
            if ent.name.startswith("."):
                continue
            try:
                if ent.is_symlink():
                    continue
                nbytes = dir_size(ent) if ent.is_dir() else ent.stat().st_size
            except OSError:
                continue
            top.append({"path": ent.name, "bytes": nbytes, "note": ""})
    top.sort(key=lambda r: r["bytes"], reverse=True)

    demos: list[dict] = []
    junk_mp4 = 0
    junk_logs = 0
    junk_output = 0
    largest: list[tuple[int, str]] = []
    if DEMOS.is_dir():
        for compose in DEMOS.rglob("docker-compose.yml"):
            if any(p.startswith("_") for p in compose.relative_to(DEMOS).parts):
                continue
            root = compose.parent
            demos.append({"slug": root.name, "path": _rel(root), "bytes": dir_size(root)})
        demos.sort(key=lambda r: r["bytes"], reverse=True)

        for dirpath, dirnames, filenames in os.walk(DEMOS):
            dirnames[:] = [d for d in dirnames if not _skip_dir_name(d)]
            base = Path(dirpath)
            for fn in filenames:
                fp = base / fn
                try:
                    if fp.is_symlink() or not fp.is_file():
                        continue
                    size = fp.stat().st_size
                except OSError:
                    continue
                rel = _rel(fp)
                largest.append((size, rel))
                parts = fp.parts
                if fn == "construction-replay.mp4":
                    junk_mp4 += size
                if "logs" in parts:
                    junk_logs += size
                if "output" in parts and fn != ".gitkeep":
                    junk_output += size
        largest.sort(reverse=True)
        largest = largest[:40]

    total = sum(int(r["bytes"]) for r in top)
    payload = {
        "root": str(ROOT),
        "total": total,
        "total_label": fmt_bytes(total),
        "top_folders": [{**r, "label": fmt_bytes(r["bytes"])} for r in top[:20]],
        "demos": [{**r, "label": fmt_bytes(r["bytes"])} for r in demos],
        "largest_files": [{"path": p, "bytes": b, "label": fmt_bytes(b), "deletable": is_allowed_delete(ROOT / p)} for b, p in largest],
        "junk": {
            "construction_videos": {"bytes": junk_mp4, "label": fmt_bytes(junk_mp4), "count": len(construction_videos())},
            "logs": {"bytes": junk_logs, "label": fmt_bytes(junk_logs)},
            "output": {"bytes": junk_output, "label": fmt_bytes(junk_output)},
        },
        "scanned_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }
    return payload


def scan(*, force: bool = False) -> dict:
    now = time.time()
    with _cache_lock:
        if not force and _cache["payload"] and (now - float(_cache["at"])) < CACHE_SEC:
            return _cache["payload"]
    payload = _scan()
    with _cache_lock:
        _cache["at"] = time.time()
        _cache["payload"] = payload
    return payload
