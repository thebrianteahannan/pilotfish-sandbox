#!/usr/bin/env python3
"""Regenerate construction-replay.mp4 + transcript for one Clients/Demos demo.

Stops other Sandbox demo stacks (no -v), re-records module replay, brings up
that demo's Web UI, exports video + transcript, leaves the target stack up.

Usage (repo root):
  python3 tools/regenerate_construction_video.py csv-sftp-to-sql
  python3 tools/regenerate_construction_video.py triggered-ftp-download --keep-replay
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from demo_paths import DEMOS, iter_demo_roots, require_demo

ROOT = Path(__file__).resolve().parents[1]

# Reuse the one-demo-at-a-time exporter.
sys.path.insert(0, str(ROOT / "tools"))
from batch_export_construction_videos import (  # noqa: E402
    VENV_PY,
    eligible_demos,
    process_demo,
)


def resolve_demo(raw: str) -> Path:
    text = (raw or "").strip().rstrip("/")
    if not text:
        raise SystemExit("Pass a demo slug, e.g. csv-sftp-to-sql")
    return require_demo(text)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("demo", help="Demo slug or path under Clients/Demos/")
    ap.add_argument(
        "--keep-replay",
        action="store_true",
        help="Do not re-run record_module_replay (reuse existing manifest)",
    )
    args = ap.parse_args()
    if not VENV_PY.is_file():
        print(f"Missing {VENV_PY} — create tools/.venv-video first", file=sys.stderr)
        return 2
    demo = resolve_demo(args.demo)
    print(f"Regenerating construction video for {demo.name}", flush=True)
    status = process_demo(
        demo,
        force_rerecord=not args.keep_replay,
        skip_existing=False,
        leave_up=True,
    )
    video = demo / "documents" / "construction-replay.mp4"
    print(f"{demo.name}: {status}", flush=True)
    print(video, flush=True)
    return 0 if status == "ok" else 1


if __name__ == "__main__":
    raise SystemExit(main())
