#!/usr/bin/env python3
"""Apply progressive build-live assets + build-status API to demo Web UIs.

Copies from Clients/Demos/_shared/webui:
  - document_routes.py (includes ensure_build_status_api)
  - static/build-live.js + build-live.css + build-stage.js

Patches templates/index.html to include build-live CSS/JS when missing.
Patches app.py to call ensure_build_status_api when timing API is present.

Usage:
  python3 tools/apply_build_live_standard.py
  python3 tools/apply_build_live_standard.py --root Clients/Demos/ftp-named-download-trigger
"""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

from demo_paths import DEMOS, iter_demo_roots, require_demo

ROOT = Path(__file__).resolve().parents[1]
SHARED = DEMOS / "_shared" / "webui"


def demos_with_webui() -> list[Path]:
    out = []
    for p in iter_demo_roots():
        if (p / "webui" / "templates" / "index.html").is_file():
            out.append(p)
    return out


def copy_assets(demo: Path) -> None:
    webui = demo / "webui"
    shutil.copy2(SHARED / "document_routes.py", webui / "document_routes.py")
    static = webui / "static"
    static.mkdir(parents=True, exist_ok=True)
    for name in ("build-live.js", "build-live.css", "build-stage.js", "pilotfish-logo.jpg", "construction-video.js"):
        src = SHARED / "static" / name
        if src.is_file():
            shutil.copy2(src, static / name)


def patch_index(demo: Path) -> bool:
    idx = demo / "webui" / "templates" / "index.html"
    text = idx.read_text(encoding="utf-8")
    orig = text
    if "build-live.css" not in text:
        text = text.replace(
            "</head>",
            '  <link rel="stylesheet" href="/static/build-live.css" />\n</head>',
            1,
        )
    if "build-stage.js" not in text:
        if "build-live.js" in text:
            text = text.replace(
                '<script src="/static/build-live.js"></script>',
                '<script src="/static/build-stage.js"></script>\n  <script src="/static/build-live.js"></script>',
                1,
            )
        elif re.search(r'<script[^>]+src="/static/app\.js"', text):
            text = re.sub(
                r'(<script[^>]+src="/static/app\.js"[^>]*>\s*</script>)',
                r'<script src="/static/build-stage.js"></script>\n  <script src="/static/build-live.js"></script>\n  \1',
                text,
                count=1,
            )
    if "build-live.js" not in text:
        # Prefer before closing body, after other scripts
        if re.search(r'<script[^>]+src="/static/app\.js"', text):
            text = re.sub(
                r'(<script[^>]+src="/static/app\.js"[^>]*>\s*</script>)',
                r'<script src="/static/build-live.js"></script>\n  \1',
                text,
                count=1,
            )
        else:
            text = text.replace(
                "</body>",
                '  <script src="/static/build-live.js"></script>\n</body>',
                1,
            )
    if "construction-video.js" not in text:
        if "build-live.js" in text:
            text = text.replace(
                '<script src="/static/build-live.js"></script>',
                '<script src="/static/build-live.js"></script>\n  <script src="/static/construction-video.js"></script>',
                1,
            )
        elif re.search(r'<script[^>]+src="/static/app\.js"', text):
            text = re.sub(
                r'(<script[^>]+src="/static/app\.js"[^>]*>\s*</script>)',
                r'<script src="/static/construction-video.js"></script>\n  \1',
                text,
                count=1,
            )
        else:
            text = text.replace(
                "</body>",
                '  <script src="/static/construction-video.js"></script>\n</body>',
                1,
            )
    if text != orig:
        idx.write_text(text, encoding="utf-8")
        return True
    return False


def patch_app(demo: Path) -> bool:
    app = demo / "webui" / "app.py"
    if not app.is_file():
        return False
    text = app.read_text(encoding="utf-8")
    if "ensure_build_status_api(app" in text and "ensure_build_status_api = None" in text:
        return False

    block = (
        "try:\n"
        "    from document_routes import ensure_build_status_api, ensure_build_timing_api\n"
        "except ImportError:\n"
        "    ensure_build_timing_api = None  # type: ignore\n"
        "    ensure_build_status_api = None  # type: ignore\n"
        "if ensure_build_timing_api is not None:\n"
        "    from pathlib import Path as _PathTiming\n"
        "    import os as _os_timing\n"
        "\n"
        '    _docs_dir = _PathTiming(_os_timing.environ.get("DOCUMENTS_DIR", "/documents"))\n'
        "    ensure_build_timing_api(app, _docs_dir)\n"
        "if ensure_build_status_api is not None:\n"
        "    from pathlib import Path as _PathTiming2\n"
        "    import os as _os_timing2\n"
        "\n"
        "    ensure_build_status_api(\n"
        "        app,\n"
        '        _PathTiming2(_os_timing2.environ.get("DOCUMENTS_DIR", "/documents")),\n'
        "    )\n"
    )

    # Replace any existing timing/status bootstrap before if __name__
    import re

    pat = re.compile(
        r"try:\s*\n\s*from document_routes import ensure_build_(?:status_api, )?timing_api\n"
        r"except ImportError:.*?(?=\nif __name__)",
        re.S,
    )
    if pat.search(text):
        text = pat.sub(block + "\n", text)
    elif "if __name__" in text:
        text = text.replace("\nif __name__", "\n" + block + "\nif __name__", 1)
    else:
        text = text.rstrip() + "\n\n" + block

    app.write_text(text, encoding="utf-8")
    compile(text, str(app), "exec")
    return True


def ensure_idle_status(demo: Path) -> bool:
    docs = demo / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    path = docs / "build-status.json"
    if path.is_file():
        return False
    path.write_text(
        '{\n  "version": 1,\n  "active": false,\n  "phase": "idle",\n'
        '  "message": "Idle",\n  "routes_ready": [],\n  "updated_at": null\n}\n',
        encoding="utf-8",
    )
    return True


def apply_one(demo: Path) -> dict:
    copy_assets(demo)
    return {
        "demo": demo.name,
        "index": patch_index(demo),
        "app": patch_app(demo),
        "status": ensure_idle_status(demo),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", help="Single demo root")
    args = ap.parse_args()
    targets = [require_demo(args.root)] if args.root else demos_with_webui()
    for demo in targets:
        if not demo.is_dir():
            raise SystemExit(f"Not a demo dir: {demo}")
        info = apply_one(demo)
        print(
            f"{info['demo']}: index={'patched' if info['index'] else 'ok'} "
            f"app={'patched' if info['app'] else 'ok'} "
            f"status={'created' if info['status'] else 'ok'}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
