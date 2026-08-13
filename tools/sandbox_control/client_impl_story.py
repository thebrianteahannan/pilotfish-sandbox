"""Plain-language walkthrough of a client's V2 routes for the implementation guide."""

from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from pathlib import Path

from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate

import client_impl_docs as docs
import client_impl_guide as guide

STORY_MD = "how-it-works.md"

NOISE = re.compile(
    r"(^|\.)processor(\d+)?([- ]copy[- ]\d+)?$|"
    r"^(format xml|store xml to attribute.*|put blank data into transdata.*|"
    r"remove the xml.*|write db lookup xml to disk.*|"
    r"store database results to attribute|put import xml back.*|"
    r"directory / file( listener\d*)?)$",
    re.I,
)

FAMILIES = (
    (re.compile(r"^set facility name", re.I), "sets the facility name for each inbound folder"),
    (re.compile(r"^transform .*xml", re.I), "turns those files into XML"),
    (re.compile(r"^merge patient", re.I), "merges demographics when the same person shows up more than once"),
    (re.compile(r"^apply stripping|^strip (charges|demographics|records)", re.I), "applies the strip rules"),
    (re.compile(r"tweak", re.I), "applies the tweak rules"),
    (re.compile(r"^strip charges if", re.I), "drops charges outside the date range from the database"),
)


def _clean(label: str, route: str, iface: str) -> str:
    text = (label or "").replace("&amp;", "&")
    for part in (iface, route, "New Architecture.2-0"):
        text = re.sub(re.escape(part) + r"[\s.\-]*", "", text, flags=re.I)
    text = re.sub(
        r"\.(Processor\d*|Directory / File (Listener|Transport)|"
        r"Route to Route Transport|Programmable \(Trigger\) Listener)$",
        "",
        text,
        flags=re.I,
    )
    return re.sub(r"\s+", " ", text).strip(" .-")


def _mod(folder: Path, mid: str) -> dict:
    path = folder / "modules" / f"{mid}.xml"
    if not path.is_file():
        return {}
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError:
        return {}
    return {"type": root.get("type") or "", "tag": (root.get("tag") or "").lower()}


def _uniq(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        key = item.lower()
        if key in seen:
            continue
        seen.add(key)
        out.append(item)
    return out


def _purpose(name: str) -> str:
    low = name.lower()
    if "pickup" in low or "incoming" in low:
        return "watches inbound folders and turns the client flat file into XML the rest of the interface can read"
    if re.search(r"\b1[a-e]\b", low) or low.endswith(" multi") or " multi" in low:
        return "is a client-specific pickup — same idea as the main inbound route, but for this partition only"
    if "stripping" in low or "tweaking" in low:
        return "marks records that must not go to HL7, and tweaks values that still should"
    if "specimen" in low and "determine" in low:
        return "decides whether this batch needs to split on specimen alpha IDs"
    if "specimen" in low:
        return "splits the batch when specimen alpha IDs say the work belongs in more than one place"
    if "splitting" in low or "split" in low:
        return "sends each account to the facility that should bill it"
    if "debug" in low and "adt" in low:
        return "writes a debug copy of the ADT so you can see what left the interface"
    if "debug" in low and "dft" in low:
        return "writes a debug copy of the DFT so you can see what left the interface"
    if "generate hl7" in low or re.search(r"\bdft\b", low) or re.search(r"\badt\b", low):
        return "writes the HL7 that actually goes out — ADT for demographics, DFT for charges"
    if "accession" in low:
        return "builds the accession-log kickout sheet"
    if "cumulative" in low:
        return "builds the cumulative kickout sheet"
    if "warning" in low:
        return "builds the warnings kickout sheet"
    if "ref phys" in low or "ariana" in low:
        return "builds the referring-physician kickout sheet (Ariana / Ligolab)"
    if "no date of service" in low:
        return "lists accounts that have no date of service"
    if "stripped and tweaked" in low:
        return "writes the stripped-and-tweaked kickout workbook, including FLG Location Charges"
    if "mue" in low:
        return "builds the MUE edits report"
    if "cdm" in low:
        return "builds the CDM appended-A report"
    if "additional report" in low or "generate report" in low:
        return "fans the remaining kickout and ops reports out to their writers"
    if "kickout" in low or "report" in low:
        return "writes a kickout or ops report from records that did not go to HL7, or that need a human look"
    if "flg" in low:
        return "adds flagged / FLG location rows so the strip route can mark those codes"
    if "secondary strip" in low:
        return "adds secondary strip locations for a client"
    if "er_ins" in low or "ins plan" in low:
        return "adds ER insurance plan codes used later in stripping and tweaking"
    if "split facility" in low or "new facility" in low:
        return "adds a facility or a client split so later routes know where to send the account"
    if "partition config" in low:
        return "loads partition and client settings from the database so the rest of the run knows who this file is for"
    if "charge without demo" in low:
        return "catches a charge that arrived without matching demographics"
    if "wrong facility" in low:
        return "catches a facility name the interface does not know"
    if "error" in low:
        return "is the catch-all when something in the run fails"
    return "is one step in this interface"


def _iface_intro(name: str, n: int) -> str:
    low = name.lower()
    if "flat file" in low and "kickout" in low:
        return (
            "This is the live production path. Client flat files come in by partition, "
            "become XML, get stripped or tweaked, split by facility, and leave as ADT, DFT, "
            f"and kickout Excel. {n} routes."
        )
    if "88363" in low:
        return (
            "This is the older 88363 log path. It picks up log files, turns them into XML, "
            f"optionally splits on specimen alpha IDs, then writes DFT and kickout reports. {n} routes."
        )
    return f"{name} has {n} routes."


def _spoken(name: str) -> str:
    return re.sub(r"^\d+[a-z]?\s*[-–.]\s*", "", name or "").strip() or name


def _join(items: list[str], limit: int = 6) -> str:
    items = items[:limit]
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    if len(items) == 2:
        return f"{items[0]} and {items[1]}"
    return ", ".join(items[:-1]) + f", and {items[-1]}"


def _nodes(folder: Path) -> tuple[list[str], list[str], list[str]]:
    v2 = folder / "route.v2.xml"
    if not v2.is_file():
        return [], [], []
    try:
        root = ET.parse(v2).getroot()
    except ET.ParseError:
        return [], [], []
    iface = folder.parent.parent.name
    route = folder.name
    listen, work, outs = [], [], []
    for node in root.findall("./Nodes/Node"):
        label = node.get("label") or ""
        meta = _mod(folder, node.get("moduleId") or "")
        tag = meta.get("tag") or ""
        cleaned = _clean(label, route, iface)
        low = label.lower()
        if tag == "listener" or "listener" in low:
            listen.append(cleaned or "a directory listener")
        elif tag == "transport" or "transport" in low:
            kind = "the next route" if "route to route" in low else (cleaned or meta.get("type") or "a file drop")
            outs.append(kind)
        elif cleaned and not NOISE.match(cleaned):
            work.append(cleaned)
    return _uniq(listen), _uniq(work), _uniq(outs)


def _start(listeners: list[str]) -> str:
    if not listeners:
        return ""
    generic = [x for x in listeners if re.match(r"^(a directory listener|directory / file( listener\d*)?)$", x, re.I)]
    if generic and len(generic) == len(listeners):
        return "It starts with a directory listener."
    if len(listeners) == 1:
        return f"It starts with {listeners[0]}."
    folders = []
    for item in listeners:
        bit = re.sub(r"^.*dir listener\s*-?\s*", "", item, flags=re.I).strip(" -")
        if bit and bit.lower() not in {"a directory listener", "directory / file"}:
            folders.append(bit)
    folders = _uniq(folders)
    if len(listeners) > 4:
        extra = f" ({_join(folders, 5)} among them)" if folders else ""
        return f"It watches {len(listeners)} inbound folders{extra}."
    return f"It starts from {_join(listeners, 4)}."


def _collapse(work: list[str]) -> list[str]:
    used: set[int] = set()
    out: list[str] = []
    leftover: list[str] = []
    for i, item in enumerate(work):
        hit = next((n for pat, n in FAMILIES if pat.search(item)), None)
        if not hit:
            leftover.append(item)
            continue
        if id(hit) in used:
            continue
        used.add(id(hit))
        out.append(hit)
    keep = [w for w in leftover if not NOISE.search(w)]
    return out + keep[:6]


def _mid(work: list[str]) -> str:
    items = _collapse(work)
    if not items:
        return ""
    return f"Along the way it {_join(items, 7)}."


def _end(outs: list[str]) -> str:
    if not outs:
        return ""
    files = [o for o in outs if re.search(r"directory|file|cerner|sql", o, re.I)]
    nxt = any("next route" in o.lower() or "route to route" in o.lower() for o in outs)
    if files and nxt:
        return "It writes the outbound files and hands the rest to the next route."
    if nxt and len(outs) == 1:
        return "When it is done it hands the transaction to the next route."
    if files and len(files) == len(outs):
        return "It finishes by writing the outbound files."
    return f"It finishes by writing to {_join(outs, 4)}."


def explain(folder: Path) -> dict:
    iface = folder.parent.parent.name
    name = folder.name
    listen, work, outs = _nodes(folder)
    purpose = _purpose(name)
    bits = [f"{_spoken(name)} {purpose}."]
    start, mid, end = _start(listen), _mid(work), _end(outs)
    if start:
        bits.append(start)
    if mid:
        bits.append(mid)
    if end:
        bits.append(end)
    return {
        "id": docs._slug(name),
        "name": name,
        "interface": iface,
        "title": _spoken(name),
        "blurb": " ".join(bits),
    }


def walk(root: Path) -> list[dict]:
    rows: list[dict] = []
    for folder, _formats in docs.iter_routes(root):
        rows.append(explain(folder))
    return rows


def write_md(root: Path) -> Path:
    rows = walk(root)
    brand = guide.client_title(root) if hasattr(guide, "client_title") else root.name
    try:
        import clients

        brand = clients.client_title(root)
    except Exception:
        brand = root.name
    lines = [
        f"# How {brand} works",
        "",
        "Read this first. The diagrams after it are the same routes drawn as boxes — useful when you want to see a step, not required to understand the flow.",
        "",
    ]
    current = ""
    grouped: dict[str, list[dict]] = {}
    for row in rows:
        grouped.setdefault(row["interface"], []).append(row)
    for iface, items in grouped.items():
        if iface != current:
            lines.append(f"## {iface}")
            lines.append("")
            lines.append(_iface_intro(iface, len(items)))
            lines.append("")
            current = iface
        for row in items:
            lines.append(f"### {row['name']}")
            lines.append("")
            lines.append(row["blurb"])
            lines.append("")
    dest = guide.documents_dir(root) / STORY_MD
    dest.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    return dest


def write_pdf(root: Path, dest: Path | None = None) -> Path:
    md_path = write_md(root)
    out = dest or (guide.documents_dir(root) / "_how_it_works.pdf")
    styles = guide._styles()
    doc = SimpleDocTemplate(
        str(out),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.65 * inch,
        title="How this interface works",
        author="PilotFish Sandbox",
    )
    doc.build(guide._md_to_story(md_path.read_text(encoding="utf-8"), styles))
    return out
