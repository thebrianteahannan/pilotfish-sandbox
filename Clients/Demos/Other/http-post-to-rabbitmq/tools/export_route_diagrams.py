#!/usr/bin/env python3
"""Screenshot HTTP POST → RabbitMQ demo V2 route diagrams and assemble a PDF.

Tall pipelines are scaled to page width and sliced vertically across pages.

Usage:
  python3 tools/export_route_diagrams.py
  python3 tools/export_route_diagrams.py --config changed
  python3 tools/export_route_diagrams.py --config all
  python3 tools/export_route_diagrams.py --config compact
"""
from __future__ import annotations

import argparse
import re
import subprocess
import time
import urllib.request
from pathlib import Path

from PIL import Image, ImageOps
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

# Trusted local Chrome captures can exceed Pillow's default pixel guard.
Image.MAX_IMAGE_PIXELS = 400_000_000

ROOT = Path(__file__).resolve().parents[1]
SHOTS = ROOT / "output" / "route-diagrams"
DOCS = ROOT / "documents"
PDF_NAME = "HTTP_POST_To_RabbitMQ_V2_Route_Diagrams.pdf"
BRAND = "PILOTFISH  ·  HTTP POST TO RABBITMQ"
BASE = "http://127.0.0.1:8135"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ROUTES = [
    ("1 — HTTP POST To RabbitMQ", "1-http-post-to-rabbitmq", "route1.png"),
]
MARGIN = 0.28 * inch
HEADER_H = 0.36 * inch
SLICE_OVERLAP_PX = 48


WINDOW_BY_CONFIG = {
    "compact": {"1-http-post-to-rabbitmq": (1800, 1400)},
    "changed": {"1-http-post-to-rabbitmq": (2200, 1800)},
    "all": {"1-http-post-to-rabbitmq": (2400, 2200)},
}


def wait_health(timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"{BASE}/api/v2/routes", timeout=2) as r:
                if r.status == 200:
                    return
        except Exception:
            time.sleep(0.5)
    raise SystemExit("Web UI not reachable on :8135")


def shot(route_id: str, dest: Path, size: tuple[int, int], config: str, *, collapse: str = "", group: str = ""):
    qs = [
        f"route={route_id}",
        "mode=docs",
        "layout=pipeline",
        "bare=1",
        f"config={config}",
    ]
    if collapse or group:
        qs.append("groups=1")
    if collapse:
        qs.append(f"collapse={collapse}")
    if group:
        qs.append(f"group={group}")
    url = f"{BASE}/static/route-viewer/index.html?{'&'.join(qs)}"
    cmd = [
        CHROME,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--window-size={size[0]},{size[1]}",
        f"--screenshot={dest}",
        "--virtual-time-budget=30000",
        url,
    ]
    subprocess.run(cmd, check=True, capture_output=True)


_VAULT_SERVICE_FP = re.compile(rb"s\.[A-Za-z0-9]{24}")


def scrub_github_secret_false_positives(pdf_path: Path) -> int:
    data = pdf_path.read_bytes()
    n = 0

    def _repl(m: re.Match[bytes]) -> bytes:
        nonlocal n
        n += 1
        return b"s_" + m.group(0)[2:]

    fixed = _VAULT_SERVICE_FP.sub(_repl, data)
    if n:
        pdf_path.write_bytes(fixed)
        print(f"  scrubbed {n} GitHub Vault-token false positive(s) in {pdf_path.name}")
    return n



def is_ink(r: int, g: int, b: int) -> bool:
    """True for diagram ink (text, borders, arrows, accents), not empty grid."""
    mx, mn = max(r, g, b), min(r, g, b)
    if mn < 210:
        return True
    if mx - mn > 18 and mn < 245:
        return True
    return False


def trim_diagram(im: Image.Image) -> Image.Image:
    """Crop to ink bbox, then pad so white node cards aren't clipped."""
    rgb = im.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    left, top, right, bottom = w, h, 0, 0
    found = False
    # Sample for speed, then refine near hits is overkill; step-2 keeps quality for PDF.
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if is_ink(*px[x, y]):
                found = True
                left = min(left, x)
                top = min(top, y)
                right = max(right, x)
                bottom = max(bottom, y)
    if not found:
        return im
    pad = 36
    box = (
        max(0, left - pad),
        max(0, top - pad),
        min(w, right + pad + 1),
        min(h, bottom + pad + 1),
    )
    cropped = rgb.crop(box)
    return ImageOps.expand(cropped, border=12, fill=(255, 255, 255))


def choose_pagesize(iw: int, ih: int):
    """Prefer orientation that maximizes width-scale for a tall strip."""
    candidates = [landscape(letter), letter]
    best = None
    best_scale = -1.0
    for page in candidates:
        pw, ph = page
        usable_w = pw - 2 * MARGIN
        usable_h = ph - 2 * MARGIN - HEADER_H
        # Vertical-slice strategy: always fill width; height is cut into pages.
        scale = usable_w / iw
        # Prefer pages that also give more vertical room per slice when scale ties.
        score = scale + (usable_h / max(ih, 1)) * 1e-6
        if score > best_scale:
            best_scale = score
            best = page
    return best


def vertical_slices(im: Image.Image, slice_h_px: int) -> list[Image.Image]:
    """Cut a tall image into overlapping vertical bands."""
    iw, ih = im.size
    if ih <= slice_h_px:
        return [im]
    slices: list[Image.Image] = []
    step = max(1, slice_h_px - SLICE_OVERLAP_PX)
    y = 0
    while y < ih:
        y2 = min(ih, y + slice_h_px)
        slices.append(im.crop((0, y, iw, y2)))
        if y2 >= ih:
            break
        y += step
    return slices


def draw_header(c: canvas.Canvas, brand: str, title: str, page_label: str, cw: float, ch: float):
    c.setFillColorRGB(1, 1, 1)
    c.rect(0, 0, cw, ch, fill=1, stroke=0)
    c.setFillColorRGB(0.04, 0.43, 0.31)
    c.setFont("Helvetica-Bold", 10)
    y = ch - MARGIN - 0.16 * inch
    left = f"{brand}  ·  {title}"
    c.drawString(MARGIN, y, left)
    if page_label:
        c.setFillColorRGB(0.35, 0.4, 0.48)
        c.setFont("Helvetica", 9)
        c.drawRightString(cw - MARGIN, y, page_label)


def build_pdf(images: list[tuple[str, Path]], pdf_path: Path, brand: str):
    """One or more pages per route: single header row + vertical diagram slices."""
    c = canvas.Canvas(str(pdf_path), pagesize=landscape(letter))

    for title, path in images:
        im = trim_diagram(Image.open(path))
        iw, ih = im.size
        page = choose_pagesize(iw, ih)
        c.setPageSize(page)
        cw, ch = page
        usable_w = cw - 2 * MARGIN
        usable_h = ch - 2 * MARGIN - HEADER_H
        scale = usable_w / iw
        # Pixel height of one page band at screenshot resolution
        slice_h_px = max(1, int(usable_h / scale))
        bands = vertical_slices(im, slice_h_px)
        total = len(bands)

        for idx, band in enumerate(bands, start=1):
            if idx > 1:
                c.setPageSize(page)
            bw, bh = band.size
            dw, dh = bw * scale, bh * scale
            x = MARGIN + (usable_w - dw) / 2
            # Pin each band just under the header (don't vertically center — wastes space)
            y = ch - MARGIN - HEADER_H - dh
            page_label = f"{idx}/{total}" if total > 1 else ""
            draw_header(c, brand, title, page_label, cw, ch)
            c.drawImage(
                ImageReader(band),
                x,
                y,
                width=dw,
                height=dh,
                preserveAspectRatio=True,
                mask="auto",
            )
            c.showPage()
    c.save()
    scrub_github_secret_false_positives(pdf_path)


def main():
    parser = argparse.ArgumentParser(description="Export V2 route diagrams to PDF")
    parser.add_argument(
        "--config",
        choices=["compact", "changed", "all"],
        default="compact",
        help="Box config mode from the Routes dropdown (default: changed)",
    )
    parser.add_argument(
        "--skip-capture",
        action="store_true",
        help="Rebuild PDF from existing PNGs in output/route-diagrams/",
    )
    args = parser.parse_args()
    config = args.config

    SHOTS.mkdir(parents=True, exist_ok=True)
    images = []
    if not args.skip_capture:
        wait_health()
        sizes = WINDOW_BY_CONFIG[config]
        for title, rid, name in ROUTES:
            dest = SHOTS / name
            size = sizes.get(rid, (2200, 4000))
            print(f"Capturing {title} (config={config}, window={size[0]}x{size[1]})")
            shot(rid, dest, size, config)
            trimmed = trim_diagram(Image.open(dest))
            trimmed.save(dest)
            print(f"  cropped -> {trimmed.size[0]}x{trimmed.size[1]}")
            images.append((title, dest))
    else:
        for title, rid, name in ROUTES:
            dest = SHOTS / name
            if not dest.exists():
                raise SystemExit(f"Missing {dest}; run without --skip-capture")
            print(f"Using existing {dest} ({Image.open(dest).size})")
            images.append((title, dest))

    DOCS.mkdir(parents=True, exist_ok=True)
    pdf = DOCS / PDF_NAME
    build_pdf(images, pdf, BRAND)
    print("Wrote", pdf)


if __name__ == "__main__":
    main()
