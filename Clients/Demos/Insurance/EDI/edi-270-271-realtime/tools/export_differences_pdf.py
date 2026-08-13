#!/usr/bin/env python3
"""Orig vs realtime eligibility architecture one-pager."""

from pathlib import Path

from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from reportlab.lib import colors

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "documents" / "EDI270_271_Orig_vs_Realtime_Differences.pdf"


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    styles = getSampleStyleSheet()
    doc = SimpleDocTemplate(str(OUT), pagesize=letter, leftMargin=0.7 * inch, rightMargin=0.7 * inch)
    story = [
        Paragraph("EDI 270/271 — Orig vs Realtime", styles["Title"]),
        Spacer(1, 0.2 * inch),
        Paragraph(
            "Same clinic story (FAIL001 AAA theater, then OK001 active benefits). "
            "Different ownership of the round-trip.",
            styles["BodyText"],
        ),
        Spacer(1, 0.25 * inch),
    ]
    data = [
        ["", "Orig (edi-270-271-eligibility)", "Realtime (this demo)"],
        ["Clinic HTTP calls", "Three: /build → payer → /parse", "One: /eligibility/check"],
        ["Who calls the payer", "Clinic Web UI", "PilotFish HttpPost"],
        ["Sync reply", "Synchronous Response transport", "Synchronous Response processor after PostProcessors"],
        ["Best for", "Teaching the wire steps", "Production-shaped real-time integration"],
        ["Ports", "8106 / 8107 / 8210", "8120 / 8121 / 8211"],
    ]
    table = Table(data, colWidths=[1.5 * inch, 2.6 * inch, 2.6 * inch])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#007cba")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#d5e0ea")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ("BACKGROUND", (0, 1), (0, -1), colors.HexColor("#f5f8fb")),
            ]
        )
    )
    story.append(table)
    story.append(Spacer(1, 0.3 * inch))
    story.append(
        Paragraph(
            "Both demos use the same mock payer theater (AAA 72 / AAA 75 / active EB) "
            "and the same structural 271 parse. Realtime keeps that parse inside PilotFish "
            "after the HTTP Post returns.",
            styles["BodyText"],
        )
    )
    doc.build(story)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
