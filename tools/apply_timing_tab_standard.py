#!/usr/bin/env python3
"""Apply Timing tab (build-timing.json viewer) across Sandbox demos.

Source:
  Clients/Demos/_shared/webui/templates/partials/timing_tab.html
  Clients/Demos/_shared/webui/static/timing-tab.{js,css}
  Clients/Demos/_shared/webui/document_routes.py → ensure_build_timing_api

Run:
  python3 tools/apply_timing_tab_standard.py
  python3 tools/apply_timing_tab_standard.py --demo edi-837-snip-sqlserver
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

SANDBOX = Path(__file__).resolve().parents[1]
DEMOS = SANDBOX / "Clients" / "Demos"
SHARED = DEMOS / "_shared" / "webui"

MARKER_START = "<!-- TIMING_TAB_STANDARD:START -->"
MARKER_END = "<!-- TIMING_TAB_STANDARD:END -->"
INCLUDE = "{% include 'partials/timing_tab.html' %}"
API_MARKER = "# TIMING_TAB_API_BOOTSTRAP"
ASSET_CSS = '  <link rel="stylesheet" href="/static/timing-tab.css" />'
ASSET_JS = '  <script src="/static/timing-tab.js"></script>'


def demo_roots() -> list[Path]:
    out = []
    for p in sorted(DEMOS.iterdir()):
        if p.name.startswith("_"):
            continue
        if (p / "webui" / "templates" / "index.html").is_file():
            out.append(p)
    return out


def copy_shared(demo: Path) -> None:
    webui = demo / "webui"
    shutil.copy2(SHARED / "document_routes.py", webui / "document_routes.py")
    partial_dir = webui / "templates" / "partials"
    partial_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SHARED / "templates" / "partials" / "timing_tab.html", partial_dir / "timing_tab.html")
    static = webui / "static"
    static.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SHARED / "static" / "timing-tab.js", static / "timing-tab.js")
    shutil.copy2(SHARED / "static" / "timing-tab.css", static / "timing-tab.css")


def ensure_assets(html: str) -> str:
    if "timing-tab.css" not in html:
        if "</head>" in html:
            html = html.replace("</head>", ASSET_CSS + "\n</head>", 1)
        else:
            html = ASSET_CSS + "\n" + html
    if "timing-tab.js" not in html:
        # after app.js if present, else before </body>
        if re.search(r'<script[^>]+src=["\']/static/app\.js["\']', html):
            html = re.sub(
                r'(<script[^>]+src=["\']/static/app\.js["\'][^>]*>\s*</script>)',
                r"\1\n" + ASSET_JS,
                html,
                count=1,
            )
        elif "</body>" in html:
            html = html.replace("</body>", ASSET_JS + "\n</body>", 1)
        else:
            html += "\n" + ASSET_JS
    return html


def ensure_timing_button(html: str) -> str:
    if re.search(r"""data-(?:main-)?tab=["']timing["']""", html):
        return html
    # Insert before Info button when present
    m = re.search(
        r"""(<button[^>]+data-(?:main-)?tab=["']info["'][^>]*>.*?</button>)""",
        html,
        re.S | re.I,
    )
    if m:
        sibling = m.group(1)
        if 'data-main-tab="' in sibling:
            btn = (
                '<button type="button" class="main-tab" data-main-tab="timing" '
                'role="tab" aria-selected="false">Timing</button>\n        '
            )
        else:
            btn = (
                '<button type="button" class="tab" data-tab="timing" '
                'aria-selected="false">Timing</button>\n        '
            )
        return html[: m.start()] + btn + html[m.start() :]

    # Else after last tab button
    m = re.search(
        r"""(<button[^>]+data-(?:main-)?tab=["'][^"']+["'][^>]*>.*?</button>)(?![\s\S]*?<button[^>]+data-(?:main-)?tab=)""",
        html,
        re.S,
    )
    if not m:
        return html
    sibling = m.group(1)
    if 'data-main-tab="' in sibling:
        btn = (
            '\n        <button type="button" class="main-tab" data-main-tab="timing" '
            'role="tab" aria-selected="false">Timing</button>'
        )
    else:
        btn = (
            '\n        <button type="button" class="tab" data-tab="timing" '
            'aria-selected="false">Timing</button>'
        )
    return html[: m.end()] + btn + html[m.end() :]


def _replace_balanced(html: str, tag: str, id_value: str, replacement: str) -> str | None:
    open_re = re.compile(rf"[ \t]*<{tag}\b[^>]*\bid=[\"']{re.escape(id_value)}[\"'][^>]*>", re.I)
    m = open_re.search(html)
    if not m:
        return None
    start = m.start()
    i = m.end()
    depth = 1
    open_tag = re.compile(rf"<{tag}\b", re.I)
    close_tag = re.compile(rf"</{tag}\s*>", re.I)
    while i < len(html) and depth:
        om = open_tag.search(html, i)
        cm = close_tag.search(html, i)
        if not cm:
            return None
        if om and om.start() < cm.start():
            depth += 1
            i = om.end()
        else:
            depth -= 1
            i = cm.end()
            if depth == 0:
                end = i + (1 if i < len(html) and html[i] == "\n" else 0)
                return html[:start] + replacement + html[end:]
    return None


def ensure_timing_include(html: str) -> str:
    block = f"  {MARKER_START}\n  {INCLUDE}\n  {MARKER_END}\n"
    if MARKER_START in html and MARKER_END in html:
        return re.sub(
            re.escape(MARKER_START) + r".*?" + re.escape(MARKER_END),
            f"{MARKER_START}\n  {INCLUDE}\n  {MARKER_END}",
            html,
            count=1,
            flags=re.S,
        )
    out = _replace_balanced(html, "div", "tab-timing", block)
    if out:
        return out
    # Insert before Info markers or info include or scripts
    for needle in (
        "<!-- INFO_TAB_STANDARD:START -->",
        "{% include 'partials/info_tab.html' %}",
        'id="tab-info"',
    ):
        idx = html.find(needle)
        if idx != -1:
            # walk back to line start
            line = html.rfind("\n", 0, idx) + 1
            return html[:line] + block + html[line:]
    m = re.search(r"[ \t]*<script\b", html)
    if m:
        return html[: m.start()] + block + "\n" + html[m.start() :]
    return html + "\n" + block


def ensure_api_bootstrap(app_py: Path) -> None:
    if not app_py.is_file():
        return
    text = app_py.read_text(encoding="utf-8")
    bootstrap = f'''
{API_MARKER}
try:
    from document_routes import ensure_build_timing_api
except ImportError:
    ensure_build_timing_api = None  # type: ignore
if ensure_build_timing_api is not None:
    from pathlib import Path as _PathTiming
    import os as _os_timing
    ensure_build_timing_api(
        app,
        _PathTiming(_os_timing.environ.get("DOCUMENTS_DIR", "/documents")),
    )
# END TIMING_TAB_API_BOOTSTRAP
'''
    if API_MARKER in text:
        text = re.sub(
            re.escape(API_MARKER) + r".*?# END TIMING_TAB_API_BOOTSTRAP\n?",
            bootstrap.lstrip("\n"),
            text,
            count=1,
            flags=re.S,
        )
    else:
        m = re.search(r"\nif __name__ == [\"']__main__[\"']:", text)
        if m:
            text = text[: m.start()] + "\n" + bootstrap + text[m.start() :]
        else:
            text = text.rstrip() + "\n" + bootstrap + "\n"
    app_py.write_text(text, encoding="utf-8")


def patch_set_main_tab(js_path: Path) -> None:
    """Light touch: ensure setMainTab toggles #tab-timing when function exists."""
    if not js_path.is_file():
        return
    js = js_path.read_text(encoding="utf-8")
    if "tab-timing" in js and "timing.hidden" in js:
        return
    # Insert after const info = ... block inside setMainTab if present
    if "function setMainTab" not in js:
        return
    if "getElementById(\"tab-timing\")" in js or "getElementById('tab-timing')" in js:
        return
    # After info.hidden line or demo.hidden
    m = re.search(
        r"(if \(info\) info\.hidden = tab !== [\"']info[\"'];\n)",
        js,
    )
    insert = (
        '  const timing = document.getElementById("tab-timing");\n'
        '  if (timing) timing.hidden = tab !== "timing";\n'
    )
    if m:
        js = js[: m.end()] + insert + js[m.end() :]
    else:
        m2 = re.search(r"(demo\.hidden = tab !== [\"']demo[\"'];\n)", js)
        if m2:
            js = js[: m2.end()] + insert + js[m2.end() :]
        else:
            return
    js_path.write_text(js, encoding="utf-8")


def strip_duplicate_claim_scrub_timing_js(js_path: Path) -> None:
    """Remove inlined Timing tab from claim-scrub app.js once shared file is used."""
    if js_path.parent.parent.parent.name != "edi-837-claim-scrub":
        return
    js = js_path.read_text(encoding="utf-8")
    js2 = re.sub(
        r'\n  if \(tab === ["\']timing["\']\) \{\n'
        r'    loadTimingTab\(\)\.catch\(\(e\) => \{\n'
        r"[\s\S]*?"
        r"    \}\);\n"
        r"  \}\n",
        "\n",
        js,
        count=1,
    )
    if "/* Build timing tab */" in js2:
        js2 = re.sub(
            r"\n/\* Build timing tab \*/[\s\S]*\Z",
            "\n/* Build timing tab: see /static/timing-tab.js */\n",
            js2,
            count=1,
        )
    if js2 != js:
        js_path.write_text(js2, encoding="utf-8")


def ensure_dockerfile(demo: Path) -> None:
    df = demo / "webui" / "Dockerfile"
    if not df.is_file():
        return
    text = df.read_text(encoding="utf-8")
    if "document_routes.py" in text:
        return
    replacements = [
        (r"COPY app\.py snip_report\.py docs_and_v2\.py \./", "COPY app.py snip_report.py docs_and_v2.py document_routes.py ./"),
        (r"COPY app\.py snip_report\.py \./", "COPY app.py snip_report.py document_routes.py ./"),
        (r"COPY app\.py \./", "COPY app.py document_routes.py ./"),
        (r"COPY app\.py \.", "COPY app.py document_routes.py ."),
    ]
    for pat, repl in replacements:
        if re.search(pat, text):
            df.write_text(re.sub(pat, repl, text, count=1), encoding="utf-8")
            return


def apply_demo(demo: Path) -> None:
    copy_shared(demo)
    ensure_dockerfile(demo)
    idx = demo / "webui" / "templates" / "index.html"
    html = idx.read_text(encoding="utf-8")
    html = ensure_timing_button(html)
    html = ensure_timing_include(html)
    html = ensure_assets(html)
    # ensure CSS hidden rule for #tab-timing exists via timing-tab.css
    idx.write_text(html, encoding="utf-8")

    ensure_api_bootstrap(demo / "webui" / "app.py")
    patch_set_main_tab(demo / "webui" / "static" / "app.js")
    strip_duplicate_claim_scrub_timing_js(demo / "webui" / "static" / "app.js")

    # CSS body rule from claim-scrub for [hidden] list may omit timing — append if needed
    css = demo / "webui" / "static" / "app.css"
    if css.is_file():
        text = css.read_text(encoding="utf-8")
        if "#tab-timing[hidden]" not in text and "timing-tab.css" in html:
            pass  # covered by timing-tab.css
        # If old claim-scrub had inline timing CSS, leave it (harmless duplicate)

    print(f"applied: {demo.name}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", action="append")
    args = ap.parse_args()
    roots = demo_roots()
    if args.demo:
        wanted = set(args.demo)
        roots = [r for r in roots if r.name in wanted]
        missing = wanted - {r.name for r in roots}
        if missing:
            raise SystemExit(f"Unknown demos: {sorted(missing)}")
    for root in roots:
        apply_demo(root)


if __name__ == "__main__":
    main()
