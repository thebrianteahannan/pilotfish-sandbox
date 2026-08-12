#!/usr/bin/env python3
"""Generate living status PDF for Med Rec Karen Munoz request batch (Aug 2026).

Edit ITEMS / META below as design and implementation progress, then re-run:

  python3 "Clients/Med Rec/create_karen_requests_status_pdf.py"
"""

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

OUT = Path(__file__).resolve().parent / "MedRec_Karen_Requests_Status.pdf"

# ---------------------------------------------------------------------------
# UPDATE THESE as work progresses, then re-run this script.
# Status values: Waiting on files | Design | In progress | Ready for deploy | Done | Blocked
# ---------------------------------------------------------------------------
META = {
    "title": "Med Rec — Karen Requests Status",
    "subtitle": "Design + implementation tracker (Flat File → HL7)",
    "requester": "Karen Munoz <karen.munoz@medreceivables.com>",
    "cc": "Rachael Holloway <Rachael.Holloway@medreceivables.com>",
    "priority_email_date": "2026-08-05",
    "package": "Clients/Med Rec/eip-root (Flat File to HL7 and Kickout Reports)",
    "karen_drop_path": "Clients/Med Rec/data/Karen-Requests-Aug7th2026/",
    "last_updated": date.today().isoformat(),
    "overall_phase": "#2/#3/#4/#5 Ready for deploy; #1 Done; #6 waiting on MUE files",
}

ITEMS = [
    {
        "id": 1,
        "name": "Transfer NHL Catholic to live",
        "short": "NHL CAT go-live",
        "status": "Done",
        "priority": 1,
        "emails": "Priority list email; go-live deploy completed by Brian",
        "ask": (
            "Transfer NHL Catholic (CAT) from test/sandbox posture to live/production."
        ),
        "known": [
            "Deploy to live completed (confirmed 2026-08-07).",
            "Software ID 524 (Catholic Medical).",
        ],
        "design": [
            "No further design — already live.",
        ],
        "likely_touch": [],
        "missing": [],
        "acceptance": [
            "Live processing confirmed by Brian.",
        ],
        "notes": "Done.",
    },
    {
        "id": 2,
        "name": "HAL Splitting (Halifax Location_ABRR crosswalk)",
        "short": "HAL split crosswalk",
        "status": "Ready for deploy",
        "priority": 2,
        "emails": "Halifax Splitting — update splitting via crosswalk; Location_ABRR codes changed",
        "ask": (
            "Update Halifax splitting using the client LocationAbbreviation → FAC crosswalk."
        ),
        "known": [
            "Code complete 2026-08-07: full 71-entry crosswalk in transform-halifax-flatfilexml-to-canconicalxml.xslt.",
            "Legacy EMSHM/EMSHC/HPO kept (not in Karen crosswalk).",
            "Mock regression pair: New mapping/Halifax/mock-hax-mis-split/.",
            "Scope: HAX (software 750) only.",
        ],
        "design": [
            "Exact LOCATION_ABBR → FAC lookup from Excel; unknown → HAX.",
            "No CLIENT_SPLITS row changes — FAC codes already exist for 750.",
        ],
        "likely_touch": [
            "routes/1 …/transform-halifax-flatfilexml-to-canconicalxml.xslt (done)",
        ],
        "missing": [],
        "acceptance": [
            "Mock: MCD CT→DEX, HMC DBN ED→HED, HPO CT→POX, PO FSED CT→PXE, HMC→HAX",
            "Split folders follow FAC via existing CLIENT_SPLITS",
        ],
        "notes": "Ready for deploy. Smoke with mock-hax-mis-split files.",
    },
    {
        "id": 3,
        "name": "NGP Healthfirst — Ins Name (IN1.4)",
        "short": "NGP Healthfirst IN1.4",
        "status": "Ready for deploy",
        "priority": 3,
        "emails": "NGP Healthfirst — blanks in IN1.4; map Primary payer → IN1.4",
        "ask": (
            "Populate ADT IN1.4 from raw Primary payer. Accounts CC25012553248 / CC25025725798 / CC25026279073."
        ),
        "known": [
            "Have raw 20260714NextGenFlatFile.txt + CAQ0806a.ADT + NGP HF Examples.xlsx.",
            "Root cause: transform maps admInsName ← PRIMARY_CVG_PAYER; bad rows have Primary Cvg Payer blank while Primary Payer is populated.",
            "Confirmed empty IN1.4 on example accounts in CAQ0806a.ADT; Primary Payer values: UNITED HEALTHCARE MEDICARE / HEALTH FIRST COMMERCIAL / HF CIGNA ALLEGIANCE.",
            "Feed: NGP CAQ (Health First), software 652.",
        ],
        "design": [
            "In transform-ngp-healthfirst-flatfilexml-to-canconicalxml.xslt: set admInsName = PRIMARY_PAYER if non-blank, else PRIMARY_CVG_PAYER (Brian approved).",
            "No ADT XSLT change — IN1.4 already reads admInsName.",
            "Retest the three CSN/account examples end-to-end.",
        ],
        "likely_touch": [
            "routes/1 …/transform-ngp-healthfirst-flatfilexml-to-canconicalxml.xslt only",
        ],
        "missing": [],
        "acceptance": [
            "IN1.4 = UNITED HEALTHCARE MEDICARE / HEALTH FIRST COMMERCIAL / HF CIGNA ALLEGIANCE for the three examples",
            "Rows that already have Primary Cvg Payer still map correctly (fallback path)",
        ],
        "notes": "Code complete 2026-08-07: admInsName = PRIMARY_PAYER else PRIMARY_CVG_PAYER. Smoke in TEST, then deploy → Done.",
    },
    {
        "id": 4,
        "name": "Ariana — Subscriber name (IN1.16)",
        "short": "Ariana IN1.16",
        "status": "Ready for deploy",
        "priority": 4,
        "emails": "Ariana - Subscriber name — blank IN1.16 on SELFPAY; use patient name when blank",
        "ask": (
            "Populate IN1.16 when subscriber blank so Cerner loads SELFPAY. Examples 40172067 / 40172062 / 40171058."
        ),
        "known": [
            "Have ARIANA_LIGOLAB_*.xml (3) + PLB0806a.ADT (contains 40172062 + 40171058; 40172067 not in this ADT).",
            "Feed path: LigoLab (ARIANA_LIGOLAB.*) → transform.xslt + transform-ariana-part2.xslt; split PLB under ARA software 801.",
            "Source XML has InsuredName First/Last (types NS) for SELFPAY; ADT shows IN1.16 as blank '^'.",
            "ADT ARA empty-fallback currently writes XPN.* while NHL / non-empty path uses XCN.* — likely why fallback does not appear on wire.",
        ],
        "design": [
            "LigoLab transform.xslt: harden InsuredName → adminsinsuredname/subscribername (cover xifin + types NS); if still blank, set from patient Name.",
            "Generate ADT A04: for ARA empty (or effectively blank) adminsinsuredname, emit patient name using XCN.1/XCN.2 (not XPN) — same shape as NHL.",
            "Do not force patient name when InsuredName is valid.",
            "Verify with 40172062 + 40171058; optional reprocess 40172067 XML alone.",
        ],
        "likely_touch": [
            "routes/1 …/transform.xslt (Ariana LigoLab)",
            "formats/Generate ADT A04 HL7/transform.xslt (IN1.16 ARA branch)",
        ],
        "missing": [
            "Optional: ADT snippet for 40172067 if needed for sign-off",
        ],
        "acceptance": [
            "IN1.16 = PARKER^SUSAN / ALFARO^GLENDA MAGDALENA (or insured equivalent) on examples",
            "SELFPAY IN1 still present with non-blank subscriber name for Cerner",
        ],
        "notes": "Code complete 2026-08-07: LigoLab InsuredName(+ patient fallback) + ADT ARA IN1.16 XCN patient fallback. Smoke in TEST, then deploy → Done.",
    },
    {
        "id": 5,
        "name": "NTX Frisco END date (software 406)",
        "short": "NTX FRI end date",
        "status": "Ready for deploy",
        "priority": 5,
        "emails": "NTX - Frisco — END date by DOS; send only DOS 08/02/2026 and prior; mirror NTX MED",
        "ask": (
            "For NTX Frisco (software 406), only send DOS on/before 2026-08-02 — same pattern as NTX MED."
        ),
        "known": [
            "Code complete 2026-08-07: FRI on strip-after; removed from strip-before.",
            "SQL: deploy/sql/02_update_NTX_FRI_end_date.sql sets CLIENT_SPLITS DATE_RANGE=20260802 for software 406.",
            "reports/CLIENT_SPLITS_full.csv updated to 20260802 for documentation.",
        ],
        "design": [
            "Route 2: FRI on strip-after (with MED/WCH); FRI removed from strip-before.",
            "DB DATE_RANGE=20260802 drives cutoff via existing DateRange attribute lookup.",
        ],
        "likely_touch": [
            "routes/2 - Stripping and Tweaking/route.xml (done)",
            "deploy/sql/02_update_NTX_FRI_end_date.sql (done)",
        ],
        "missing": [],
        "acceptance": [
            "Apply SQL on target DB before/with eip-root copy",
            "DOS > 20260802 stripped: Exam Service Date Is After DateRange",
            "DOS ≤ 20260802 not stripped by this rule",
            "FRI no longer uses strip-before DATE_RANGE start gate",
        ],
        "notes": "Ready for deploy — route + SQL. Smoke on TEST then PROD.",
    },
    {
        "id": 6,
        "name": "MUEs — HAL, NGP Healthfirst, NSP, PPS",
        "short": "MUEs ×4",
        "status": "Waiting on files",
        "priority": 6,
        "emails": "Add MUEs logic to HAL, NGP Healthfirst, NSP, PPS; logs in PilotFish\\MUE examples",
        "ask": (
            "Add MUE logic for HAL, NGP Healthfirst, NSP, and PPS."
        ),
        "known": [
            "NOT in Karen-Requests-Aug7th2026 drop (PilotFish\\MUE examples missing).",
            "DFT already applies MUE_EDITS by SOFTWARE_ID; loader 88e + report 4b exist.",
            "Likely IDs: HAL 750/751, NGP CAQ 652, NSP 760, PPS 761.",
        ],
        "design": [
            "Deferred until MUE example files arrive — expected mostly MUE_EDITS seed rows via 88e/SQL.",
        ],
        "likely_touch": [
            "MUE_EDITS DB rows; possibly DFT only if a partition needs special casing",
        ],
        "missing": [
            "REQUIRED: PilotFish\\MUE examples folder (software ids, CPT/CDM, max per line)",
        ],
        "acceptance": [
            "MUE-matching charges split per MAX_VALUE_PER_LINE for the four clients",
            "MUE edits report shows expected sample accounts",
        ],
        "notes": "Only remaining file-blocked item.",
    },
]

STATUS_COLORS = {
    "Waiting on files": colors.HexColor("#8a4b08"),
    "Design": colors.HexColor("#1a5276"),
    "In progress": colors.HexColor("#1a5673"),
    "Ready for deploy": colors.HexColor("#1e6b3a"),
    "Done": colors.HexColor("#145a32"),
    "Blocked": colors.HexColor("#922b21"),
}


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            parent=base["Heading1"],
            fontSize=16,
            leading=20,
            spaceAfter=4,
            textColor=colors.HexColor("#1a2332"),
        ),
        "sub": ParagraphStyle(
            "sub",
            parent=base["BodyText"],
            fontSize=10,
            leading=13,
            textColor=colors.HexColor("#4a5568"),
            spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontSize=12,
            leading=15,
            spaceBefore=12,
            spaceAfter=6,
            textColor=colors.HexColor("#1a2332"),
        ),
        "h3": ParagraphStyle(
            "h3",
            parent=base["Heading3"],
            fontSize=11,
            leading=14,
            spaceBefore=8,
            spaceAfter=4,
            textColor=colors.HexColor("#2c3e50"),
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
            spaceAfter=3,
        ),
        "bullet": ParagraphStyle(
            "bullet",
            parent=base["BodyText"],
            fontSize=9,
            leading=12,
            leftIndent=4,
        ),
        "meta": ParagraphStyle(
            "meta",
            parent=base["BodyText"],
            fontSize=8.5,
            leading=11,
            textColor=colors.HexColor("#333333"),
            spaceAfter=2,
        ),
        "status": ParagraphStyle(
            "status",
            parent=base["BodyText"],
            fontSize=9,
            leading=11,
            fontName="Helvetica-Bold",
        ),
        "th": ParagraphStyle(
            "th",
            parent=base["BodyText"],
            fontSize=8.5,
            leading=11,
            fontName="Helvetica-Bold",
            textColor=colors.white,
        ),
        "footer": ParagraphStyle(
            "footer",
            parent=base["Normal"],
            fontSize=8,
            textColor=colors.HexColor("#666666"),
        ),
    }


def bullets(items, style):
    return ListFlowable(
        [ListItem(Paragraph(_esc(i), style), leftIndent=10, value="•") for i in items],
        bulletType="bullet",
        start="•",
    )


def _esc(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def status_para(status: str, s) -> Paragraph:
    color = STATUS_COLORS.get(status, colors.HexColor("#333333"))
    style = ParagraphStyle(
        f"st_{status}",
        parent=s["status"],
        textColor=color,
    )
    return Paragraph(_esc(status), style)


def cell(text: str, style) -> Paragraph:
    return Paragraph(_esc(text), style)


def overview_table(s):
    header = [
        cell("#", s["th"]),
        cell("Item", s["th"]),
        cell("Status", s["th"]),
        cell("Blocked on", s["th"]),
    ]
    rows = [header]
    for item in ITEMS:
        blocked = overview_blocked(item)
        rows.append(
            [
                cell(str(item["id"]), s["small"]),
                cell(item["short"], s["small"]),
                status_para(item["status"], s),
                cell(blocked, s["small"]),
            ]
        )
    t = Table(rows, colWidths=[0.35 * inch, 1.8 * inch, 1.35 * inch, 3.9 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a2332")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#fafbfc")),
                (
                    "ROWBACKGROUNDS",
                    (0, 1),
                    (-1, -1),
                    [colors.HexColor("#fafbfc"), colors.HexColor("#eef2f6")],
                ),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#c5ced6")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return t


def item_section(item, s, story):
    story.append(
        Paragraph(
            f"{item['id']}. {_esc(item['name'])}",
            s["h2"],
        )
    )
    meta_bits = [
        f"<b>Status:</b> {_esc(item['status'])}",
        f"<b>Priority:</b> {item['priority']} (Karen list order)",
        f"<b>Email context:</b> {_esc(item['emails'])}",
    ]
    for bit in meta_bits:
        story.append(Paragraph(bit, s["meta"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("<b>Request</b>", s["h3"]))
    story.append(Paragraph(_esc(item["ask"]), s["body"]))
    if item.get("known"):
        story.append(Paragraph("<b>Already known (package / samples)</b>", s["h3"]))
        story.append(bullets(item["known"], s["bullet"]))
    if item.get("design"):
        story.append(Paragraph("<b>Design (proposed)</b>", s["h3"]))
        story.append(bullets(item["design"], s["bullet"]))
    if item.get("likely_touch"):
        story.append(Paragraph("<b>Likely touchpoints</b>", s["h3"]))
        story.append(bullets(item["likely_touch"], s["bullet"]))
    if item.get("missing"):
        story.append(Paragraph("<b>Still missing / open questions</b>", s["h3"]))
        story.append(bullets(item["missing"], s["bullet"]))
    if item.get("acceptance"):
        story.append(Paragraph("<b>Acceptance checks</b>", s["h3"]))
        story.append(bullets(item["acceptance"], s["bullet"]))
    if item.get("notes"):
        story.append(Paragraph(f"<b>Notes:</b> {_esc(item['notes'])}", s["small"]))
    story.append(Spacer(1, 6))


def overview_blocked(item) -> str:
    if item["status"] == "Done":
        return "—"
    if item.get("missing"):
        return item["missing"][0]
    if item["status"] == "Design":
        return "Ready for implement (awaiting go-ahead)"
    return "—"


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#666666"))
    canvas.drawString(
        0.75 * inch,
        0.45 * inch,
        f"Med Rec Karen Requests — last updated {META['last_updated']}",
    )
    canvas.drawRightString(
        letter[0] - 0.75 * inch,
        0.45 * inch,
        f"Page {doc.page}",
    )
    canvas.restoreState()


def build():
    s = styles()
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.7 * inch,
        title=META["title"],
        author="PilotFish Sandbox — Med Rec",
    )
    story = []
    story.append(Paragraph(_esc(META["title"]), s["title"]))
    story.append(Paragraph(_esc(META["subtitle"]), s["sub"]))
    story.append(
        Paragraph(
            f"<b>Overall phase:</b> {_esc(META['overall_phase'])} &nbsp;&nbsp; "
            f"<b>Last updated:</b> {_esc(META['last_updated'])}",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            f"<b>Requester:</b> {_esc(META['requester'])}<br/>"
            f"<b>CC:</b> {_esc(META['cc'])}<br/>"
            f"<b>Priority email:</b> {_esc(META['priority_email_date'])}<br/>"
            f"<b>Package:</b> {_esc(META['package'])}<br/>"
            f"<b>Karen file drop:</b> {_esc(META['karen_drop_path'])}",
            s["meta"],
        )
    )
    story.append(Spacer(1, 8))
    story.append(Paragraph("Status overview", s["h2"]))
    story.append(
        Paragraph(
            "Re-generate this PDF after editing ITEMS/META in "
            "<font face='Courier'>create_karen_requests_status_pdf.py</font>.",
            s["small"],
        )
    )
    story.append(overview_table(s))
    story.append(Spacer(1, 8))
    story.append(Paragraph("How we will use this doc", s["h2"]))
    story.append(
        bullets(
            [
                "Design round first — do not implement until missing samples/confirmations land.",
                "Update each item status: Waiting on files → Design → In progress → Ready for deploy → Done.",
                "When Karen folders arrive, place under Clients/Med Rec/data/karen-requests/ and refresh Missing lists.",
                "After each implementation slice, update Known / Touchpoints / Acceptance and bump Last updated.",
            ],
            s["bullet"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("Item details", s["h2"]))
    for item in ITEMS:
        item_section(item, s, story)

    story.append(PageBreak())
    story.append(Paragraph("Status legend", s["h2"]))
    legend_rows = [[cell("Status", s["th"]), cell("Meaning", s["th"])]]
    meanings = {
        "Waiting on files": "Need Karen folders, env answers, or sample pairs before coding.",
        "Design": "Samples in hand; writing/confirming approach; no prod change yet.",
        "In progress": "Code/DB changes underway in Med Rec package.",
        "Ready for deploy": "Locally verified; deploy package / SQL ready for TEST or PROD.",
        "Done": "Deployed and accepted (or signed off).",
        "Blocked": "Cannot proceed until a named external dependency clears.",
    }
    for status, meaning in meanings.items():
        legend_rows.append([status_para(status, s), cell(meaning, s["small"])])
    legend = Table(legend_rows, colWidths=[1.5 * inch, 5.9 * inch])
    legend.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a2332")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#c5ced6")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                (
                    "ROWBACKGROUNDS",
                    (0, 1),
                    (-1, -1),
                    [colors.HexColor("#fafbfc"), colors.HexColor("#eef2f6")],
                ),
            ]
        )
    )
    story.append(legend)
    story.append(Spacer(1, 12))
    story.append(
        Paragraph(
            "Refresh command: "
            "<font face='Courier'>python3 \"Clients/Med Rec/create_karen_requests_status_pdf.py\"</font>",
            s["small"],
        )
    )

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
