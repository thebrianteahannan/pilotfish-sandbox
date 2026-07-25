#!/usr/bin/env python3
"""Generate design PDF for CRL Plus American Income Life (AIL) programming."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
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

OUT = Path(__file__).resolve().parent / "AIL_Programming_Design.pdf"


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            parent=base["Heading1"],
            fontSize=16,
            leading=20,
            spaceAfter=8,
            textColor=colors.HexColor("#1a2332"),
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontSize=12,
            leading=15,
            spaceBefore=14,
            spaceAfter=6,
            textColor=colors.HexColor("#1a2332"),
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["BodyText"],
            fontSize=9.5,
            leading=12.5,
            spaceAfter=6,
            alignment=TA_LEFT,
        ),
        "small": ParagraphStyle(
            "small",
            parent=base["BodyText"],
            fontSize=8.5,
            leading=11,
            textColor=colors.HexColor("#444444"),
            spaceAfter=4,
        ),
        "bullet": ParagraphStyle(
            "bullet",
            parent=base["BodyText"],
            fontSize=9.5,
            leading=12.5,
            leftIndent=8,
        ),
        "code": ParagraphStyle(
            "code",
            parent=base["BodyText"],
            fontName="Courier",
            fontSize=8.5,
            leading=11,
            backColor=colors.HexColor("#f4f6f8"),
            spaceAfter=6,
        ),
    }


def bullets(items, s):
    return ListFlowable(
        [ListItem(Paragraph(i, s["bullet"]), leftIndent=12, value="•") for i in items],
        bulletType="bullet",
        start="•",
    )


def main():
    s = styles()
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.65 * inch,
        title="CRL Plus — American Income Life (AIL) Programming Design",
        author="PilotFish Sandbox",
    )
    story = []

    story.append(Paragraph("CRL Plus — American Income Life (AIL) Programming Design", s["title"]))
    story.append(
        Paragraph(
            "Request source: Wendy Jorgensen (CRL) approval to proceed with AIL programming, "
            "using the prior FGL / Ladder Life electronic-order pattern as the reference.",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            "Scope: extend the existing <b>AmericanIncomeLife</b> client interface (today only "
            "<b>ProcessStatus</b>) to a full Ladder/FGLI-style ACORD 121 / 1122 interface, wire "
            "Status routing, publish TEST HTTP credentials/URL, and demonstrate in sandbox with "
            "a LAN web UI.",
            s["body"],
        )
    )

    story.append(Paragraph("1. Current state", s["h2"]))
    story.append(
        bullets(
            [
                "Client folder exists: <b>interfaces/Clients/interfaces/AmericanIncomeLife</b>",
                "Only route present previously: <b>ProcessStatus</b> (listener <b>AmericanIncomeLife 122 Status</b>)",
                "Status route <b>4 - Route to client specific</b> already maps <b>sourceClient=AIL</b> → To AmericanIncomeLife",
                "Sibling clients NIL / GL / GLNY / LNL are ProcessStatus-only; Ladder + FGLI (Resonant) are the full pattern to copy",
            ],
            s,
        )
    )

    story.append(Paragraph("2. Target design (Ladder / FGL pattern)", s["h2"]))
    story.append(
        Paragraph(
            "Clone the FGLI (Resonant) / Ladder Life client-specific route set into AmericanIncomeLife "
            "and re-key identifiers to <b>AIL</b>.",
            s["body"],
        )
    )

    rows = [
        [Paragraph("<b>Route</b>", s["small"]), Paragraph("<b>Purpose</b>", s["small"])],
        [
            Paragraph("1 - 121 Incoming", s["small"]),
            Paragraph(
                "HttpPostListener path <b>ail</b> + basic auth file; sets sourceClient=AIL; "
                "directory listener under inputDir/ail; forwards to Source Document Listener",
                s["small"],
            ),
        ],
        [
            Paragraph("2 - 121 Response", s["small"]),
            Paragraph(
                "Synchronous 121 accept / failure response back to sender (same pattern as Ladder/FGLI)",
                s["small"],
            ),
        ],
        [
            Paragraph("3 - 1122 Status or Result POST", s["small"]),
            Paragraph(
                "Listener <b>AIL 1122 Status</b>; transforms via format <b>AIL 1122</b>; "
                "HTTP POST to $$AILOutgoingWsURL (sandbox mock; can be skipped until AIL provides endpoint)",
                s["small"],
            ),
        ],
        [
            Paragraph("4 - 1122 POST Response", s["small"]),
            Paragraph(
                "Handles carrier POST response: archive + mark status sent in database",
                s["small"],
            ),
        ],
        [
            Paragraph("ProcessStatus", s["small"]),
            Paragraph(
                "Retained for compatibility / 122-style updates; Status.4 primary path now uses route 3",
                s["small"],
            ),
        ],
    ]
    t = Table(rows, colWidths=[1.7 * inch, 5.1 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e8eef5")),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#99a3ad")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    story.append(t)
    story.append(Spacer(1, 8))

    story.append(Paragraph("3. Status.4 wiring change", s["h2"]))
    story.append(
        Paragraph(
            "In <b>Status / 4 - Route to client specific</b>, keep the existing rule "
            "<b>sourceClient = AIL → To AmericanIncomeLife</b>, but change the transport "
            "ServiceName from <b>AmericanIncomeLife 122 Status</b> to <b>AIL 1122 Status</b> "
            "(new route 3 listener). This matches how FGLIRES / LADDER enter their 1122 routes.",
            s["body"],
        )
    )

    story.append(Paragraph("4. External TEST credentials / URL", s["h2"]))
    story.append(
        Paragraph(
            "Following the FGL setup email: CRL publishes an HTTP POST URL and PilotFish-owned "
            "basic-auth credentials for the carrier to send TEST orders.",
            s["body"],
        )
    )
    story.append(Paragraph("External URL (TEST pattern):", s["small"]))
    story.append(Paragraph("https://plus.intg.crlcorp.com/http-post/ail", s["code"]))
    story.append(Paragraph("Sandbox / local equivalent:", s["small"]))
    story.append(Paragraph("http://&lt;lan-ip&gt;:8094/http-post/ail", s["code"]))
    story.append(Paragraph("auth-test.txt (sandbox values — rotate for real TEST/PROD):", s["small"]))
    story.append(Paragraph("ail=AilSandbox$Test1<br/>AIL=AilSandbox$Test1", s["code"]))
    story.append(
        Paragraph(
            "Outbound carrier web service: initially point $$AILOutgoingWsURL at the sandbox mock "
            "(or skip POST until Wendy confirms AIL wants a response / provides their endpoint), "
            "same approach used when FGL credentials were not yet available.",
            s["body"],
        )
    )

    story.append(Paragraph("5. Sandbox demonstration", s["h2"]))
    story.append(
        bullets(
            [
                "Docker/Flask LAN UI on port <b>8094</b> shows route design + live transaction results",
                "POST sample ACORD 121 to <b>/http-post/ail</b> with basic auth",
                "UI walks Status.4 → AIL 1122 Status → mock outbound (skippable)",
                "Artifacts written under <b>Clients/CRL Plus/sandbox/output/</b>",
            ],
            s,
        )
    )

    story.append(Paragraph("6. Deploy checklist (TEST)", s["h2"]))
    story.append(
        bullets(
            [
                "Copy AmericanIncomeLife formats + routes 1–4 into CRLPlus TEST eip-root",
                "Deploy updated Status.4 transport ServiceName = AIL 1122 Status",
                "Set environment props: AILIncomingAuthFile, AILOutgoingWsURL/User/Password",
                "Restart eiPlatform; smoke-test HTTP POST + status routing",
                "Confirm with Wendy whether AIL requires sync 121 response and/or outbound 1122 POST",
            ],
            s,
        )
    )

    story.append(Paragraph("7. File map", s["h2"]))
    story.append(
        Paragraph(
            "Clients/CRL Plus/eip-root/interfaces/Clients/interfaces/AmericanIncomeLife/<br/>"
            "Clients/CRL Plus/eip-root/interfaces/Status/routes/4 - Route to client specific/route.xml<br/>"
            "Clients/CRL Plus/sandbox/ (LAN web UI + mock endpoints)",
            s["code"],
        )
    )

    doc.build(story)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
