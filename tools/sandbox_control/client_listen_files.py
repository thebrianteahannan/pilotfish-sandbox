"""Expected inbound filenames from Med Rec directory listeners."""

from __future__ import annotations

import re
from pathlib import Path

ROUTE = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/1 - Incoming Flat Files by Partition and Client/route.xml"
)
PAIR = re.compile(r"eip_pair:(PartitionName|ClientName):eip_name:([^:]+):eip_value", re.I)


def _example(pattern: str, ext: str) -> str:
    pat = (pattern or "").strip()
    extra = f".{ext}" if ext and not pat.lower().endswith(ext.lower()) else ""
    if not pat:
        return f"*.{ext}" if ext else "(any name in the inbound folder)"
    shown = pat
    if shown.endswith(".*"):
        shown = shown[:-2] + "….txt" if ext == "txt" else shown[:-2] + "…" + (f".{ext}" if ext else "")
        return shown
    shown = shown.replace(".*", "*").replace(".+", "*")
    if extra and "*" in shown and not shown.endswith(ext):
        shown = shown + extra
    elif extra and "." not in Path(shown.replace("*", "x")).suffix:
        shown = shown + extra
    return shown


def listeners(root: Path) -> list[dict]:
    path = root / ROUTE
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    chunks = re.split(r"<Source\b", text)[1:]
    out = []
    for chunk in chunks:
        if "DirectoryListener" not in chunk and "FileNameRestriction" not in chunk:
            continue
        src = re.search(r'\bname="([^"]+)"', chunk)
        rest = re.search(r"<FileNameRestriction>([^<]*)</FileNameRestriction>", chunk)
        ext = re.search(r"<FileExtensionRestriction>([^<]*)</FileExtensionRestriction>", chunk)
        part = cli = ""
        for kind, val in PAIR.findall(chunk):
            if kind.lower() == "partitionname":
                part = val.strip().upper()
            else:
                cli = val.strip().upper()
        title = src.group(1) if src else ""
        if not part or not cli:
            bits = [b.strip() for b in title.replace("Pickup Flat Files", "").split("-") if b.strip()]
            if len(bits) >= 2:
                part = part or bits[-2].upper()
                cli = cli or bits[-1].upper()
        pat = (rest.group(1) if rest else "").strip()
        extension = (ext.group(1) if ext else "").strip().lstrip(".")
        out.append(
            {
                "name": title,
                "partition": part,
                "client": cli,
                "pattern": pat,
                "extension": extension,
                "example": _example(pat, extension),
            }
        )
    return out


def match(rows: list[dict], rec: dict) -> list[dict]:
    part = str(rec.get("partition") or "").strip().upper()
    cli = str(rec.get("client") or "").strip().upper()
    hits = [r for r in rows if r.get("partition") == part and r.get("client") == cli]
    if hits:
        return hits
    if cli:
        hits = [r for r in rows if r.get("client") == cli]
    return hits
