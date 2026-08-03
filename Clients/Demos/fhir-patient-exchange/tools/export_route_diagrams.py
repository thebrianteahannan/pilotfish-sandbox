#!/usr/bin/env python3
"""Screenshot FHIR demo V2 route diagrams and assemble a PDF.

Usage:
  python3 tools/export_route_diagrams.py
  python3 tools/export_route_diagrams.py --config changed
  python3 tools/export_route_diagrams.py --config all
  python3 tools/export_route_diagrams.py --config compact
"""
from __future__ import annotations

import argparse
import subprocess
import time
import urllib.request
from pathlib import Path

from PIL import Image, ImageOps
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parents[1]
SHOTS = ROOT / "output" / "route-diagrams"
DOCS = ROOT / "documents"
PDF_NAME = "FHIR_V2_Route_Diagrams.pdf"
BRAND = "PILOTFISH  ·  FHIR PATIENT EXCHANGE"
BASE = "http://127.0.0.1:8103"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ROUTES = [
    ("1 — Process FHIR Patient", "1-process-fhir-patient", "route1.png"),
]
MARGIN = 0.28 * inch
TITLE_H = 0.42 * inch

CONFIG_LABELS = {
    "compact": "Names only",
    "changed": "Non-default box config",
    "all": "All box config values",
}

WINDOW_BY_CONFIG = {
    "compact": {"1-process-fhir-patient": (2000, 2200)},
    "changed": {"1-process-fhir-patient": (2400, 3600)},
    "all": {"1-process-fhir-patient": (2600, 5200)},
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
    raise SystemExit("Web UI not reachable on :8103")


def shot(route_id: str, dest: Path, size: tuple[int, int], config: str):
    url = (
        f"{BASE}/static/route-viewer/index.html"
        f"?route={route_id}&mode=docs&layout=pipeline&bare=1&config={config}"
    )
    cmd = [
        CHROME,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=2",
        f"--window-size={size[0]},{size[1]}",
        f"--screenshot={dest}",
        "--virtual-time-budget=20000",
        url,
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def is_ink(r: int, g: int, b: int) -> bool:
    mx, mn = max(r, g, b), min(r, g, b)
    if mn < 210:
        return True
    if mx - mn > 18 and mn < 245:
        return True
    return False


def trim_diagram(im: Image.Image) -> Image.Image:
    rgb = im.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    left, top, right, bottom = w, h, 0, 0
    found = False
    for y in range(0, h, 1):
        for x in range(0, w, 1):
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
    return ImageOps.expand(rgb.crop(box), border=12, fill=(255, 255, 255))


def best_pagesize(iw: int, ih: int):
    candidates = [landscape(letter), letter]
    best = None
    best_scale = -1.0
    for page in candidates:
        cw, ch = page
        usable_w = cw - 2 * MARGIN
        usable_h = ch - 2 * MARGIN - TITLE_H
        scale = min(usable_w / iw, usable_h / ih)
        if scale > best_scale:
            best_scale = scale
            best = page
    return best, best_scale



def build_pdf(images: list[tuple[str, Path]], pdf_path: Path, config: str, brand: str):
    """One page per route: green brand header + diagram (no cover page)."""
    c = canvas.Canvas(str(pdf_path), pagesize=landscape(letter))
    brand_h = 0.30 * inch
    title_h = 0.34 * inch
    top_chrome = brand_h + title_h

    for title, path in images:
        im = trim_diagram(Image.open(path))
        iw, ih = im.size
        # pagesize with room for brand + title
        candidates = [landscape(letter), letter]
        best_page, best_scale = None, -1.0
        for page in candidates:
            pw, ph = page
            usable_w = pw - 2 * MARGIN
            usable_h = ph - 2 * MARGIN - top_chrome
            scale = min(usable_w / iw, usable_h / ih)
            if scale > best_scale:
                best_scale = scale
                best_page = page
        c.setPageSize(best_page)
        cw, ch = best_page
        dw, dh = iw * best_scale, ih * best_scale
        x = (cw - dw) / 2
        y = MARGIN + max(0, (ch - 2 * MARGIN - top_chrome - dh) / 2)

        c.setFillColorRGB(1, 1, 1)
        c.rect(0, 0, cw, ch, fill=1, stroke=0)
        c.setFillColorRGB(0.04, 0.43, 0.31)
        c.setFont("Helvetica-Bold", 11)
        c.drawString(MARGIN, ch - MARGIN - 0.18 * inch, brand)
        c.setFillColorRGB(0.09, 0.14, 0.2)
        c.setFont("Helvetica-Bold", 12)
        c.drawString(
            MARGIN,
            ch - MARGIN - 0.18 * inch - brand_h,
            f"{title}  ·  {CONFIG_LABELS.get(config, config)}",
        )
        c.drawImage(
            ImageReader(im),
            x,
            y,
            width=dw,
            height=dh,
            preserveAspectRatio=True,
            mask="auto",
        )
        c.showPage()
    c.save()


def main():
    parser = argparse.ArgumentParser(description="Export FHIR V2 route diagrams to PDF")
    parser.add_argument(
        "--config",
        choices=["compact", "changed", "all"],
        default="changed",
        help="Box config mode from the Routes dropdown (default: changed)",
    )
    args = parser.parse_args()
    config = args.config

    wait_health()
    SHOTS.mkdir(parents=True, exist_ok=True)
    images = []
    sizes = WINDOW_BY_CONFIG[config]
    for title, rid, name in ROUTES:
        dest = SHOTS / name
        size = sizes.get(rid, (2400, 3200))
        print(f"Capturing {title} (config={config}, window={size[0]}x{size[1]})")
        shot(rid, dest, size, config)
        trimmed = trim_diagram(Image.open(dest))
        trimmed.save(dest)
        print(f"  cropped -> {trimmed.size[0]}x{trimmed.size[1]}")
        images.append((title, dest))
    DOCS.mkdir(parents=True, exist_ok=True)
    pdf = DOCS / PDF_NAME
    build_pdf(images, pdf, config, BRAND)
    print("Wrote", pdf)


if __name__ == "__main__":
    main()
