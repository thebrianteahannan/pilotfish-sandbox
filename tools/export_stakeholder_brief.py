#!/usr/bin/env python3
"""Generate a stakeholder-facing Interface Capability Brief PDF.

Sources (best-effort, all optional except that the demo root must exist):
  - DESIGN.md          (purpose, actors, in-scope / deferred, ops)
  - CapabilityStatement JSON when present (FHIR demos)
  - route.v2.xml       (high-level route inventory)
  - README.md          (title / ports hints)

Usage:
  python3 tools/export_stakeholder_brief.py --root Clients/Demos/fhir-r4-platform
  cd Clients/Demos/fhir-r4-platform && python3 tools/export_stakeholder_brief.py
"""
from __future__ import annotations

import argparse
import json
import re
import xml.etree.ElementTree as ET
from datetime import date
from pathlib import Path

from demo_paths import require_demo
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    KeepTogether,
    ListFlowable,
    ListItem,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

INTERACTION_LABELS = {
    "create": "Create",
    "read": "Read",
    "update": "Update",
    "delete": "Delete (soft)",
    "search-type": "Search",
    "vread": "Versioned read",
    "history-instance": "History",
    "history-type": "Type history",
    "patch": "Patch",
}

FRIENDLY_KIND = {
    "listener": "Receives inbound traffic",
    "processor": "Transforms or enriches the message",
    "transform": "Maps / converts formats",
    "routing": "Decides which path to take",
    "transport": "Delivers the outbound response or file",
    "post-processor": "Post-processing / cleanup",
}


def demo_title(root: Path) -> str:
    readme = root / "README.md"
    if readme.is_file():
        for line in readme.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if line.startswith("# "):
                return line[2:].strip()
    design = root / "DESIGN.md"
    if design.is_file():
        for line in design.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if line.startswith("# "):
                return re.sub(r"^DESIGN\.md\s*[—–-]\s*", "", line[2:]).strip()
    return root.name.replace("-", " ").title()


def brand_line(root: Path, title: str) -> str:
    short = re.sub(r"\s+", " ", title)
    short = re.sub(r"\s*\(.*?\)\s*", " ", short).strip()
    if len(short) > 48:
        short = short[:45].rstrip() + "…"
    return f"PILOTFISH  ·  {short.upper()}"


def output_pdf_name(root: Path) -> str:
    docs = root / "documents"
    if docs.is_dir():
        for p in sorted(docs.glob("*_V2_Route_Diagrams.pdf")):
            return p.name.replace("_V2_Route_Diagrams.pdf", "_Capability_Brief.pdf")
    slug = re.sub(r"[^A-Za-z0-9]+", "_", root.name).strip("_")
    return f"{slug}_Capability_Brief.pdf"


def find_capability_statement(root: Path) -> Path | None:
    candidates = list(root.glob("**/capability-statement.json"))
    # Prefer eip-root over nested copies
    preferred = [p for p in candidates if "eip-root" in p.parts]
    pool = preferred or candidates
    if not pool:
        return None
    pool.sort(key=lambda p: (0 if "Phase" in p.read_text(encoding="utf-8", errors="ignore")[:200] else 1, len(str(p))))
    return pool[0]


def find_route_v2_files(root: Path) -> list[Path]:
    found = sorted(root.glob("eip-root/**/route.v2.xml"))
    if found:
        return found
    return sorted(root.glob("**/route.v2.xml"))


# ---------- markdown helpers ----------

def parse_markdown_sections(text: str) -> list[tuple[int, str, str]]:
    """Return [(level, heading, body), ...] for ATX headings."""
    lines = text.splitlines()
    sections: list[tuple[int, str, list[str]]] = []
    cur_level, cur_title, buf = 0, "Document", []
    for line in lines:
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            if cur_title or buf:
                sections.append((cur_level, cur_title, buf))
            cur_level = len(m.group(1))
            cur_title = m.group(2).strip()
            buf = []
        else:
            buf.append(line)
    sections.append((cur_level, cur_title, buf))
    return [(lvl, title, "\n".join(body).strip()) for lvl, title, body in sections]


def first_paragraph(body: str) -> str:
    chunks = re.split(r"\n\s*\n", body.strip())
    for chunk in chunks:
        cleaned = chunk.strip()
        if not cleaned or cleaned.startswith("|") or cleaned.startswith("```"):
            continue
        # Drop pure ASCII diagrams
        if cleaned.startswith("```") or (cleaned.count("│") + cleaned.count("▼") > 2):
            continue
        return re.sub(r"\s+", " ", cleaned)
    return ""


def parse_md_tables(body: str) -> list[list[list[str]]]:
    tables: list[list[list[str]]] = []
    lines = body.splitlines()
    i = 0
    while i < len(lines):
        if "|" in lines[i] and i + 1 < len(lines) and re.match(r"^\s*\|?[\s:-]+\|", lines[i + 1]):
            rows = []
            while i < len(lines) and "|" in lines[i]:
                if re.match(r"^\s*\|?[\s:-]+\|", lines[i]):
                    i += 1
                    continue
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                rows.append(cells)
                i += 1
            if rows:
                tables.append(rows)
            continue
        i += 1
    return tables


def section_by_title(sections: list[tuple[int, str, str]], *hints: str) -> tuple[str, str] | None:
    for _lvl, title, body in sections:
        t = title.lower()
        for h in hints:
            if h.lower() in t:
                return title, body
    return None


def bullets_from_body(body: str, limit: int = 12) -> list[str]:
    items = []
    for line in body.splitlines():
        m = re.match(r"^\s*[-*•]\s+(.*)$", line)
        if m:
            items.append(re.sub(r"\s+", " ", m.group(1).strip()))
        if len(items) >= limit:
            break
    return items


def strip_md(text: str) -> str:
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# ---------- route / capstmt ----------

def summarize_routes(files: list[Path]) -> list[dict]:
    out = []
    for path in files:
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError:
            continue
        name = root.get("name") or path.parent.name
        nodes = []
        for n in root.findall("./Nodes/Node"):
            nodes.append(
                {
                    "kind": (n.get("kind") or "processor").lower(),
                    "label": n.get("name") or n.get("label") or n.get("id") or "step",
                }
            )
        listeners = [n["label"] for n in nodes if n["kind"] == "listener"]
        transports = [n["label"] for n in nodes if n["kind"] == "transport"]
        processors = [n["label"] for n in nodes if n["kind"] not in ("listener", "transport")]
        out.append(
            {
                "name": name,
                "path": path,
                "listeners": listeners,
                "transports": transports,
                "processors": processors[:8],
                "node_count": len(nodes),
            }
        )
    return out


def load_capstmt(path: Path | None) -> dict | None:
    if not path or not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None


def capstmt_resource_rows(cap: dict) -> list[list[str]]:
    rows = [["Resource", "Supported actions", "Search highlights"]]
    rest = (cap.get("rest") or [{}])[0]
    for res in rest.get("resource") or []:
        rtype = res.get("type") or "?"
        acts = ", ".join(
            INTERACTION_LABELS.get(i.get("code", ""), i.get("code", ""))
            for i in (res.get("interaction") or [])
        ) or "—"
        params = [p.get("name") for p in (res.get("searchParam") or []) if p.get("name")]
        search = ", ".join(params[:8]) + ("…" if len(params) > 8 else "") if params else "—"
        rows.append([rtype, acts, search])
    return rows


def capstmt_ops(cap: dict) -> list[str]:
    ops = []
    rest = (cap.get("rest") or [{}])[0]
    for op in rest.get("operation") or []:
        name = op.get("name") or op.get("code") or "operation"
        doc = op.get("documentation") or ""
        ops.append(f"${name}" + (f" — {doc}" if doc else ""))
    for inter in rest.get("interaction") or []:
        code = inter.get("code")
        if code:
            ops.append(f"System interaction: {code}")
    # Also resource-level ops
    for res in rest.get("resource") or []:
        for op in res.get("operation") or []:
            name = op.get("name") or "?"
            ops.append(f"{res.get('type')}/${name}")
    # de-dupe preserve order
    seen = set()
    uniq = []
    for o in ops:
        if o not in seen:
            seen.add(o)
            uniq.append(o)
    return uniq


# ---------- PDF styles / chrome ----------

def make_styles():
    base = getSampleStyleSheet()
    green = colors.HexColor("#0b6e4f")
    ink = colors.HexColor("#172033")
    muted = colors.HexColor("#4b5568")
    return {
        "brand": ParagraphStyle(
            "Brand",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=9,
            textColor=green,
            spaceAfter=2,
        ),
        "title": ParagraphStyle(
            "Title",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=18,
            textColor=ink,
            spaceAfter=4,
            spaceBefore=2,
            leading=22,
        ),
        "subtitle": ParagraphStyle(
            "Subtitle",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=10.5,
            textColor=muted,
            spaceAfter=12,
            leading=14,
        ),
        "h2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12.5,
            textColor=green,
            spaceBefore=14,
            spaceAfter=6,
            leading=15,
        ),
        "h3": ParagraphStyle(
            "H3",
            parent=base["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=10.5,
            textColor=ink,
            spaceBefore=10,
            spaceAfter=4,
        ),
        "body": ParagraphStyle(
            "Body",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            alignment=TA_JUSTIFY,
            textColor=ink,
            spaceAfter=6,
        ),
        "bullet": ParagraphStyle(
            "Bullet",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=12.5,
            textColor=ink,
            leftIndent=2,
            spaceAfter=2,
        ),
        "note": ParagraphStyle(
            "Note",
            parent=base["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=9,
            leading=12,
            textColor=muted,
            spaceAfter=8,
        ),
        "footer": ParagraphStyle(
            "Footer",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=8,
            textColor=muted,
            alignment=TA_CENTER,
        ),
        "th": ParagraphStyle(
            "TH",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=8.5,
            textColor=colors.white,
            leading=11,
        ),
        "td": ParagraphStyle(
            "TD",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=8.2,
            leading=11,
            textColor=ink,
        ),
    }


def bullets(items: list[str], styles) -> ListFlowable:
    return ListFlowable(
        [ListItem(Paragraph(strip_md(i), styles["bullet"]), leftIndent=8, value="•") for i in items],
        bulletType="bullet",
        start="•",
        leftIndent=12,
        spaceBefore=2,
        spaceAfter=8,
    )


def styled_table(rows: list[list[str]], styles, col_widths=None) -> Table:
    data = []
    for r_i, row in enumerate(rows):
        style = styles["th"] if r_i == 0 else styles["td"]
        data.append([Paragraph(strip_md(c), style) for c in row])
    t = Table(data, colWidths=col_widths, hAlign="LEFT", repeatRows=1)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0b6e4f")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f8fafc")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#f8fafc"), colors.white]),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#d4dbe8")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def plain_route_blurb(route: dict) -> str:
    bits = []
    if route["listeners"]:
        bits.append("listens via " + ", ".join(route["listeners"][:3]))
    if route["processors"]:
        bits.append("runs steps such as " + ", ".join(route["processors"][:4]))
    if route["transports"]:
        bits.append("responds or delivers through " + ", ".join(route["transports"][:3]))
    if not bits:
        return f"{route['name']} ({route['node_count']} connected steps)."
    return f"{route['name']}: " + "; ".join(bits) + "."


def build_pdf(root: Path, out_path: Path) -> Path:
    title = demo_title(root)
    brand = brand_line(root, title)
    styles = make_styles()

    design_text = (root / "DESIGN.md").read_text(encoding="utf-8", errors="replace") if (root / "DESIGN.md").is_file() else ""
    sections = parse_markdown_sections(design_text) if design_text else []
    cap_path = find_capability_statement(root)
    cap = load_capstmt(cap_path)
    routes = summarize_routes(find_route_v2_files(root))
    route_pdf = None
    docs_dir = root / "documents"
    if docs_dir.is_dir():
        hits = list(docs_dir.glob("*_V2_Route_Diagrams.pdf"))
        route_pdf = hits[0].name if hits else None

    story = []
    story.append(Paragraph(brand, styles["brand"]))
    story.append(Paragraph("Interface Capability Brief", styles["title"]))
    story.append(
        Paragraph(
            f"{strip_md(title)}  ·  Stakeholder overview  ·  {date.today().isoformat()}",
            styles["subtitle"],
        )
    )

    # --- Executive summary ---
    story.append(Paragraph("1. Executive summary", styles["h2"]))
    purpose = section_by_title(sections, "purpose", "business goal", "goal")
    summary = ""
    if purpose:
        summary = first_paragraph(purpose[1])
    if not summary and cap and cap.get("description"):
        summary = cap["description"]
    if not summary:
        summary = (
            f"{title} is a PilotFish demo interface that integrates systems using "
            "configurable listeners, processors, and transports. This brief summarizes "
            "what it can do today for stakeholders."
        )
    story.append(Paragraph(strip_md(summary), styles["body"]))
    if cap:
        ver = cap.get("version") or ""
        fhir = cap.get("fhirVersion") or ""
        meta = []
        if fhir:
            meta.append(f"FHIR {fhir}")
        if ver:
            meta.append(f"CapabilityStatement {ver}")
        if cap.get("status"):
            meta.append(str(cap["status"]))
        if meta:
            story.append(Paragraph(strip_md(" · ".join(meta)), styles["note"]))

    # --- Who it's for ---
    story.append(Paragraph("2. Who this is for", styles["h2"]))
    actors = section_by_title(sections, "actor", "context", "narrative")
    actor_items = []
    if actors:
        tables = parse_md_tables(actors[1])
        if tables:
            # Prefer Actor/Role style tables
            for table in tables:
                headers = [h.lower() for h in table[0]]
                if any("actor" in h or "role" in h or "source" in h for h in headers):
                    for row in table[1:]:
                        actor_items.append(" — ".join(row[:3]))
        if not actor_items:
            actor_items = bullets_from_body(actors[1])
        para = first_paragraph(actors[1])
        if para and "Demo narrative" not in actors[0]:
            story.append(Paragraph(strip_md(para), styles["body"]))
    if not actor_items:
        actor_items = [
            "Business / clinical stakeholders evaluating whether the integration covers needed workflows",
            "Solution architects comparing PilotFish capabilities to project requirements",
            "Demo audiences walking the happy-path in the Web UI",
        ]
    story.append(bullets(actor_items[:8], styles))

    # --- Capabilities ---
    story.append(Paragraph("3. What the interface can do", styles["h2"]))
    story.append(
        Paragraph(
            "Capabilities below are drawn from the working design and, when present, the "
            "published CapabilityStatement — not from aspirational roadmap items.",
            styles["note"],
        )
    )

    in_scope = section_by_title(sections, "honest scope", "in scope", "phase", "inbound", "outbound")
    if in_scope:
        tables = parse_md_tables(in_scope[1])
        used_table = False
        for table in tables:
            headers = " ".join(table[0]).lower()
            if "deferred" in headers or "in phase" in headers or "destination" in headers or "format" in headers:
                story.append(Paragraph(strip_md(in_scope[0]), styles["h3"]))
                # keep tables readable
                width = 7.0 * inch
                if len(table[0]) == 2:
                    cols = [3.2 * inch, 3.8 * inch]
                elif len(table[0]) == 3:
                    cols = [2.1 * inch, 2.5 * inch, 2.4 * inch]
                else:
                    cols = None
                story.append(styled_table(table[:16], styles, cols))
                story.append(Spacer(1, 6))
                used_table = True
        if not used_table:
            items = bullets_from_body(in_scope[1])
            if items:
                story.append(bullets(items, styles))
            else:
                p = first_paragraph(in_scope[1])
                if p:
                    story.append(Paragraph(strip_md(p), styles["body"]))

    if cap:
        story.append(Paragraph("FHIR resources &amp; actions", styles["h3"]))
        if cap.get("description"):
            story.append(Paragraph(strip_md(cap["description"]), styles["body"]))
        rows = capstmt_resource_rows(cap)
        story.append(
            styled_table(
                rows,
                styles,
                [1.5 * inch, 2.5 * inch, 3.0 * inch],
            )
        )
        story.append(
            Paragraph(
                f"{len(rows) - 1} FHIR resource type(s) declared for this instance.",
                styles["note"],
            )
        )
        ops = capstmt_ops(cap)
        if ops:
            story.append(Paragraph("Server operations &amp; system interactions", styles["h3"]))
            story.append(bullets(ops[:16], styles))
        formats = cap.get("format") or []
        if formats:
            story.append(
                Paragraph(
                    "Supported formats: " + strip_md(", ".join(str(f) for f in formats)),
                    styles["body"],
                )
            )

    # DESIGN capabilities bullets from validation / pipeline if no CapStmt
    if not cap:
        pipe = section_by_title(sections, "pipeline", "architecture", "module")
        if pipe:
            story.append(Paragraph("Integration highlights", styles["h3"]))
            p = first_paragraph(pipe[1])
            if p:
                story.append(Paragraph(strip_md(p), styles["body"]))
            tables = parse_md_tables(pipe[1])
            if tables:
                t = tables[0]
                # reduce FQCN noise for stakeholders — keep Stage / Notes columns when present
                headers = [h.lower() for h in t[0]]
                keep_idx = list(range(min(3, len(t[0]))))
                slim = [[t[0][i] for i in keep_idx]]
                for row in t[1:12]:
                    slim.append([(row[i] if i < len(row) else "") for i in keep_idx])
                widths = [2.2 * inch] * len(keep_idx)
                story.append(styled_table(slim, styles, widths))

    # --- Out of scope ---
    story.append(Paragraph("4. Honest boundaries (not claimed yet)", styles["h2"]))
    deferred_bits = []
    scope = section_by_title(sections, "honest scope", "deferred", "open questions", "risks")
    if scope:
        for table in parse_md_tables(scope[1]):
            headers = [h.lower() for h in table[0]]
            # columns like In Phase | Explicitly deferred
            if len(headers) >= 2 and any("defer" in h for h in headers):
                di = next(i for i, h in enumerate(headers) if "defer" in h)
                for row in table[1:]:
                    if di < len(row) and row[di].strip():
                        deferred_bits.append(row[di].strip())
        deferred_bits.extend(bullets_from_body(scope[1]))
    openq = section_by_title(sections, "open question")
    if openq:
        deferred_bits.extend(bullets_from_body(openq[1]))
    if cap and cap.get("description") and "Deferred:" in cap["description"]:
        deferred_bits.append(cap["description"].split("Deferred:", 1)[1].strip())
    if not deferred_bits:
        deferred_bits = [
            "Production hardening (HA, disaster recovery, full audit workflows) is outside this demo brief",
            "Anything not listed in §3 should be treated as future work unless confirmed in DESIGN.md",
        ]
    # de-dupe
    seen = set()
    uniq = []
    for b in deferred_bits:
        key = b.lower()
        if key not in seen:
            seen.add(key)
            uniq.append(b)
    story.append(bullets(uniq[:10], styles))

    # --- Stakeholder scenarios ---
    story.append(Paragraph("5. What you can verify in a walkthrough", styles["h2"]))
    story.append(
        Paragraph(
            "Use these as checklist items when reviewing the demo with business stakeholders. "
            "They describe outcomes, not module names.",
            styles["note"],
        )
    )
    scenarios = []
    narrative = section_by_title(sections, "demo narrative", "bulk", "phase 6", "purpose")
    if narrative:
        scenarios.extend(bullets_from_body(narrative[1])[:8])
    if cap:
        scenarios.extend(
            [
                "Create and read clinical resources (for example Patient) through the FHIR REST façade",
                "Search using the indexed parameters declared for each resource type",
                "Reject or accept writes according to validation rules configured for the demo",
            ]
        )
        ops_list = capstmt_ops(cap)
        ops_blob = " ".join(ops_list).lower()
        if "export" in ops_blob:
            scenarios.append(
                "Kick off an async Bulk $export, poll job status, and download NDJSON output files"
            )
        if any("transaction" in o.lower() or "batch" in o.lower() for o in ops_list):
            scenarios.append("Submit a Bundle as transaction (atomic) or batch (per-entry status)")
        sec = ((cap.get("rest") or [{}])[0].get("security") or {}).get("description") or ""
        if "bearer" in sec.lower() or "oauth" in sec.lower():
            scenarios.append(
                "Confirm unauthenticated writes are rejected and Bearer tokens unlock write/export paths"
            )
    if not scenarios:
        for r in routes[:4]:
            scenarios.append(f"Exercise route “{r['name']}” from the Web UI or documented smoke path")
        scenarios.append(
            "Confirm outputs land in the documented folders / queues and appear in the Web UI status views"
        )
    seen_s = set()
    uniq_s = []
    for s in scenarios:
        k = s.lower()
        if k not in seen_s:
            seen_s.add(k)
            uniq_s.append(s)
    story.append(bullets(uniq_s[:12], styles))

    # --- How it works ---
    story.append(Paragraph("6. How it works (plain language)", styles["h2"]))
    narrative2 = section_by_title(sections, "demo narrative", "architecture", "phase 6", "bulk")
    if narrative2:
        p = first_paragraph(narrative2[1])
        if p:
            story.append(Paragraph(strip_md(p), styles["body"]))
        items = bullets_from_body(narrative2[1])
        if items:
            story.append(bullets(items[:8], styles))

    for hint in ("validation", "state", "dual-write", "inbound contract", "outbound contract"):
        sec = section_by_title(sections, hint)
        if not sec:
            continue
        p = first_paragraph(sec[1])
        if not p:
            continue
        story.append(Paragraph(strip_md(sec[0]), styles["h3"]))
        story.append(Paragraph(strip_md(p), styles["body"]))

    if routes:
        story.append(Paragraph("Routes in this interface", styles["h3"]))
        story.append(
            Paragraph(
                "Each route is a configured PilotFish flow. Technical wiring appears in the "
                "Route Diagrams PDF; here is the stakeholder reading.",
                styles["note"],
            )
        )
        for r in routes:
            story.append(Paragraph(strip_md(plain_route_blurb(r)), styles["body"]))
    else:
        story.append(
            Paragraph(
                "Route inventory was not found (no route.v2.xml yet). Generate V2 routes, then re-run this brief.",
                styles["note"],
            )
        )

    # --- Security ---
    story.append(Paragraph("7. Security &amp; trust posture", styles["h2"]))
    sec_items = []
    if cap:
        sec = (cap.get("rest") or [{}])[0].get("security") or {}
        if sec.get("description"):
            sec_items.append(sec["description"])
        for svc in sec.get("service") or []:
            text = svc.get("text")
            if text:
                sec_items.append(text)
    blob = design_text.lower()
    if "keycloak" in blob or "bearer" in blob or "oauth" in blob:
        sec_items.append(
            "OAuth2 / OIDC Bearer tokens (Keycloak in this demo) protect write and export operations"
        )
    if "snip" in blob:
        sec_items.append(
            "X12 SNIP validation is used where configured to reject bad EDI before downstream work"
        )
    if "validate" in blob or "hapi" in blob:
        sec_items.append("Inbound clinical/FHIR payloads can be validated before persistence")
    if "demo" in blob and ("password" in blob or "demo-only" in blob or "demo only" in blob):
        sec_items.append("Credentials and passwords in this package are demo-only — not production secrets")
    risks = section_by_title(sections, "risk")
    if risks:
        for table in parse_md_tables(risks[1]):
            for row in table[1:6]:
                if row:
                    sec_items.append("Risk noted in design: " + " — ".join(row[:3]))
    if not sec_items:
        sec_items = [
            "Treat this as a controlled demo environment unless a production security review is completed",
            "Network exposure should remain on the lab / LAN ports documented in DESIGN.md",
        ]
    seen2 = set()
    uniq2 = []
    for b in sec_items:
        key = b.lower()
        if key not in seen2:
            seen2.add(key)
            uniq2.append(b)
    story.append(bullets(uniq2[:10], styles))

    # --- Try it ---
    story.append(Paragraph("8. Seeing it work", styles["h2"]))
    ops = section_by_title(sections, "ops", "observability")
    try_bits = []
    if ops:
        p = first_paragraph(ops[1])
        if p:
            try_bits.append(p)
        for table in parse_md_tables(ops[1]):
            for row in table[1:]:
                try_bits.append(" / ".join(row[:3]))
    readme = root / "README.md"
    if readme.is_file():
        for line in readme.read_text(encoding="utf-8", errors="replace").splitlines():
            if "localhost" in line or "127.0.0.1" in line or line.strip().startswith("docker compose"):
                try_bits.append(line.strip(" `"))
            if len(try_bits) > 10:
                break
    if not try_bits:
        try_bits = [
            "Start with docker compose up -d --build from the interface folder",
            "Open the Web UI Info / Demo tabs and walk the documented happy path",
            "Use tools/smoke.sh when provided to prove end-to-end behavior",
        ]
    story.append(bullets(try_bits[:10], styles))

    # --- Related docs ---
    story.append(Paragraph("9. Related technical documents", styles["h2"]))
    related = [
        "DESIGN.md — working engineering specification for this interface",
        "README.md — how to run, ports, and smoke commands",
    ]
    if route_pdf:
        related.append(f"{route_pdf} — detailed PilotFish route wiring diagrams")
    if cap_path:
        related.append(f"{cap_path.relative_to(root)} — machine-readable FHIR CapabilityStatement")
    related.append(
        "This Capability Brief — shareable stakeholder summary (regenerate after design changes)"
    )
    story.append(bullets(related, styles))
    story.append(
        Paragraph(
            "This document is generated from the interface sources listed above. If design and "
            "runtime diverge, believe the smoke-tested runtime and update DESIGN.md.",
            styles["note"],
        )
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)

    def on_page(canvas, doc):
        canvas.saveState()
        canvas.setStrokeColor(colors.HexColor("#0b6e4f"))
        canvas.setLineWidth(1.2)
        canvas.line(0.7 * inch, letter[1] - 0.45 * inch, letter[0] - 0.7 * inch, letter[1] - 0.45 * inch)
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(colors.HexColor("#6b7280"))
        canvas.drawString(0.7 * inch, 0.45 * inch, brand)
        canvas.drawRightString(letter[0] - 0.7 * inch, 0.45 * inch, f"Page {doc.page}")
        canvas.restoreState()

    doc = SimpleDocTemplate(
        str(out_path),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.7 * inch,
        title=f"{title} — Capability Brief",
        author="PilotFish Sandbox",
    )
    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    return out_path


def main():
    parser = argparse.ArgumentParser(description="Export stakeholder Interface Capability Brief PDF")
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="Demo / interface root (default: cwd, or parent of tools/ when run via wrapper)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Output PDF path (default: documents/<ShortName>_Capability_Brief.pdf)",
    )
    args = parser.parse_args()
    root = require_demo(args.root)
    if not root.is_dir():
        raise SystemExit(f"Root not found: {root}")
    out = args.out or (root / "documents" / output_pdf_name(root))
    path = build_pdf(root, out.resolve())
    print("Wrote", path)


if __name__ == "__main__":
    main()
