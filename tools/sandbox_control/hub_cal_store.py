"""Local calendar events from screenshots (until Graph calendar is approved)."""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
DIR = HERE / "data" / "calendar"
PATH = DIR / "events.json"


def load() -> list[dict]:
    if not PATH.is_file():
        return []
    try:
        data = json.loads(PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    rows = data.get("events") if isinstance(data, dict) else data
    return [r for r in (rows or []) if isinstance(r, dict)]


def save(rows: list[dict]) -> None:
    DIR.mkdir(parents=True, exist_ok=True)
    PATH.write_text(json.dumps({"events": rows}, indent=2) + "\n", encoding="utf-8")


def in_range(start: date, end: date) -> list[dict]:
    out = []
    for row in load():
        day = str(row.get("day") or row.get("start") or "")[:10]
        if not day:
            continue
        try:
            d = date.fromisoformat(day)
        except ValueError:
            continue
        if start <= d <= end:
            out.append(row)
    out.sort(key=lambda r: (r.get("start") or "", r.get("subject") or ""))
    return out


def replace_days(incoming: list[dict]) -> list[dict]:
    days = {str(r.get("day") or "")[:10] for r in incoming if r.get("day")}
    kept = [r for r in load() if str(r.get("day") or "")[:10] not in days]
    kept.extend(incoming)
    kept.sort(key=lambda r: (r.get("start") or "", r.get("subject") or ""))
    save(kept)
    return kept


def clear() -> None:
    save([])
