#!/usr/bin/env python3
"""Export interface test results to a printable PDF.

Writes documents/test-results.pdf (stable name for the Tests tab) and a
branded twin when a *_V2_Route_Diagrams.pdf exists
(e.g. FHIR_R4_Platform_Test_Results.pdf).

Usage:
  python3 tools/export_test_results_pdf.py --root Clients/Demos/fhir-r4-platform
  # or after a run, from the in-memory report via write_from_report()
"""
from __future__ import annotations

import argparse
import json
from datetime import date
from pathlib import Path
from typing import Any

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


def esc(s: Any) -> str:
    return (
        str(s if s is not None else "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def branded_name(root: Path, interface: str) -> str | None:
    docs = root / "documents"
    if docs.is_dir():
        for p in sorted(docs.glob("*_V2_Route_Diagrams.pdf")):
            return p.name.replace("_V2_Route_Diagrams.pdf", "_Test_Results.pdf")
    slug = (interface or root.name).replace(" ", "_").replace("-", "_")
    if slug:
        return f"{slug}_Test_Results.pdf"
    return None


def _styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    return {
        "brand": ParagraphStyle(
            "b", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9, textColor=green
        ),
        "title": ParagraphStyle(
            "t",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=17,
            textColor=ink,
            spaceAfter=4,
        ),
        "sub": ParagraphStyle(
            "s",
            parent=base["Normal"],
            fontSize=10,
            textColor=colors.HexColor("#4b5568"),
            spaceAfter=10,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["Normal"],
            fontSize=9.5,
            leading=12.5,
            alignment=TA_LEFT,
            spaceAfter=5,
        ),
        "th": ParagraphStyle(
            "th",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8.0,
            textColor=colors.white,
        ),
        "td": ParagraphStyle(
            "td", parent=base["Normal"], fontSize=7.8, leading=10, textColor=ink
        ),
        "pass": ParagraphStyle(
            "pass",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8.0,
            textColor=colors.HexColor("#0b6e4f"),
        ),
        "fail": ParagraphStyle(
            "fail",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8.0,
            textColor=colors.HexColor("#b42318"),
        ),
        "skip": ParagraphStyle(
            "skip",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8.0,
            textColor=colors.HexColor("#b54708"),
        ),
        "err": ParagraphStyle(
            "err",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8.0,
            textColor=colors.HexColor("#b42318"),
        ),
    }


def _status_style(styles: dict[str, ParagraphStyle], status: str) -> ParagraphStyle:
    s = (status or "").lower()
    if s == "pass":
        return styles["pass"]
    if s == "skip":
        return styles["skip"]
    if s == "error":
        return styles["err"]
    return styles["fail"]


def write_from_report(root: Path, report: Any, out: Path | None = None) -> Path:
    """report may be a RunReport dataclass or a dict (asdict / loaded JSON)."""
    if hasattr(report, "__dataclass_fields__"):
        from dataclasses import asdict

        payload = asdict(report)
    elif isinstance(report, dict):
        payload = report
    else:
        raise TypeError(f"Unsupported report type: {type(report)!r}")
    return build(root, payload, out=out)


def build(root: Path, payload: dict[str, Any], out: Path | None = None) -> Path:
    docs = root / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    out_path = out or (docs / "test-results.pdf")
    out_path.parent.mkdir(parents=True, exist_ok=True)

    interface = payload.get("interface") or root.name
    summary = payload.get("summary") or {}
    results = payload.get("results") or []
    finished = payload.get("finished_at") or ""
    started = payload.get("started_at") or ""

    styles = _styles()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    story = []
    story.append(Paragraph(f"PILOTFISH  ·  {esc(interface).upper()}", styles["brand"]))
    story.append(Paragraph("Interface Test Results", styles["title"]))
    story.append(
        Paragraph(
            f"{esc(interface)}  ·  Generated {date.today().isoformat()}  ·  "
            f"Finished {esc(finished) or 'n/a'}",
            styles["sub"],
        )
    )

    failed = int(summary.get("fail", 0)) + int(summary.get("error", 0))
    overall = "PASS" if failed == 0 and int(summary.get("total", 0)) > 0 else (
        "NO RESULTS" if int(summary.get("total", 0)) == 0 else "FAIL"
    )
    story.append(
        Paragraph(
            f"<b>Overall: {esc(overall)}</b>  ·  "
            f"pass {int(summary.get('pass', 0))}  ·  "
            f"fail {int(summary.get('fail', 0))}  ·  "
            f"error {int(summary.get('error', 0))}  ·  "
            f"skip {int(summary.get('skip', 0))}  ·  "
            f"total {int(summary.get('total', 0))}",
            styles["body"],
        )
    )
    if started:
        story.append(Paragraph(f"Started {esc(started)}", styles["body"]))
    story.append(Spacer(1, 8))

    header = [
        Paragraph("Status", styles["th"]),
        Paragraph("Suite", styles["th"]),
        Paragraph("Test", styles["th"]),
        Paragraph("Message", styles["th"]),
        Paragraph("ms", styles["th"]),
    ]
    rows = [header]
    for r in results:
        status = str(r.get("status") or "")
        st = _status_style(styles, status)
        msg = str(r.get("message") or "")
        if len(msg) > 280:
            msg = msg[:277] + "…"
        rows.append(
            [
                Paragraph(esc(status.upper()), st),
                Paragraph(esc(r.get("suite") or ""), styles["td"]),
                Paragraph(esc(r.get("name") or ""), styles["td"]),
                Paragraph(esc(msg), styles["td"]),
                Paragraph(esc(r.get("duration_ms") or 0), styles["td"]),
            ]
        )

    if len(rows) == 1:
        rows.append(
            [
                Paragraph("—", styles["td"]),
                Paragraph("", styles["td"]),
                Paragraph("No test cases recorded.", styles["td"]),
                Paragraph("", styles["td"]),
                Paragraph("", styles["td"]),
            ]
        )

    table = Table(
        rows,
        colWidths=[0.7 * inch, 1.35 * inch, 1.7 * inch, 3.0 * inch, 0.45 * inch],
        repeatRows=1,
    )
    style_cmds = [
        ("BACKGROUND", (0, 0), (-1, 0), green),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#d4dbe8")),
        ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f8fafc")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
    ]
    # Stripe fail/error rows lightly
    for i, r in enumerate(results, start=1):
        st = str(r.get("status") or "").lower()
        if st in {"fail", "error"}:
            style_cmds.append(
                ("BACKGROUND", (0, i), (-1, i), colors.HexColor("#fef3f2"))
            )
        elif st == "skip":
            style_cmds.append(
                ("BACKGROUND", (0, i), (-1, i), colors.HexColor("#fffaeb"))
            )
    table.setStyle(TableStyle(style_cmds))
    story.append(table)
    story.append(Spacer(1, 10))
    story.append(
        Paragraph(
            "Source: documents/test-results.json (written by "
            "<b>python3 tools/run_interface_tests.py</b>). "
            "Open this PDF from disk — no browser required.",
            styles["sub"],
        )
    )

    def _footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(ink)
        canvas.drawString(0.75 * inch, 0.5 * inch, "PilotFish  ·  Interface Test Results")
        canvas.drawRightString(letter[0] - 0.75 * inch, 0.5 * inch, f"Page {doc.page}")
        canvas.restoreState()

    doc = SimpleDocTemplate(
        str(out_path),
        pagesize=letter,
        leftMargin=0.65 * inch,
        rightMargin=0.65 * inch,
        topMargin=0.6 * inch,
        bottomMargin=0.7 * inch,
        title=f"Test Results — {interface}",
        author="PilotFish",
    )
    doc.build(story, onFirstPage=_footer, onLaterPages=_footer)

    # Branded twin for stakeholder docs folder parity
    twin = branded_name(root, str(interface))
    if twin and twin != out_path.name:
        branded_path = docs / twin
        branded_path.write_bytes(out_path.read_bytes())

    # Mirror under output/ for local tooling
    mirror_dir = root / "output" / "test-results"
    mirror_dir.mkdir(parents=True, exist_ok=True)
    (mirror_dir / "latest.pdf").write_bytes(out_path.read_bytes())

    return out_path


def build_from_json(root: Path, json_path: Path | None = None, out: Path | None = None) -> Path:
    path = json_path or (root / "documents" / "test-results.json")
    if not path.is_file():
        raise SystemExit(f"Missing results JSON: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    return build(root, payload, out=out)


def main() -> int:
    parser = argparse.ArgumentParser(description="Export test-results.json to PDF")
    parser.add_argument("--root", type=Path, default=None, help="Interface root (default: cwd)")
    parser.add_argument("--json", type=Path, default=None, help="Path to test-results.json")
    parser.add_argument("--out", type=Path, default=None, help="Output PDF path")
    args = parser.parse_args()
    root = (args.root or Path.cwd()).resolve()
    path = build_from_json(root, json_path=args.json, out=args.out)
    print("Wrote", path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
