"""Official YouTube-style open and close cards for every construction video."""

from __future__ import annotations

import base64
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "Clients" / "Demos" / "_shared" / "webui" / "static" / "pilotfish-logo.png"
EICONSOLE_LOGO = ROOT / "Clients" / "Demos" / "_shared" / "webui" / "static" / "eiconsole-logo.png"
CATALOG = ROOT / "docs" / "website-demos.json"
BRAND_MS = 2200
PRODUCT_MS = 3500
CLOSE_MS = 4500
PHONE = "860 632-9900"

OPEN_CSS = """
.pf-brand-layer, .pf-product-layer {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; pointer-events: none;
}
.pf-brand-layer { background: #8ed4f8; }
.pf-brand-layer img {
  width: min(72vw, 980px); height: auto;
}
.pf-product-layer { background: #007cba; }
.pf-product-top {
  flex: 0 0 42%; width: 100%; background: #ececec;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 2.2rem 2rem 1.4rem;
}
.pf-product-top .pf-kind {
  margin: 0 0 1.1rem; font-size: clamp(2.1rem, 4.2vw, 3.4rem);
  font-weight: 800; color: #2a2a2a; letter-spacing: -0.02em;
}
.pf-eic { text-align: center; line-height: 1; }
.pf-eic-logo {
  display: block; width: min(56vw, 760px); height: auto; margin: 0 auto;
}
.pf-eic-sub {
  margin: 0.7rem 0 0; font-size: clamp(1.05rem, 2vw, 1.55rem);
  font-weight: 700; color: #0797f7;
}
.pf-product-bot {
  flex: 1 1 auto; width: 100%;
  background: linear-gradient(180deg, #0797f7 0%, #007cba 100%);
  display: flex; align-items: center; justify-content: center;
  padding: 2rem 3rem 2.4rem; text-align: center;
}
.pf-product-bot h1 {
  margin: 0; color: #fff; font-weight: 800;
  font-size: clamp(2rem, 4.4vw, 3.5rem); line-height: 1.15;
  max-width: 18ch;
}
.pf-close-layer {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; text-align: center;
  padding: 3.2rem 2.4rem 2.2rem;
  background: linear-gradient(180deg, #c5ebfc 0%, #8ed4f8 36%, #0797f7 72%, #007cba 100%);
  pointer-events: none;
}
.pf-close-layer .pf-eic { margin: 0 0 2.4rem; }
.pf-close-layer .pf-eic-logo { width: min(50vw, 680px); }
.pf-close-layer .pf-eic-sub { color: #2a2a2a; font-weight: 700; }
.pf-close-trial {
  margin: 0 0 1.15rem; font-size: clamp(1.7rem, 3.4vw, 2.55rem);
  font-weight: 800; color: #2a2a2a;
}
.pf-close-url {
  margin: 0 0 1rem; font-size: clamp(1.55rem, 3.2vw, 2.35rem);
  font-weight: 800; color: #fff; letter-spacing: -0.01em;
}
.pf-close-phone {
  margin: 0 0 2.4rem; font-size: clamp(1.15rem, 2.1vw, 1.55rem);
  font-weight: 600; color: #fff;
}
.pf-close-copy {
  margin: 0; font-size: 0.95rem; font-weight: 600; color: #3d4a54;
}
"""


def _catalog_item(demo: Path) -> dict:
    slug = demo.name
    raw = {}
    if CATALOG.is_file():
        try:
            raw = json.loads(CATALOG.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            raw = {}
    for item in raw.get("items") or []:
        if not isinstance(item, dict):
            continue
        if str(item.get("slug") or "") == slug or str(item.get("id") or "") == slug:
            return item
    return {}


def product_line(demo: Path) -> str:
    item = _catalog_item(demo)
    group = str(item.get("group") or "")
    blob = f"{group} {item.get('title') or ''} {demo.name}".lower()
    if "acord" in blob:
        return "for ACORD"
    if any(k in blob for k in ("hl7", "fhir", "healthcare", "x12", "edi")):
        return "for Healthcare"
    try:
        from demo_paths import infer_category

        cat = infer_category(demo.name)
    except Exception:
        cat = ""
    if str(cat).startswith("Medical"):
        return "for Healthcare"
    if str(cat).startswith("Insurance"):
        return "for Insurance"
    return ""


def demo_title(demo: Path) -> str:
    item = _catalog_item(demo)
    title = str(item.get("title") or "").strip()
    if title and title.lower() != "quick tour":
        return title
    from construction_demo_context import load_demo_display_name

    return load_demo_display_name(demo)


def trial_url(demo: Path) -> str:
    line = product_line(demo)
    if "Healthcare" in line:
        return "www.Healthcare.PilotFishTechnology.com"
    return "www.PilotFishTechnology.com"


def logo_url(demo: Path | None = None) -> str:
    from construction_demo_context import logo_data_uri

    return logo_data_uri(demo)


def eiconsole_logo_uri() -> str:
    """Official eiConsole wordmark (trial-page laptop art), inlined for theater + stills."""
    if EICONSOLE_LOGO.is_file():
        b64 = base64.b64encode(EICONSOLE_LOGO.read_bytes()).decode("ascii")
        return f"data:image/png;base64,{b64}"
    return ""


def brand_html(logo: str) -> str:
    return f'<div class="pf-t-layer pf-brand-layer"><img src="{logo}" alt="PilotFish" /></div>'


def _esc(s: str) -> str:
    return (
        str(s or "")
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def _eic_mark(line: str, logo: str | None = None) -> str:
    src = logo if logo is not None else eiconsole_logo_uri()
    img = f'<img class="pf-eic-logo" src="{src}" alt="eiConsole" />' if src else ""
    sub = f'<p class="pf-eic-sub">{_esc(line)}</p>' if line else ""
    return f'<div class="pf-eic">{img}{sub}</div>'


def product_html(title: str, line: str, logo: str | None = None) -> str:
    return (
        f'<div class="pf-t-layer pf-product-layer">'
        f'<div class="pf-product-top"><p class="pf-kind">Product Demo</p>'
        f'{_eic_mark(line, logo)}</div>'
        f'<div class="pf-product-bot"><h1>{_esc(title)}</h1></div></div>'
    )


def close_html(line: str, url: str, year: int | None = None, logo: str | None = None) -> str:
    year = year or datetime.now().year
    return (
        f'<div class="pf-t-layer pf-close-layer">'
        f'{_eic_mark(line, logo)}'
        f'<p class="pf-close-trial">Download a Free 90-Day Trial</p>'
        f'<p class="pf-close-url">{_esc(url)}</p>'
        f'<p class="pf-close-phone">Learn more by calling: {PHONE}</p>'
        f'<p class="pf-close-copy">©{year} PilotFish, Inc.</p></div>'
    )


def open_intro_line(demo: Path) -> str:
    return (
        f"This is PilotFish and the eiConsole, and this is a demo for {demo_title(demo)}."
    )


def preamble_open_entries(demo: Path, welcome: str) -> list[dict]:
    """YouTube-style open: Product Demo / eiConsole first. No fish lockup card."""
    title = demo_title(demo)
    line = product_line(demo)
    entries = [
        {
            "kind": "ui_gesture",
            "action": "show_product_demo",
            "id": "open-product",
            "demo_name": title,
            "product_line": line,
            "detail": open_intro_line(demo),
            "min_dwell_ms": PRODUCT_MS,
        },
    ]
    if welcome.strip():
        entries.append(
            {
                "kind": "ui_gesture",
                "action": "show_product_demo",
                "id": "open-product-welcome",
                "demo_name": title,
                "product_line": line,
                "detail": welcome,
                "min_dwell_ms": 1200,
            }
        )
    return entries


def _page_html(inner: str) -> str:
    return (
        "<!doctype html><html><head><meta charset='utf-8'>"
        "<style>html,body{margin:0;height:100%;font-family:Arial,Helvetica,sans-serif}"
        "#pf-theater-root{position:fixed;inset:0}"
        f"{OPEN_CSS}</style></head>"
        f"<body><div id='pf-theater-root'>{inner}</div></body></html>"
    )


def render_official_pngs(demo: Path, work: Path) -> tuple[Path, Path]:
    from playwright.sync_api import sync_playwright

    product = work / "open-product.png"
    close = work / "close-trial.png"
    title = demo_title(demo)
    line = product_line(demo)
    url = trial_url(demo)
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1920, "height": 1080})
        page.set_content(_page_html(product_html(title, line)), wait_until="load")
        page.screenshot(path=str(product), type="png")
        page.set_content(_page_html(close_html(line, url)), wait_until="load")
        page.screenshot(path=str(close), type="png")
        browser.close()
    return product, close


def still_mp4(png: Path, dest: Path, ms: int) -> Path:
    """Silent AAC on the still so concat does not drop the body narration track."""
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required for the official open")
    sec = max(ms, 400) / 1000.0
    proc = subprocess.run(
        [
            ffmpeg, "-y", "-loop", "1", "-i", str(png),
            "-f", "lavfi", "-t", f"{sec:.3f}",
            "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
            "-t", f"{sec:.3f}", "-r", "15", "-pix_fmt", "yuv420p",
            "-c:v", "libx264", "-c:a", "aac", "-ac", "2", "-ar", "44100",
            "-shortest", str(dest),
        ],
        capture_output=True, text=True,
    )
    if proc.returncode != 0 or not dest.is_file():
        raise SystemExit((proc.stderr or "open still failed")[-1500:])
    return dest


def _wav_ms(path: Path) -> int:
    import wave

    with wave.open(str(path), "rb") as wf:
        rate = float(wf.getframerate() or 1)
        return int(round(1000.0 * wf.getnframes() / rate))


def _concat_av(parts: list[Path], dest: Path) -> None:
    """Concat video+audio with a filter so stream layout cannot drop AAC."""
    ffmpeg = shutil.which("ffmpeg")
    cmd = [ffmpeg, "-y"]
    for part in parts:
        cmd.extend(["-i", str(part)])
    n = len(parts)
    pieces = []
    labels = []
    for i in range(n):
        pieces.append(
            f"[{i}:v:0]scale=1920:1080:force_original_aspect_ratio=decrease,"
            f"pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=15,format=yuv420p,setsar=1[v{i}];"
            f"[{i}:a:0]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,"
            f"aresample=async=1:first_pts=0[a{i}];"
        )
        labels.append(f"[v{i}][a{i}]")
    fc = "".join(pieces) + "".join(labels) + f"concat=n={n}:v=1:a=1[v][a]"
    cmd.extend(
        [
            "-filter_complex", fc, "-map", "[v]", "-map", "[a]",
            "-c:v", "libx264", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "160k", "-ar", "44100", "-ac", "2",
            "-movflags", "+faststart", str(dest),
        ]
    )
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0 or not dest.is_file():
        raise SystemExit((proc.stderr or "official open/close wrap failed")[-1500:])


def wrap_official_cards(
    demo: Path,
    body_mp4: Path,
    dest: Path,
    work: Path,
    *,
    intro_wav: Path | None = None,
) -> Path:
    """Put the YouTube Product Demo card in front and the trial card after."""
    product_png, close_png = render_official_pngs(demo, work)
    intro_ms = _wav_ms(intro_wav) if intro_wav and intro_wav.is_file() else 0
    open_ms = max(PRODUCT_MS, intro_ms + 180) if intro_ms else PRODUCT_MS
    product_v = still_mp4(product_png, work / "open-product.mp4", open_ms)
    close_v = still_mp4(close_png, work / "close-trial.mp4", CLOSE_MS)
    open_cards = product_v
    if intro_wav and intro_wav.is_file():
        ffmpeg = shutil.which("ffmpeg")
        spoken = work / "open-intro.mp4"
        sec = open_ms / 1000.0
        proc = subprocess.run(
            [
                ffmpeg, "-y", "-i", str(open_cards), "-i", str(intro_wav),
                "-map", "0:v:0", "-map", "1:a:0",
                "-c:v", "copy", "-c:a", "aac", "-b:a", "160k",
                "-ar", "44100", "-ac", "2", "-af", "apad",
                "-t", f"{sec:.3f}", "-movflags", "+faststart", str(spoken),
            ],
            capture_output=True, text=True,
        )
        if proc.returncode != 0 or not spoken.is_file():
            raise SystemExit((proc.stderr or "open intro mux failed")[-1500:])
        open_cards = spoken
    tmp = work / "open-wrapped.mp4"
    _concat_av([open_cards, body_mp4.resolve(), close_v], tmp)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(tmp, dest)
    return dest


def prepend_official_open(
    demo: Path,
    body_mp4: Path,
    dest: Path,
    work: Path,
    *,
    intro_wav: Path | None = None,
) -> Path:
    return wrap_official_cards(demo, body_mp4, dest, work, intro_wav=intro_wav)
