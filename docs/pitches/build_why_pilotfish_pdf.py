#!/usr/bin/env python3
"""Build docs/pitches/Why_PilotFish_eiPlatform_Not_Just_AI.pdf."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "Why_PilotFish_eiPlatform_Not_Just_AI.pdf"
BRAND = "PILOTFISH  ·  eiPLATFORM POSITIONING"
GREEN = colors.HexColor("#0b6e4f")
INK = colors.HexColor("#1e293b")
MUTED = colors.HexColor("#475569")
RULE = colors.HexColor("#cbd5e1")
SOFT = colors.HexColor("#f1f5f4")


def styles():
    base = getSampleStyleSheet()

    def p(name, parent, **kw):
        return ParagraphStyle(name, parent=base[parent], **kw)

    return {
        "title": p("Title", "Title", fontName="Helvetica-Bold", fontSize=20, leading=24, textColor=GREEN, alignment=TA_CENTER, spaceAfter=8),
        "subtitle": p("Subtitle", "Normal", fontName="Helvetica", fontSize=11, leading=14, textColor=MUTED, alignment=TA_CENTER, spaceAfter=18),
        "h1": p("H1", "Heading1", fontName="Helvetica-Bold", fontSize=14, textColor=GREEN, spaceBefore=12, spaceAfter=8),
        "h2": p("H2", "Heading2", fontName="Helvetica-Bold", fontSize=11.5, textColor=INK, spaceBefore=12, spaceAfter=5),
        "body": p("Body", "Normal", fontName="Helvetica", fontSize=9.5, leading=13, textColor=INK, alignment=TA_JUSTIFY, spaceAfter=7),
        "bullet": p("Bullet", "Normal", fontName="Helvetica", fontSize=9.3, leading=12.5, textColor=INK, alignment=TA_LEFT, spaceAfter=2),
        "callout": p("Callout", "Normal", fontName="Helvetica-Oblique", fontSize=9.5, leading=13, textColor=MUTED, alignment=TA_JUSTIFY, spaceBefore=4, spaceAfter=10),
        "footer": p("Footer", "Normal", fontName="Helvetica", fontSize=8, textColor=MUTED),
        "cell": p("Cell", "Normal", fontName="Helvetica", fontSize=8.4, leading=11, textColor=INK),
        "cellh": p("CellH", "Normal", fontName="Helvetica-Bold", fontSize=8.6, leading=11, textColor=colors.white),
    }


def bullets(items, st):
    return ListFlowable(
        [ListItem(Paragraph(i, st["bullet"]), leftIndent=12, value="•") for i in items],
        bulletType="bullet",
        start="•",
        leftIndent=14,
        spaceBefore=1,
        spaceAfter=8,
    )


def table(rows, col_widths):
    st = styles()
    data = [[Paragraph(c, st["cellh" if i == 0 else "cell"]) for c in row] for i, row in enumerate(rows)]
    t = Table(data, colWidths=col_widths, hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), GREEN),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, SOFT]),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("GRID", (0, 0), (-1, -1), 0.4, RULE),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return t


def footer(canvas, doc):
    canvas.saveState()
    y = 0.55 * inch
    canvas.setStrokeColor(RULE)
    canvas.setLineWidth(0.6)
    canvas.line(0.75 * inch, y + 10, letter[0] - 0.75 * inch, y + 10)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(0.75 * inch, y, BRAND)
    canvas.drawRightString(letter[0] - 0.75 * inch, y, f"Page {doc.page}")
    canvas.restoreState()


def build():
    st = styles()
    story = []

    story.append(Paragraph("Why PilotFish eiPlatform — Not Just AI and Python", st["title"]))
    story.append(
        Paragraph(
            "A practical guide for healthcare, insurance, and enterprise teams choosing "
            "an integration platform versus generating scripts with AI.",
            st["subtitle"],
        )
    )
    story.append(
        Paragraph(
            "Yes — with AI you can generate Python that moves files, calls APIs, and "
            "parses JSON. That is real, useful work. It is also not the same job as "
            "running production interfaces for EDI, HL7, FHIR, DICOM, ACORD, and the "
            "rest of regulated healthcare and insurance traffic.",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "This document explains what PilotFish’s eiPlatform is optimized for, where "
            "AI-written scripts fall short, and when PilotFish is a strong fit even "
            "outside healthcare.",
            st["callout"],
        )
    )

    story.append(Paragraph("1. The real problem is not “write some code”", st["h1"]))
    story.append(
        Paragraph(
            "An interface is a living operational contract between systems. It must "
            "accept traffic on the protocols partners actually use, validate against "
            "standards, transform safely, recover from failure, prove what happened, "
            "and stay maintainable after the original author leaves. AI helps you "
            "draft code quickly. It does not, by itself, give you a durable "
            "integration runtime.",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "PilotFish eiPlatform is an integration engine: listeners, processors, "
            "transports, routing, monitoring, and configuration packaged as "
            "repeatable routes rather than one-off scripts.",
            st["body"],
        )
    )

    story.append(Paragraph("2. Standards PilotFish is built to carry", st["h1"]))
    story.append(
        Paragraph(
            "Healthcare and insurance interfaces rarely stay in one format. The same "
            "organization may need several of these at once:",
            st["body"],
        )
    )
    story.append(
        bullets(
            [
                "<b>EDI / X12</b> — claims (837), remittance (835), eligibility (270/271), "
                "claim status (276/277), acknowledgments, SNIP-style structural checks.",
                "<b>HL7 v2</b> — ADT, ORM/ORU, DFT, lab and device feeds over MLLP/LLP, "
                "file drop, or hybrid hospital patterns.",
                "<b>FHIR</b> — REST resource APIs (Patient, Observation, Bundle, "
                "OperationOutcome), create/read/search/transaction style exchanges.",
                "<b>DICOM</b> — imaging workflows and metadata movement that must "
                "coexist with clinical messaging, not just “send a file.”",
                "<b>ACORD</b> — insurance XML/messaging used across property &amp; casualty "
                "and life distribution / carrier connectivity.",
                "<b>Other common payloads</b> — NCPDP, CCD/CDA, flat files, CSV/XML/JSON "
                "partner formats, proprietary EHR or payer APIs wrapped around the above.",
            ],
            st,
        )
    )
    story.append(
        Paragraph(
            "AI can generate a parser for a happy-path sample. Production needs "
            "version drift, partner-specific quirks, acknowledgments, partial "
            "failures, and auditability — especially when payers, HIEs, labs, "
            "imaging, and TPAs all speak different dialects of “standard.”",
            st["body"],
        )
    )

    story.append(Paragraph("3. Advantages versus AI-written Python scripts", st["h1"]))

    story.append(Paragraph("3.1 Protocol and connectivity modules already exist", st["h2"]))
    story.append(
        Paragraph(
            "Interfaces fail first at the wire: MLLP keepalives, AS2 signing, SFTP "
            "polling, JDBC transactions, synchronous HTTP responses, directory "
            "watchers with rename semantics, scheduled SQL polls. PilotFish ships "
            "listeners and transports for these patterns. With AI+Python you rebuild "
            "each one — including the ugly edge cases — every project.",
            st["body"],
        )
    )

    story.append(Paragraph("3.2 Transformation is a first-class stage, not a side script", st["h2"]))
    story.append(
        Paragraph(
            "Routes compose validation, XSLT/mapping, attribute extraction, SQL, "
            "routing rules, and response shaping as visible stages. That makes "
            "healthcare mapping work inspectable. A pile of generated Python functions "
            "tends to hide the mapping logic inside ad hoc code that only the author "
            "trusts.",
            st["body"],
        )
    )

    story.append(Paragraph("3.3 Operations: retries, kickouts, monitoring, sync replies", st["h2"]))
    story.append(
        bullets(
            [
                "Transaction identity, logging, and debug traces for failed messages.",
                "Synchronous response patterns (critical for FHIR REST, eligibility, "
                "and real-time payer/provider calls).",
                "Kickout / quarantine paths for bad data instead of silent drop or "
                "crashed workers.",
                "Connection pooling, timeouts, and restart behavior designed for "
                "always-on listeners — not a cron job that “usually works.”",
            ],
            st,
        )
    )

    story.append(Paragraph("3.4 Maintainability for teams, not only for the coder", st["h2"]))
    story.append(
        Paragraph(
            "Integration ownership often spans analysts, interface engineers, and "
            "operations. PilotFish routes and diagrams are a shared artifact. "
            "AI-generated scripts optimize for “it runs on my laptop,” not for "
            "handoffs, change control, or explaining a 2 a.m. production failure to "
            "a hospital CIO.",
            st["body"],
        )
    )

    story.append(Paragraph("3.5 Longevity and change under partner pressure", st["h2"]))
    story.append(
        Paragraph(
            "Partners change segments, code sets, certificates, endpoints, and SLAs. "
            "A platform with reusable modules absorbs that change in configuration "
            "and route updates. A bespoke Python service absorbs it as perpetual "
            "rework — and every AI regeneration risks inventing a slightly different "
            "architecture than last month’s script.",
            st["body"],
        )
    )

    story.append(Paragraph("3.6 Security, credentials, and environment separation", st["h2"]))
    story.append(
        Paragraph(
            "Production interfaces need secrets management, environment-specific "
            "endpoints, least-privilege database access, and clear boundaries between "
            "dev/test/prod. Platform configuration encourages that discipline. "
            "Generated scripts often hard-code URLs, leave credentials in source, or "
            "skip TLS/auth details until an audit finds them.",
            st["body"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("4. Side-by-side decision view", st["h1"]))
    story.append(
        table(
            [
                ["Concern", "AI + custom Python", "PilotFish eiPlatform"],
                [
                    "Speed to first demo",
                    "Often fastest for a narrow happy path",
                    "Fast when reusing known listeners/transports and demo patterns",
                ],
                [
                    "HL7 MLLP / EDI AS2 / FHIR sync REST",
                    "You own the protocol stack and edge cases",
                    "Modules and route patterns already exist",
                ],
                [
                    "Validation &amp; kickouts",
                    "Custom code; easy to under-build",
                    "Explicit route stages and failure paths",
                ],
                [
                    "Ops visibility",
                    "Depends on what you bolt on later",
                    "Transaction logs, traces, listener lifecycle",
                ],
                [
                    "Multi-standard estate",
                    "Many micro-services / scripts to keep alive",
                    "One platform, many routes and formats",
                ],
                [
                    "Staffing model",
                    "Needs strong developers for every change",
                    "Interface engineers + configurable routes; code when needed",
                ],
                [
                    "2-year cost of change",
                    "Often dominates; rewrite risk is high",
                    "Configuration and module reuse lower rewrite risk",
                ],
            ],
            [1.55 * inch, 2.55 * inch, 2.55 * inch],
        )
    )
    story.append(Spacer(1, 10))

    story.append(Paragraph("5. When AI and Python are still the right tool", st["h1"]))
    story.append(
        Paragraph(
            "PilotFish is not a religion. Prefer AI-assisted scripts when:",
            st["body"],
        )
    )
    story.append(
        bullets(
            [
                "The job is a one-time migration, report, or data cleanup.",
                "You are prototyping an idea before any partner traffic exists.",
                "The integration is a simple internal API glue with no regulated "
                "standard, no SLA, and no operational on-call surface.",
                "You need a thin client or helper around an already-running PilotFish "
                "route (test harnesses, UI façades, seed tools).",
            ],
            st,
        )
    )
    story.append(
        Paragraph(
            "In this Sandbox, that hybrid is common: PilotFish owns the interface "
            "runtime; Python/AI helps with demos, PDF generation, and operator UIs.",
            st["callout"],
        )
    )

    story.append(Paragraph("6. Is PilotFish only for healthcare?", st["h1"]))
    story.append(
        Paragraph(
            "No. Healthcare and insurance are where the standards pressure is "
            "highest, so the product’s strengths show clearly there. The same "
            "engine is a strong fit anywhere you have high-stakes B2B messaging:",
            st["body"],
        )
    )
    story.append(
        bullets(
            [
                "<b>Insurance &amp; financial exchange</b> — ACORD, EDI, payment files, "
                "eligibility-like request/response, partner onboarding at volume.",
                "<b>Supply chain / logistics EDI</b> — purchase orders, ASNs, invoices, "
                "acknowledgment cycles, VAN or SFTP partner networks.",
                "<b>Enterprise application integration</b> — ERP ↔ CRM ↔ data warehouse "
                "with mixed protocols (files, SQL, REST, queues).",
                "<b>Government / clearinghouse style hubs</b> — many trading partners, "
                "one operational model, strict audit requirements.",
                "<b>Any “always listening” integration fabric</b> — where uptime, "
                "replay, and proof-of-delivery matter more than code novelty.",
            ],
            st,
        )
    )
    story.append(
        Paragraph(
            "AI+Python is weakest precisely where PilotFish is strongest: many "
            "partners, many protocols, long-lived operational ownership, and "
            "expensive failure modes.",
            st["body"],
        )
    )

    story.append(Paragraph("7. What AI is bad at that platforms absorb", st["h1"]))
    story.append(
        bullets(
            [
                "<b>Non-deterministic architecture</b> — each chat session may invent a "
                "new folder layout, error model, or dependency set.",
                "<b>Under-specified standards</b> — models know slogans about FHIR/HL7; "
                "they miss partner-specific reality until production breaks.",
                "<b>Operational boredom</b> — retries, poison messages, certificate "
                "rotation, daylight-saving batch windows, dual-writes.",
                "<b>Evidence</b> — auditors and customers ask for message lineage; a "
                "script without a transaction model has to apologize.",
                "<b>Scale of ownership</b> — fifty interfaces as fifty AI scripts is a "
                "staffing and reliability problem dressed up as velocity.",
            ],
            st,
        )
    )

    story.append(Paragraph("8. Practical recommendation", st["h1"]))
    story.append(
        KeepTogether(
            [
                Paragraph(
                    "Use <b>PilotFish eiPlatform</b> when you are implementing or "
                    "operating interfaces that speak healthcare/insurance standards "
                    "(EDI, HL7, FHIR, DICOM, ACORD, and kin), or any multi-partner "
                    "B2B fabric with real SLAs.",
                    st["body"],
                ),
                Paragraph(
                    "Use <b>AI + Python</b> to accelerate surrounding work: scaffolding, "
                    "tests, documentation, light UIs, and prototypes — and to extend "
                    "PilotFish where a custom processor or helper is genuinely needed.",
                    st["body"],
                ),
                Paragraph(
                    "Do not confuse “I can generate a script that works once” with "
                    "“I have an integration platform.” For EDI, HL7, FHIR, and "
                    "similar estates, PilotFish is the better default runtime; AI is "
                    "the better accelerator around that runtime.",
                    st["callout"],
                ),
            ]
        )
    )

    story.append(Paragraph("9. Bottom line", st["h1"]))
    story.append(
        Paragraph(
            "AI makes writing Python cheaper. It does not make production "
            "interoperability free. PilotFish turns standards-heavy, always-on "
            "interface work into operable routes — with modules for the protocols "
            "healthcare and insurance already depend on — and remains a strong "
            "engine for high-stakes B2B messaging beyond clinical messaging alone.",
            st["body"],
        )
    )

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.75 * inch,
        rightMargin=0.75 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.8 * inch,
        title="Why PilotFish eiPlatform — Not Just AI and Python",
        author="PilotFish Sandbox",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
