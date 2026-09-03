#!/usr/bin/env python3
"""Naturalize construction-replay spoken copy (demo-presenter voice).

Always run this before shipping construction-replay.mp4 or
construction-replay-transcript.{pdf,txt}. Wired into:

  - tools/export_construction_transcript_pdf.py
  - tools/export_construction_video.py
  - tools/record_module_replay.py (optional in-process)

CLI (rewrite demo artifacts in place, then re-export transcript):

  python3 tools/construction_narration_naturalize.py --root Clients/Demos/csv-sftp-to-sql
  python3 tools/construction_narration_naturalize.py --root Clients/Demos/csv-sftp-to-sql --export-transcript
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from demo_paths import require_demo
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Exact / near-exact awkward lines → natural replacements (apply first).
CREATE_IFACE_NATURAL = (
    "Here is a blank canvas, so let's get started creating the new PilotFish interface."
)
EXACT_REPLACEMENTS: list[tuple[str, str]] = [
    (
        "We'll start from scratch. Click Create New PilotFish Interface — empty canvas, ready to build.",
        CREATE_IFACE_NATURAL,
    ),
    (
        "Alright — blank slate. I'll create a new PilotFish Interface so we start with an empty canvas.",
        CREATE_IFACE_NATURAL,
    ),
    (
        "Alright — blank slate. I'll create a new PilotFish interface so we start with an empty canvas.",
        CREATE_IFACE_NATURAL,
    ),
    (
        "Next I'll create a new interface — empty canvas, nothing on it yet.",
        CREATE_IFACE_NATURAL,
    ),
    (
        "Why this demo? So ops can drop a patient CSV and get rows in the database "
        "without anyone hand-loading the data. We'll build that in two routes — pickup first, then the load.",
        "Ops drops a patient CSV and we land the rows in the database — no hand-loading. "
        "Two routes: pickup first, then the load.",
    ),
    (
        "Now the CSV processor. Stock module — turns the file into XML and uses the header row for column names. No custom code here.",
        "Here's the CSV processor — it turns the file into XML and uses the header row for the column names.",
    ),
    (
        "Here's the CSV processor — a stock PilotFish module that turns the file into XML "
        "and uses the header row for the column names. No custom code.",
        "Here's the CSV processor — it turns the file into XML and uses the header row for the column names.",
    ),
    (
        "Here's the CSV processor — a stock PilotFish module that turns the file into XML and uses the header row for the column names. No custom code.",
        "Here's the CSV processor — it turns the file into XML and uses the header row for the column names.",
    ),
    (
        "Now the mapping step — I'll open the custom stylesheet. Stock XSLT processor; the interesting part is csv-to-sqlxml.xslt. Watch the for-each over each CSV record, and the column mappings — Dialect A tags like PATIENTID into the SQL insert fields. STATE becomes StateCode.",
        "Now for the mapping — I'll open the stylesheet. We're using the stock XSLT processor with csv-to-sqlxml.xslt. "
        "Watch the for-each over each CSV record and the column mappings: "
        "Dialect A tags like PATIENTID into the SQL insert fields, and STATE becomes StateCode.",
    ),
    (
        "And finally, the SQL insert. Run those inserts into the demo database over JDBC. That's it — CSV in, patients in SQL.",
        "And finally we insert into SQL — those inserts go into the demo database over JDBC. "
        "That's it: CSV in, patients in SQL.",
    ),
]

# Regex rewrites applied in order (display / transcript prose).
REGEX_REPLACEMENTS: list[tuple[str, str, int]] = [
    (r"\bSFTP\b", "FTP", 0),
    (r"\bSftp\b", "FTP", 0),
    (
        r"All of that is Docker for the demo\.?",
        "All of those are spun up in docker images for this demo.",
        re.I,
    ),
    # Formal “Click X — …” UI chrome
    (
        r"Click Create New PilotFish Interface\s*[—\-–]\s*empty canvas,?\s*ready to build\.?",
        CREATE_IFACE_NATURAL,
        re.I,
    ),
    (
        r"We'll start from scratch\.\s*",
        "",
        re.I,
    ),
    (
        r"Alright\s*[—\-–]\s*blank slate\.\s*I'll create a new PilotFish interface so we start with an empty canvas\.?",
        CREATE_IFACE_NATURAL,
        re.I,
    ),
    (
        r"Next I'll create a new interface\s*[—\-–]\s*empty canvas,?\s*nothing on it yet\.?",
        CREATE_IFACE_NATURAL,
        re.I,
    ),
    (
        r"^Create New Interface$",
        "Blank canvas",
        re.I,
    ),
    (
        r"^New interface$",
        "Blank canvas",
        re.I,
    ),
    (
        r"Module documentation for this step:.*$",
        "",
        re.I | re.M,
    ),
    (
        r"empty canvas\s*[—\-–]\s*starting from nothing",
        "empty canvas",
        re.I,
    ),
    (
        r"Construction is done\.\s*Let's switch to the Demo tab and prove the interface actually works\.",
        "Routes are built. Let's switch to the Demo tab and prove it works.",
        re.I,
    ),
    (
        r"It's set up for\s+",
        "",
        re.I,
    ),
    (
        r"Configured for\s+",
        "",
        re.I,
    ),
    (
        r"\bDecision\s+[—\-–]\s*",
        "",
        re.I,
    ),
    # No live audience — drop rhetorical setup questions
    (
        r"Why this demo\?\s*So ops can drop a patient CSV and get rows in the database without anyone hand-loading the data\.\s*"
        r"We'll build that in two routes\s*[—\-–]\s*pickup first, then the load\.",
        "Ops drops a patient CSV and we land the rows in the database — no hand-loading. "
        "Two routes: pickup first, then the load.",
        re.I,
    ),
    (
        r"Why this demo\?\s*So\s+",
        "",
        re.I,
    ),
    (
        r"Why this demo\?\s*",
        "",
        re.I,
    ),
    (
        r"Why (?:are we|do we) (?:here|building this|doing this)\?\s*",
        "",
        re.I,
    ),
    (
        r"We'll build that in two routes\s*[—\-–]\s*",
        "Two routes: ",
        re.I,
    ),
    # Choppy catalog fragments → spoken sentences
    (
        r"Now the CSV processor\.\s*Stock module\s*[—\-–]\s*turns the file into XML and uses the header row for column names\.\s*No custom code here\.",
        "Here's the CSV processor — it turns the file into XML and uses the header row for the column names.",
        re.I,
    ),
    (
        r"Here's the CSV processor\s*[—\-–]\s*a stock PilotFish module that turns the file into XML and uses the header row for the column names\.\s*No custom code\.",
        "Here's the CSV processor — it turns the file into XML and uses the header row for the column names.",
        re.I,
    ),
    (
        r"\s*No custom code(?: here)?\.",
        "",
        re.I,
    ),
    (
        r"Stock module\s*[—\-–]\s*",
        "It's a stock module that ",
        re.I,
    ),
    (
        r"Stock XSLT processor;\s*the interesting part is\s+",
        "We're using the stock XSLT processor with ",
        re.I,
    ),
    (
        r"Now the mapping step\s*[—\-–]\s*I'll open the custom stylesheet\.",
        "Now for the mapping — I'll open the stylesheet.",
        re.I,
    ),
    (
        r"And finally,\s*the SQL insert\.\s*Run those inserts into",
        "And finally we insert into SQL — those inserts go into",
        re.I,
    ),
    (
        r"Now the load route\.\s*This one never talks to FTP\.",
        "Onto the load route — this one never talks to FTP.",
        re.I,
    ),
    (
        r"First up:\s*the FTP listener\.\s*It watches",
        "First up is the FTP listener — it watches",
        re.I,
    ),
    (
        r"Next:\s*the staged-folder listener\.\s*It never talks to FTP\s*[—\-–]\s*just the local stage\.",
        "Next is the staged-folder listener — it never talks to FTP, just the local stage.",
        re.I,
    ),
    (
        r"Then we archive the raw file\.\s*Before we touch the data,\s*keep an exact copy of whatever arrived\.",
        "Next we archive the raw file — an exact copy of whatever arrived, before we touch the data.",
        re.I,
    ),
]


def naturalize_spoken(text: str) -> str:
    """Rewrite a spoken/demo line into natural presenter voice."""
    t = (text or "").strip()
    if not t:
        return t
    for old, new in EXACT_REPLACEMENTS:
        if t == old or t.strip() == old.strip():
            t = new
            break
    for pattern, repl, flags in REGEX_REPLACEMENTS:
        t = re.sub(pattern, repl, t, flags=flags)
    # Collapse whitespace / duplicate spaces after removals
    t = re.sub(r"[ \t]{2,}", " ", t)
    t = re.sub(r"\n{3,}", "\n\n", t)
    # Only collapse "word ." sentence endings — never " .csv" / " .xml"
    t = re.sub(r"\s+\.(?=\s|$)", ".", t)
    # Repair accidental glued extensions from older naturalize runs
    t = re.sub(
        r"\b(then|taking|only|timestamp,)\.(csv|xml|xslt|json|pdf)\b",
        r"\1 .\2",
        t,
        flags=re.I,
    )
    t = t.strip()
    # Capitalize if we stripped a leading sentence
    if t and t[0].islower():
        t = t[0].upper() + t[1:]
    return t


def naturalize_message(text: str) -> str:
    """Short step titles — keep human, drop formal route chrome."""
    t = (text or "").strip()
    t = re.sub(r"^Create New Interface$", "Blank canvas", t, flags=re.I)
    t = re.sub(r"^New interface$", "Blank canvas", t, flags=re.I)
    t = re.sub(r"^OGNL\s*[—\-–].*$", "What OGNL is", t, flags=re.I)
    t = naturalize_spoken(t)
    return t.strip()


def _naturalize_step_dict(step: dict, *, detail_keys: tuple[str, ...] = ("detail", "text")) -> dict:
    out = dict(step)
    if "message" in out and out["message"]:
        out["message"] = naturalize_message(str(out["message"]))
    for k in detail_keys:
        if k in out and out[k]:
            out[k] = naturalize_spoken(str(out[k]))
    return out


def naturalize_manifest(path: Path) -> int:
    """Rewrite detail/message on build-replay/manifest.json. Returns changed count."""
    if not path.is_file():
        return 0
    data = json.loads(path.read_text(encoding="utf-8"))
    steps = data.get("steps") if isinstance(data, dict) else None
    if not isinstance(steps, list):
        return 0
    changed = 0
    new_steps = []
    for step in steps:
        if not isinstance(step, dict):
            new_steps.append(step)
            continue
        nxt = _naturalize_step_dict(step)
        if nxt.get("detail") != step.get("detail") or nxt.get("message") != step.get("message"):
            changed += 1
        new_steps.append(nxt)
    data["steps"] = new_steps
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return changed


def naturalize_demo_test_json(path: Path) -> int:
    """Rewrite preamble / live-test / outro spoken lines."""
    if not path.is_file():
        return 0
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        return 0
    changed = 0
    for key in ("preamble", "steps", "outro"):
        items = data.get(key)
        if not isinstance(items, list):
            continue
        new_items = []
        for step in items:
            if not isinstance(step, dict):
                new_items.append(step)
                continue
            nxt = _naturalize_step_dict(step)
            if (
                nxt.get("detail") != step.get("detail")
                or nxt.get("message") != step.get("message")
                or nxt.get("text") != step.get("text")
            ):
                changed += 1
            new_items.append(nxt)
        data[key] = new_items
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return changed


def naturalize_eiconsole_yaml(path: Path) -> int:
    """Rewrite spoken detail lines on eiconsole-walkthrough.yaml."""
    if not path.is_file():
        return 0
    head = path.read_text(encoding="utf-8")[:600]
    if "source of truth" in head.lower() or "Do not run generate_eiconsole_walkthrough" in head:
        return 0
    try:
        import yaml  # type: ignore
    except ImportError:
        return 0
    raw = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(raw, dict):
        return 0
    steps = raw.get("steps")
    if not isinstance(steps, list):
        return 0
    changed = 0
    new_steps = []
    for step in steps:
        if not isinstance(step, dict):
            new_steps.append(step)
            continue
        nxt = dict(step)
        detail = nxt.get("detail")
        if isinstance(detail, str) and detail.strip():
            spoken = naturalize_spoken(detail)
            if spoken != detail:
                nxt["detail"] = spoken
                changed += 1
        new_steps.append(nxt)
    if changed:
        raw["steps"] = new_steps
        path.write_text(
            yaml.safe_dump(raw, sort_keys=False, allow_unicode=True),
            encoding="utf-8",
        )
    return changed


def naturalize_demo_root(demo: Path) -> dict[str, int]:
    docs = demo / "documents"
    return {
        "manifest": naturalize_manifest(docs / "build-replay" / "manifest.json"),
        "demo_test": naturalize_demo_test_json(docs / "construction-demo-test.json"),
        "eiconsole": naturalize_eiconsole_yaml(docs / "eiconsole-walkthrough.yaml"),
    }


def export_transcript(demo: Path) -> int:
    script = Path(__file__).resolve().parent / "export_construction_transcript_pdf.py"
    proc = subprocess.run(
        [sys.executable, str(script), "--root", str(demo)],
        cwd=str(ROOT),
    )
    return int(proc.returncode)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", help="Demo root under Clients/Demos/")
    ap.add_argument(
        "--export-transcript",
        action="store_true",
        help="After rewriting JSON, regenerate construction-replay-transcript PDF/TXT",
    )
    ap.add_argument(
        "--text",
        help="Naturalize a single string and print it (smoke test)",
    )
    args = ap.parse_args()
    if args.text is not None:
        print(naturalize_spoken(args.text))
        return 0
    if not args.root:
        ap.error("--root is required unless --text is set")
    demo = require_demo(args.root)
    counts = naturalize_demo_root(demo)
    print(
        f"Naturalized {demo.name}: "
        f"manifest steps changed={counts['manifest']}, "
        f"demo-test lines changed={counts['demo_test']}, "
        f"eiconsole lines changed={counts.get('eiconsole', 0)}"
    )
    if args.export_transcript:
        rc = export_transcript(demo)
        if rc != 0:
            return rc
        print(demo / "documents" / "construction-replay-transcript.pdf")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
