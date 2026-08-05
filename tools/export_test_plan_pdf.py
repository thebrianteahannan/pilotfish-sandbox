#!/usr/bin/env python3
"""Export tests/plan.json to a stakeholder/engineer Test Plan PDF."""
from __future__ import annotations

import argparse
import json
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import ListFlowable, ListItem, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


def esc(s: str) -> str:
    return (
        str(s)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def load_plan(root: Path) -> tuple[dict, Path]:
    path = root / "tests" / "plan.json"
    if not path.is_file():
        raise SystemExit(f"Missing {path}")
    return json.loads(path.read_text(encoding="utf-8")), path


def pdf_name(root: Path, plan: dict) -> str:
    docs = root / "documents"
    for p in sorted(docs.glob("*_V2_Route_Diagrams.pdf")) if docs.is_dir() else []:
        return p.name.replace("_V2_Route_Diagrams.pdf", "_Test_Plan.pdf")
    slug = plan.get("short_name") or root.name.replace("-", "_")
    return f"{slug}_Test_Plan.pdf"


def build(root: Path, out: Path | None = None) -> Path:
    plan, plan_path = load_plan(root)
    title = plan.get("interface") or root.name
    out_path = out or (root / "documents" / pdf_name(root, plan))
    out_path.parent.mkdir(parents=True, exist_ok=True)

    base = getSampleStyleSheet()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    styles = {
        "brand": ParagraphStyle("b", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9, textColor=green),
        "title": ParagraphStyle("t", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=17, textColor=ink, spaceAfter=4),
        "sub": ParagraphStyle("s", parent=base["Normal"], fontSize=10, textColor=colors.HexColor("#4b5568"), spaceAfter=10),
        "h2": ParagraphStyle("h2", parent=base["Heading2"], fontName="Helvetica-Bold", fontSize=12, textColor=green, spaceBefore=12, spaceAfter=6),
        "h3": ParagraphStyle("h3", parent=base["Heading3"], fontName="Helvetica-Bold", fontSize=10.5, textColor=ink, spaceBefore=8, spaceAfter=3),
        "body": ParagraphStyle("body", parent=base["Normal"], fontSize=9.5, leading=12.5, alignment=TA_JUSTIFY, spaceAfter=5),
        "bullet": ParagraphStyle("bu", parent=base["Normal"], fontSize=9.2, leading=12),
        "th": ParagraphStyle("th", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=8.2, textColor=colors.white),
        "td": ParagraphStyle("td", parent=base["Normal"], fontSize=8.2, leading=10.5, textColor=ink),
        "note": ParagraphStyle("n", parent=base["Normal"], fontName="Helvetica-Oblique", fontSize=8.5, textColor=colors.HexColor("#4b5568"), spaceAfter=8),
    }

    story = []
    story.append(Paragraph(f"PILOTFISH  ·  {esc(title).upper()}", styles["brand"]))
    story.append(Paragraph("Interface Test Plan", styles["title"]))
    story.append(
        Paragraph(
            f"{esc(title)}  ·  Generated {date.today().isoformat()} from {esc(plan_path.name)}",
            styles["sub"],
        )
    )
    story.append(
        Paragraph(
            "This plan is the source of truth for automated verification. "
            "Run <b>python3 tools/run_interface_tests.py</b> to execute it and write "
            "<b>documents/test-results.json</b>, HTML, and PDF. Update <b>tests/plan.json</b> as "
            "capabilities are added so the PDF and runner stay aligned.",
            styles["body"],
        )
    )

    if plan.get("description"):
        story.append(Paragraph("1. Purpose", styles["h2"]))
        story.append(Paragraph(esc(plan["description"]), styles["body"]))

    story.append(Paragraph("2. Environments &amp; base URLs", styles["h2"]))
    rows = [["Key", "URL"]]
    for k, v in (plan.get("base_urls") or {}).items():
        rows.append([k, str(v)])
    data = [[Paragraph(esc(c), styles["th" if i == 0 else "td"]) for c in row] for i, row in enumerate(rows)]
    t = Table(data, colWidths=[1.4 * inch, 5.6 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), green),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#d4dbe8")),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f8fafc")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    story.append(t)
    story.append(Spacer(1, 6))

    if plan.get("healthcheck_urls"):
        story.append(
            ListFlowable(
                [ListItem(Paragraph(esc(u), styles["bullet"])) for u in plan["healthcheck_urls"]],
                bulletType="bullet",
                leftIndent=12,
            )
        )

    story.append(Paragraph("3. Test suites", styles["h2"]))
    n = 0
    for suite in plan.get("suites") or []:
        n += 1
        sname = suite.get("name") or suite.get("id") or f"Suite {n}"
        story.append(Paragraph(esc(sname), styles["h3"]))
        if suite.get("description"):
            story.append(Paragraph(esc(suite["description"]), styles["note"]))
        items = []
        for test in suite.get("tests") or []:
            typ = test.get("type") or "http"
            tid = test.get("id") or ""
            tname = test.get("name") or tid
            expect = test.get("expect") or {}
            hint = ""
            if "status" in expect:
                hint = f" → expect HTTP {expect['status']}"
            elif expect.get("contains"):
                hint = " → expect body markers"
            items.append(f"<b>{esc(tname)}</b> <font color='#6b7280'>({esc(typ)}{esc(hint)})</font>")
        if items:
            story.append(
                ListFlowable(
                    [ListItem(Paragraph(i, styles["bullet"]), leftIndent=6) for i in items],
                    bulletType="bullet",
                    leftIndent=14,
                    spaceAfter=6,
                )
            )

    story.append(Paragraph("4. How to run", styles["h2"]))
    story.append(
        Paragraph(
            "From the interface root (stack up):<br/>"
            "<font face='Courier' size='8'>python3 tools/run_interface_tests.py --wait</font><br/>"
            "Watch mode (re-run on DESIGN/routes/samples/plan changes):<br/>"
            "<font face='Courier' size='8'>python3 tools/run_interface_tests.py --watch</font><br/>"
            "After compose:<br/>"
            "<font face='Courier' size='8'>docker compose up -d --build &amp;&amp; ./tools/post_up_tests.sh</font>",
            styles["body"],
        )
    )
    story.append(
        Paragraph(
            "Results appear in the Web UI Tests tab, and as documents/test-results.html "
            "(easy pass/fail list) plus documents/test-results.json.",
            styles["note"],
        )
    )

    brand = f"PILOTFISH  ·  {title}"

    def on_page(canvas, doc):
        canvas.saveState()
        canvas.setStrokeColor(green)
        canvas.setLineWidth(1.1)
        canvas.line(0.7 * inch, letter[1] - 0.45 * inch, letter[0] - 0.7 * inch, letter[1] - 0.45 * inch)
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(colors.HexColor("#6b7280"))
        canvas.drawString(0.7 * inch, 0.45 * inch, brand[:80])
        canvas.drawRightString(letter[0] - 0.7 * inch, 0.45 * inch, f"Page {doc.page}")
        canvas.restoreState()

    doc = SimpleDocTemplate(
        str(out_path),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.7 * inch,
        title=f"{title} — Test Plan",
        author="PilotFish Sandbox",
    )
    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    return out_path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, default=None)
    p.add_argument("--out", type=Path, default=None)
    args = p.parse_args()
    root = (args.root or Path.cwd()).resolve()
    path = build(root, args.out)
    print("Wrote", path)


if __name__ == "__main__":
    main()
