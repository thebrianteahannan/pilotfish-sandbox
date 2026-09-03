#!/usr/bin/env python3
"""Export a Construction Replay shooting-script PDF (and plain-text twin).

Timecode, where to click in eiConsole, then the spoken line — the same
beats an actor (or the construction video) would play.

  documents/construction-replay-transcript.pdf
  documents/construction-replay-transcript.txt

Usage:
  python3 tools/export_construction_transcript_pdf.py --root Clients/Demos/csv-sftp-to-sql
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

from demo_paths import require_demo
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import KeepTogether, Paragraph, SimpleDocTemplate, Spacer

# Route-grid columns in the eiConsole main table (RoutingSource row).
GRID = {
    0: "Source System",
    1: "Listener",
    2: "Source Transform",
    3: "Routing",
    4: "Target Transform",
    5: "Transport",
}


def esc(s: str) -> str:
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def clean(s: str) -> str:
    t = (s or "").strip()
    t = t.replace("\u201c", '"').replace("\u201d", '"').replace("\u2019", "'")
    t = t.replace("\u2014", " — ").replace("\u2192", " to ")
    return re.sub(r"\s+", " ", t).strip()


def _design_title(demo: Path) -> str:
    design = demo / "DESIGN.md"
    if design.is_file():
        for line in design.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("# "):
                return line[2:].strip()
    return ""


def _now_label() -> str:
    now = datetime.now()
    return f"{now:%A, %B} {now.day}, {now:%Y}"


def fmt_clock(ms: int) -> str:
    s = max(0, int(ms) // 1000)
    return f"{s // 60}:{s % 60:02d}"


def beat_ms(text: str, dwell_ms: int = 0) -> int:
    """Match construction video pacing: AvaNeural ~-10%, then 180 ms pad."""
    words = len((text or "").split())
    if words:
        speech = int(words / 2.4 * 1000)
        return max(speech + 180, int(dwell_ms or 0), 500)
    return max(int(dwell_ms or 0), 200)


def _inline_map(raw: str) -> dict:
    raw = raw.strip()
    if raw.startswith("{") and raw.endswith("}"):
        raw = raw[1:-1]
    out: dict = {}
    for key, val in re.findall(r'(\w+)\s*:\s*("(?:[^"\\]|\\.)*"|[^\s,]+)', raw):
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        out[key] = int(val) if key == "column" else val
    return out


def _parse_walkthrough(text: str) -> list[dict]:
    steps: list[dict] = []
    current: dict | None = None
    for line in text.splitlines():
        if re.match(r"^\s*-\s+id:", line):
            if current:
                steps.append(current)
            current = {"id": line.split(":", 1)[1].strip()}
            continue
        if current is None:
            continue
        stripped = line.strip()
        if stripped.startswith("action:"):
            current["action"] = stripped.split(":", 1)[1].strip()
        elif stripped.startswith("detail:"):
            val = stripped.split(":", 1)[1].strip()
            if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
                val = val[1:-1]
            current["detail"] = val
        elif stripped.startswith("dwell_ms:"):
            current["dwell_ms"] = int(stripped.split(":", 1)[1].strip())
        elif stripped.startswith("target:"):
            current["target"] = _inline_map(stripped.split(":", 1)[1])
    if current:
        steps.append(current)
    return steps


def load_eiconsole_steps(demo: Path) -> list[dict] | None:
    path = demo / "documents" / "eiconsole-walkthrough.yaml"
    if not path.is_file():
        return None
    raw_steps: list[dict] = []
    try:
        import yaml  # type: ignore

        raw = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        if isinstance(raw, dict):
            raw_steps = [s for s in (raw.get("steps") or []) if isinstance(s, dict)]
    except Exception:
        raw_steps = []
    if not raw_steps:
        raw_steps = _parse_walkthrough(path.read_text(encoding="utf-8"))
    if not raw_steps:
        return None
    for step in raw_steps:
        step["eiconsole"] = True
    try:
        from construction_official_open import open_intro_line

        raw_steps.insert(
            0,
            {
                "id": "open-intro",
                "action": "open_card",
                "detail": open_intro_line(demo),
                "eiconsole": True,
            },
        )
    except Exception:
        pass
    return raw_steps


def load_steps(demo: Path) -> tuple[list[dict], str, dict]:
    eco = load_eiconsole_steps(demo)
    if eco:
        return eco, _design_title(demo) or demo.name, {"eiconsole": True}

    manifest = demo / "documents" / "build-replay" / "manifest.json"
    if not manifest.is_file():
        raise SystemExit(f"Missing {manifest}")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    steps = data.get("steps") if isinstance(data, dict) else []
    if not isinstance(steps, list):
        steps = []
    title = _design_title(demo)
    if not title and isinstance(data, dict):
        title = str(data.get("title") or "")
    return steps, title or demo.name, data if isinstance(data, dict) else {}


def load_video_extras(demo: Path) -> dict:
    live_test = demo / "documents" / "construction-demo-test.json"
    live_steps: list[dict] = []
    preamble_steps: list[dict] = []
    outro_steps: list[dict] = []
    if live_test.is_file():
        try:
            live = json.loads(live_test.read_text(encoding="utf-8"))
            live_steps = [s for s in (live.get("steps") or []) if isinstance(s, dict)]
            preamble_steps = [s for s in (live.get("preamble") or []) if isinstance(s, dict)]
            outro_steps = [s for s in (live.get("outro") or []) if isinstance(s, dict)]
        except json.JSONDecodeError:
            live_steps = []
    return {
        "live_test_steps": live_steps,
        "preamble_steps": preamble_steps,
        "outro_steps": outro_steps,
    }


def step_transcript(step: dict) -> str:
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_narration_naturalize import naturalize_spoken

    detail = clean(str(step.get("detail") or ""))
    message = clean(str(step.get("message") or ""))
    # Official YouTube / website-verbatim walkthroughs keep spoken copy as written.
    if not step.get("eiconsole"):
        detail = naturalize_spoken(detail)
        message = naturalize_spoken(message)
    return detail or message


def describe_click(step: dict, last_place: str) -> tuple[str, str]:
    """Return (place, cue). Empty cue = hold / automation wait."""
    action = str(step.get("action") or "")
    tgt = step.get("target") if isinstance(step.get("target"), dict) else {}
    typ = str(tgt.get("type") or "")
    label = str(tgt.get("contains") or tgt.get("text") or "").strip()
    col = tgt.get("column")

    if not action and not tgt:
        route = clean(str(step.get("route_name") or ""))
        focus = clean(str(step.get("focus_label") or step.get("module_type") or ""))
        place = focus or route or last_place
        if route and focus:
            return place, f"{route} — {focus}"
        return place, focus or route

    if action == "open_card":
        return "Opening", "Official open cards"

    if typ == "JMenu" or (action == "wait_for" and label == "File"):
        return last_place, ""

    if typ == "tab" and label:
        return last_place or label, f"Click the {label} tab"

    if col is not None and "RoutingSource" in label:
        place = GRID.get(int(col), f"column {col}")
        return place, f"Route grid — click the {place} column"

    verb = "Double-click" if action == "double_click" else "Click"
    if typ == "table" and label:
        if action == "double_click":
            if label[:1].isdigit() or " - " in label:
                return "Route grid", f'Double-click route “{label}”'
            return "Route File Management", f'Double-click package “{label}”'
        return last_place or label, f'{verb} “{label}”'

    if label == "XSLT":
        return "Data Mapper", "Open the Data Mapper"
    if "Listener Type" in label:
        return "Listener", "Click Listener Type"
    if "Transformation Module" in label:
        return last_place or "Source Transform", "Click Transformation Module"
    if label:
        return last_place or label, f"{verb} {label}"
    return last_place, ""


def place_from_line(line: str, place: str) -> str:
    low = line.lower()
    if any(k in low for k in ("testing mode", "execute test", "question marks", "pre-saved")):
        return "Testing Mode"
    return place


def script_beats(steps: list[dict], extras: dict) -> list[dict]:
    ordered: list[tuple[str, dict]] = []
    for step in extras.get("preamble_steps") or []:
        ordered.append(("Opening", step))
    for step in steps:
        ordered.append(("", step))
    for step in extras.get("live_test_steps") or []:
        ordered.append(("Demo tab", step))
    for step in extras.get("outro_steps") or []:
        ordered.append(("Close", step))

    beats: list[dict] = []
    pending: list[str] = []
    pending_ms = 0
    place = "Route File Management"
    t = 0
    for fallback, step in ordered:
        line = step_transcript(step)
        new_place, cue = describe_click(step, place)
        if fallback and not cue:
            cue = fallback
            new_place = fallback
        if new_place:
            place = new_place
        dwell = int(step.get("dwell_ms") or 0)
        if line:
            place = place_from_line(line, place)
            cues = list(pending)
            if cue:
                cues.append(cue)
            pending = []
            start = t
            t += pending_ms
            pending_ms = 0
            if not cues:
                cues = [f"Hold — {place}" if place else "Hold on this screen"]
            dur = beat_ms(line, dwell)
            beats.append(
                {"start": start, "end": t + dur, "cues": cues, "line": line, "place": place}
            )
            t += dur
        elif cue:
            pending.append(cue)
            pending_ms += beat_ms("", dwell)
    if pending:
        beats.append(
            {
                "start": t,
                "end": t + max(pending_ms, 200),
                "cues": pending,
                "line": "",
                "place": place,
            }
        )
    return beats


def build_plain_text(title: str, when: str, beats: list[dict]) -> str:
    runtime = fmt_clock(beats[-1]["end"]) if beats else "0:00"
    lines = [
        "Construction Replay Transcript",
        title,
        f"{when}  ·  running time {runtime}",
        "Shooting script: timecode, where to click in eiConsole, then the spoken line.",
        "",
    ]
    for beat in beats:
        clock = f"{fmt_clock(beat['start'])} – {fmt_clock(beat['end'])}"
        lines.append(clock)
        for cue in beat.get("cues") or []:
            lines.append(f"[{cue}]")
        if beat.get("line"):
            lines.append(beat["line"])
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def _footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#4b5568"))
    canvas.drawString(0.75 * inch, 0.42 * inch, "PilotFish  ·  Construction Replay Transcript")
    canvas.drawRightString(letter[0] - 0.75 * inch, 0.42 * inch, str(doc.page))
    canvas.restoreState()


def build_pdf(title: str, when: str, beats: list[dict], out_path: Path) -> Path:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    base = getSampleStyleSheet()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    muted = colors.HexColor("#4b5568")
    styles = {
        "brand": ParagraphStyle(
            "brand", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9, textColor=green
        ),
        "title": ParagraphStyle(
            "title",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=18,
            textColor=ink,
            spaceAfter=4,
        ),
        "sub": ParagraphStyle(
            "sub", parent=base["Normal"], fontSize=10.5, textColor=muted, spaceAfter=6
        ),
        "note": ParagraphStyle(
            "note",
            parent=base["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=9,
            textColor=muted,
            spaceAfter=12,
        ),
        "time": ParagraphStyle(
            "time",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=10,
            textColor=green,
            spaceBefore=8,
            spaceAfter=2,
        ),
        "cue": ParagraphStyle(
            "cue",
            parent=base["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=10,
            textColor=muted,
            spaceAfter=2,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["Normal"],
            fontSize=10.5,
            leading=14,
            alignment=TA_LEFT,
            textColor=ink,
            spaceAfter=4,
        ),
    }
    runtime = fmt_clock(beats[-1]["end"]) if beats else "0:00"
    story = [
        Paragraph("PILOTFISH", styles["brand"]),
        Paragraph("Construction Replay Transcript", styles["title"]),
        Paragraph(f"{esc(title)}  ·  {esc(when)}  ·  running time {runtime}", styles["sub"]),
        Paragraph(
            "Shooting script: timecode, where to click in eiConsole, then the spoken line.",
            styles["note"],
        ),
    ]
    for beat in beats:
        clock = f"{fmt_clock(beat['start'])} – {fmt_clock(beat['end'])}"
        chunk = [Paragraph(esc(clock), styles["time"])]
        for cue in beat.get("cues") or []:
            chunk.append(Paragraph(f"[{esc(cue)}]", styles["cue"]))
        if beat.get("line"):
            chunk.append(Paragraph(esc(beat["line"]), styles["body"]))
        chunk.append(Spacer(1, 0.06 * inch))
        story.append(KeepTogether(chunk))

    doc = SimpleDocTemplate(
        str(out_path),
        pagesize=letter,
        leftMargin=0.8 * inch,
        rightMargin=0.8 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.7 * inch,
        title=f"Construction Replay Transcript — {title}",
        author="PilotFish Sandbox",
    )
    doc.build(story, onFirstPage=_footer, onLaterPages=_footer)
    return out_path


def export(demo: Path, *, out_pdf: Path | None = None, out_txt: Path | None = None) -> tuple[Path, Path]:
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_narration_naturalize import naturalize_demo_root, naturalize_spoken

    counts = naturalize_demo_root(demo)
    if counts.get("manifest") or counts.get("demo_test"):
        print(
            f"Naturalized narration: manifest={counts['manifest']}, "
            f"demo-test={counts['demo_test']}"
        )

    steps, title, manifest = load_steps(demo)
    if not steps:
        raise SystemExit(f"No narration steps under {demo / 'documents'}")
    extras = load_video_extras(demo)
    if manifest.get("eiconsole"):
        extras = {"preamble_steps": [], "live_test_steps": [], "outro_steps": []}
    for key in ("preamble_steps", "live_test_steps", "outro_steps"):
        for step in extras.get(key) or []:
            if isinstance(step, dict):
                for field in ("detail", "text", "message"):
                    if step.get(field):
                        step[field] = naturalize_spoken(str(step[field]))
    beats = script_beats(steps, extras)
    docs = demo / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    pdf_path = out_pdf or (docs / "construction-replay-transcript.pdf")
    txt_path = out_txt or (docs / "construction-replay-transcript.txt")
    when = _now_label()
    txt_path.write_text(build_plain_text(title, when, beats), encoding="utf-8")
    build_pdf(title, when, beats, pdf_path)
    return pdf_path, txt_path


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="Demo root under Clients/Demos/")
    ap.add_argument("--out", help="PDF output path")
    ap.add_argument("--out-txt", help="Plain-text twin path")
    args = ap.parse_args()
    demo = require_demo(args.root)
    pdf_path = Path(args.out).expanduser().resolve() if args.out else None
    txt_path = Path(args.out_txt).expanduser().resolve() if args.out_txt else None
    pdf, txt = export(demo, out_pdf=pdf_path, out_txt=txt_path)
    print(pdf)
    print(txt)
    print(f"PDF size: {pdf.stat().st_size // 1024} KB · {txt.name} written")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
