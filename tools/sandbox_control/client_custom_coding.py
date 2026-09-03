"""Map Med Rec partition/client/facility special-cases in OGNL, XSLT, and routes."""

from __future__ import annotations

import html
import io
import re
from datetime import date
from pathlib import Path

import client_custom_coding_labels as labels
import client_regression
import clients

SKIP_FILES = re.compile(r"(grouping|transform-test|transform2-test|sample|\.bak|backup)", re.I)
SKIP_TOKEN = {
    "YES", "NO", "XML", "DFT", "ADT", "HL7", "CPT", "CDM", "IN1", "GT1", "PID", "FT1", "MSH",
    "AND", "THE", "FOR", "NOT", "NULL", "TRUE", "FALSE", "UTF", "ISO", "SQL", "CSV", "PDF",
    "XLS", "NPI", "DOS", "ACC", "MRN", "SSN", "DOB", "SEX", "ZIP", "N/A", "OGNL", "EIP",
    "HTTP", "SFTP", "FTP", "CSV", "TXT", "XLSX", "HTML", "JSON", "NONE", "ALL", "ANY",
}
QUOTED = re.compile(r"['\"]([A-Za-z]{2,8}|[0-9]{3,4})['\"]")
NAME_ATTR = re.compile(r'\bname="([^"]{2,120})"')
CLIENT_EQ = re.compile(
    r"(?:\$clientName|ClientName|getAttribute\(\s*['\"]Client(?:Name)?['\"]\s*\))\s*(==|=|!=)\s*['\"]([A-Za-z0-9]+)['\"]",
    re.I,
)
PART_EQ = re.compile(
    r"(?:\$partitionName|\$Partition|PartitionName|getAttribute\(\s*['\"]Partition(?:Name)?['\"]\s*\))\s*(==|=|!=)\s*['\"]([A-Za-z0-9]+)['\"]",
    re.I,
)
SID_NEAR = re.compile(r"\$?softwareID.{0,500}", re.I)


def _index_clients(root: Path) -> tuple[list[dict], dict[str, dict[str, list[int]]]]:
    rows = list(client_regression.clients_table(root))
    seen = {
        (str(r.get("partition") or "").strip().upper(), str(r.get("client") or "").strip().upper())
        for r in rows
    }
    for case in client_regression.catalog(root):
        part = str(case.get("partition") or "").strip().upper()
        cli = str(case.get("client") or "").strip().upper()
        if not part or not cli or (part, cli) in seen:
            continue
        sid = str(case.get("software_id") or "").strip()
        if not sid and part == "NHL" and cli == "CAT":
            sid = "513"
        rows.append(
            {
                "name": case.get("client_name") or case.get("title") or cli,
                "partition": part,
                "client": cli,
                "software_id": sid,
                "facilities": case.get("facilities") or [],
            }
        )
        seen.add((part, cli))
    maps: dict[str, dict[str, list[int]]] = {"part": {}, "cli": {}, "sid": {}, "fac": {}}
    for i, rec in enumerate(rows):
        part = str(rec.get("partition") or "").strip().upper()
        cli = str(rec.get("client") or "").strip().upper()
        sid = str(rec.get("software_id") or "").strip()
        if part and part not in SKIP_TOKEN:
            maps["part"].setdefault(part, []).append(i)
        if cli and cli not in SKIP_TOKEN:
            maps["cli"].setdefault(cli, []).append(i)
        if sid and sid not in SKIP_TOKEN:
            maps["sid"].setdefault(sid, []).append(i)
        for fac in rec.get("facilities") or []:
            if isinstance(fac, dict):
                vals = [fac.get("FACILITY"), fac.get("FACILITY_CODE")]
            else:
                vals = [fac]
            for v in vals:
                t = str(v or "").strip().upper()
                if t and t not in SKIP_TOKEN:
                    maps["fac"].setdefault(t, []).append(i)
    return rows, maps


def _lookup(mp: dict[str, list[int]], *toks: str) -> set[int]:
    out: set[int] = set()
    for tok in toks:
        t = (tok or "").strip().upper()
        if t and t in mp:
            out.update(mp[t])
    return out


def _line_targets(raw: str, maps: dict[str, dict[str, list[int]]]) -> tuple[set[int], list[str]]:
    text = html.unescape(raw)
    clients = [m.group(2).upper() for m in CLIENT_EQ.finditer(text)]
    parts = [m.group(2).upper() for m in PART_EQ.finditer(text)]
    sids = []
    for chunk in SID_NEAR.findall(text):
        sids.extend(m.group(1) for m in re.finditer(r"['\"](\d{3,4})['\"]", chunk))
    if clients:
        return _lookup(maps["cli"], *clients) | _lookup(maps["sid"], *clients), []
    if sids and len(sids) <= 6:
        idxs = _lookup(maps["sid"], *sids)
        if parts:
            both = idxs & _lookup(maps["part"], *parts)
            if both:
                idxs = both
        return idxs, []
    if parts:
        return _lookup(maps["part"], *parts), []
    leftover = []
    idxs: set[int] = set()
    if "FileNameRestriction" in text or re.search(r"\bname=", raw):
        for m in QUOTED.finditer(text):
            tok = m.group(1).upper()
            if tok in SKIP_TOKEN:
                continue
            idxs |= _lookup(maps["cli"], tok) | _lookup(maps["sid"], tok) | _lookup(maps["part"], tok)
    return idxs, leftover


KIND_OGNL = re.compile(r"ExecuteProcessor|\{ognl:|getAttribute\(", re.I)
KIND_LISTEN = re.compile(r"FileNameRestriction|DirectoryListener|Listener", re.I)
KIND_XSLT = re.compile(r"xsl:when|xsl:if|partitionName|softwareID", re.I)


def _kind(line: str, path: Path) -> str:
    if KIND_OGNL.search(line):
        return "OGNL"
    if path.suffix.lower() in {".xslt", ".xsl"} or KIND_XSLT.search(line):
        return "XSLT"
    if KIND_LISTEN.search(line):
        return "Listener"
    return "Route"


def _clean(line: str) -> str:
    text = html.unescape(line)
    test = re.search(r'\b(?:test|select)="([^"]+)"', text)
    if test:
        text = test.group(1)
    else:
        text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > 280:
        text = text[:277] + "…"
    return text


def _name_near(lines: list[str], i: int) -> str:
    for j in range(i, max(-1, i - 18), -1):
        m = NAME_ATTR.search(lines[j])
        if m:
            return m.group(1)
    return ""


def _iter_files(eip: Path) -> list[Path]:
    out = []
    for p in eip.rglob("*"):
        if not p.is_file():
            continue
        if p.suffix.lower() not in {".xml", ".xslt", ".xsl"}:
            continue
        if any(part.lower() == "backups" for part in p.parts):
            continue
        if SKIP_FILES.search(p.name):
            continue
        if p.stat().st_size > 4_000_000:
            continue
        if p.name not in {"route.xml", "transform.xslt"} and p.suffix.lower() not in {".xslt", ".xsl"}:
            if "route" not in p.name.lower():
                continue
        out.append(p)
    return out


def snapshot(slug: str) -> dict:
    if slug != "med-rec":
        return {"ok": False, "error": "Client custom coding is only for Med Rec."}
    root = clients.require_root(slug)
    eip = root / "eip-root"
    if not eip.is_dir():
        return {"ok": False, "error": "No eip-root"}
    rows, maps = _index_clients(root)
    buckets: list[list[dict]] = [[] for _ in rows]
    extra: dict[str, list[dict]] = {}
    seen: set[tuple] = set()
    for path in _iter_files(eip):
        rel = path.relative_to(root).as_posix()
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        lines = text.splitlines()
        for i, raw in enumerate(lines):
            if "'" not in raw and '"' not in raw:
                continue
            hit_idx, leftover = _line_targets(raw, maps)
            if not hit_idx and not leftover:
                continue
            snippet = _clean(raw)
            if not snippet:
                continue
            rec = {
                "kind": _kind(raw, path),
                "name": _name_near(lines, i),
                "file": rel,
                "line": i + 1,
                "text": snippet,
            }
            rec.update(labels.describe(rel, rec["name"], snippet, rec["kind"]))
            key = (rel, rec["line"], rec["text"])
            for idx in hit_idx:
                mark = key + (idx,)
                if mark in seen:
                    continue
                seen.add(mark)
                buckets[idx].append(rec)
            for tok in leftover:
                if not re.fullmatch(r"[A-Z]{2,4}|\d{3,4}", tok):
                    continue
                mark = key + ("x", tok)
                if mark in seen:
                    continue
                seen.add(mark)
                extra.setdefault(tok, []).append(rec)
    groups = []
    for rec, rules in zip(rows, buckets):
        if not rules:
            continue
        groups.append(
            {
                "title": rec.get("name") or rec.get("client") or "",
                "partition": rec.get("partition") or "",
                "client": rec.get("client") or "",
                "software_id": rec.get("software_id") or "",
                "facilities": [
                    (f.get("FACILITY") or f.get("FACILITY_CODE") or "")
                    if isinstance(f, dict)
                    else str(f)
                    for f in (rec.get("facilities") or [])
                ],
                "rules": rules,
            }
        )
    for tok, rules in sorted(extra.items()):
        if len(rules) < 2:
            continue
        groups.append(
            {
                "title": tok,
                "partition": "",
                "client": tok,
                "software_id": "",
                "facilities": [],
                "rules": rules,
                "unlisted": True,
            }
        )
    groups.sort(key=lambda g: (g.get("partition") or "zzz", g.get("client") or "", g.get("software_id") or ""))
    n_rules = sum(len(g["rules"]) for g in groups)
    commons = labels.tally(groups)
    return {
        "ok": True,
        "note": (
            "Special-case OGNL, XSLT tests, listeners, and route conditions that name a partition, "
            "client, software id, or facility. Shared names are the same on every client. "
            "H2 stripping tables are on the H2 tab — this is interface code."
        ),
        "groups": groups,
        "commons": commons,
        "clients_with_rules": len(groups),
        "rule_hits": n_rules,
    }


def _esc(s: str) -> str:
    return (
        str(s or "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def pdf_bytes(slug: str, q: str = "") -> bytes:
    data = snapshot(slug)
    if not data.get("ok"):
        raise RuntimeError(data.get("error") or "Could not build custom coding")
    needle = (q or "").strip().lower()
    groups = data.get("groups") or []
    if needle:
        groups = [
            g
            for g in groups
            if needle in " ".join(
                [str(g.get("title") or ""), str(g.get("partition") or ""), str(g.get("client") or ""), str(g.get("software_id") or ""), str(g.get("rules") or "")]
            ).lower()
        ]
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_LEFT
    from reportlab.lib.pagesizes import letter
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import inch
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

    ink = colors.HexColor("#172033")
    muted = colors.HexColor("#4b5568")
    green = colors.HexColor("#0b6e4f")
    base = getSampleStyleSheet()
    styles = {
        "brand": ParagraphStyle("ccb", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9, textColor=green),
        "title": ParagraphStyle("cct", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=16, textColor=ink, spaceAfter=4),
        "sub": ParagraphStyle("ccs", parent=base["Normal"], fontSize=9, textColor=muted, spaceAfter=10, leading=12),
        "h2": ParagraphStyle("cch", parent=base["Heading2"], fontName="Helvetica-Bold", fontSize=11, textColor=green, spaceBefore=10, spaceAfter=3),
        "meta": ParagraphStyle("ccm", parent=base["Normal"], fontSize=8.5, textColor=muted, spaceAfter=4),
        "rule": ParagraphStyle("ccr", parent=base["Normal"], fontSize=8, leading=10.5, alignment=TA_LEFT, spaceAfter=2, textColor=ink),
        "path": ParagraphStyle("ccp", parent=base["Normal"], fontName="Courier", fontSize=7, leading=9, textColor=muted, spaceAfter=4),
    }
    story = [
        Paragraph("PILOTFISH  ·  MED REC", styles["brand"]),
        Paragraph("Client custom coding", styles["title"]),
        Paragraph(
            _esc(data.get("note") or "")
            + f"  ·  {date.today().isoformat()}  ·  {len(groups)} client(s)"
            + (f"  ·  filter “{_esc(q)}”" if needle else ""),
            styles["sub"],
        ),
    ]
    for g in groups:
        head = f"{_esc(g.get('title') or g.get('client') or '')}  ·  {_esc(g.get('partition') or '—')} / {_esc(g.get('client') or '')}  ·  software {_esc(g.get('software_id') or '—')}"
        story.append(Paragraph(head, styles["h2"]))
        fac = ", ".join([str(x) for x in (g.get("facilities") or []) if x][:12])
        if fac:
            story.append(Paragraph("Facilities: " + _esc(fac), styles["meta"]))
        for r in g.get("rules") or []:
            story.append(
                Paragraph(
                    f"<b>{_esc(r.get('title') or r.get('kind') or '')}</b>  "
                    f"{_esc(r.get('about') or '')}  —  {_esc(r.get('text') or '')}",
                    styles["rule"],
                )
            )
            story.append(Paragraph(_esc(f"{r.get('file') or ''}:{r.get('line') or ''}"), styles["path"]))
        story.append(Spacer(1, 0.08 * inch))
    buf = io.BytesIO()
    SimpleDocTemplate(
        buf,
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.6 * inch,
        bottomMargin=0.6 * inch,
        title="Med Rec client custom coding",
    ).build(story)
    return buf.getvalue()
