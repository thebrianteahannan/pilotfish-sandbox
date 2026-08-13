"""Load a client's implementation guide and keep request plans honest."""

from __future__ import annotations

import json
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import ListFlowable, ListItem, Paragraph, SimpleDocTemplate, Spacer

JSON_NAME = "implementation-guide.json"
MD_NAME = "MedRec_Interface_Implementation.md"
PDF_NAME = "MedRec_Interface_Implementation.pdf"


def documents_dir(root: Path) -> Path:
    path = root / "documents"
    path.mkdir(parents=True, exist_ok=True)
    return path


def pdf_path(root: Path) -> Path | None:
    folder = root / "documents"
    rules: dict = {}
    js = folder / JSON_NAME
    if js.is_file():
        try:
            loaded = json.loads(js.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                rules = loaded
        except (OSError, json.JSONDecodeError):
            rules = {}
    rel = str(rules.get("pdf") or f"documents/{PDF_NAME}")
    path = (root / rel).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError:
        return None
    return path if path.is_file() else None


def load_rules(root: Path) -> dict:
    path = documents_dir(root) / JSON_NAME
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def apply(root: Path, dive: dict) -> dict:
    rules = load_rules(root)
    if not rules:
        return dive
    dive["impl_guide"] = str(rules.get("pdf") or f"documents/{PDF_NAME}")
    if rules.get("strip_is_not_map_delete") and dive.get("intent") == "strip":
        dive["edits"] = [e for e in (dive.get("edits") or []) if e.get("action") != "remove_when"]
        dive["risks"] = [
            r
            for r in (dive.get("risks") or [])
            if "when-branches" not in r and "deleting the when" not in r.lower()
        ]
    return dive


def _esc(s: str) -> str:
    text = (
        str(s or "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\n", "<br/>")
    )
    text = re.sub(r"`([^`]+)`", r"<font face='Courier'>\1</font>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    return text


def _styles() -> dict:
    base = getSampleStyleSheet()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    muted = colors.HexColor("#4b5568")
    return {
        "brand": ParagraphStyle("b", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9, textColor=green),
        "title": ParagraphStyle("t", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=16, textColor=ink, spaceAfter=6),
        "h2": ParagraphStyle("h2", parent=base["Heading2"], fontName="Helvetica-Bold", fontSize=11.5, textColor=green, spaceBefore=12, spaceAfter=5),
        "h3": ParagraphStyle("h3", parent=base["Heading3"], fontName="Helvetica-Bold", fontSize=10, textColor=ink, spaceBefore=8, spaceAfter=3),
        "body": ParagraphStyle("body", parent=base["Normal"], fontSize=9.5, leading=12.8, alignment=TA_JUSTIFY, spaceAfter=6),
        "left": ParagraphStyle("left", parent=base["Normal"], fontSize=9.2, leading=12.4, alignment=TA_LEFT, spaceAfter=3),
        "bu": ParagraphStyle("bu", parent=base["Normal"], fontSize=9.2, leading=12.2),
        "th": ParagraphStyle("th", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=8.5, leading=11),
        "td": ParagraphStyle("td", parent=base["Normal"], fontSize=8.5, leading=11),
        "note": ParagraphStyle("n", parent=base["Normal"], fontName="Helvetica-Oblique", fontSize=8.5, textColor=muted, spaceBefore=8),
    }


def _md_to_story(md: str, styles: dict, footer: str | None = None) -> list:
    from reportlab.platypus import Table, TableStyle

    story: list = []
    chunks = re.split(r"\n{2,}", (md or "").strip())
    for chunk in chunks:
        lines = [ln.rstrip() for ln in chunk.splitlines() if ln.strip()]
        if not lines:
            continue
        first = lines[0]
        if first.startswith("# "):
            story.append(Paragraph("PILOTFISH  ·  MED REC", styles["brand"]))
            story.append(Paragraph(_esc(first[2:].strip()), styles["title"]))
            continue
        if first.startswith("### "):
            story.append(Paragraph(_esc(first[4:].strip()), styles["h3"]))
            rest = lines[1:]
            if rest:
                story.append(Paragraph(_esc(" ".join(rest)), styles["body"]))
            continue
        if first.startswith("## "):
            story.append(Paragraph(_esc(first[3:].strip()), styles["h2"]))
            rest = lines[1:]
            if rest and not rest[0].startswith("|") and not rest[0].startswith("- "):
                story.append(Paragraph(_esc(" ".join(rest)), styles["body"]))
            elif rest and rest[0].startswith("- "):
                items = [ListItem(Paragraph(_esc(ln[2:].strip()), styles["bu"]), leftIndent=8) for ln in rest]
                story.append(ListFlowable(items, bulletType="bullet", start="•"))
            continue
        if first.startswith("| "):
            rows = []
            for ln in lines:
                if re.match(r"^\|\s*---", ln):
                    continue
                cells = [c.strip() for c in ln.strip("|").split("|")]
                rows.append(cells)
            if rows:
                data = []
                for i, row in enumerate(rows):
                    sty = styles["th"] if i == 0 else styles["td"]
                    data.append([Paragraph(_esc(c), sty) for c in row])
                table = Table(data, colWidths=[2.4 * inch, 4.5 * inch])
                table.setStyle(
                    TableStyle(
                        [
                            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e8f2ec")),
                            ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#d5e0ea")),
                            ("VALIGN", (0, 0), (-1, -1), "TOP"),
                            ("LEFTPADDING", (0, 0), (-1, -1), 6),
                            ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                            ("TOPPADDING", (0, 0), (-1, -1), 4),
                            ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                        ]
                    )
                )
                story.append(table)
                story.append(Spacer(1, 0.12 * inch))
            continue
        if first.startswith("- "):
            items = [ListItem(Paragraph(_esc(ln[2:].strip()), styles["bu"]), leftIndent=8) for ln in lines]
            story.append(ListFlowable(items, bulletType="bullet", start="•"))
            continue
        story.append(Paragraph(_esc(" ".join(lines)), styles["body"]))
    if footer:
        story.append(Paragraph(footer, styles["note"]))
    return story


def write_pdf(root: Path, dest: Path | None = None) -> Path:
    folder = documents_dir(root)
    md_path = folder / MD_NAME
    out = dest or (folder / PDF_NAME)
    md = md_path.read_text(encoding="utf-8") if md_path.is_file() else "# Med Rec interface implementation\n"
    styles = _styles()
    doc = SimpleDocTemplate(
        str(out),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.65 * inch,
        title="Med Rec interface implementation",
        author="PilotFish Sandbox",
    )
    doc.build(
        _md_to_story(
            md,
            styles,
            footer=(
                "The hub reads documents/implementation-guide.json when it builds a change plan. "
                "Update this guide when the real interface rules change."
            ),
        )
    )
    return out


if __name__ == "__main__":
    import clients

    root = clients.require_root("med-rec")
    path = write_pdf(root)
    print(path)
