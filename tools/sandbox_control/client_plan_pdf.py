"""Write a stakeholder PDF for a client-request change plan."""

from __future__ import annotations

from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import ListFlowable, ListItem, Paragraph, SimpleDocTemplate, Spacer


def _esc(s: str) -> str:
    return (
        str(s or "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\n", "<br/>")
    )


def write_plan_pdf(folder: Path, meta: dict, dive: dict) -> Path:
    out = folder / "changes-needed.pdf"
    base = getSampleStyleSheet()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    muted = colors.HexColor("#4b5568")
    styles = {
        "brand": ParagraphStyle("b", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9, textColor=green),
        "title": ParagraphStyle("t", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=16, textColor=ink, spaceAfter=4),
        "sub": ParagraphStyle("s", parent=base["Normal"], fontSize=9.5, textColor=muted, spaceAfter=10),
        "h2": ParagraphStyle("h2", parent=base["Heading2"], fontName="Helvetica-Bold", fontSize=11.5, textColor=green, spaceBefore=11, spaceAfter=5),
        "body": ParagraphStyle("body", parent=base["Normal"], fontSize=9.5, leading=12.6, alignment=TA_JUSTIFY, spaceAfter=5),
        "left": ParagraphStyle("left", parent=base["Normal"], fontSize=9.2, leading=12.2, alignment=TA_LEFT, spaceAfter=3),
        "code": ParagraphStyle("code", parent=base["Normal"], fontName="Courier", fontSize=8, leading=10.5, textColor=ink, spaceAfter=2),
        "note": ParagraphStyle("n", parent=base["Normal"], fontName="Helvetica-Oblique", fontSize=8.5, textColor=muted, spaceAfter=6),
        "bu": ParagraphStyle("bu", parent=base["Normal"], fontSize=9.2, leading=12),
    }
    client = meta.get("client") or "Client"
    story = [
        Paragraph(f"PILOTFISH  ·  { _esc(str(client).upper()) }", styles["brand"]),
        Paragraph("Proposed interface changes", styles["title"]),
        Paragraph(
            f"{_esc(dive.get('summary') or '')}  ·  {date.today().isoformat()}  ·  request { _esc(meta.get('id') or '') }",
            styles["sub"],
        ),
        Paragraph("What the email is asking", styles["h2"]),
        Paragraph(_esc(dive.get("ask") or "See the saved email."), styles["body"]),
        Paragraph(f"From {_esc(meta.get('from') or '—')}  ·  {_esc(dive.get('subject') or meta.get('subject') or '')}", styles["note"]),
    ]
    codes = dive.get("codes") or []
    if codes:
        story.append(Paragraph("Codes to change", styles["h2"]))
        story.append(
            ListFlowable(
                [ListItem(Paragraph(_esc(c), styles["bu"]), leftIndent=8) for c in codes],
                bulletType="bullet",
                start="•",
            )
        )
    story.append(Paragraph("Where it lives", styles["h2"]))
    files = dive.get("files") or []
    if not files:
        story.append(Paragraph("No matching mapping lines were found under eip-root (skipped backups, tests, and giant route.xml files).", styles["body"]))
    for rec in files:
        story.append(Paragraph(f"<b>{_esc(rec.get('path'))}</b>", styles["left"]))
        for hit in rec.get("hits") or []:
            extra = f" → {hit['maps_to']}" if hit.get("maps_to") else ""
            story.append(
                Paragraph(
                    f"L{hit.get('line')}  {_esc(hit.get('code') or '')}{ _esc(extra) }  {_esc(hit.get('text') or '')}",
                    styles["code"],
                )
            )
        story.append(Spacer(1, 0.08 * inch))
    story.append(Paragraph("What Start work will do", styles["h2"]))
    edits = dive.get("edits") or []
    if edits:
        items = []
        for ed in edits:
            if ed.get("action") == "replace_block":
                flag = " Already on disk." if ed.get("already_applied") else ""
                items.append(ListItem(Paragraph(_esc((ed.get("title") or "Replace") + flag), styles["bu"]), leftIndent=8))
            else:
                bit = f"Remove the <font face='Courier'>xsl:when</font> for {_esc(ed.get('code'))} in {_esc(ed.get('path'))} (line {ed.get('line')}"
                if ed.get("maps_to"):
                    bit += f", today maps to { _esc(ed['maps_to']) }"
                bit += ")"
                items.append(ListItem(Paragraph(bit, styles["bu"]), leftIndent=8))
        story.append(ListFlowable(items, bulletType="bullet", start="•"))
        for ed in edits:
            if ed.get("action") != "replace_block":
                continue
            story.append(Paragraph(_esc(ed.get("why") or ""), styles["body"]))
            story.append(Paragraph(f"<b>{_esc(ed.get('path') or '')}</b>", styles["left"]))
            if ed.get("old"):
                story.append(Paragraph("Before", styles["note"]))
                story.append(Paragraph(_esc(ed["old"]), styles["code"]))
            if ed.get("new"):
                story.append(Paragraph("After", styles["note"]))
                story.append(Paragraph(_esc(ed["new"]), styles["code"]))
        already = any(e.get("already_applied") for e in edits)
        story.append(
            Paragraph(
                "These edits are already in eip-root."
                if already
                else "A copy of each edited file is saved beside it as <font face='Courier'>*.bak-req</font> before the first change.",
                styles["note"],
            )
        )
    else:
        story.append(
            Paragraph(
                "Nothing the hub can apply automatically. Open the files above in eiConsole or Cursor and edit by hand.",
                styles["body"],
            )
        )
    if dive.get("risks"):
        story.append(Paragraph("Watch-outs", styles["h2"]))
        story.append(
            ListFlowable(
                [ListItem(Paragraph(_esc(r), styles["bu"]), leftIndent=8) for r in dive["risks"]],
                bulletType="bullet",
                start="•",
            )
        )
    doc = SimpleDocTemplate(
        str(out),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.65 * inch,
        title=f"{client} change plan",
        author="PilotFish Sandbox",
    )
    doc.build(story)
    return out
