"""Rebuild a client implementation guide from V1 routes: convert to V2, then diagram PDF."""

from __future__ import annotations

import importlib.util
import json
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

from flask import Flask, Response, jsonify, send_file
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas
from werkzeug.serving import make_server

import client_impl_guide as guide
import clients
import demos

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
VIEWER = demos.CLIENTS / "Demos" / "_shared" / "webui" / "static" / "route-viewer"
MARGIN = 0.28 * inch
HEADER_H = 0.36 * inch
SLICE_OVERLAP = 48
def _need(*mods: str) -> None:
    missing = []
    for name in mods:
        try:
            __import__(name)
        except ImportError:
            missing.append("pillow" if name == "PIL" else name)
    if missing:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", *missing])


def _slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", (name or "").strip().lower()).strip("-")


def _short(root: Path) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "", root.name) or "Client"


def _brand(root: Path) -> str:
    return f"PILOTFISH  ·  {_short(root).upper()}"


def iter_routes(root: Path) -> list[tuple[Path, Path]]:
    found: list[tuple[Path, Path]] = []
    ifaces = root / "eip-root" / "interfaces"
    if not ifaces.is_dir():
        return found
    for iface in sorted(ifaces.iterdir()):
        routes = iface / "routes"
        if not routes.is_dir():
            continue
        formats = iface / "formats"
        for route in sorted(routes.iterdir()):
            if (route / "route.xml").is_file():
                found.append((route, formats))
    return found


def _converter():
    prefer = demos.CLIENTS / "Demos/Insurance/EDI/edi-837-ncci-mue/tools/convert_routes_to_v2.py"
    hits = [prefer] if prefer.is_file() else []
    hits += [p for p in sorted((demos.CLIENTS / "Demos").glob("**/tools/convert_routes_to_v2.py")) if p != prefer]
    if not hits:
        raise RuntimeError("No convert_routes_to_v2.py under Clients/Demos")
    spec = importlib.util.spec_from_file_location("pf_convert_v2", hits[0])
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.Converter


def convert_routes(root: Path, log) -> list[Path]:
    Converter = _converter()
    out: list[Path] = []
    pairs = iter_routes(root)
    for i, (route, formats) in enumerate(pairs, start=1):
        log(f"Converting {route.name} ({i}/{len(pairs)})")
        Converter(route, formats).convert()
        v2 = route / "route.v2.xml"
        if v2.is_file():
            out.append(v2)
    return out


def _nodes(v2: Path) -> int:
    return v2.read_text(encoding="utf-8", errors="replace").count("<Node ")


def _window(v2: Path) -> tuple[int, int]:
    n = max(1, _nodes(v2))
    return (min(3600, 2200 + n * 8), min(12000, 900 + n * 90))


class _Viewer:
    def __init__(self, routes: list[Path]):
        self.by_id = {_slug(p.parent.name): p.parent for p in routes}
        app = Flask("impl-docs-viewer")
        by_id = self.by_id

        @app.get("/api/v2/routes")
        def api_list():
            rows = [{"id": k, "name": p.name} for k, p in by_id.items()]
            return jsonify({"routes": rows})

        @app.get("/api/v2/environment-settings")
        def api_env():
            return jsonify({})

        @app.get("/api/v2/routes/<rid>/route.v2.xml")
        def api_xml(rid: str):
            folder = by_id.get(rid)
            path = folder / "route.v2.xml" if folder else None
            if not path or not path.is_file():
                return Response("not found", status=404)
            return send_file(path, mimetype="application/xml")

        @app.get("/api/v2/routes/<rid>/diagram-groups.json")
        def api_groups(rid: str):
            folder = by_id.get(rid)
            path = folder / "diagram-groups.json" if folder else None
            if path and path.is_file():
                return send_file(path, mimetype="application/json")
            return jsonify({"groups": []})

        @app.get("/api/v2/routes/<rid>/modules/<mid>.xml")
        def api_mod(rid: str, mid: str):
            folder = by_id.get(rid)
            path = folder / "modules" / f"{mid}.xml" if folder else None
            if not path or not path.is_file():
                return Response("not found", status=404)
            return send_file(path, mimetype="application/xml")

        @app.get("/static/route-viewer/<path:name>")
        def api_static(name: str):
            return send_file(VIEWER / name)

        self.server = make_server("127.0.0.1", 0, app, threaded=True)
        self.port = int(self.server.server_port)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    def start(self) -> int:
        self.thread.start()
        return self.port

    def stop(self) -> None:
        self.server.shutdown()


def _shot(url: str, dest: Path, size: tuple[int, int]) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        CHROME,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--window-size={size[0]},{size[1]}",
        f"--screenshot={dest}",
        "--virtual-time-budget=45000",
        url,
    ]
    subprocess.run(cmd, check=True, capture_output=True, timeout=90)


def _trim(path: Path):
    from PIL import Image, ImageOps

    Image.MAX_IMAGE_PIXELS = 400_000_000
    im = Image.open(path).convert("RGB")
    px = im.load()
    w, h = im.size
    left, top, right, bottom = w, h, 0, 0
    found = False
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r, g, b = px[x, y]
            if min(r, g, b) < 210 or (max(r, g, b) - min(r, g, b) > 18 and min(r, g, b) < 245):
                found = True
                left, top = min(left, x), min(top, y)
                right, bottom = max(right, x), max(bottom, y)
    if not found:
        return im
    box = (max(0, left - 36), max(0, top - 36), min(w, right + 37), min(h, bottom + 37))
    return ImageOps.expand(im.crop(box), border=12, fill=(255, 255, 255))


def capture(routes: list[Path], shots: Path, log) -> list[tuple[str, Path]]:
    if not Path(CHROME).is_file():
        raise RuntimeError("Google Chrome is required to capture route diagrams")
    if not VIEWER.is_dir():
        raise RuntimeError(f"Route viewer missing at {VIEWER}")
    viewer = _Viewer(routes)
    port = viewer.start()
    time.sleep(0.4)
    images: list[tuple[str, Path]] = []
    try:
        for i, v2 in enumerate(routes, start=1):
            rid = _slug(v2.parent.name)
            dest = shots / f"{i:02d}-{rid}.png"
            size = _window(v2)
            log(f"Diagram {v2.parent.name} ({i}/{len(routes)})")
            qs = f"route={rid}&mode=docs&layout=pipeline&bare=1&config=compact"
            _shot(f"http://127.0.0.1:{port}/static/route-viewer/index.html?{qs}", dest, size)
            trimmed = _trim(dest)
            trimmed.save(dest)
            images.append((v2.parent.name, dest))
    finally:
        viewer.stop()
    return images


def _slices(im, slice_h: int):
    iw, ih = im.size
    if ih <= slice_h:
        return [im]
    out = []
    step = max(1, slice_h - SLICE_OVERLAP)
    y = 0
    while y < ih:
        y2 = min(ih, y + slice_h)
        out.append(im.crop((0, y, iw, y2)))
        if y2 >= ih:
            break
        y += step
    return out


def write_diagrams_pdf(images: list[tuple[str, Path]], dest: Path, brand: str) -> Path:
    from PIL import Image

    dest.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(dest), pagesize=landscape(letter))
    for title, path in images:
        im = Image.open(path)
        iw, ih = im.size
        page = landscape(letter) if iw >= ih else letter
        c.setPageSize(page)
        cw, ch = page
        usable_w = cw - 2 * MARGIN
        usable_h = ch - 2 * MARGIN - HEADER_H
        scale = usable_w / max(iw, 1)
        bands = _slices(im, max(1, int(usable_h / scale)))
        for idx, band in enumerate(bands, start=1):
            if idx > 1:
                c.setPageSize(page)
            bw, bh = band.size
            dw, dh = bw * scale, bh * scale
            c.setFillColorRGB(1, 1, 1)
            c.rect(0, 0, cw, ch, fill=1, stroke=0)
            c.setFillColorRGB(0.04, 0.43, 0.31)
            c.setFont("Helvetica-Bold", 10)
            c.drawString(MARGIN, ch - MARGIN - 0.16 * inch, f"{brand}  ·  {title}")
            if len(bands) > 1:
                c.setFillColorRGB(0.35, 0.4, 0.48)
                c.setFont("Helvetica", 9)
                c.drawRightString(cw - MARGIN, ch - MARGIN - 0.16 * inch, f"{idx}/{len(bands)}")
            c.drawImage(ImageReader(band), MARGIN, ch - MARGIN - HEADER_H - dh, width=dw, height=dh, mask="auto")
            c.showPage()
    c.save()
    return dest


def _merge(parts: list[Path], dest: Path) -> Path:
    from pypdf import PdfReader, PdfWriter

    writer = PdfWriter()
    for path in parts:
        reader = PdfReader(str(path))
        for page in reader.pages:
            writer.add_page(page)
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as fh:
        writer.write(fh)
    return dest


def _save_rules(root: Path, n: int) -> None:
    rules = guide.load_rules(root)
    rules["pdf"] = f"documents/{guide.PDF_NAME}"
    rules["diagrams"] = f"documents/{_short(root)}_V2_Route_Diagrams.pdf"
    rules["story"] = "documents/how-it-works.md"
    rules["routes"] = n
    (guide.documents_dir(root) / guide.JSON_NAME).write_text(json.dumps(rules, indent=2) + "\n", encoding="utf-8")


def regenerate(root: Path, set_job=None) -> Path:
    def log(msg: str) -> None:
        if set_job:
            set_job(message=msg)

    _need("PIL", "pypdf")
    docs = guide.documents_dir(root)
    shots = docs / "_guide-shots"
    shots.mkdir(parents=True, exist_ok=True)
    if set_job:
        set_job(phase="convert", message="Converting routes to V2…")
    routes = convert_routes(root, log)
    if not routes:
        raise RuntimeError("No route.xml files under eip-root/interfaces")
    if set_job:
        set_job(phase="diagrams", message="Capturing V2 route diagrams…")
    images = capture(routes, shots, log)
    if set_job:
        set_job(phase="pdf", message="Writing implementation guide PDF…")
    diagrams = write_diagrams_pdf(images, docs / f"{_short(root)}_V2_Route_Diagrams.pdf", _brand(root))
    rules_pdf = guide.write_pdf(root, docs / "_rules_tmp.pdf")
    import client_impl_story as story

    story_pdf = story.write_pdf(root, docs / "_story_tmp.pdf")
    out = _merge([rules_pdf, story_pdf, diagrams], docs / guide.PDF_NAME)
    rules_pdf.unlink(missing_ok=True)
    story_pdf.unlink(missing_ok=True)
    _save_rules(root, len(routes))
    return out
