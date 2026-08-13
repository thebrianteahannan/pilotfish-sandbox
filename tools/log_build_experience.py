#!/usr/bin/env python3
"""Append narrated events to documents/build-experience.json (Build Experience tab).

Kinds: phase | decision | route | sql | test | docs | ops | note

Examples:
  python3 tools/log_build_experience.py --root Clients/Demos/my-demo \\
    --kind decision --title "Chose XPath router" \\
    --summary "Route accept vs reject with Conditional Node Router." \\
    --rationale "Stock PF routing; avoids a custom Java module for demo honesty." \\
    --alternative "Custom processor" --alternative "Single-file script"

  python3 tools/log_build_experience.py --root Clients/Demos/my-demo \\
    --kind sql --title "Inserted eligibility fixture" \\
    --detail "INSERT INTO members ..." --summary "Seeded SQL Server for smoke."

  python3 tools/log_build_experience.py --root Clients/Demos/my-demo --clear
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from demo_paths import require_demo
from pathlib import Path


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def next_id(events: list) -> str:
    n = len(events) + 1
    return f"e{n:03d}"


def load(path: Path) -> dict:
    data = {
        "version": 1,
        "title": "Interface construction experience",
        "demo": path.parent.parent.name if path.parent.name == "documents" else "",
        "events": [],
    }
    if path.is_file():
        try:
            loaded = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                data.update(loaded)
        except json.JSONDecodeError:
            pass
    if not isinstance(data.get("events"), list):
        data["events"] = []
    return data


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="Demo root")
    ap.add_argument("--clear", action="store_true", help="Wipe experience log")
    ap.add_argument(
        "--kind",
        choices=["phase", "decision", "route", "sql", "test", "docs", "ops", "note"],
        help="Event kind",
    )
    ap.add_argument("--title", help="Short headline")
    ap.add_argument("--summary", default="", help="One-line what happened")
    ap.add_argument("--detail", default="", help="Longer explanation / SQL / log excerpt")
    ap.add_argument("--rationale", default="", help="Why this tactic / choice")
    ap.add_argument("--alternative", action="append", default=[], help="Rejected alternative (repeatable)")
    ap.add_argument("--route-id", default="", help="Route slug when kind=route")
    ap.add_argument("--replay-step", default="", help="build-replay step id e.g. 0003")
    ap.add_argument("--link", action="append", default=[], help="label|href (repeatable)")
    ap.add_argument("--status-message", default="", help="Also update build-status.json message")
    args = ap.parse_args()

    root = require_demo(args.root)
    docs = root / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    path = docs / "build-experience.json"

    if args.clear:
        data = {
            "version": 1,
            "title": "Interface construction experience",
            "demo": root.name,
            "events": [],
            "updated_at": utc_now(),
        }
        path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        print(path)
        return 0

    if not args.kind or not args.title:
        ap.error("--kind and --title are required unless --clear")

    data = load(path)
    data["demo"] = root.name
    events = list(data.get("events") or [])
    links = []
    for raw in args.link:
        if "|" in raw:
            label, href = raw.split("|", 1)
            links.append({"label": label.strip(), "href": href.strip()})
        elif raw.strip():
            links.append({"label": raw.strip(), "href": raw.strip()})

    event = {
        "id": next_id(events),
        "kind": args.kind,
        "title": args.title,
        "summary": args.summary,
        "detail": args.detail,
        "rationale": args.rationale,
        "at": utc_now(),
    }
    if args.alternative:
        event["alternatives"] = args.alternative
    if args.route_id:
        event["route_id"] = args.route_id
    if args.replay_step:
        event["replay_step"] = args.replay_step
    if links:
        event["links"] = links

    events.append(event)
    data["events"] = events
    data["updated_at"] = utc_now()
    data["version"] = 1
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(path)
    print(json.dumps(event, indent=2))

    if args.status_message:
        status_path = docs / "build-status.json"
        status = {"version": 1, "active": True, "phase": "routes", "routes_ready": []}
        if status_path.is_file():
            try:
                loaded = json.loads(status_path.read_text(encoding="utf-8"))
                if isinstance(loaded, dict):
                    status.update(loaded)
            except json.JSONDecodeError:
                pass
        status["active"] = True
        status["message"] = args.status_message
        status["updated_at"] = utc_now()
        status_path.write_text(json.dumps(status, indent=2) + "\n", encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
