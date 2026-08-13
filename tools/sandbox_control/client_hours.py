"""Best-guess billable hours if a human did the request by hand in eiConsole."""

from __future__ import annotations

import json
from pathlib import Path


def _blob(meta: dict, dive: dict) -> str:
    parts = [
        meta.get("subject"),
        meta.get("request_summary"),
        meta.get("message"),
        dive.get("summary"),
        dive.get("ask"),
        dive.get("intent"),
        " ".join(str(c) for c in (dive.get("codes") or meta.get("asks") or [])),
    ]
    return " ".join(str(p or "") for p in parts).lower()


def _files(meta: dict, dive: dict) -> int:
    paths = set()
    for rec in dive.get("files") or []:
        if isinstance(rec, dict) and rec.get("path"):
            paths.add(rec["path"])
        elif rec:
            paths.add(str(rec))
    for rec in meta.get("changes") or []:
        if isinstance(rec, dict) and rec.get("path"):
            paths.add(rec["path"])
    for path in meta.get("likely_files") or []:
        if path:
            paths.add(str(path))
    return len(paths)


def _edits(meta: dict, dive: dict) -> int:
    edits = dive.get("edits") or []
    if edits:
        return len(edits)
    n = int(dive.get("edit_count") or meta.get("edit_count") or 0)
    return n or _files(meta, dive)


def _codes(meta: dict, dive: dict) -> int:
    codes = [c for c in (dive.get("codes") or meta.get("asks") or []) if c and not str(c).startswith("$")]
    return len(codes)


def _tests(meta: dict) -> int:
    tests = meta.get("tests")
    if isinstance(tests, dict):
        return len(tests.get("items") or [])
    return 0


def for_request(meta: dict | None = None, folder=None, dive: dict | None = None) -> dict:
    meta = meta or {}
    if dive is None and folder is not None:
        path = Path(folder) / "dive.json"
        if path.is_file():
            try:
                loaded = json.loads(path.read_text(encoding="utf-8"))
                if isinstance(loaded, dict):
                    dive = loaded
            except (OSError, json.JSONDecodeError):
                dive = None
    return estimate(meta, dive)


def estimate(meta: dict | None = None, dive: dict | None = None) -> dict:
    """Hours a skilled human would bill to do this request manually."""
    meta = meta or {}
    dive = dive or meta.get("dive") or {}
    text = _blob(meta, dive)
    files = _files(meta, dive)
    edits = _edits(meta, dive)
    codes = _codes(meta, dive)
    tests = _tests(meta)

    hours = 0.5
    hours += 0.5 * max(files, 1)
    hours += 0.4 * max(edits, 1)
    if codes:
        hours += 0.2 * max(0, codes - 2)

    if "strip" in text:
        hours += 2.0
    if "halifax" in text and "strip" in text:
        hours += 1.0
    if "ariana" in text or "in1" in text:
        hours += 1.5
    if "split" in text or "facility" in text:
        hours += 0.75
    if "mue" in text:
        hours += 1.0

    comments = str(meta.get("comments") or dive.get("comments") or "").strip()
    if comments:
        hours += 0.5
    hours += 0.4 * min(len(dive.get("delta") or []), 4)

    if tests:
        hours += 0.25 * min(tests, 6)
    elif meta.get("status") in {"tested", "ready", "applied"}:
        hours += 1.0

    shots = meta.get("screenshots") or []
    if shots:
        hours += 0.25 * min(len(shots), 3)

    hours = max(1.0, min(16.0, round(hours * 2) / 2))
    label = f"{hours:g}h"
    return {"hours": hours, "label": label, "billable_hours": hours, "billable_label": label}
