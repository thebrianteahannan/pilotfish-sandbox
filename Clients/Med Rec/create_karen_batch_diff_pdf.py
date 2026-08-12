#!/usr/bin/env python3
"""Generate an easy-to-read PDF summarizing Med Rec Karen-batch code changes (#2–#5).

  python3 "Clients/Med Rec/create_karen_batch_diff_pdf.py"
"""

from __future__ import annotations

import subprocess
import textwrap
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[2]
MED = Path(__file__).resolve().parent
OUT = MED / "MedRec_Karen_Batch_Changes_Diff.pdf"

# Request → files (paths relative to repo root)
CHANGESETS = [
    {
        "id": 2,
        "title": "HAL split crosswalk (HAX)",
        "summary": (
            "Replaced limited LOCATION_ABBR choose() with Karen’s 71-entry LocationAbbreviation "
            "→ FAC crosswalk. Kept legacy EMSHM/EMSHC/HPO. Unknown → HAX."
        ),
        "files": [
            "Clients/Med Rec/eip-root/interfaces/Flat File to HL7 and Kickout Reports/routes/1 - Incoming Flat Files by Partition and Client/transform-halifax-flatfilexml-to-canconicalxml.xslt",
        ],
        "extras": [
            "Mock regression files: data/Karen-Requests-Aug7th2026/New mapping/Halifax/mock-hax-mis-split/",
        ],
    },
    {
        "id": 3,
        "title": "NGP Healthfirst IN1.4",
        "summary": (
            "admInsName prefers PRIMARY_PAYER, falls back to PRIMARY_CVG_PAYER "
            "(fixes blank Primary Cvg Payer rows)."
        ),
        "files": [
            "Clients/Med Rec/eip-root/interfaces/Flat File to HL7 and Kickout Reports/routes/1 - Incoming Flat Files by Partition and Client/transform-ngp-healthfirst-flatfilexml-to-canconicalxml.xslt",
        ],
        "extras": [],
    },
    {
        "id": 4,
        "title": "Ariana IN1.16 subscriber",
        "summary": (
            "LigoLab transform hardens InsuredName (+ patient fallback). "
            "ADT ARA empty IN1.16 uses XCN patient name (not XPN)."
        ),
        "files": [
            "Clients/Med Rec/eip-root/interfaces/Flat File to HL7 and Kickout Reports/routes/1 - Incoming Flat Files by Partition and Client/transform.xslt",
            "Clients/Med Rec/eip-root/interfaces/Flat File to HL7 and Kickout Reports/formats/Generate ADT A04 HL7/transform.xslt",
        ],
        "extras": [],
    },
    {
        "id": 5,
        "title": "NTX Frisco end date",
        "summary": (
            "FRI moved from strip-before to strip-after (MED pattern). "
            "CLIENT_SPLITS DATE_RANGE → 20260802 via SQL."
        ),
        "files": [
            "Clients/Med Rec/eip-root/interfaces/Flat File to HL7 and Kickout Reports/routes/2 - Stripping and Tweaking/route.xml",
            "Clients/Med Rec/reports/CLIENT_SPLITS_full.csv",
        ],
        "extras": [
            "NEW SQL: Clients/Med Rec/deploy/sql/02_update_NTX_FRI_end_date.sql",
        ],
        "new_files": [
            "Clients/Med Rec/deploy/sql/02_update_NTX_FRI_end_date.sql",
        ],
    },
]

STATUS_EXTRAS = [
    "Clients/Med Rec/create_karen_requests_status_pdf.py (living status tracker generator)",
    "Clients/Med Rec/MedRec_Karen_Requests_Status.pdf (regenerated status overview)",
    "Clients/Med Rec/data/Karen-Requests-Aug7th2026/ (Karen drop + Halifax mock)",
]


def esc(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title", parent=base["Heading1"], fontSize=16, leading=20,
            spaceAfter=4, textColor=colors.HexColor("#1a2332"),
        ),
        "sub": ParagraphStyle(
            "sub", parent=base["BodyText"], fontSize=10, leading=13,
            textColor=colors.HexColor("#4a5568"), spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "h2", parent=base["Heading2"], fontSize=12, leading=15,
            spaceBefore=12, spaceAfter=6, textColor=colors.HexColor("#1a2332"),
        ),
        "h3": ParagraphStyle(
            "h3", parent=base["Heading3"], fontSize=10.5, leading=13,
            spaceBefore=8, spaceAfter=4, textColor=colors.HexColor("#2c3e50"),
        ),
        "body": ParagraphStyle(
            "body", parent=base["BodyText"], fontSize=9.5, leading=12.5,
            spaceAfter=6, alignment=TA_LEFT,
        ),
        "small": ParagraphStyle(
            "small", parent=base["BodyText"], fontSize=8.5, leading=11,
            textColor=colors.HexColor("#444444"), spaceAfter=3,
        ),
        "bullet": ParagraphStyle(
            "bullet", parent=base["BodyText"], fontSize=9, leading=12, leftIndent=4,
        ),
        "th": ParagraphStyle(
            "th", parent=base["BodyText"], fontSize=8.5, leading=11,
            fontName="Helvetica-Bold", textColor=colors.white,
        ),
        "path": ParagraphStyle(
            "path", parent=base["Code"], fontSize=7.5, leading=9.5,
            textColor=colors.HexColor("#1a2332"), spaceAfter=4,
        ),
        "diff": ParagraphStyle(
            "diff", fontName="Courier", fontSize=6.5, leading=8,
            textColor=colors.HexColor("#222222"),
        ),
        "add": ParagraphStyle(
            "add", fontName="Courier", fontSize=6.5, leading=8,
            textColor=colors.HexColor("#0b5e1f"), backColor=colors.HexColor("#e8f7ec"),
        ),
        "del": ParagraphStyle(
            "del", fontName="Courier", fontSize=6.5, leading=8,
            textColor=colors.HexColor("#8a1f11"), backColor=colors.HexColor("#fdeceb"),
        ),
        "meta": ParagraphStyle(
            "meta", fontName="Courier", fontSize=6.5, leading=8,
            textColor=colors.HexColor("#555555"),
        ),
    }


def bullets(items, style):
    return ListFlowable(
        [ListItem(Paragraph(esc(i), style), leftIndent=10, value="•") for i in items],
        bulletType="bullet", start="•",
    )


def git_diff(rel: str) -> str:
    r = subprocess.run(
        ["git", "diff", "--no-color", "--", rel],
        cwd=ROOT, capture_output=True, text=True,
    )
    return r.stdout or ""


def short_name(rel: str) -> str:
    return Path(rel).name


def overview_table(s):
    rows = [[
        Paragraph("#", s["th"]),
        Paragraph("Item", s["th"]),
        Paragraph("What changed", s["th"]),
        Paragraph("Primary file(s)", s["th"]),
    ]]
    for cs in CHANGESETS:
        files = ", ".join(short_name(f) for f in cs["files"])
        if cs.get("extras"):
            files += " (+ SQL/mock)"
        rows.append([
            Paragraph(str(cs["id"]), s["small"]),
            Paragraph(esc(cs["title"]), s["small"]),
            Paragraph(esc(cs["summary"]), s["small"]),
            Paragraph(esc(files), s["small"]),
        ])
    t = Table(rows, colWidths=[0.35 * inch, 1.5 * inch, 3.2 * inch, 2.3 * inch])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a2332")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#c5ced6")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1),
         [colors.HexColor("#fafbfc"), colors.HexColor("#eef2f6")]),
    ]))
    return t


def wrap_diff_line(line: str, width: int = 108) -> list[str]:
    if len(line) <= width:
        return [line]
    # keep leading marker on wrapped chunks
    marker = line[:1] if line[:1] in "+- @" else ""
    body = line[1:] if marker and line[:1] in "+-" else line
    chunks = textwrap.wrap(body, width=width - (1 if marker else 0), replace_whitespace=False, drop_whitespace=False) or [""]
    out = []
    for i, chunk in enumerate(chunks):
        if marker and i == 0:
            out.append(marker + chunk)
        elif marker:
            out.append(" " + chunk)
        else:
            out.append(chunk)
    return out


def diff_flowables(diff_text: str, s, max_lines: int = 220) -> list:
    """Render unified diff with simple +/- coloring. Truncate huge diffs."""
    if not diff_text.strip():
        return [Paragraph("<i>(no git diff — new/untracked or unchanged vs HEAD)</i>", s["small"])]

    lines = diff_text.splitlines()
    # Drop noisy git headers partially but keep @@ / +/- content
    kept = []
    for line in lines:
        if line.startswith("diff --git") or line.startswith("index ") or line.startswith("--- ") or line.startswith("+++ "):
            continue
        kept.append(line)

    truncated = False
    if len(kept) > max_lines:
        kept = kept[:max_lines]
        truncated = True

    flow = []
    for line in kept:
        style = s["diff"]
        if line.startswith("+") and not line.startswith("+++"):
            style = s["add"]
        elif line.startswith("-") and not line.startswith("---"):
            style = s["del"]
        elif line.startswith("@@"):
            style = s["meta"]
        for chunk in wrap_diff_line(line):
            # Preformatted escapes poorly for <; use Paragraph with esc
            flow.append(Paragraph(esc(chunk).replace(" ", "&nbsp;"), style))

    if truncated:
        flow.append(Paragraph(
            f"<i>… truncated after {max_lines} lines. Full diff: "
            f"<font face='Courier'>git diff -- path</font></i>",
            s["small"],
        ))
    return flow


def new_file_preview(rel: str, s, max_lines: int = 80) -> list:
    path = ROOT / rel
    if not path.exists():
        return [Paragraph(f"<i>Missing: {esc(rel)}</i>", s["small"])]
    text = path.read_text(errors="replace")
    lines = text.splitlines()
    shown = lines[:max_lines]
    flow = [Paragraph(esc(rel), s["path"])]
    for line in shown:
        for chunk in wrap_diff_line("+" + line if not line.startswith("+") else line):
            # show as added
            body = chunk[1:] if chunk.startswith("+") else chunk
            flow.append(Paragraph(esc("+" + body).replace(" ", "&nbsp;"), s["add"]))
    if len(lines) > max_lines:
        flow.append(Paragraph(f"<i>… {len(lines) - max_lines} more lines not shown</i>", s["small"]))
    return flow


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#666666"))
    canvas.drawString(0.7 * inch, 0.45 * inch, f"Med Rec Karen batch changes — {date.today().isoformat()}")
    canvas.drawRightString(letter[0] - 0.7 * inch, 0.45 * inch, f"Page {doc.page}")
    canvas.restoreState()


def build():
    s = styles()
    doc = SimpleDocTemplate(
        str(OUT), pagesize=letter,
        leftMargin=0.65 * inch, rightMargin=0.65 * inch,
        topMargin=0.6 * inch, bottomMargin=0.7 * inch,
        title="Med Rec Karen Batch Changes Diff",
        author="PilotFish Sandbox — Med Rec",
    )
    story = []
    story.append(Paragraph("Med Rec — Karen Batch Change Diff", s["title"]))
    story.append(Paragraph(
        f"Readable summary of implemented requests #2–#5 (skipping #6 MUEs). "
        f"Generated {date.today().isoformat()}.",
        s["sub"],
    ))
    story.append(Paragraph(
        "<b>#1 NHL CAT go-live</b> is Done (prior live deploy) and has no code delta in this batch.",
        s["body"],
    ))
    story.append(Paragraph("Overview", s["h2"]))
    story.append(overview_table(s))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Also included (status / samples)", s["h2"]))
    story.append(bullets(STATUS_EXTRAS, s["bullet"]))
    story.append(Paragraph(
        "How to read: green = added, red = removed, grey = hunk headers. "
        "Halifax crosswalk expansion is large — that section may truncate; use git diff for the full dump.",
        s["small"],
    ))

    for cs in CHANGESETS:
        story.append(PageBreak())
        story.append(Paragraph(f"#{cs['id']} — {esc(cs['title'])}", s["h2"]))
        story.append(Paragraph(esc(cs["summary"]), s["body"]))
        if cs.get("extras"):
            story.append(Paragraph("<b>Related</b>", s["h3"]))
            story.append(bullets(cs["extras"], s["bullet"]))

        for rel in cs["files"]:
            story.append(Paragraph(f"Diff: {esc(short_name(rel))}", s["h3"]))
            story.append(Paragraph(esc(rel), s["path"]))
            # Halifax is huge — allow more lines but still cap
            cap = 320 if "halifax" in rel.lower() else 220
            story.extend(diff_flowables(git_diff(rel), s, max_lines=cap))

        for rel in cs.get("new_files", []):
            story.append(Paragraph(f"New file: {esc(short_name(rel))}", s["h3"]))
            story.extend(new_file_preview(rel, s))

    story.append(PageBreak())
    story.append(Paragraph("Deploy checklist (ready items)", s["h2"]))
    story.append(bullets([
        "#2 Copy updated transform-halifax-flatfilexml-to-canconicalxml.xslt; smoke mock-hax-mis-split.",
        "#3 Copy transform-ngp-healthfirst-…xslt; smoke Primary Payer accounts.",
        "#4 Copy Ariana LigoLab transform.xslt + Generate ADT A04 transform.xslt; smoke SELFPAY IN1.16.",
        "#5 Copy route 2 Stripping and Tweaking/route.xml; run deploy/sql/02_update_NTX_FRI_end_date.sql on target DB.",
        "#6 Still skipped — waiting on PilotFish\\MUE examples.",
        "Living status: regenerate MedRec_Karen_Requests_Status.pdf after status updates.",
    ], s["bullet"]))
    story.append(Spacer(1, 10))
    story.append(Paragraph(
        "Regenerate this PDF: "
        "<font face='Courier'>python3 \"Clients/Med Rec/create_karen_batch_diff_pdf.py\"</font>",
        s["small"],
    ))

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
