#!/usr/bin/env python3
"""Parse EIP stage Entered/Exited timings and write a bottleneck PDF (no interface changes).

Usage:
  python3 tools/eip_stage_timings.py --since-file data/archive/MedReceivables_Charges_*_Part3.txt
  python3 tools/eip_stage_timings.py --after '08/05/26 18:20:00' --label Part3 --pdf
"""
from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOG = ROOT / "logs" / "eip.log"
OUT_DIR = ROOT / "Clients" / "Med Rec" / "data" / "Halifax-Historical-File-Issue" / "Halifax" / "Historical file - Output" / "Five_Parts_20260805"

STAGE_RE = re.compile(
    r"(?P<ts>\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}).*?"
    r"(?P<action>Entered|Exited) stage: \[(?P<body>[^\]]+)\](?P<rest>.*)$"
)
TX_RE = re.compile(r"\[TxID:(?P<txid>[^\]]+)\]")


def parse_ts(s: str) -> datetime:
    # EIP logs use MM/DD/YY HH:MM:SS (container clock; treat as naive)
    return datetime.strptime(s, "%m/%d/%y %H:%M:%S")


def parse_stage_line(line: str) -> dict | None:
    m = STAGE_RE.search(line)
    if not m:
        return None
    rest = m.group("rest") or ""
    rest_parts = re.findall(r"\[([^\]]+)\]", rest)
    txm = TX_RE.search(line)
    txid = txm.group("txid") if txm else None
    if txid == "null":
        txid = None
    return {
        "ts": m.group("ts"),
        "dt": parse_ts(m.group("ts")),
        "action": m.group("action"),
        "route": m.group("body"),
        "stage": rest_parts[0] if rest_parts else m.group("body"),
        "kind": rest_parts[1] if len(rest_parts) > 1 else "",
        "txid": txid,
    }


def collect_timings(log_path: Path, after: datetime | None = None) -> dict:
    """Pair Entered/Exited by (txid, route, stage) stack; aggregate totals."""
    open_stacks: dict[tuple, list[datetime]] = defaultdict(list)
    durations: list[dict] = []
    current = None
    first_dt = None
    last_dt = None

    with log_path.open("r", errors="replace") as f:
        for line in f:
            ev = parse_stage_line(line)
            if not ev:
                continue
            if after and ev["dt"] < after:
                continue
            if first_dt is None:
                first_dt = ev["dt"]
            last_dt = ev["dt"]
            key = (ev["txid"] or "_", ev["route"], ev["stage"])
            if ev["action"] == "Entered":
                open_stacks[key].append(ev["dt"])
                current = {
                    "ts": ev["ts"],
                    "route": ev["route"],
                    "stage": ev["stage"],
                    "kind": ev["kind"],
                    "txid": ev["txid"],
                }
            else:  # Exited
                stack = open_stacks.get(key)
                if not stack:
                    continue
                start = stack.pop()
                secs = (ev["dt"] - start).total_seconds()
                if secs < 0:
                    continue
                durations.append(
                    {
                        "route": ev["route"],
                        "stage": ev["stage"],
                        "kind": ev["kind"],
                        "txid": ev["txid"],
                        "started": start.strftime("%Y-%m-%d %H:%M:%S"),
                        "ended": ev["dt"].strftime("%Y-%m-%d %H:%M:%S"),
                        "seconds": round(secs, 3),
                    }
                )

    # Still-open stages (in progress)
    in_progress = []
    now_ref = last_dt or datetime.now()
    for (txid, route, stage), starts in open_stacks.items():
        for start in starts:
            in_progress.append(
                {
                    "route": route,
                    "stage": stage,
                    "txid": None if txid == "_" else txid,
                    "started": start.strftime("%Y-%m-%d %H:%M:%S"),
                    "seconds_so_far": round((now_ref - start).total_seconds(), 3),
                }
            )

    by_stage: dict[str, dict] = {}
    for d in durations:
        name = d["stage"]
        bucket = by_stage.setdefault(
            name,
            {"stage": name, "route": d["route"], "total_seconds": 0.0, "count": 0, "max_seconds": 0.0},
        )
        bucket["total_seconds"] += d["seconds"]
        bucket["count"] += 1
        bucket["max_seconds"] = max(bucket["max_seconds"], d["seconds"])

    ranked = sorted(by_stage.values(), key=lambda x: x["total_seconds"], reverse=True)
    total = sum(x["total_seconds"] for x in ranked) or 1.0
    for row in ranked:
        row["total_seconds"] = round(row["total_seconds"], 3)
        row["max_seconds"] = round(row["max_seconds"], 3)
        row["pct"] = round(100.0 * row["total_seconds"] / total, 1)

    wall = None
    if first_dt and last_dt:
        wall = round((last_dt - first_dt).total_seconds(), 3)

    return {
        "first_ts": first_dt.strftime("%Y-%m-%d %H:%M:%S") if first_dt else None,
        "last_ts": last_dt.strftime("%Y-%m-%d %H:%M:%S") if last_dt else None,
        "wall_seconds": wall,
        "completed_steps": len(durations),
        "in_progress": in_progress,
        "current": current,
        "by_stage": ranked,
        "durations": durations,
        "bottlenecks": ranked[:8],
    }


def recommendations_for(bottlenecks: list[dict]) -> list[dict]:
    """Advisory-only suggestions keyed off observed stage names. No code changes."""
    tips: list[dict] = []
    seen = set()

    def add(title: str, detail: str, priority: str = "medium"):
        if title in seen:
            return
        seen.add(title)
        tips.append({"priority": priority, "title": title, "detail": detail})

    names = " | ".join(b["stage"].lower() for b in bottlenecks)

    if any(k in names for k in ("tweak", "strip", "xslt", "transform", "group", "concat", "duplicate")):
        add(
            "Keep debug-trace off for historical volume",
            "Debug-trace serializes every stage payload to disk and can dominate I/O/memory on "
            "250k+ charge files. Confirm debuggingTrace=false on all Flat File routes before each run.",
            "high",
        )
        add(
            "Shrink per-transaction XML (already partially done via 5-part split)",
            "Group-by / strip / tweak stages build large in-memory DOM trees. Smaller Part files "
            "(or splitting earlier by date/CSN) reduces peak heap and stage wall time almost linearly.",
            "high",
        )

    if "tweak" in names or "strip" in names:
        add(
            "Profile Apply Tweaking / Stripping XSLTs",
            "These are usually the #1 CPU sinks. Prefer keyed lookups (xsl:key / maps) over nested "
            "// scans, avoid deep copy of the full document per rule, and gate client-specific "
            "templates so HAL/HAX skips Stamford/PPA/NGP-only logic.",
            "high",
        )
        add(
            "Consider streaming or chunked apply for rules engines",
            "If rules must touch every account node, process in account-batches (or fork by facility "
            "earlier) so each transform operates on a smaller tree instead of one giant document.",
            "medium",
        )

    if "group" in names or "concat" in names or "account" in names:
        add(
            "Optimize account grouping / concat stage",
            "Building charges_xml + demos_xml then merging is peak-memory. Options: join on CSN "
            "via sorted external merge, or push grouping earlier with a lighter format than full XML.",
            "high",
        )

    if "duplicate" in names or "split" in names:
        add(
            "Index split-code / duplicate removal lookups",
            "Remove-duplicates and assign-split-code stages that re-scan the full XML per account "
            "scale poorly. Pre-index by account/facility in one pass, or push duplicate suppression "
            "to SQL keyed by CSN.",
            "medium",
        )

    if "database" in names or "query" in names or "lookup" in names:
        add(
            "Batch database lookups",
            "Per-record or chatty DB queries during a historical run amplify latency. Fetch feed/"
            "split/software maps once per partition+client and reuse in memory for the transaction.",
            "medium",
        )

    if "csv" in names or "xml2" in names or "transform charges" in names:
        add(
            "CSV→XML conversion cost",
            "Converting 250k pipe-delimited rows to XML expands size ~5–10×. A flatter intermediate "
            "(or delaying XML until after filter/group) can cut both time and heap.",
            "medium",
        )

    if "hl7" in names or "generate" in names:
        add(
            "HL7 generation parallelism (carefully)",
            "If Generate HL7 is top-ranked, consider bounded parallelism by facility/client split "
            "with careful heap caps — but only after group/tweak memory pressure is under control.",
            "low",
        )

    add(
        "Runtime environment",
        "Stop unused demo containers before historical runs so Docker RAM/CPU goes to pilotfish-eip. "
        "12GB heap helped; leave headroom for native/XML overhead above -Xmx.",
        "medium",
    )
    add(
        "Listener / polling wait is not CPU time",
        "DirectoryListener PollingInterval (120s) adds idle wait before pickup. For controlled "
        "historical drops, a shorter interval (or manual trigger) reduces clock time without "
        "changing transform cost.",
        "low",
    )
    return tips


def write_pdf(report: dict, pdf_path: Path, label: str) -> Path:
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_LEFT
    from reportlab.lib.pagesizes import letter
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import inch
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    pdf_path.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(pdf_path),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.65 * inch,
    )
    styles = getSampleStyleSheet()
    title = ParagraphStyle("t", parent=styles["Heading1"], fontSize=16, spaceAfter=8)
    h2 = ParagraphStyle("h2", parent=styles["Heading2"], fontSize=12, spaceBefore=12, spaceAfter=6)
    body = ParagraphStyle("b", parent=styles["Normal"], fontSize=9, leading=12, alignment=TA_LEFT)
    small = ParagraphStyle("s", parent=styles["Normal"], fontSize=8, textColor=colors.grey)

    story = []
    story.append(Paragraph(f"Halifax Historical EIP Bottleneck Report — {label}", title))
    story.append(
        Paragraph(
            f"Generated {datetime.now().strftime('%Y-%m-%d %H:%M')} · Advisory only — no interface changes applied.",
            small,
        )
    )
    story.append(Spacer(1, 8))

    wall = report.get("wall_seconds")
    story.append(Paragraph("Run summary", h2))
    story.append(
        Paragraph(
            f"Window: <b>{report.get('first_ts') or '—'}</b> → <b>{report.get('last_ts') or '—'}</b><br/>"
            f"Wall clock (first→last stage log): <b>{wall if wall is not None else '—'} s</b><br/>"
            f"Completed stage intervals: <b>{report.get('completed_steps', 0)}</b>",
            body,
        )
    )

    story.append(Paragraph("Biggest bottlenecks (by total stage time)", h2))
    rows = [["#", "Stage", "Route", "Total s", "%", "Max s", "Count"]]
    for i, b in enumerate(report.get("bottlenecks") or [], 1):
        rows.append(
            [
                str(i),
                Paragraph(b["stage"][:60], small),
                Paragraph((b.get("route") or "")[:40], small),
                f"{b['total_seconds']:.1f}",
                f"{b['pct']}%",
                f"{b['max_seconds']:.1f}",
                str(b["count"]),
            ]
        )
    if len(rows) == 1:
        rows.append(["—", "No completed Entered/Exited pairs yet", "", "", "", "", ""])
    tbl = Table(rows, colWidths=[0.3 * inch, 2.2 * inch, 1.6 * inch, 0.7 * inch, 0.5 * inch, 0.7 * inch, 0.55 * inch])
    tbl.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a2332")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#8899aa")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f4f7fb")]),
            ]
        )
    )
    story.append(tbl)

    story.append(Paragraph("Recommended improvements (do not auto-apply)", h2))
    tips = report.get("recommendations") or recommendations_for(report.get("bottlenecks") or [])
    for t in tips:
        story.append(
            Paragraph(
                f"<b>[{t['priority'].upper()}] {t['title']}</b><br/>{t['detail']}",
                body,
            )
        )
        story.append(Spacer(1, 6))

    story.append(Paragraph("Notes", h2))
    story.append(
        Paragraph(
            "Durations come from EIP DEBUG Entered/Exited stage pairs. Long in-progress stages "
            "(no Exited yet) appear only in the live monitor. Listener poll waits before pickup "
            "are outside transform time. This PDF does not modify routes, XSLT, heap, or Docker.",
            body,
        )
    )
    doc.build(story)
    return pdf_path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", type=Path, default=LOG)
    ap.add_argument("--after", help="Only stages at/after MM/DD/YY HH:MM:SS")
    ap.add_argument("--label", default="Run")
    ap.add_argument("--json-out", type=Path)
    ap.add_argument("--pdf", action="store_true")
    ap.add_argument("--pdf-out", type=Path)
    args = ap.parse_args()

    after = parse_ts(args.after) if args.after else None
    report = collect_timings(args.log, after=after)
    report["label"] = args.label
    report["recommendations"] = recommendations_for(report.get("bottlenecks") or [])

    json_out = args.json_out or (OUT_DIR / f"{args.label}_stage_timings.json")
    json_out.parent.mkdir(parents=True, exist_ok=True)
    # Keep JSON smaller for dashboard (drop every duration if huge)
    slim = {k: v for k, v in report.items() if k != "durations"}
    slim["durations_sample"] = report["durations"][:50]
    json_out.write_text(json.dumps(slim, indent=2))
    print(f"Wrote {json_out}")

    if args.pdf or args.pdf_out:
        pdf_out = args.pdf_out or (OUT_DIR / f"{args.label}_Bottleneck_Report.pdf")
        write_pdf(report, pdf_out, args.label)
        print(f"Wrote {pdf_out}")

    for i, b in enumerate(report.get("bottlenecks") or [][:5], 1):
        print(f"  #{i} {b['total_seconds']:.1f}s ({b['pct']}%)  {b['stage']}")


if __name__ == "__main__":
    main()
