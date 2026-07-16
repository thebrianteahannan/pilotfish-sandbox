#!/usr/bin/env python3
"""Landscape PDF: Captures table structure + data (up to 100 rows)."""

from __future__ import annotations

import subprocess
from datetime import datetime, timezone
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "PilotFishDemo_Captures_Table.pdf"
MAX_ROWS = 100


def sqlcmd(query: str) -> str:
    cmd = [
        "docker",
        "compose",
        "exec",
        "-T",
        "sqlserver",
        "/opt/mssql-tools18/bin/sqlcmd",
        "-S",
        "localhost",
        "-U",
        "sa",
        "-P",
        "PilotFish_Demo1!",
        "-C",
        "-d",
        "PilotFishDemo",
        "-Q",
        query,
        "-h",
        "-1",
        "-W",
        "-s",
        "|",
    ]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=True)
    return result.stdout


def fetch_schema() -> list[list[str]]:
    raw = sqlcmd(
        "SET NOCOUNT ON; "
        "SELECT COLUMN_NAME, DATA_TYPE, "
        "COALESCE(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(20)), 'n/a'), "
        "IS_NULLABLE "
        "FROM INFORMATION_SCHEMA.COLUMNS "
        "WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Captures' "
        "ORDER BY ORDINAL_POSITION;"
    )
    rows = [["Column", "Data Type", "Max Length", "Nullable"]]
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("-") or "|" not in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 4 and parts[0] != "COLUMN_NAME":
            rows.append(parts[:4])
    return rows


def fetch_data() -> list[list[str]]:
    raw = sqlcmd(
        "SET NOCOUNT ON; "
        "SELECT TOP 100 "
        "CaptureId, ClientName, DocumentType, Status, CapturePayload, "
        "CONVERT(VARCHAR(19), CreatedAt, 126) "
        "FROM dbo.Captures ORDER BY CaptureId;"
    )
    rows = [
        [
            "CaptureId",
            "ClientName",
            "DocumentType",
            "Status",
            "CapturePayload",
            "CreatedAt",
        ]
    ]
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("-") or "|" not in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 6 and parts[0] != "CaptureId":
            rows.append(parts[:6])
    return rows[: MAX_ROWS + 1]


def make_table(data: list[list[str]], col_widths: list[float]) -> Table:
    styled = []
    for i, row in enumerate(data):
        if i == 0:
            styled.append(
                [Paragraph(f"<b>{cell}</b>", ParagraphStyle("h", fontSize=8, leading=10, alignment=TA_CENTER)) for cell in row]
            )
        else:
            styled.append(
                [Paragraph(str(cell), ParagraphStyle("c", fontSize=8, leading=10, alignment=TA_LEFT)) for cell in row]
            )
    t = Table(styled, colWidths=col_widths, repeatRows=1)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3a5f")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f7f9fc")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#f7f9fc"), colors.white]),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#9aa7b8")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def main() -> None:
    schema = fetch_schema()
    data = fetch_data()
    data_row_count = max(0, len(data) - 1)
    generated = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    page = landscape(letter)
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=page,
        leftMargin=0.5 * inch,
        rightMargin=0.5 * inch,
        topMargin=0.45 * inch,
        bottomMargin=0.4 * inch,
        title="PilotFishDemo Captures Table",
    )
    styles = getSampleStyleSheet()
    title = ParagraphStyle(
        "title",
        parent=styles["Heading1"],
        fontSize=16,
        leading=18,
        textColor=colors.HexColor("#1f3a5f"),
        spaceAfter=4,
    )
    subtitle = ParagraphStyle(
        "subtitle",
        parent=styles["Normal"],
        fontSize=9,
        leading=12,
        textColor=colors.HexColor("#334155"),
        spaceAfter=10,
    )
    section = ParagraphStyle(
        "section",
        parent=styles["Heading2"],
        fontSize=11,
        leading=13,
        textColor=colors.HexColor("#1f3a5f"),
        spaceBefore=8,
        spaceAfter=6,
    )

    usable = page[0] - doc.leftMargin - doc.rightMargin
    story = [
        Paragraph("PilotFishDemo — Captures Table", title),
        Paragraph(
            f"Database: <b>PilotFishDemo</b> &nbsp;|&nbsp; Schema: <b>dbo</b> &nbsp;|&nbsp; "
            f"Table: <b>Captures</b> &nbsp;|&nbsp; Rows shown: <b>{data_row_count}</b> "
            f"(max {MAX_ROWS}) &nbsp;|&nbsp; Generated: {generated}",
            subtitle,
        ),
        Paragraph("Table Structure", section),
        make_table(schema, [1.6 * inch, 1.4 * inch, 1.3 * inch, 1.2 * inch]),
        Spacer(1, 0.18 * inch),
        Paragraph("Table Data", section),
        make_table(
            data,
            [
                0.85 * inch,
                1.5 * inch,
                1.15 * inch,
                0.95 * inch,
                usable - (0.85 + 1.5 + 1.15 + 0.95 + 1.4) * inch,
                1.4 * inch,
            ],
        ),
    ]
    doc.build(story)
    print(OUT)


if __name__ == "__main__":
    main()
