#!/usr/bin/env python3
"""Build documents/EDI270_271_Orig_vs_Realtime_Differences.pdf for Gary."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    ListFlowable,
    ListItem,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "documents" / "EDI270_271_Orig_vs_Realtime_Differences.pdf"


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "t",
            parent=base["Title"],
            fontSize=18,
            leading=22,
            textColor=colors.HexColor("#0f172a"),
            spaceAfter=8,
        ),
        "sub": ParagraphStyle(
            "s",
            parent=base["Normal"],
            fontSize=10,
            textColor=colors.HexColor("#475569"),
            alignment=TA_CENTER,
            spaceAfter=16,
        ),
        "h": ParagraphStyle(
            "h",
            parent=base["Heading2"],
            fontSize=12,
            textColor=colors.HexColor("#1e3a5f"),
            spaceBefore=12,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "b",
            parent=base["Normal"],
            fontSize=10,
            leading=14,
            alignment=TA_JUSTIFY,
            spaceAfter=8,
        ),
        "cell": ParagraphStyle(
            "c",
            parent=base["Normal"],
            fontSize=8.5,
            leading=11,
            alignment=TA_LEFT,
        ),
        "bullet": ParagraphStyle(
            "bu",
            parent=base["Normal"],
            fontSize=10,
            leading=13,
        ),
        "foot": ParagraphStyle(
            "f",
            parent=base["Normal"],
            fontSize=8,
            textColor=colors.HexColor("#64748b"),
            spaceBefore=18,
        ),
    }


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    st = styles()
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.75 * inch,
        rightMargin=0.75 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.7 * inch,
        title="EDI 270/271 — Original vs Realtime Demo",
        author="PilotFish Sandbox",
    )
    story = [
        Paragraph("EDI 270/271 Eligibility Demos", st["title"]),
        Paragraph(
            "Original (<font face='Courier'>edi-270-271-eligibility</font>) vs "
            "Realtime (<font face='Courier'>edi-270-271-realtime</font>)<br/>"
            "Prepared for Gary Beatty — real-time eligibility inquiry / response demo",
            st["sub"],
        ),
        Paragraph("Why two demos?", st["h"]),
        Paragraph(
            "Both demos exchange <b>real X12 270 eligibility inquiries</b> and "
            "<b>271 eligibility responses</b> (005010X279A1) with AAA reject and "
            "active-benefits theater. The original demo is already synchronous HTTP, "
            "but the <b>Clinic Web UI orchestrates three HTTP calls</b> "
            "(PilotFish build → payer → PilotFish parse). "
            "Gary asked for a <b>real-time</b> eligibility demo; the new sibling puts "
            "<b>PilotFish in charge of the entire round-trip on a single sync REST call</b> "
            "— the shape you would deploy behind an EHR or front-desk system.",
            st["body"],
        ),
        Paragraph("Side-by-side", st["h"]),
    ]

    hdr = [
        Paragraph("<b>Topic</b>", st["cell"]),
        Paragraph("<b>Original demo</b>", st["cell"]),
        Paragraph("<b>Realtime demo (new)</b>", st["cell"]),
    ]
    rows = [
        hdr,
        [
            Paragraph("Folder", st["cell"]),
            Paragraph("<font face='Courier'>edi-270-271-eligibility</font>", st["cell"]),
            Paragraph("<font face='Courier'>edi-270-271-realtime</font>", st["cell"]),
        ],
        [
            Paragraph("Clinic HTTP calls per check", st["cell"]),
            Paragraph("<b>3</b> — PF <font face='Courier'>/build</font> → mock payer → PF <font face='Courier'>/parse</font>", st["cell"]),
            Paragraph("<b>1</b> — PF <font face='Courier'>/eligibility/check</font>", st["cell"]),
        ],
        [
            Paragraph("Who calls the payer?", st["cell"]),
            Paragraph("Clinic Web UI (Flask)", st["cell"]),
            Paragraph("PilotFish <font face='Courier'>HttpPostTransport</font>", st["cell"]),
        ],
        [
            Paragraph("How sync reply works", st["cell"]),
            Paragraph("<font face='Courier'>SynchronousResponseTransport</font> on build &amp; parse targets", st["cell"]),
            Paragraph("<font face='Courier'>HttpPost</font> + <b>PostProcessors</b> + <font face='Courier'>SynchronousResponseProcessor</font> (Keycloak callout pattern)", st["cell"]),
        ],
        [
            Paragraph("Best audience", st["cell"]),
            Paragraph("Teaching wire steps; showing each hop distinctly", st["cell"]),
            Paragraph("Production-shaped real-time integration / sales demo for Gary", st["cell"]),
        ],
        [
            Paragraph("Ports (host)", st["cell"]),
            Paragraph("EIP <b>8106</b> · UI <b>8107</b> · Payer <b>8210</b>", st["cell"]),
            Paragraph("EIP <b>8120</b> · UI <b>8121</b> · Payer <b>8211</b>", st["cell"]),
        ],
        [
            Paragraph("Same in both", st["cell"]),
            Paragraph("Real X12 270/271 · FAIL001 AAA · OK001 EB benefits · audit files under output/", st["cell"]),
            Paragraph("Same presets, transforms, and mock-payer theater", st["cell"]),
        ],
    ]
    table = Table(rows, colWidths=[1.35 * inch, 2.85 * inch, 2.85 * inch])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1e3a5f")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f8fafc")),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#cbd5e1")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ("BACKGROUND", (2, 1), (2, -1), colors.HexColor("#ecfeff")),
            ]
        )
    )
    story.append(table)
    story.append(Spacer(1, 10))

    story.extend(
        [
            Paragraph("Realtime flow (new)", st["h"]),
            ListFlowable(
                [
                    ListItem(Paragraph("Clinic POSTs <font face='Courier'>EligibilityRequest</font> XML to PilotFish.", st["bullet"])),
                    ListItem(Paragraph("PilotFish maps to EDI XML → XML→EDI <b>270</b> wire.", st["bullet"])),
                    ListItem(Paragraph("PilotFish <b>HttpPost</b> sends the 270 to the mock payer.", st["bullet"])),
                    ListItem(Paragraph("271 response continues in route PostProcessors → structural XSLT → clinic JSON.", st["bullet"])),
                    ListItem(Paragraph("<font face='Courier'>SynchronousResponseProcessor</font> returns that JSON on the original clinic HTTP request.", st["bullet"])),
                ],
                bulletType="1",
                start="1",
            ),
            Paragraph("Original flow (unchanged sibling)", st["h"]),
            ListFlowable(
                [
                    ListItem(Paragraph("UI → PF <font face='Courier'>/build</font> → returns 270.", st["bullet"])),
                    ListItem(Paragraph("UI → mock payer → returns 271.", st["bullet"])),
                    ListItem(Paragraph("UI → PF <font face='Courier'>/parse</font> → returns JSON.", st["bullet"])),
                ],
                bulletType="1",
                start="1",
            ),
            Paragraph("Demo script for Gary", st["h"]),
            Paragraph(
                "Bring up <font face='Courier'>edi-270-271-realtime</font> "
                "(<font face='Courier'>http://127.0.0.1:8121/</font> or LAN "
                "<font face='Courier'>http://192.168.68.52:8121/</font>). "
                "Run FAIL001 then OK001. Point at the single elapsed-ms figure and the route PDF "
                "showing HttpPost in the middle of the sync chain. Optionally open the original "
                "demo on :8107 to contrast the three-step wire panel.",
                st["body"],
            ),
            Paragraph(
                "Sandbox honesty: both demos use a local mock payer and the same 23R1 trial-table "
                "workarounds documented in DESIGN.md. Swap <font face='Courier'>PAYER_X12_URL</font> "
                "for a clearinghouse endpoint when ready for a live payer pilot.",
                st["foot"],
            ),
        ]
    )
    doc.build(story)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
