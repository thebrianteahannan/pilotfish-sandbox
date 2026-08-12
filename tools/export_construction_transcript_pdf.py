#!/usr/bin/env python3
"""Export a Construction Replay transcript PDF (and plain-text twin).

Reads documents/build-replay/manifest.json plus the interface documentation
package (DESIGN.md, capability brief, test plan, module-docs) and writes:

  documents/construction-replay-transcript.pdf
  documents/construction-replay-transcript.txt

The PDF is the readable companion to construction-replay.mp4 for people who
cannot watch the video. It also frames who the interface is for and which
review documents the construction produces.

Usage:
  python3 tools/export_construction_transcript_pdf.py --root Clients/Demos/csv-sftp-to-sql
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer


def esc(s: str) -> str:
    return (
        str(s)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def clean(s: str) -> str:
    t = (s or "").strip()
    t = t.replace("\u201c", '"').replace("\u201d", '"').replace("\u2019", "'")
    t = t.replace("\u2014", " — ").replace("\u2192", " to ")
    t = re.sub(r"\s+", " ", t).strip()
    return t


def strip_md(s: str) -> str:
    t = clean(s)
    t = re.sub(r"\*\*([^*]+)\*\*", r"\1", t)
    t = re.sub(r"`([^`]+)`", r"\1", t)
    t = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", t)
    return t


def parse_design_sections(design_text: str) -> dict[str, str]:
    """Map lowercase section title → body text from DESIGN.md."""
    sections: dict[str, str] = {}
    current = ""
    buf: list[str] = []
    for line in design_text.splitlines():
        m = re.match(r"^#{1,3}\s+(?:\d+\.\s*)?(.+)$", line)
        if m:
            if current:
                sections[current] = "\n".join(buf).strip()
            current = m.group(1).strip().lower()
            buf = []
        else:
            buf.append(line)
    if current:
        sections[current] = "\n".join(buf).strip()
    return sections


def section_match(sections: dict[str, str], *needles: str) -> str:
    for key, body in sections.items():
        if any(n in key for n in needles):
            return body
    return ""


def bullets_from_md(body: str) -> list[str]:
    items: list[str] = []
    for line in body.splitlines():
        m = re.match(r"^\s*[-*]\s+(.+)$", line)
        if m:
            items.append(strip_md(m.group(1)))
    return items


def first_paragraph(body: str) -> str:
    parts = re.split(r"\n\s*\n", body.strip())
    for p in parts:
        p = strip_md(p)
        if p and not p.startswith("|") and not p.startswith("#"):
            # drop table-only chunks
            if p.startswith("- ") or p.startswith("* "):
                continue
            return p
    return ""


def load_steps(demo: Path) -> tuple[list[dict], str, dict]:
    manifest = demo / "documents" / "build-replay" / "manifest.json"
    if not manifest.is_file():
        raise SystemExit(f"Missing {manifest}")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    steps = data.get("steps") if isinstance(data, dict) else []
    if not isinstance(steps, list):
        steps = []
    title = ""
    design = demo / "DESIGN.md"
    if design.is_file():
        for line in design.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("# "):
                title = line[2:].strip()
                break
    if not title and isinstance(data, dict):
        title = str(data.get("title") or "")
    return steps, title or demo.name, data if isinstance(data, dict) else {}


def discover_docs(demo: Path) -> dict:
    """Collect companion documentation this interface builds / ships."""
    docs = demo / "documents"
    design_path = demo / "DESIGN.md"
    design_text = design_path.read_text(encoding="utf-8", errors="replace") if design_path.is_file() else ""
    sections = parse_design_sections(design_text) if design_text else {}

    purpose = first_paragraph(section_match(sections, "purpose", "business goal", "goal"))
    # Spoken/demo wording prefers FTP over SFTP in human-facing transcript prose
    if purpose:
        purpose = re.sub(r"\bSFTP\b", "FTP", purpose)
        purpose = re.sub(r"\bSftp\b", "FTP", purpose)
    system_actors = bullets_from_md(section_match(sections, "actor", "system", "context"))
    system_actors = [
        re.sub(r"\bSftp\b", "FTP", re.sub(r"\bSFTP\b", "FTP", s)) for s in system_actors
    ]
    audiences = [
        "Ops and trading partners dropping CSV files on FTP",
        "Stakeholders who want the Capability Brief, not route XML",
        "Engineers running the Test Plan against the Demo UI and SQL",
        "Anyone watching the construction video or reading this transcript",
    ]
    # Keep concrete systems from DESIGN as context under "connected systems"
    actors = audiences
    if system_actors:
        # Prefer human-facing audience list; systems listed separately in companions/purpose
        pass

    # Capability brief
    brief = None
    for pattern in ("*_Capability_Brief.pdf", "*_capability_brief.pdf"):
        hits = sorted(docs.glob(pattern)) if docs.is_dir() else []
        if hits:
            brief = hits[0]
            break
    if brief is None and docs.is_dir():
        for name in ("capability-brief.pdf", "Capability_Brief.pdf"):
            p = docs / name
            if p.is_file():
                brief = p
                break

    # Test plan
    test_plan_pdf = None
    for pattern in ("*_Test_Plan.pdf", "*_test_plan.pdf"):
        hits = sorted(docs.glob(pattern)) if docs.is_dir() else []
        if hits:
            test_plan_pdf = hits[0]
            break
    if test_plan_pdf is None and (docs / "test-plan.pdf").is_file():
        test_plan_pdf = docs / "test-plan.pdf"

    plan_json = demo / "tests" / "plan.json"
    plan_meta: dict = {}
    if plan_json.is_file():
        try:
            plan_meta = json.loads(plan_json.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            plan_meta = {}
    case_count = len(plan_meta.get("cases") or []) if isinstance(plan_meta, dict) else 0
    plan_desc = ""
    if isinstance(plan_meta, dict):
        plan_desc = clean(str(plan_meta.get("description") or plan_meta.get("interface") or ""))

    # Module docs
    mod_manifest = docs / "module-docs" / "manifest.json"
    modules: list[dict] = []
    if mod_manifest.is_file():
        try:
            mdata = json.loads(mod_manifest.read_text(encoding="utf-8"))
            modules = [m for m in (mdata.get("modules") or []) if isinstance(m, dict)]
        except json.JSONDecodeError:
            modules = []

    route_pdf = None
    if docs.is_dir():
        hits = sorted(docs.glob("*_V2_Route_Diagrams.pdf"))
        if hits:
            route_pdf = hits[0]
        elif (docs / "route-diagrams.pdf").is_file():
            route_pdf = docs / "route-diagrams.pdf"

    companions: list[dict] = []
    companions.append(
        {
            "name": brief.name if brief else "Capability Brief PDF (generate with tools/export_stakeholder_brief.py)",
            "exists": brief is not None,
            "role": "Short overview of what the interface does — shareable without reading route XML.",
            "path": str(brief.relative_to(demo)) if brief else "documents/*_Capability_Brief.pdf",
        }
    )
    companions.append(
        {
            "name": test_plan_pdf.name if test_plan_pdf else "Test Plan PDF (from tests/plan.json)",
            "exists": test_plan_pdf is not None,
            "role": (
                "Scenarios that prove the interface works end-to-end"
                + (f" ({case_count} cases in tests/plan.json)" if case_count else "")
                + "."
            ),
            "path": str(test_plan_pdf.relative_to(demo)) if test_plan_pdf else "documents/*_Test_Plan.pdf",
        }
    )
    if modules:
        companions.append(
            {
                "name": f"Module documentation pack ({len(modules)} deep-dive PDFs)",
                "exists": True,
                "role": "PilotFish product PDFs for the modules used in this build.",
                "path": "documents/module-docs/",
                "modules": modules,
            }
        )
    if route_pdf:
        companions.append(
            {
                "name": route_pdf.name,
                "exists": True,
                "role": "V2 route diagrams for visual review of module topology.",
                "path": str(route_pdf.relative_to(demo)),
            }
        )
    companions.append(
        {
            "name": "construction-replay.mp4 + this transcript",
            "exists": (docs / "construction-replay.mp4").is_file(),
            "role": "Narrated walkthrough of building the routes, then a live inject → SQL smoke test.",
            "path": "documents/construction-replay.mp4",
        }
    )

    live_test = docs / "construction-demo-test.json"
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
        "purpose": purpose
        or f"{demo.name} is a PilotFish Sandbox interface. See DESIGN.md for the working purpose.",
        "actors": actors,
        "systems": system_actors,
        "companions": companions,
        "modules": modules,
        "live_test_steps": live_steps,
        "preamble_steps": preamble_steps,
        "outro_steps": outro_steps,
        "design_path": "DESIGN.md" if design_path.is_file() else "",
    }


def module_doc_for_step(step: dict, modules: list[dict]) -> str | None:
    """Best-effort link from a replay step to a synced module deep-dive."""
    if not modules:
        return None
    type_name = clean(str(step.get("module_type") or "")).lower()
    tag = clean(str(step.get("module_tag") or "")).lower()
    label = clean(str(step.get("focus_label") or "")).lower()
    class_name = clean(str(step.get("module_class") or "")).lower()
    hay = f"{type_name} {tag} {label} {class_name}"
    if not any((type_name, tag, label, class_name)):
        return None

    best = None
    best_score = 0
    for mod in modules:
        ui = clean(str(mod.get("ui_type") or "")).lower()
        kind = clean(str(mod.get("kind") or "")).lower()
        fqcn = clean(str(mod.get("fqcn") or "")).lower()
        short = fqcn.rsplit(".", 1)[-1] if fqcn else ""
        score = 0
        if ui and ui in hay:
            score += 5
        if short and short in class_name:
            score += 6
        if kind and kind in hay:
            score += 1
        # Light aliases
        if "sftp" in hay or "ftp" in hay:
            if "ftp" in ui or "sftp" in ui:
                score += 4
        if "csv" in hay and "csv" in ui:
            score += 4
        if "xslt" in hay and "xslt" in ui:
            score += 4
        if "database" in hay or "sql" in hay:
            if "database" in ui or "sql" in ui:
                score += 4
        if "file writing" in hay and "file writing" in ui:
            score += 4
        if "directory" in hay and "directory" in ui:
            score += 2
        if score > best_score:
            best_score = score
            best = mod
    if not best or best_score < 4:
        return None
    pdf = best.get("pdf") or ""
    ui = best.get("ui_type") or best.get("fqcn") or "module"
    name = Path(str(pdf)).name if pdf else ""
    if name:
        return f"Module documentation for this step: {ui} → documents/{pdf}"
    return f"Module documentation for this step: {ui}"


def step_transcript(step: dict) -> str:
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_narration_naturalize import naturalize_spoken

    detail = naturalize_spoken(clean(str(step.get("detail") or "")))
    message = naturalize_spoken(clean(str(step.get("message") or "")))
    return detail or message


def build_plain_text(demo: Path, steps: list[dict], title: str, ctx: dict) -> str:
    lines = [
        f"Construction Replay Transcript — {title}",
        f"Demo: {demo.name}  ·  Generated {date.today().isoformat()}",
        f"Video: documents/construction-replay.mp4",
        "",
        "What this interface does",
        "-" * 40,
        ctx.get("purpose") or "",
        "",
        "Who it's for",
        "-" * 40,
    ]
    for a in ctx.get("actors") or []:
        lines.append(f"- {a}")
    systems = ctx.get("systems") or []
    if systems:
        lines += ["", "Systems involved", "-" * 40]
        for s in systems:
            lines.append(f"- {s}")
    lines += ["", "Documents we also produce", "-" * 40]
    for c in ctx.get("companions") or []:
        status = "ready" if c.get("exists") else "generate when ready"
        lines.append(f"- {c.get('name')} ({status})")
        role = clean(str(c.get("role") or ""))
        if role:
            lines.append(f"  {role}")
    lines += ["", "=" * 40, "Narration (what you'll hear)", "=" * 40, ""]

    preamble = ctx.get("preamble_steps") or []
    if preamble:
        lines += ["[Setup]", ""]
        for i, step in enumerate(preamble, start=1):
            lines.append(f"S{i}. {clean(str(step.get('message') or ''))}")
            lines.append(clean(str(step.get("detail") or step.get("text") or "")) or "")
            lines.append("")

    current_route = None
    for i, step in enumerate(steps, start=1):
        route = clean(str(step.get("route_name") or step.get("route_id") or ""))
        if route and route != current_route:
            current_route = route
            lines.append(f"[{route}]")
            lines.append("")
        focus = clean(str(step.get("focus_label") or ""))
        msg = clean(str(step.get("message") or ""))
        # Prefer human message over raw diagram labels (e.g. "Poll SFTP for CSV")
        heading = msg or focus or f"Step {i}"
        lines.append(f"{i}. {heading}")
        lines.append(step_transcript(step) or "(no narration)")
        lines.append("")
    live_steps = ctx.get("live_test_steps") or []
    if live_steps:
        lines += ["[Live test]", ""]
        for i, step in enumerate(live_steps, start=1):
            lines.append(f"T{i}. {clean(str(step.get('message') or ''))}")
            lines.append(clean(str(step.get("detail") or step.get("text") or "")) or "")
            lines.append("")
    outro = ctx.get("outro_steps") or []
    if outro:
        lines += ["[Closing]", ""]
        for i, step in enumerate(outro, start=1):
            lines.append(f"C{i}. {clean(str(step.get('message') or ''))}")
            lines.append(clean(str(step.get("detail") or step.get("text") or "")) or "")
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def _bullets(items: list[str], style) -> list:
    """Simple • paragraphs — avoid ReportLab ListFlowable(value='bullet'), which prints the word 'bullet'."""
    return [Paragraph(f"• {esc(it)}", style) for it in items if str(it).strip()]


def build_pdf(demo: Path, steps: list[dict], title: str, ctx: dict, out_path: Path) -> Path:
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
            fontSize=17,
            textColor=ink,
            spaceAfter=4,
        ),
        "sub": ParagraphStyle(
            "sub", parent=base["Normal"], fontSize=10, textColor=muted, spaceAfter=8
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            textColor=green,
            spaceBefore=12,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["Normal"],
            fontSize=9.5,
            leading=13,
            alignment=TA_JUSTIFY,
            spaceAfter=6,
        ),
        "route": ParagraphStyle(
            "route",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            textColor=green,
            spaceBefore=14,
            spaceAfter=6,
        ),
        "step": ParagraphStyle(
            "step",
            parent=base["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=10.5,
            textColor=ink,
            spaceBefore=10,
            spaceAfter=2,
        ),
        "meta": ParagraphStyle(
            "meta", parent=base["Normal"], fontSize=8.5, textColor=muted, spaceAfter=4
        ),
        "note": ParagraphStyle(
            "note",
            parent=base["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=8.5,
            textColor=muted,
            spaceAfter=8,
            alignment=TA_LEFT,
        ),
        "bullet": ParagraphStyle(
            "bullet", parent=base["Normal"], fontSize=9.2, leading=12, textColor=ink
        ),
    }

    story = []
    story.append(Paragraph(f"PILOTFISH  ·  {esc(title).upper()}", styles["brand"]))
    story.append(Paragraph("Construction Replay Transcript", styles["title"]))
    story.append(
        Paragraph(
            f"{esc(title)}  ·  {date.today().isoformat()}  ·  "
            f"what you'll hear in documents/construction-replay.mp4",
            styles["sub"],
        )
    )

    story.append(Paragraph("What this interface does", styles["h2"]))
    story.append(Paragraph(esc(ctx.get("purpose") or ""), styles["body"]))

    story.append(Paragraph("Who it's for", styles["h2"]))
    story.extend(_bullets(list(ctx.get("actors") or []), styles["bullet"]))
    systems = ctx.get("systems") or []
    if systems:
        story.append(Paragraph("Systems involved", styles["h2"]))
        story.extend(_bullets(list(systems), styles["bullet"]))
    story.append(Spacer(1, 0.08 * inch))

    story.append(Paragraph("Documents we also produce", styles["h2"]))
    for c in ctx.get("companions") or []:
        status = "ready" if c.get("exists") else "generate when ready"
        role = clean(str(c.get("role") or ""))
        story.append(
            Paragraph(
                f"<b>{esc(c.get('name') or '')}</b>  ·  {esc(status)}<br/>"
                f"{esc(role)}",
                styles["body"],
            )
        )

    story.append(Paragraph("Narration", styles["h2"]))
    story.append(
        Paragraph(
            "Spoken lines from the construction video (setup, build-replay, live test, closing).",
            styles["note"],
        )
    )

    preamble = ctx.get("preamble_steps") or []
    if preamble:
        story.append(Paragraph("Setup", styles["route"]))
        for step in preamble:
            heading = clean(str(step.get("message") or step.get("action") or "Setup"))
            story.append(Paragraph(esc(heading), styles["step"]))
            body = clean(str(step.get("detail") or step.get("text") or ""))
            story.append(Paragraph(esc(body or "(no transcript)"), styles["body"]))

    current_route = None
    for i, step in enumerate(steps, start=1):
        route = clean(str(step.get("route_name") or step.get("route_id") or ""))
        if route and route != current_route:
            current_route = route
            story.append(Paragraph(esc(route), styles["route"]))
        focus = clean(str(step.get("focus_label") or ""))
        msg = clean(str(step.get("message") or ""))
        # Prefer human message over raw diagram labels (e.g. "Poll SFTP for CSV")
        heading = msg or focus or f"Step {i}"
        story.append(Paragraph(esc(heading), styles["step"]))
        body = step_transcript(step)
        story.append(Paragraph(esc(body or "(no transcript)"), styles["body"]))
        story.append(Spacer(1, 0.04 * inch))

    live_steps = ctx.get("live_test_steps") or []
    if live_steps:
        story.append(Paragraph("Live test", styles["h2"]))
        story.append(
            Paragraph(
                "After construction, the video switches to the Demo tab and runs inject → SQL.",
                styles["body"],
            )
        )
        for i, step in enumerate(live_steps, start=1):
            heading = clean(str(step.get("message") or step.get("action") or f"Test {i}"))
            story.append(Paragraph(esc(heading), styles["step"]))
            body = clean(str(step.get("detail") or step.get("text") or ""))
            story.append(Paragraph(esc(body or "(no transcript)"), styles["body"]))

    outro = ctx.get("outro_steps") or []
    if outro:
        story.append(Paragraph("Closing", styles["h2"]))
        for step in outro:
            heading = clean(str(step.get("message") or "Demo complete"))
            story.append(Paragraph(esc(heading), styles["step"]))
            body = clean(str(step.get("detail") or step.get("text") or ""))
            story.append(Paragraph(esc(body or "(no transcript)"), styles["body"]))

    doc = SimpleDocTemplate(
        str(out_path),
        pagesize=letter,
        leftMargin=0.75 * inch,
        rightMargin=0.75 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.7 * inch,
        title=f"Construction Replay Transcript — {title}",
        author="PilotFish Sandbox",
    )
    doc.build(story)
    return out_path


def export(demo: Path, *, out_pdf: Path | None = None, out_txt: Path | None = None) -> tuple[Path, Path]:
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_narration_naturalize import naturalize_demo_root, naturalize_spoken

    # Always run the naturalization pass before writing transcript artifacts.
    counts = naturalize_demo_root(demo)
    if counts.get("manifest") or counts.get("demo_test"):
        print(
            f"Naturalized narration: manifest={counts['manifest']}, "
            f"demo-test={counts['demo_test']}"
        )

    steps, title, _manifest = load_steps(demo)
    if not steps:
        raise SystemExit(f"No build-replay steps under {demo / 'documents' / 'build-replay'}")
    ctx = discover_docs(demo)
    # Soften front-matter purpose through the same pass
    if ctx.get("purpose"):
        ctx["purpose"] = naturalize_spoken(str(ctx["purpose"]))
    for key in ("preamble_steps", "live_test_steps", "outro_steps"):
        items = ctx.get(key) or []
        if isinstance(items, list):
            for step in items:
                if isinstance(step, dict):
                    if step.get("detail"):
                        step["detail"] = naturalize_spoken(str(step["detail"]))
                    if step.get("text"):
                        step["text"] = naturalize_spoken(str(step["text"]))
                    if step.get("message"):
                        step["message"] = naturalize_spoken(str(step["message"]))
    docs = demo / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    pdf_path = out_pdf or (docs / "construction-replay-transcript.pdf")
    txt_path = out_txt or (docs / "construction-replay-transcript.txt")
    txt_path.write_text(build_plain_text(demo, steps, title, ctx), encoding="utf-8")
    build_pdf(demo, steps, title, ctx, pdf_path)
    return pdf_path, txt_path


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="Demo root under Clients/Demos/")
    ap.add_argument("--out", help="PDF output path (default: documents/construction-replay-transcript.pdf)")
    ap.add_argument("--out-txt", help="Plain-text twin path (default: documents/construction-replay-transcript.txt)")
    args = ap.parse_args()
    demo = Path(args.root).expanduser().resolve()
    pdf_path = Path(args.out).expanduser().resolve() if args.out else None
    txt_path = Path(args.out_txt).expanduser().resolve() if args.out_txt else None
    pdf, txt = export(demo, out_pdf=pdf_path, out_txt=txt_path)
    print(pdf)
    print(txt)
    print(f"PDF size: {pdf.stat().st_size // 1024} KB · {txt.name} written")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
