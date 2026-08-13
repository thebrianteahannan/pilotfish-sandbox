"""OCR a dropped email screenshot and pull From / Subject / date / body."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

import clients

HERE = Path(__file__).resolve().parent
SWIFT = HERE / "ocr_vision.swift"
ALLOWED = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".tif", ".tiff"}
HEADER = re.compile(r"^(from|to|cc|bcc|sent|date|subject|re|fwd)\s*[:\-]\s*(.*)$", re.I)
GMAIL_DATE = re.compile(
    r"\b(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,?\s+"
    r"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}"
    r"(?:,?\s+\d{4})?"
    r"(?:,?\s+\d{1,2}:\d{2}\s*(?:AM|PM))?",
    re.I,
)
SKIP_SUBJ = re.compile(r"^(to me|to |cc |bcc )\b", re.I)


def inbox_dir(root: Path) -> Path:
    path = root / "requests" / "_inbox"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _bin(name: str, extra: tuple[str, ...]) -> str:
    for path in extra:
        if Path(path).is_file():
            return path
    return shutil.which(name) or name


def _run(cmd: list[str], timeout: int = 60) -> tuple[int, str]:
    env = os.environ.copy()
    env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + env.get("PATH", "")
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=env)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 1, str(exc)
    out = (proc.stdout or "").strip()
    if proc.returncode != 0 and not out:
        out = (proc.stderr or "").strip()
    return proc.returncode, out


def ocr_tesseract(path: Path) -> str:
    exe = _bin("tesseract", ("/opt/homebrew/bin/tesseract", "/usr/local/bin/tesseract"))
    best = ""
    for psm in ("6", "4"):
        code, out = _run([exe, str(path), "stdout", "-l", "eng", "--psm", psm], timeout=45)
        if code == 0 and len(out) > len(best):
            best = out
    return best.strip()


def ocr_vision(path: Path) -> str:
    if not SWIFT.is_file():
        return ""
    code, out = _run(["/usr/bin/swift", str(SWIFT), str(path)], timeout=90)
    return out.strip() if code == 0 else ""


def ocr_image(path: Path) -> str:
    work = path
    if path.suffix.lower() == ".webp":
        png = path.with_suffix(".png")
        code, _ = _run(["/usr/bin/sips", "-s", "format", "png", str(path), "--out", str(png)], timeout=20)
        if code == 0 and png.is_file():
            work = png
    text = ocr_tesseract(work)
    if len(text) < 40:
        vis = ocr_vision(work)
        if len(vis) > len(text):
            text = vis
    return text.strip()


def _headers(text: str) -> dict[str, str]:
    found: dict[str, str] = {}
    for raw in text.splitlines():
        m = HEADER.match(raw.strip())
        if not m:
            continue
        key = m.group(1).lower()
        if key == "re":
            key = "subject"
        if key not in found and m.group(2).strip():
            found[key] = m.group(2).strip()
    return found


def parse_email_text(text: str) -> dict:
    raw = (text or "").replace("\r\n", "\n").strip()
    heads = _headers(raw)
    sender = heads.get("from") or ""
    subject = heads.get("subject") or ""
    received = heads.get("sent") or heads.get("date") or ""
    if not sender:
        m = re.search(r"([A-Z][A-Za-z .'\-]+)\s*<([^>]+@[^>]+)>", raw)
        if m:
            sender = f"{m.group(1).strip()} <{m.group(2).strip()}>"
        else:
            m = re.search(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}", raw)
            if m:
                sender = m.group(0)
    if not received:
        m = GMAIL_DATE.search(raw)
        if m:
            received = m.group(0)
    body = raw
    last = None
    for key in ("subject", "sent", "date"):
        m = re.search(rf"(?im)^{key}\s*[:\-].+$", raw)
        if m and (last is None or m.end() > last):
            last = m.end()
    if last:
        rest = raw[last:].lstrip("\n")
        if len(rest) > 20:
            body = rest
    elif received:
        idx = raw.find(received)
        if idx >= 0:
            rest = raw[idx + len(received) :].lstrip(" \n,")
            rest = re.sub(r"^to me[^\n]*\n?", "", rest, count=1, flags=re.I).lstrip("\n")
            if len(rest) > 20:
                body = rest
    if not subject:
        for line in raw.splitlines():
            line = line.strip()
            if len(line) < 12:
                continue
            if HEADER.match(line) or "@" in line or GMAIL_DATE.search(line) or SKIP_SUBJ.match(line):
                continue
            subject = line[:120]
            break
    return {
        "from": sender,
        "subject": subject,
        "received_at": received,
        "email": body or raw,
        "ocr": raw,
    }


def save_upload(slug: str, data: bytes, filename: str) -> Path:
    root = clients.require_root(slug)
    ext = Path(filename or "screenshot.png").suffix.lower() or ".png"
    if ext not in ALLOWED:
        ext = ".png"
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")[:18]
    dest = inbox_dir(root) / f"{stamp}{ext}"
    dest.write_bytes(data)
    return dest


def ingest(slug: str, data: bytes, filename: str) -> dict:
    path = save_upload(slug, data, filename)
    text = ocr_image(path)
    parsed = parse_email_text(text)
    rel = path.relative_to(clients.ROOT).as_posix()
    parsed["path"] = rel
    parsed["filename"] = path.name
    parsed["chars"] = len(text)
    sidecar = path.with_name(path.name + ".ocr.json")
    sidecar.write_text(json.dumps({"path": rel, **parsed}, indent=2) + "\n", encoding="utf-8")
    if not text:
        parsed["error"] = "Could not read text from the screenshot."
    return parsed
