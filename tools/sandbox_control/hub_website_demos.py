"""Track website product-demo recreations (cms.pilotfishtechnology.com/product-demos)."""

from __future__ import annotations

import json
import shutil
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

from flask import jsonify, request

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CATALOG = ROOT / "docs" / "website-demos.json"
PROGRESS = HERE / "website-demo-progress.json"

STATUSES = [
    ("not_started", "Not Started"),
    ("building_interface", "Building Interface"),
    ("building_video", "Building Video"),
    ("refining_video", "Refining Video"),
    ("done", "Done"),
]
STATUS_IDS = {k for k, _ in STATUSES}
ORIGINS = [
    ("unknown", "—"),
    ("received", "Pre-built"),
    ("sandbox", "Built here"),
]
ORIGIN_IDS = {k for k, _ in ORIGINS}
FFPROBE = shutil.which("ffprobe") or "/opt/homebrew/bin/ffprobe"
_mp4_cache: dict[str, tuple[float, int]] = {}
_slug_map: dict[str, Path] | None = None
_slug_map_at = 0.0


def _load_json(path: Path, default):
    if not path.is_file():
        return default
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return default
    return data if data is not None else default


def _catalog() -> dict:
    raw = _load_json(CATALOG, {})
    items = raw.get("items") if isinstance(raw, dict) else []
    return {
        "source": (raw or {}).get("source") or "https://cms.pilotfishtechnology.com/product-demos/",
        "items": [x for x in items if isinstance(x, dict) and x.get("id")],
    }


def _progress() -> dict:
    raw = _load_json(PROGRESS, {})
    return raw if isinstance(raw, dict) else {}


def _save_progress(data: dict) -> None:
    PROGRESS.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def _sec_label(sec: int) -> str:
    if sec <= 0:
        return ""
    h, rem = divmod(sec, 3600)
    m, s = divmod(rem, 60)
    if h:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"


def _as_sec(raw) -> int:
    try:
        return int(raw)
    except (TypeError, ValueError):
        return 0


def _demo_roots() -> dict[str, Path]:
    global _slug_map, _slug_map_at
    now = time.monotonic()
    if _slug_map is not None and now - _slug_map_at < 30:
        return _slug_map
    try:
        from demo_paths import iter_demo_roots

        _slug_map = {p.name.lower(): p for p in iter_demo_roots()}
    except Exception:
        _slug_map = {}
    _slug_map_at = now
    return _slug_map


def _demo_root(slug: str):
    slug = (slug or "").strip()
    if not slug:
        return None
    return _demo_roots().get(slug.lower())


def _mp4_sec(slug: str) -> int:
    root = _demo_root(slug)
    if root is None:
        return 0
    mp4 = root / "documents" / "construction-replay.mp4"
    if not mp4.is_file():
        return 0
    key = str(mp4)
    mtime = mp4.stat().st_mtime
    hit = _mp4_cache.get(key)
    if hit and hit[0] == mtime:
        return hit[1]
    if not FFPROBE or not Path(FFPROBE).is_file():
        return 0
    proc = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(mp4)],
        capture_output=True,
        text=True,
        timeout=8,
    )
    try:
        sec = int(round(float((proc.stdout or "").strip())))
    except ValueError:
        sec = 0
    _mp4_cache[key] = (mtime, sec)
    return sec


def _demo_exists(slug: str) -> bool:
    return _demo_root(slug) is not None


def _video_meta(slug: str) -> tuple[str, str]:
    """ISO generated-at and eiConsole version from the sandbox mp4 / job file."""
    root = _demo_root(slug)
    if root is None:
        return "", ""
    job_path = root / "documents" / "construction-video-job.json"
    job = _load_json(job_path, {}) if job_path.is_file() else {}
    if not isinstance(job, dict):
        job = {}
    ver = str(job.get("eiconsole_version") or "").strip()
    when = str(job.get("video_generated_at") or "").strip()
    if not when and str(job.get("phase") or "") == "done":
        when = str(job.get("updated_at") or "").strip()
    mp4 = root / "documents" / "construction-replay.mp4"
    if not when and mp4.is_file():
        when = datetime.fromtimestamp(mp4.stat().st_mtime, timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        )
    return when, ver


def _resolve_slug(item: dict, rec: dict) -> str:
    for cand in (item.get("slug"), item.get("id"), rec.get("slug")):
        slug = str(cand or "").strip()
        if slug and _demo_exists(slug):
            return slug
    return str(item.get("slug") or item.get("id") or "").strip()


def list_rows() -> dict:
    cat = _catalog()
    prog = _progress()
    rows = []
    counts = {k: 0 for k, _ in STATUSES}
    for item in cat["items"]:
        pid = str(item["id"])
        rec = prog.get(pid) if isinstance(prog.get(pid), dict) else {}
        status = rec.get("status") if rec.get("status") in STATUS_IDS else "not_started"
        origin = rec.get("origin") if rec.get("origin") in ORIGIN_IDS else "unknown"
        slug = _resolve_slug(item, rec)
        old_sec = _as_sec(item.get("duration_sec"))
        new_sec = _mp4_sec(slug)
        generated_at, eic_ver = _video_meta(slug)
        counts[status] = counts.get(status, 0) + 1
        rows.append(
            {
                "id": pid,
                "group": item.get("group") or "Other",
                "title": item.get("title") or pid,
                "page": item.get("page") or "",
                "youtube": item.get("youtube") or "",
                "duration": _sec_label(old_sec),
                "duration_sec": old_sec,
                "new_duration": _sec_label(new_sec),
                "new_duration_sec": new_sec,
                "video_generated_at": generated_at,
                "eiconsole_version": eic_ver,
                "status": status,
                "origin": origin,
                "slug": slug,
                "exists": _demo_exists(slug),
                "updated_at": rec.get("updated_at") or "",
            }
        )
    return {
        "ok": True,
        "source": cat["source"],
        "statuses": [{"id": k, "label": lab} for k, lab in STATUSES],
        "origins": [{"id": k, "label": lab} for k, lab in ORIGINS],
        "counts": counts,
        "items": rows,
    }


def patch_row(item_id: str, payload: dict) -> dict:
    cat = _catalog()
    if not any(str(x.get("id")) == item_id for x in cat["items"]):
        return {"ok": False, "error": "Unknown website demo."}
    prog = _progress()
    rec = dict(prog.get(item_id) or {})
    if "status" in payload:
        status = str(payload.get("status") or "").strip()
        if status not in STATUS_IDS:
            return {"ok": False, "error": "Unknown status."}
        rec["status"] = status
    if "origin" in payload:
        origin = str(payload.get("origin") or "").strip()
        if origin not in ORIGIN_IDS:
            return {"ok": False, "error": "Unknown routes origin."}
        rec["origin"] = origin
    rec["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    prog[item_id] = rec
    _save_progress(prog)
    return {"ok": True, **list_rows()}


def register(app) -> None:
    @app.get("/api/website-demos")
    def api_website_demos():
        return jsonify(list_rows())

    @app.post("/api/website-demos/<item_id>")
    def api_website_demo_patch(item_id: str):
        data = request.get_json(silent=True) or {}
        result = patch_row(item_id, data)
        return jsonify(result), (200 if result.get("ok") else 400)
