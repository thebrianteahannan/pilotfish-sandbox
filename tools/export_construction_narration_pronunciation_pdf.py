#!/usr/bin/env python3
"""Export docs/CONSTRUCTION_NARRATION_PRONUNCIATION.pdf from the JSON + markdown guide."""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

ROOT = Path(__file__).resolve().parents[1]
GUIDE_JSON = ROOT / "docs" / "construction-narration-pronunciation.json"
OUT_PDF = ROOT / "docs" / "CONSTRUCTION_NARRATION_PRONUNCIATION.pdf"


def esc(s: str) -> str:
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def main() -> int:
    guide = json.loads(GUIDE_JSON.read_text(encoding="utf-8"))
    base = getSampleStyleSheet()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    muted = colors.HexColor("#4b5568")
    styles = {
        "brand": ParagraphStyle("brand", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9, textColor=green),
        "title": ParagraphStyle("title", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=16, textColor=ink, spaceAfter=4),
        "sub": ParagraphStyle("sub", parent=base["Normal"], fontSize=9.5, textColor=muted, spaceAfter=8),
        "h2": ParagraphStyle("h2", parent=base["Heading2"], fontName="Helvetica-Bold", fontSize=11.5, textColor=green, spaceBefore=12, spaceAfter=6),
        "body": ParagraphStyle("body", parent=base["Normal"], fontSize=9.2, leading=12.5, spaceAfter=5),
        "th": ParagraphStyle("th", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=8.2, textColor=colors.white),
        "td": ParagraphStyle("td", parent=base["Normal"], fontSize=8.2, leading=10.5, textColor=ink),
        "note": ParagraphStyle("note", parent=base["Normal"], fontName="Helvetica-Oblique", fontSize=8.3, textColor=muted, spaceAfter=8),
    }

    story = []
    story.append(Paragraph("PILOTFISH SANDBOX  ·  GLOBAL DOCUMENTATION", styles["brand"]))
    story.append(Paragraph("Construction Narration Pronunciation", styles["title"]))
    story.append(
        Paragraph(
            f"Generated {date.today().isoformat()} from construction-narration-pronunciation.json  ·  "
            "Used by tools/construction_speech.py when exporting construction-replay.mp4",
            styles["sub"],
        )
    )
    story.append(Paragraph(esc(guide.get("purpose") or ""), styles["body"]))
    story.append(
        Paragraph(
            "<b>Display vs speech:</b> transcripts and overlays keep normal spelling "
            "(SFTP, /opt/…). Only the TTS voiceover is rewritten.",
            styles["body"],
        )
    )

    story.append(Paragraph("1. Paths — never say “slash”", styles["h2"]))
    pr = guide.get("path_rules") or {}
    for key in ("never_say_slash", "unix_path_speak", "prefer_friendly_folder", "file_extensions"):
        if key in pr:
            label = key.replace("_", " ")
            story.append(Paragraph(f"<b>{esc(label)}.</b> {esc(pr[key])}", styles["body"]))

    story.append(Paragraph("Friendly folder phrases", styles["h2"]))
    rows = [[Paragraph("Path / fragment", styles["th"]), Paragraph("Say", styles["th"])]]
    for item in guide.get("friendly_paths") or []:
        rows.append(
            [
                Paragraph(esc(item.get("match") or ""), styles["td"]),
                Paragraph(esc(item.get("speak") or ""), styles["td"]),
            ]
        )
    t = Table(rows, colWidths=[3.2 * inch, 3.8 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), green),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#d4dbe8")),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f8fafc")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    story.append(t)
    story.append(Spacer(1, 0.12 * inch))

    story.append(Paragraph("2. Term pronunciation", styles["h2"]))
    rows = [
        [
            Paragraph("Match", styles["th"]),
            Paragraph("Say", styles["th"]),
            Paragraph("Notes", styles["th"]),
        ]
    ]
    for item in guide.get("replacements") or []:
        speak = item.get("speak")
        if speak is None and item.get("speak_map"):
            speak = ", ".join(f"{k}→{v}" for k, v in item["speak_map"].items() if k.isupper())
        rows.append(
            [
                Paragraph(esc(item.get("id") or item.get("match") or ""), styles["td"]),
                Paragraph(esc(str(speak or "")), styles["td"]),
                Paragraph(esc(item.get("notes") or ""), styles["td"]),
            ]
        )
    t2 = Table(rows, colWidths=[1.3 * inch, 2.2 * inch, 3.5 * inch])
    t2.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), green),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#d4dbe8")),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f8fafc")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    story.append(t2)

    story.append(Paragraph("3. Examples (display → speech)", styles["h2"]))
    for ex in guide.get("examples") or []:
        story.append(
            Paragraph(
                f"<b>Display:</b> {esc(ex.get('display') or '')}<br/>"
                f"<b>Speech:</b> {esc(ex.get('speak') or '')}",
                styles["body"],
            )
        )

    story.append(Paragraph("4. Agent workflow", styles["h2"]))
    story.append(
        Paragraph(
            "1. Keep build-replay <b>detail</b> human-readable.<br/>"
            "2. <b>tools/construction_speech.py</b> rewrites lines for TTS when exporting video.<br/>"
            "3. Edit <b>docs/construction-narration-pronunciation.json</b> to add terms; re-run this PDF exporter.<br/>"
            "4. Re-export <b>construction-replay.mp4</b> so voiceover picks up the change.",
            styles["body"],
        )
    )
    story.append(
        Paragraph(
            "Companion markdown: docs/CONSTRUCTION_NARRATION_PRONUNCIATION.md",
            styles["note"],
        )
    )

    OUT_PDF.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUT_PDF),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.65 * inch,
        title="Construction Narration Pronunciation",
        author="PilotFish Sandbox",
    )
    doc.build(story)
    print(OUT_PDF)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
