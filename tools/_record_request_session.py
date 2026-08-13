#!/usr/bin/env python3
"""Playwright recorder for request-demo theater pages.

Args: <theater.html> <plan.json> <out.webm>
Plan entries: html, dwell_ms
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from playwright.sync_api import sync_playwright

THEATER_CSS = """
html, body { margin: 0; background: #0b1220; }
#pf-theater-root {
  position: fixed; inset: 0; z-index: 1; pointer-events: none;
  font-family: "Segoe UI", system-ui, sans-serif;
}
#pf-theater-root * { box-sizing: border-box; }
#pf-theater-root .pf-t-layer {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  background: #0b1220; padding: 28px 32px 72px;
}
.pf-welcome-card, .pf-outro-card {
  width: min(720px, 92vw); text-align: center; background: #0f172a; color: #e8eef8;
  border: 1px solid #334155; border-radius: 18px; padding: 48px 44px 44px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.5);
}
.pf-welcome-card .logo, .pf-outro-card .logo {
  display: block; margin: 0 auto 28px; height: 72px; width: auto;
  object-fit: contain; filter: drop-shadow(0 4px 12px rgba(0,0,0,0.35));
}
.pf-welcome-card .eyebrow, .pf-outro-card .mark, .pf-pipe-card .eyebrow {
  color: #5eead4; font-size: 13px; letter-spacing: 0.14em;
  text-transform: uppercase; font-weight: 700; margin: 0 0 12px;
}
.pf-welcome-card h1, .pf-outro-card h1 { margin: 0 0 14px; font-size: 34px; line-height: 1.2; color: #fff; }
.pf-welcome-card .demo-name { margin: 0; font-size: 22px; font-weight: 600; color: #5eead4; line-height: 1.35; }
.pf-welcome-card .lead, .pf-outro-card p, .pf-pipe-card .lead {
  margin: 18px 0 0; color: #94a3b8; font-size: 16px; line-height: 1.5;
}
.pf-pipe-card {
  width: min(1080px, 96vw); background: #0b1220; color: #e8eef8;
  border: 1px solid #334155; border-radius: 16px; padding: 28px 32px 32px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.5); max-height: 86vh; overflow: auto;
}
.pf-pipe-card h2 { margin: 0 0 8px; font-size: 26px; color: #fff; }
.pf-pipe-card .lead { margin: 0 0 16px; }
.pf-pipe-card .meta { margin: 0 0 14px; color: #64748b; font-size: 14px; }
.pf-bullets { margin: 0; padding-left: 1.2rem; color: #e2e8f0; font-size: 16px; line-height: 1.45; }
.pf-bullets li { margin: 0 0 8px; }
.pf-file-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; }
.pf-file-tile {
  background: #111827; border: 1px solid #1f2937; border-radius: 12px; padding: 14px 16px;
  color: #f8fafc; font-size: 15px; word-break: break-word;
}
.pf-pass { margin: 0 0 14px; color: #5eead4; font-size: 20px; font-weight: 700; letter-spacing: 0.08em; }
.pf-shot {
  display: block; max-width: 100%; max-height: 280px; margin: 12px 0 0; border-radius: 10px;
  border: 1px solid #1f2937; object-fit: contain; background: #020617;
}
.pf-tpair { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.pf-tpair .tmeta { margin: 0 0 6px; color: #5eead4; font-size: 13px; font-weight: 700; }
.pf-tpair pre {
  margin: 0; padding: 12px 14px; background: #020617; border: 1px solid #134e4a; border-radius: 10px;
  color: #cbd5e1; font: 13px/1.45 ui-monospace, SFMono-Regular, Menlo, monospace;
  white-space: pre-wrap; word-break: break-word; max-height: 280px; overflow: hidden;
}
.pf-caption {
  position: fixed; left: 0; right: 0; bottom: 0; z-index: 2;
  background: #0f172a; border-top: 1px solid #1e293b; color: #e2e8f0;
  padding: 12px 22px; font: 15px/1.4 "Segoe UI", system-ui, sans-serif;
}
"""


def report_job(plan: list, index: int, step: dict) -> None:
    raw = str(os.environ.get("REQUEST_VIDEO_FOLDER") or "").strip()
    if not raw:
        return
    folder = Path(raw)
    path = folder / "request-video-job.json"
    data = {}
    if path.is_file():
        try:
            loaded = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                data = loaded
        except (OSError, json.JSONDecodeError):
            data = {}
    total = len(plan) or 1
    left = sum(int(s.get("dwell_ms") or 0) for s in plan[index - 1 :]) // 1000
    label = str(step.get("message") or step.get("id") or f"Scene {index}")
    log = list(data.get("log") or [])
    log.append({"at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "text": f"Scene {index}/{total}: {label}"})
    data.update(
        {
            "status": "running",
            "phase": "recording",
            "step": index,
            "step_total": total,
            "remaining_sec": left,
            "message": f"Recording {index} of {total} — {label}",
            "log": log[-12:],
            "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
    )
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    tmp.replace(path)


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: _record_request_session.py <theater.html> <plan.json> <out.webm>", file=sys.stderr)
        return 2
    html = Path(sys.argv[1]).resolve()
    plan = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
    out = Path(sys.argv[3])
    out.parent.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1440, "height": 900},
            record_video_dir=str(out.parent),
            record_video_size={"width": 1440, "height": 900},
        )
        page = context.new_page()
        page.goto(html.as_uri(), wait_until="domcontentloaded", timeout=30000)
        page.add_style_tag(content=THEATER_CSS)
        page.evaluate(
            """() => {
              document.documentElement.style.background = '#0b1220';
              document.body.style.background = '#0b1220';
              if (!document.getElementById('pf-theater-root')) {
                const root = document.createElement('div');
                root.id = 'pf-theater-root';
                document.body.appendChild(root);
              }
              if (!document.getElementById('pf-caption')) {
                const cap = document.createElement('div');
                cap.id = 'pf-caption';
                cap.className = 'pf-caption';
                document.body.appendChild(cap);
              }
            }"""
        )
        for index, step in enumerate(plan, start=1):
            report_job(plan, index, step)
            page.evaluate(
                """({ html, message }) => {
                  const root = document.getElementById('pf-theater-root');
                  if (root) root.innerHTML = html || '';
                  const cap = document.getElementById('pf-caption');
                  if (cap) cap.textContent = message || '';
                }""",
                {"html": step.get("html") or "", "message": step.get("message") or ""},
            )
            page.wait_for_timeout(int(step.get("dwell_ms") or 2500))
        page.wait_for_timeout(400)
        video = page.video
        page.close()
        if not video:
            raise SystemExit("Playwright did not produce a video file")
        video.save_as(str(out))
        context.close()
        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
