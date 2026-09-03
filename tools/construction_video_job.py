#!/usr/bin/env python3
"""Shared construction-video-job.json writer for the Info tab progress panel."""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

ENV_DEMO = "CONSTRUCTION_VIDEO_DEMO"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def demo_from_env() -> Path | None:
    raw = str(os.environ.get(ENV_DEMO) or "").strip()
    if not raw:
        return None
    path = Path(raw).expanduser().resolve()
    return path if path.is_dir() else None


def job_path(demo: Path) -> Path:
    return demo / "documents" / "construction-video-job.json"


def atomic_write_json(path: Path, data: dict) -> None:
    """Write JSON so a concurrent reader never sees a truncated file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    tmp.replace(path)


def load_job(demo: Path) -> dict:
    path = job_path(demo)
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def update_job(demo: Path | None = None, **fields) -> dict:
    """Merge fields into documents/construction-video-job.json.

    Pass reset=True to replace the file. Pass log_line= to append a log row.
    """
    demo = demo or demo_from_env()
    if demo is None:
        return {}
    reset = bool(fields.pop("reset", False))
    log_line = fields.pop("log_line", None)
    data: dict = {} if reset else load_job(demo)
    if log_line:
        log = list(data.get("log") or [])
        text = str(log_line).strip()
        if text:
            log.append({"at": utc_now(), "text": text})
        fields["log"] = log[-12:]
    data.update(fields)
    data["updated_at"] = utc_now()
    if "slug" not in data:
        data["slug"] = demo.name
    atomic_write_json(job_path(demo), data)
    return data


def detect_eiconsole_version(home: Path | None = None) -> str:
    """Read the installed eiConsole version (26R1.14, 24R1.80, …)."""
    root = home or Path(os.environ.get("EICONSOLE_HOME") or "/Applications/eiConsole")
    props = root / "version.properties"
    if props.is_file():
        for line in props.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("Eip.Version.Number="):
                val = line.split("=", 1)[1].strip()
                if val and not val.startswith("@"):
                    return val
    i4j = root / ".install4j" / "i4jparams.conf"
    if i4j.is_file():
        import re

        match = re.search(
            r'applicationVersion="([^"]+)"',
            i4j.read_text(encoding="utf-8", errors="replace"),
        )
        if match and match.group(1).strip():
            return match.group(1).strip()
    return ""


def clip_label(entry: dict | None) -> str:
    if not isinstance(entry, dict):
        return "clip"
    return str(
        entry.get("message")
        or entry.get("focus_label")
        or entry.get("id")
        or "clip"
    ).strip() or "clip"
