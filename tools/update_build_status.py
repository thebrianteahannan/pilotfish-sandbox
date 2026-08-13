#!/usr/bin/env python3
"""Update documents/build-status.json for progressive build theater.

Usage:
  python3 tools/update_build_status.py --root Clients/Demos/my-demo \\
    --phase routes --message "Authoring 02-transform" --route 02-transform --active
  python3 tools/update_build_status.py --root Clients/Demos/my-demo --complete
  python3 tools/update_build_status.py --root Clients/Demos/my-demo --add-route 01-listen
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def resolve_root(raw: str | None) -> Path:
    from demo_paths import require_demo

    return require_demo(raw)


def maybe_prepare_video_assets(root: Path) -> None:
    script = TOOLS / "export_construction_video.py"
    if not script.is_file():
        return
    print("Preparing construction video assets (no mp4)…")
    proc = subprocess.run(
        [sys.executable, str(script), "--root", str(root), "--prepare-only"],
        cwd=str(ROOT),
    )
    if proc.returncode != 0:
        print(
            f"WARNING: construction video prepare failed (exit {proc.returncode}).",
            file=sys.stderr,
        )


def maybe_export_video(root: Path, *, enabled: bool, url: str | None) -> None:
    if not enabled:
        return
    script = TOOLS / "export_construction_video.py"
    if not script.is_file():
        print("skip video: export_construction_video.py missing", file=sys.stderr)
        return
    cmd = [sys.executable, str(script), "--root", str(root), "--skip-if-missing-replay"]
    if url:
        cmd.extend(["--url", url])
    print("Recording construction video…")
    proc = subprocess.run(cmd, cwd=str(ROOT))
    if proc.returncode != 0:
        print(
            f"WARNING: construction video export failed (exit {proc.returncode}). "
            "Re-run: python3 tools/export_construction_video.py --root …",
            file=sys.stderr,
        )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", help="Demo root (contains documents/)")
    ap.add_argument("--phase", help="Phase id: scaffold|design|routes|webui|docs|tests|idle")
    ap.add_argument("--message", help="Human-readable status line")
    ap.add_argument("--log", action="append", default=[], help="Append a live-log line (repeatable)")
    ap.add_argument("--route", dest="current_route", help="Current route being built")
    ap.add_argument("--add-route", action="append", default=[], help="Append to routes_ready (repeatable)")
    ap.add_argument("--active", action="store_true", help="Mark build active")
    ap.add_argument("--inactive", action="store_true", help="Mark build inactive")
    ap.add_argument("--complete", action="store_true", help="Mark complete (active=false, phase=complete)")
    ap.add_argument(
        "--video",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="On --complete, also record construction-replay.mp4 (default: false; Info tab button)",
    )
    ap.add_argument("--url", help="Web UI URL for video recording (optional)")
    args = ap.parse_args()

    root = resolve_root(args.root)
    docs = root / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    path = docs / "build-status.json"

    data: dict = {"version": 1, "active": True, "phase": "scaffold", "routes_ready": []}
    if path.is_file():
        try:
            loaded = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                data.update(loaded)
        except json.JSONDecodeError:
            pass

    if args.complete:
        data["active"] = False
        data["phase"] = "complete"
        data["message"] = args.message if args.message is not None else "Build complete"
        data["current_route"] = ""
    else:
        if args.active:
            data["active"] = True
        if args.inactive:
            data["active"] = False
        if args.phase:
            data["phase"] = args.phase
        if args.message is not None:
            data["message"] = args.message
        if args.current_route is not None:
            data["current_route"] = args.current_route

    ready = list(data.get("routes_ready") or [])
    for r in args.add_route:
        if r and r not in ready:
            ready.append(r)
    data["routes_ready"] = ready
    log = list(data.get("log") or [])
    for line in args.log:
        text = str(line or "").strip()
        if text:
            log.append({"at": utc_now(), "text": text})
    data["log"] = log[-12:]
    data["updated_at"] = utc_now()
    data["version"] = 1

    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(path)
    print(json.dumps(data, indent=2))

    if args.complete:
        maybe_prepare_video_assets(root)
        maybe_export_video(root, enabled=args.video, url=args.url)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
