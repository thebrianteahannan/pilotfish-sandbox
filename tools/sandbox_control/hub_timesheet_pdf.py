"""Ebility-style landscape timesheet PDF."""

from __future__ import annotations

from datetime import date, datetime, timedelta
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

HERE = Path(__file__).resolve().parent
OUT_DIR = HERE / "data" / "timesheets"

ORANGE = colors.HexColor("#e87722")
HEADER = colors.HexColor("#5a5a5a")
INK = colors.HexColor("#333333")
LINE = colors.HexColor("#c8c8c8")
ROW = colors.HexColor("#f4f4f4")
BLUE = colors.HexColor("#007cba")
GREEN = colors.HexColor("#2e7d32")


def _esc(s: str) -> str:
    return (
        str(s or "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\n", "<br/>")
    )


def _p(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(_esc(text), style)


def write(sheet: dict) -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    start = date.fromisoformat(sheet["start"])
    sat = date.fromisoformat(sheet["payroll_start"])
    days14 = [sat + timedelta(days=i) for i in range(14)]
    stamp = datetime.now().strftime("%Y%m%d-%H%M")
    path = OUT_DIR / f"ebility-timesheet-{start.isoformat()}-{stamp}.pdf"
    page = landscape(letter)
    doc = SimpleDocTemplate(
        str(path),
        pagesize=page,
        leftMargin=0.35 * inch,
        rightMargin=0.35 * inch,
        topMargin=0.3 * inch,
        bottomMargin=0.3 * inch,
    )
    usable = page[0] - 0.7 * inch
    cell = ParagraphStyle("c", fontName="Helvetica", fontSize=6.5, leading=8, alignment=TA_CENTER, textColor=INK)
    cellL = ParagraphStyle("cl", fontName="Helvetica", fontSize=7, leading=9, alignment=TA_LEFT, textColor=INK)
    head = ParagraphStyle("h", fontName="Helvetica-Bold", fontSize=6, leading=7.5, alignment=TA_CENTER, textColor=colors.white)
    headL = ParagraphStyle("hl", fontName="Helvetica-Bold", fontSize=7, leading=9, alignment=TA_LEFT, textColor=colors.white)
    title = ParagraphStyle("t", fontName="Helvetica-Bold", fontSize=16, textColor=INK, spaceAfter=2)
    sub = ParagraphStyle("s", fontName="Helvetica", fontSize=9, textColor=colors.HexColor("#555"), spaceAfter=4)
    brand = ParagraphStyle("b", fontName="Helvetica-Bold", fontSize=10, textColor=ORANGE)
    copy_s = ParagraphStyle("cp", fontName="Courier", fontSize=8, leading=11, textColor=INK, spaceAfter=8)
    ev_s = ParagraphStyle("ev", fontName="Helvetica", fontSize=8, leading=10.5, textColor=INK)
    h2 = ParagraphStyle("h2", fontName="Helvetica-Bold", fontSize=11, textColor=INK, spaceBefore=8, spaceAfter=4)

    def day_label(d: date) -> str:
        return f"{d.strftime('%a')[:3]}<br/>{d.strftime('%m/%d')}"

    hdr = [
        _p("Customer / Time Off", headL),
        _p("Service Item", headL),
        _p("Bill", head),
    ]
    for d in days14[:7]:
        hdr.append(Paragraph(day_label(d), head))
    hdr.append(_p("Wk 1 Total", head))
    for d in days14[7:]:
        hdr.append(Paragraph(day_label(d), head))
    hdr.append(_p("Wk 2 Total", head))
    hdr.append(_p("Grand Total", head))

    daily_map: dict[str, dict[str, float]] = {}
    for row in sheet["rows"]:
        m = {}
        for i, name in enumerate(["Mon", "Tue", "Wed", "Thu", "Fri"]):
            m[row["dates"][name]] = row["daily"][name]
        daily_map[row["customer"]] = m

    data = [hdr]
    totals_day = [0.0] * 14
    for i, row in enumerate(sheet["rows"]):
        wk1 = []
        wk2 = []
        for idx, d in enumerate(days14):
            val = daily_map[row["customer"]].get(d.isoformat(), 0.0)
            totals_day[idx] += val
            cell_txt = str(int(round(val))) if val else ""
            (wk1 if idx < 7 else wk2).append(_p(cell_txt, cell))
        w1 = int(round(sum(daily_map[row["customer"]].get(d.isoformat(), 0) for d in days14[:7])))
        w2 = int(round(sum(daily_map[row["customer"]].get(d.isoformat(), 0) for d in days14[7:])))
        data.append(
            [
                _p(row["customer"], cellL),
                _p(row["service"], cellL),
                _p("☑" if row["bill"] else "", cell),
                *wk1,
                _p(str(w1) if w1 else "", cell),
                *wk2,
                _p(str(w2) if w2 else "", cell),
                _p(str(int(round(row["grand"]))), cell),
            ]
        )
    foot = [_p("Total", headL), _p("", head), _p("", head)]
    t1 = int(round(sum(totals_day[:7])))
    t2 = int(round(sum(totals_day[7:])))
    for v in totals_day[:7]:
        foot.append(_p(str(int(round(v))) if v else "0", head))
    foot.append(_p(str(t1), head))
    for v in totals_day[7:]:
        foot.append(_p(str(int(round(v))) if v else "0", head))
    foot.append(_p(str(t2), head))
    foot.append(_p(str(int(round(sheet["total"]))), head))
    data.append(foot)

    # widths: customer, service, bill, 7 days, tot, 7 days, tot, grand = 20 cols
    day_w = 0.38 * inch
    col = [1.45 * inch, 1.35 * inch, 0.32 * inch]
    col += [day_w] * 7
    col.append(0.52 * inch)
    col += [day_w] * 7
    col.append(0.52 * inch)
    col.append(0.55 * inch)
    scale = usable / sum(col)
    col = [c * scale for c in col]

    style_cmds = [
        ("BACKGROUND", (0, 0), (-1, 0), HEADER),
        ("BACKGROUND", (0, -1), (-1, -1), HEADER),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("GRID", (0, 0), (-1, -1), 0.4, LINE),
        ("BACKGROUND", (2, 1), (2, -2), colors.HexColor("#fff8f0")),
    ]
    for r in range(1, len(data) - 1):
        if r % 2 == 0:
            style_cmds.append(("BACKGROUND", (0, r), (-1, r), ROW))
    table = Table(data, colWidths=col, repeatRows=1)
    table.setStyle(TableStyle(style_cmds))

    pay = f"{sat.strftime('%m/%d/%Y')} - {days14[-1].strftime('%m/%d/%Y')}"
    story = [
        Paragraph("TimeTracker by ebility", brand),
        Paragraph("Timesheets", title),
        Paragraph(f"Worker : {_esc(sheet.get('worker') or 'Hannan, Brian - Employee')}", sub),
        Paragraph(
            f"Weekly Timesheets &nbsp;&nbsp;|&nbsp;&nbsp; View Payroll Period &nbsp;&nbsp; {pay}",
            sub,
        ),
        table,
        Spacer(1, 8),
        Paragraph(
            f"Pending: {int(round(sheet['total']))} Hours &nbsp;&nbsp; Submitted: 0 Hours &nbsp;&nbsp; Approved: 0 Hours",
            sub,
        ),
        Paragraph("Copy into Ebility (exact)", h2),
        Paragraph(_esc(sheet.get("copy_block") or ""), copy_s),
        PageBreak(),
        Paragraph("Evidence used to estimate hours", h2),
        Paragraph(
            f"Meetings {sheet['meta']['meetings']} · Client requests {sheet['meta'].get('requests', 0)} · "
            f"Hours spread Mon–Fri",
            sub,
        ),
    ]
    for cust, notes in (sheet.get("evidence") or {}).items():
        story.append(Paragraph(_esc(cust), h2))
        for n in notes:
            story.append(Paragraph("• " + _esc(n), ev_s))
    doc.build(story)
    return path
