#!/usr/bin/env python3
"""Build a PDF preview from captured screenshots."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SHOT_DIR = ROOT / "artifacts" / "screenshots"
OUT = ROOT / "artifacts" / "JetsPizza_Clone_Preview.pdf"

ORDER = [
    "01-hero-desktop.png",
    "05-wings-promo.png",
    "02-fullpage-desktop.png",
    "03-mobile-hero.png",
    "04-mobile-full.png",
]


def main() -> None:
    images = []
    for name in ORDER:
        path = SHOT_DIR / name
        if not path.exists():
            raise SystemExit(f"Missing screenshot: {path}")
        img = Image.open(path).convert("RGB")
        images.append(img)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    first, *rest = images
    first.save(OUT, "PDF", resolution=100.0, save_all=True, append_images=rest)
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
