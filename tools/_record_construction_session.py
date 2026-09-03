#!/usr/bin/env python3
"""Playwright session recorder for tools/export_construction_video.py.

Args: <base_url> <plan.json> <out.webm>

Plan entries:
  Construction: id, dwell_ms, message, detail, route_id, focus_label, focus_node_id, kind
  Optional on construction: show_xslt, xslt_name, xslt_text, xslt_highlight_lines
  ui_gesture: action=show_brand|show_product_demo|show_welcome|show_pipeline|spotlight_systems|create_interface|spotlight_ognl|hide_overlays
  demo_test: action=open_demo|inject|wait_results|show_results
  outro: closing thank-you screen
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

try:
    from construction_official_open import OPEN_CSS, brand_html, close_html, product_html
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from construction_official_open import OPEN_CSS, brand_html, close_html, product_html


THEATER_CSS = """
#pf-theater-root {
  position: fixed; inset: 0; z-index: 99990; pointer-events: none;
  font-family: "Segoe UI", system-ui, sans-serif;
}
#pf-theater-root * { box-sizing: border-box; }
#pf-theater-root .pf-t-layer {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  background: rgba(10, 18, 32, 0.55); pointer-events: auto;
  animation: pfFadeIn 280ms ease;
}
#pf-theater-root .pf-t-layer.pf-welcome-layer,
#pf-theater-root .pf-t-layer.pf-outro-layer {
  background: #0b1220;
  animation: none;
  opacity: 1;
}
#pf-theater-root .pf-t-layer.is-clear { background: transparent; }
@keyframes pfFadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes pfPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(14, 165, 120, 0.55); transform: scale(1); }
  50% { box-shadow: 0 0 0 14px rgba(14, 165, 120, 0); transform: scale(1.03); }
}
@keyframes pfClick {
  0% { transform: scale(1); }
  40% { transform: scale(0.94); }
  100% { transform: scale(1); }
}
.pf-create-card {
  width: min(560px, 90vw); background: #0f172a; color: #e8eef8;
  border: 1px solid #334155; border-radius: 16px; padding: 36px 40px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.45); text-align: center;
}
.pf-create-card .eyebrow { color: #5eead4; font-size: 12px; letter-spacing: 0.12em;
  text-transform: uppercase; font-weight: 700; margin: 0 0 10px; }
.pf-create-card h1 { margin: 0 0 12px; font-size: 28px; line-height: 1.2; color: #fff; }
.pf-create-card p { margin: 0 0 28px; color: #94a3b8; font-size: 15px; line-height: 1.45; }
#pf-create-iface-btn {
  appearance: none; border: 0; cursor: pointer; pointer-events: auto;
  background: linear-gradient(180deg, #14b8a6, #0d9488); color: #042f2e;
  font-weight: 700; font-size: 16px; padding: 14px 28px; border-radius: 10px;
  animation: pfPulse 1.6s ease-in-out infinite;
}
#pf-create-iface-btn.is-clicked { animation: pfClick 280ms ease; background: #0f766e; color: #ecfdf5; }
.pf-create-card.is-done h1 { color: #5eead4; }
.pf-ognl-card {
  width: min(920px, 94vw); background: #0b1220; color: #e8eef8;
  border: 1px solid #334155; border-radius: 16px; padding: 28px 32px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.5);
}
.pf-ognl-card .eyebrow { color: #38bdf8; font-size: 12px; letter-spacing: 0.12em;
  text-transform: uppercase; font-weight: 700; margin: 0 0 8px; }
.pf-ognl-card h2 { margin: 0 0 10px; font-size: 26px; color: #fff; }
.pf-ognl-card .why { margin: 0 0 22px; color: #94a3b8; font-size: 15px; line-height: 1.5; }
.pf-ognl-summary {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 34px; line-height: 1.25; color: #5eead4; background: #020617;
  border: 1px solid #134e4a; border-radius: 12px; padding: 22px 24px; margin: 0 0 14px;
  word-break: break-word;
}
.pf-ognl-raw {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 13px; line-height: 1.45; color: #cbd5e1; background: #111827;
  border: 1px solid #1f2937; border-radius: 10px; padding: 14px 16px;
  white-space: pre-wrap; word-break: break-word; max-height: 180px; overflow: auto;
}
.pf-ognl-legend { margin: 12px 0 0; color: #64748b; font-size: 13px; }
.pf-xslt-card {
  width: min(1180px, 96vw); height: min(820px, 90vh); max-height: 90vh;
  display: flex; flex-direction: column;
  background: #0b1220; color: #e8eef8; border: 1px solid #334155; border-radius: 14px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.5); overflow: hidden;
}
.pf-xslt-head {
  display: flex; align-items: baseline; gap: 12px; padding: 14px 18px; flex: 0 0 auto;
  border-bottom: 1px solid #1f2937; background: #111827;
}
.pf-xslt-head strong { color: #5eead4; font-size: 14px; }
.pf-xslt-head span { color: #94a3b8; font-size: 13px; }
.pf-xslt-scroll {
  overflow: auto; padding: 0; flex: 1 1 auto; min-height: 0; background: #282c34;
  scroll-behavior: auto;
}
.pf-xslt-card .viewer,
.pf-xslt-card pre.xslt-source,
.pf-xslt-card pre#pf-xslt-view {
  max-height: none !important; min-height: 0 !important; height: auto !important;
  overflow: visible !important; border: 0 !important; border-radius: 0 !important;
  background: transparent !important;
}
.pf-xslt-scroll pre.xslt-source,
.pf-xslt-scroll pre#pf-xslt-view {
  margin: 0; padding: 0; background: transparent; width: 100%;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 13.5px; line-height: 1.55; color: #abb2bf;
  white-space: pre-wrap !important; word-break: break-word !important;
  overflow-wrap: anywhere !important; min-width: 0 !important;
}
.pf-xslt-scroll pre.xslt-source > code,
.pf-xslt-scroll pre#pf-xslt-view > code {
  display: block; padding: 18px 22px 72px; background: transparent !important;
  white-space: pre-wrap !important; word-break: break-word !important;
  overflow-wrap: anywhere !important; min-width: 0 !important; width: 100%;
}
.pf-xslt-caption {
  flex: 0 0 auto; padding: 12px 18px; min-height: 3.1em;
  background: #0f172a; border-top: 1px solid #1e293b;
  color: #e2e8f0; font-size: 15px; line-height: 1.4;
}
.pf-xslt-caption em { color: #5eead4; font-style: normal; font-weight: 600; }
.pf-welcome-card {
  width: min(720px, 92vw); text-align: center; background: #0f172a; color: #e8eef8;
  border: 1px solid #334155; border-radius: 18px; padding: 48px 44px 44px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.5);
}
.pf-welcome-card .logo {
  display: block; margin: 0 auto 28px; height: 72px; width: auto;
  object-fit: contain; filter: drop-shadow(0 4px 12px rgba(0,0,0,0.35));
}
.pf-welcome-card .eyebrow {
  color: #5eead4; font-size: 13px; letter-spacing: 0.14em;
  text-transform: uppercase; font-weight: 700; margin: 0 0 12px;
}
.pf-welcome-card h1 { margin: 0 0 14px; font-size: 34px; line-height: 1.2; color: #fff; }
.pf-welcome-card .demo-name {
  margin: 0; font-size: 22px; font-weight: 600; color: #5eead4; line-height: 1.35;
}
.pf-welcome-card .lead {
  margin: 18px 0 0; color: #94a3b8; font-size: 16px; line-height: 1.5;
}
.pf-outro-card {
  width: min(640px, 92vw); text-align: center; background: #0f172a; color: #e8eef8;
  border: 1px solid #334155; border-radius: 16px; padding: 44px 40px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.45);
}
.pf-outro-card .logo {
  display: block; margin: 0 auto 28px; height: 72px; width: auto;
  object-fit: contain; filter: drop-shadow(0 4px 12px rgba(0,0,0,0.35));
}
.pf-outro-card .mark { color: #5eead4; font-size: 13px; letter-spacing: 0.14em;
  text-transform: uppercase; font-weight: 700; margin: 0 0 14px; }
.pf-outro-card h1 { margin: 0 0 14px; font-size: 32px; color: #fff; }
.pf-outro-card p { margin: 0; color: #94a3b8; font-size: 17px; line-height: 1.5; }
.pf-pipe-card {
  width: min(1080px, 96vw); background: #0b1220; color: #e8eef8;
  border: 1px solid #334155; border-radius: 16px; padding: 28px 32px 32px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.5);
}
.pf-pipe-card .eyebrow { color: #5eead4; font-size: 12px; letter-spacing: 0.12em;
  text-transform: uppercase; font-weight: 700; margin: 0 0 8px; }
.pf-pipe-card h2 { margin: 0 0 8px; font-size: 26px; color: #fff; }
.pf-pipe-card .lead { margin: 0 0 22px; color: #94a3b8; font-size: 15px; line-height: 1.45; }
.pf-pipe-row {
  display: flex; align-items: stretch; gap: 10px; flex-wrap: wrap;
}
.pf-pipe-node {
  flex: 1 1 160px; min-width: 140px; background: #111827; border: 1px solid #1f2937;
  border-radius: 12px; padding: 16px 14px; text-align: center;
}
.pf-pipe-node.pf-pipe-src { border-color: #0e7490; background: #0c1a24; }
.pf-pipe-node.pf-pipe-out { border-color: #0f766e; background: #0a1f1c; }
.pf-pipe-node strong { display: block; font-size: 16px; color: #f8fafc; margin-bottom: 6px; }
.pf-pipe-node span { display: block; font-size: 13px; color: #94a3b8; line-height: 1.35; }
.pf-pipe-arrow {
  align-self: center; color: #5eead4; font-size: 22px; font-weight: 700; padding: 0 2px;
}
.pf-systems-card {
  width: min(980px, 96vw); background: #0b1220; color: #e8eef8;
  border: 1px solid #334155; border-radius: 16px; padding: 26px 28px 28px;
  box-shadow: 0 28px 80px rgba(0,0,0,0.5);
}
.pf-systems-card .eyebrow { color: #38bdf8; font-size: 12px; letter-spacing: 0.12em;
  text-transform: uppercase; font-weight: 700; margin: 0 0 8px; }
.pf-systems-card h2 { margin: 0 0 8px; font-size: 26px; color: #fff; }
.pf-systems-card .lead { margin: 0 0 18px; color: #94a3b8; font-size: 15px; line-height: 1.45; }
.pf-systems-grid {
  display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px;
}
@media (max-width: 800px) {
  .pf-systems-grid { grid-template-columns: 1fr; }
}
.pf-system-tile {
  background: #111827; border: 1px solid #1f2937; border-radius: 12px; padding: 14px 16px;
}
.pf-system-tile .kind {
  display: inline-block; font-size: 11px; font-weight: 700; letter-spacing: 0.08em;
  text-transform: uppercase; color: #042f2e; background: #5eead4; border-radius: 999px;
  padding: 2px 8px; margin-bottom: 8px;
}
.pf-system-tile strong { display: block; font-size: 16px; color: #f8fafc; margin-bottom: 4px; }
.pf-system-tile .role { margin: 0 0 8px; color: #94a3b8; font-size: 13px; line-height: 1.35; }
.pf-system-tile .meta {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 12px; color: #cbd5e1; line-height: 1.4;
}
.pf-system-tile .image { color: #64748b; }
body.pf-theater-recording #pf-build-banner,
body.pf-theater-recording #pf-routes-activity,
body.pf-theater-recording #pf-build-stage {
  display: none !important;
}
#pipeline.pf-pipeline-spotlight {
  outline: 3px solid #14b8a6; outline-offset: 6px; border-radius: 12px;
  box-shadow: 0 0 0 10px rgba(20, 184, 166, 0.15);
}
""" + OPEN_CSS


def step_frame_src(step: dict) -> str:
    step_id = step.get("id") or "0001"
    if step.get("kind") in {"intro", "demo_test", "ui_gesture", "outro"}:
        return "about:blank"
    src = (
        f"/static/route-viewer/index.html?replayStep={step_id}"
        + (f"&route={step['route_id']}" if step.get("route_id") else "")
        + (f"&focusLabel={step['focus_label']}" if step.get("focus_label") else "")
        + (f"&focusNode={step['focus_node_id']}" if step.get("focus_node_id") else "")
        + f"&mode=docs&layout=pipeline&config=changed&v={step_id}"
    )
    if step.get("show_xslt"):
        src += "&showXslt=1"
    return src


def ensure_theater_chrome(page) -> None:
    page.evaluate(
        """({ css }) => {
          let style = document.getElementById('pf-theater-style');
          if (!style) {
            style = document.createElement('style');
            style.id = 'pf-theater-style';
            style.textContent = css;
            document.head.appendChild(style);
          }
          let root = document.getElementById('pf-theater-root');
          if (!root) {
            root = document.createElement('div');
            root.id = 'pf-theater-root';
            document.body.appendChild(root);
          }
          document.body.classList.add('pf-theater-recording');
          window.__pfTheaterRecording = true;
          const liveStage = document.getElementById('pf-build-stage');
          if (liveStage) liveStage.hidden = true;
          const liveBanner = document.getElementById('pf-build-banner');
          if (liveBanner) {
            liveBanner.hidden = true;
            liveBanner.classList.remove('is-active');
          }
          const liveActivity = document.getElementById('pf-routes-activity');
          if (liveActivity) {
            liveActivity.hidden = true;
            liveActivity.classList.remove('is-active');
          }
          const statusEl = document.getElementById('routes-status');
          if (statusEl) {
            statusEl.textContent = '';
            statusEl.classList.remove('is-building');
          }
        }""",
        {"css": THEATER_CSS},
    )


def clear_theater_overlay(page) -> None:
    page.evaluate(
        """() => {
          const root = document.getElementById('pf-theater-root');
          if (root) root.innerHTML = '';
        }"""
    )


def update_banner(page, step: dict, index: int, total: int, *, phase: str) -> None:
    # Live-build banner/activity is hidden during theater recording.
    return


def show_construction_step(page, step: dict, index: int, total: int) -> None:
    clear_theater_overlay(page)
    switch_tab(page, "routes")
    page.evaluate(
        """({ step, src }) => {
          const select = document.getElementById('route-select');
          if (select && step.route_id) {
            const opt = [...select.options].find(o => o.value === step.route_id);
            if (opt) select.value = step.route_id;
          }
          const frame = document.getElementById('route-viewer-frame');
          if (frame) {
            frame.style.visibility = 'hidden';
            frame.dataset.empty = '0';
            try {
              const doc = frame.contentDocument;
              if (doc && doc.documentElement) {
                doc.documentElement.removeAttribute('data-ready');
              }
            } catch (e) {}
            frame.src = src;
          }
        }""",
        {"step": step, "src": step_frame_src(step)},
    )


def wait_frame_ready(page, timeout_ms: int = 8000, replay_step: str = "") -> None:
    page.wait_for_function(
        """(step) => {
          const frame = document.getElementById('route-viewer-frame');
          if (!frame) return true;
          if (!frame.src || frame.src === 'about:blank' || frame.src.endsWith('about:blank')) return true;
          if (step && !frame.src.includes('replayStep=' + step)) return false;
          try {
            const doc = frame.contentDocument;
            return !!(doc && doc.documentElement.getAttribute('data-ready') === '1');
          } catch (e) {
            return false;
          }
        }""",
        arg=replay_step or "",
        timeout=timeout_ms,
    )


def switch_tab(page, tab: str) -> None:
    # Theater overlays can intercept pointer events — flip tabs via DOM.
    # Do not .click() Routes during recording: demo app.js loadRoutesTab()
    # loads the finished live route (all modules), which flashes on screen
    # before the replay snapshot (one module) replaces it.
    page.evaluate(
        """(tab) => {
          const recording = !!window.__pfTheaterRecording;
          if (!(recording && tab === "routes")) {
            const btn = document.querySelector(`.main-tab[data-main-tab="${tab}"]`);
            if (btn) btn.click();
            return;
          }
          document.querySelectorAll(".main-tab").forEach((b) => {
            const on = b.dataset.mainTab === tab;
            b.classList.toggle("active", on);
            b.setAttribute("aria-selected", on ? "true" : "false");
          });
          ["demo", "routes", "timing", "info", "experience"].forEach((id) => {
            const el = document.getElementById("tab-" + id);
            if (el) el.hidden = id !== tab;
          });
          document.body.classList.toggle("routes-mode", tab === "routes");
          const nav = document.getElementById("demo-nav");
          if (nav) nav.hidden = tab !== "demo";
        }""",
        tab,
    )
    page.wait_for_timeout(350)


def show_create_interface(page, step: dict) -> None:
    switch_tab(page, "routes")
    clear_theater_overlay(page)
    page.evaluate(
        """() => {
          const el = document.getElementById('pipeline');
          if (el) el.classList.remove('pf-pipeline-spotlight');
          const frame = document.getElementById('route-viewer-frame');
          if (frame) frame.src = 'about:blank';
          const root = document.getElementById('pf-theater-root');
          if (!root) return;
          root.innerHTML = `
            <div class="pf-t-layer" id="pf-create-layer">
              <div class="pf-create-card" id="pf-create-card">
                <p class="eyebrow">eiConsole</p>
                <h1>New PilotFish Interface</h1>
                <p>Blank canvas.</p>
                <button type="button" id="pf-create-iface-btn">Create New PilotFish Interface</button>
              </div>
            </div>`;
        }"""
    )
    page.wait_for_timeout(900)
    # Pulse animation makes Playwright think the button is "unstable" — click via JS.
    page.evaluate(
        """() => {
          const btn = document.getElementById('pf-create-iface-btn');
          if (!btn) return;
          btn.style.animation = 'none';
          btn.click();
        }"""
    )
    page.evaluate(
        """() => {
          const btn = document.getElementById('pf-create-iface-btn');
          const card = document.getElementById('pf-create-card');
          if (btn) btn.classList.add('is-clicked');
          if (card) {
            card.classList.add('is-done');
            const h = card.querySelector('h1');
            if (h) h.textContent = 'Interface created';
            const p = card.querySelector('p');
            if (p) p.textContent = 'Blank canvas — starting the build.';
          }
        }"""
    )
    page.wait_for_timeout(1100)


def show_ognl_spotlight(page, step: dict) -> None:
    clear_theater_overlay(page)
    switch_tab(page, "routes")
    summary = str(step.get("ognl_summary") or "dynamic value from the transaction")
    raw = str(step.get("ognl_example") or "{ognl:…}")
    why = str(
        step.get("ognl_why")
        or (
            "OGNL is PilotFish's expression language for config fields. "
            "We use it so names and paths stay dynamic — tied to the transaction — "
            "instead of hard-coding a static string."
        )
    )
    legend = str(step.get("ognl_legend") or "Human reading above · raw OGNL below.")
    page.evaluate(
        """({ summary, raw, why, legend }) => {
          const root = document.getElementById('pf-theater-root');
          if (!root) return;
          const esc = (s) => String(s)
            .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
          root.innerHTML = `
            <div class="pf-t-layer">
              <div class="pf-ognl-card">
                <p class="eyebrow">Config language</p>
                <h2>OGNL — once, up front</h2>
                <p class="why">${esc(why)}</p>
                <div class="pf-ognl-summary">${esc(summary)}</div>
                <pre class="pf-ognl-raw">${esc(raw)}</pre>
                <p class="pf-ognl-legend">${esc(legend)}</p>
              </div>
            </div>`;
        }""",
        {"summary": summary, "raw": raw, "why": why, "legend": legend},
    )


def _xslt_highlight_lines(text: str) -> list[int]:
    hot: list[int] = []
    for i, line in enumerate(text.splitlines(), start=1):
        low = line.lower()
        if any(
            k in low
            for k in (
                "xcsrecord",
                "patientid",
                "firstname",
                "lastname",
                "dateofbirth",
                "statecode",
                "insert",
                "for-each",
                "uppercase",
            )
        ):
            hot.append(i)
    return hot


def ensure_xslt_highlight_assets(page) -> None:
    """Load highlight.js + Sandbox code-highlight (same stack as interface XSLT viewers)."""
    page.evaluate(
        """async () => {
          const hasCss = (part) => [...document.styleSheets].some(
            (s) => (s.href || '').includes(part)
          );
          const hasScript = (part) => [...document.scripts].some(
            (s) => (s.src || '').includes(part)
          );
          const loadCss = (href, part) => new Promise((resolve) => {
            if (hasCss(part)) { resolve(); return; }
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = href;
            link.onload = () => resolve();
            link.onerror = () => resolve();
            document.head.appendChild(link);
          });
          const loadJs = (src, part) => new Promise((resolve) => {
            if (hasScript(part) || (part === 'highlight.min' && window.hljs)) {
              resolve(); return;
            }
            const script = document.createElement('script');
            script.src = src;
            script.onload = () => resolve();
            script.onerror = () => resolve();
            document.head.appendChild(script);
          });
          await loadCss(
            'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/atom-one-dark.min.css',
            'atom-one-dark'
          );
          await loadCss('/static/code-highlight.css', 'code-highlight.css');
          await loadJs(
            'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/highlight.min.js',
            'highlight.min'
          );
          await loadJs(
            'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/languages/xml.min.js',
            'languages/xml'
          );
          await loadJs('/static/code-highlight.js', 'code-highlight.js');
          // Give CodeHighlight a tick to boot if it just loaded.
          await new Promise((r) => setTimeout(r, 40));
        }"""
    )


def show_xslt_overlay(page, step: dict, duration_ms: int = 12000) -> None:
    name = str(step.get("xslt_name") or "stylesheet.xslt")
    text = str(step.get("xslt_text") or "")
    if not text:
        return
    subtitle = str(step.get("xslt_subtitle") or "Stock XSLT · mapping")
    beats = step.get("xslt_beats") if isinstance(step.get("xslt_beats"), list) else []
    clean_beats = []
    for beat in beats:
        if not isinstance(beat, dict):
            continue
        caption = str(beat.get("caption") or "").strip()
        if not caption:
            continue
        try:
            line = max(1, int(beat.get("line") or 1))
        except (TypeError, ValueError):
            line = 1
        clean_beats.append({"line": line, "caption": caption})
    if not clean_beats:
        clean_beats = [{"line": 1, "caption": "Walking through the mapping"}]
    ensure_xslt_highlight_assets(page)
    page.evaluate(
        """({ name, text, subtitle, beats, durationMs }) => {
          const root = document.getElementById('pf-theater-root');
          if (!root) return;
          const esc = (s) => String(s)
            .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
            .replace(/"/g,'&quot;');
          root.innerHTML = `
            <div class="pf-t-layer">
              <div class="pf-xslt-card">
                <div class="pf-xslt-head">
                  <strong>${esc(name)}</strong>
                  <span>${esc(subtitle)}</span>
                </div>
                <div class="pf-xslt-scroll" id="pf-xslt-scroll">
                  <pre class="xslt-source" id="pf-xslt-view"><code class="language-xml"></code></pre>
                </div>
                <div class="pf-xslt-caption" id="pf-xslt-caption"><em></em></div>
              </div>
            </div>`;
          const pre = document.getElementById('pf-xslt-view');
          const code = pre && pre.querySelector('code');
          if (code) code.textContent = text;
          if (window.CodeHighlight && typeof window.CodeHighlight.xml === 'function') {
            window.CodeHighlight.xml(pre, text);
          } else if (window.hljs && code) {
            window.hljs.highlightElement(code);
          }
          const sc = document.getElementById('pf-xslt-scroll');
          const cap = document.getElementById('pf-xslt-caption');
          if (!sc || !cap) return;
          const nLines = Math.max(1, String(text).split('\\n').length);
          const setCap = (msg) => { cap.innerHTML = '<em>' + esc(msg || '') + '</em>'; };
          setCap(beats[0] && beats[0].caption);
          const dur = Math.max(3500, Number(durationMs) || 12000);
          const t0 = performance.now();
          const tick = (now) => {
            const t = Math.min(1, (now - t0) / dur);
            const maxY = Math.max(0, sc.scrollHeight - sc.clientHeight);
            if (maxY > 0) sc.scrollTop = maxY * t;
            let msg = beats[0] && beats[0].caption;
            for (const b of beats) {
              const at = (Number(b.line) - 1) / nLines;
              if (at <= t + 0.04) msg = b.caption;
            }
            setCap(msg);
            if (t < 1) requestAnimationFrame(tick);
          };
          requestAnimationFrame(() => requestAnimationFrame(tick));
        }""",
        {
            "name": name,
            "text": text,
            "subtitle": subtitle,
            "beats": clean_beats,
            "durationMs": int(duration_ms or 12000),
        },
    )


def show_brand(page, step: dict) -> None:
    clear_theater_overlay(page)
    logo = str(step.get("logo_url") or "/static/pilotfish-logo.jpg")
    page.evaluate(
        """({ html }) => {
          const root = document.getElementById('pf-theater-root');
          if (root) root.innerHTML = html;
        }""",
        {"html": brand_html(logo)},
    )


def show_product_demo(page, step: dict) -> None:
    clear_theater_overlay(page)
    title = str(step.get("demo_name") or step.get("message") or "PilotFish Demo")
    line = str(step.get("product_line") or "")
    page.evaluate(
        """({ html }) => {
          const root = document.getElementById('pf-theater-root');
          if (root) root.innerHTML = html;
        }""",
        {"html": product_html(title, line)},
    )


def show_welcome(page, step: dict) -> None:
    """Opening brand screen: PilotFish logo + welcome + demo name."""
    clear_theater_overlay(page)
    demo_name = str(step.get("demo_name") or step.get("message") or "PilotFish Demo")
    headline = str(step.get("headline") or "Welcome to the demo")
    lead = str(step.get("lead") or "")
    logo = str(step.get("logo_url") or "/static/pilotfish-logo.jpg")
    page.evaluate(
        """({ demoName, headline, lead, logo }) => {
          const root = document.getElementById('pf-theater-root');
          if (!root) return;
          const esc = (s) => String(s)
            .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
            .replace(/"/g,'&quot;');
          const leadHtml = lead
            ? `<p class="lead">${esc(lead)}</p>`
            : '';
          root.innerHTML = `
            <div class="pf-t-layer pf-welcome-layer">
              <div class="pf-welcome-card">
                <img class="logo" src="${esc(logo)}" alt="PilotFish" />
                <p class="eyebrow">PilotFish</p>
                <h1>${esc(headline)}</h1>
                <p class="demo-name">${esc(demoName)}</p>
                ${leadHtml}
              </div>
            </div>`;
        }""",
        {
            "demoName": demo_name,
            "headline": headline,
            "lead": lead,
            "logo": logo,
        },
    )


def show_pipeline_overview(page, step: dict) -> None:
    """Show Demo-tab pipeline (spotlight) plus an enlarged theater diagram."""
    clear_theater_overlay(page)
    switch_tab(page, "demo")
    page.wait_for_timeout(250)
    pipe = page.locator("#pipeline")
    if pipe.count():
        pipe.first.scroll_into_view_if_needed()
    page.evaluate(
        """() => {
          const el = document.getElementById('pipeline');
          if (el) el.classList.add('pf-pipeline-spotlight');
        }"""
    )
    stages = step.get("pipeline_stages") or []
    if not isinstance(stages, list):
        stages = []
    lead = str(step.get("lead") or "What you're about to watch us build.")
    page.evaluate(
        """({ stages, lead }) => {
          const root = document.getElementById('pf-theater-root');
          if (!root) return;
          const esc = (s) => String(s)
            .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
          const nodes = stages.map((st, i) => {
            const cls = i === 0 ? 'pf-pipe-node pf-pipe-src'
              : (i === stages.length - 1 ? 'pf-pipe-node pf-pipe-out' : 'pf-pipe-node');
            const arrow = i < stages.length - 1 ? '<div class="pf-pipe-arrow">→</div>' : '';
            return `<div class="${cls}"><strong>${esc(st.title || '')}</strong>`
              + `<span>${esc(st.subtitle || '')}</span></div>${arrow}`;
          }).join('');
          const row = nodes
            ? `<div class="pf-pipe-row">${nodes}</div>`
            : '';
          root.innerHTML = `
            <div class="pf-t-layer">
              <div class="pf-pipe-card">
                <p class="eyebrow">Context</p>
                <h2>End-to-end pipeline</h2>
                <p class="lead">${esc(lead)}</p>
                ${row}
              </div>
            </div>`;
        }""",
        {"stages": stages, "lead": lead},
    )


def show_systems_spotlight(page, step: dict) -> None:
    clear_theater_overlay(page)
    # Leave Demo tab visible under the dim so systems feel tied to the demo UI
    switch_tab(page, "demo")
    systems = step.get("systems") or []
    if not isinstance(systems, list):
        systems = []
    one = len(systems) == 1
    headline = str(
        step.get("headline")
        or (
            "External system & Docker service"
            if one
            else "External systems & Docker services"
        )
    )
    lead = str(
        step.get("lead")
        or (
            "The runtime this interface talks to — a local compose service."
            if one
            else "Mocks and runtimes this interface talks to — all local compose services."
        )
    )
    page.evaluate(
        """({ systems, headline, lead }) => {
          const root = document.getElementById('pf-theater-root');
          if (!root) return;
          const esc = (s) => String(s)
            .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
          const tiles = systems.map((s) => `
            <div class="pf-system-tile">
              <span class="kind">${esc(s.kind || 'System')}</span>
              <strong>${esc(s.name || '')}</strong>
              <p class="role">${esc(s.role || '')}</p>
              <div class="meta">${esc(s.detail || '')}</div>
              <div class="meta image">${esc(s.image || '')}</div>
            </div>`).join('');
          root.innerHTML = `
            <div class="pf-t-layer">
              <div class="pf-systems-card">
                <p class="eyebrow">Sandbox stack</p>
                <h2>${esc(headline)}</h2>
                <p class="lead">${esc(lead)}</p>
                <div class="pf-systems-grid">${tiles}</div>
              </div>
            </div>`;
        }""",
        {"systems": systems, "headline": headline, "lead": lead},
    )


def show_outro(page, step: dict) -> None:
    clear_theater_overlay(page)
    line = str(step.get("product_line") or "for Healthcare")
    url = str(step.get("trial_url") or "www.PilotFishTechnology.com")
    page.evaluate(
        """({ html }) => {
          const root = document.getElementById('pf-theater-root');
          if (root) root.innerHTML = html;
        }""",
        {"html": close_html(line, url)},
    )


def run_ui_gesture(page, step: dict) -> None:
    action = str(step.get("action") or "")
    if action == "show_brand":
        show_brand(page, step)
        return
    if action == "show_product_demo":
        show_product_demo(page, step)
        return
    if action == "show_welcome":
        show_welcome(page, step)
        return
    if action == "show_pipeline":
        show_pipeline_overview(page, step)
        return
    if action == "spotlight_systems":
        show_systems_spotlight(page, step)
        return
    if action == "create_interface":
        show_create_interface(page, step)
        return
    if action == "spotlight_ognl":
        show_ognl_spotlight(page, step)
        return
    if action == "hide_overlays":
        clear_theater_overlay(page)
        page.evaluate(
            """() => {
              const el = document.getElementById('pipeline');
              if (el) el.classList.remove('pf-pipeline-spotlight');
            }"""
        )
        return


def snapshot_demo_results(page) -> None:
    """Remember which result is on screen so we can select the new one after inject."""
    page.evaluate(
        """() => {
          const buttons = [...document.querySelectorAll(
            '#queue-list button, #json-list button, #archive-list button, #results .file-list button'
          )];
          const viewers = [...document.querySelectorAll(
            '#queue-view, #json-view, #archive-view, #results pre.viewer, #xml-view'
          )];
          window.__pfResultSnap = {
            names: buttons.map((b) => (b.textContent || '').trim()),
            viewer: viewers.map((v) => (v.textContent || '').trim()).join('\\n').slice(0, 4000),
          };
        }"""
    )


def reveal_latest_result(page) -> None:
    """Always show the new output — queues name newest as msg-0; files are usually newest-first."""
    page.evaluate(
        """() => {
          const snap = window.__pfResultSnap || { names: [], viewer: '' };
          const buttons = [...document.querySelectorAll(
            '#queue-list button, #json-list button, #archive-list button, #results .file-list button'
          )];
          const msgBtns = buttons.filter((b) => /^msg-\\d+$/i.test((b.textContent || '').trim()));
          let pick = null;
          if (msgBtns.length) {
            msgBtns.sort((a, b) => {
              const na = Number((a.textContent || '').replace(/\\D/g, '') || 0);
              const nb = Number((b.textContent || '').replace(/\\D/g, '') || 0);
              return na - nb;
            });
            pick = msgBtns[0];
          } else if (buttons.length) {
            pick = buttons.find((b) => !snap.names.includes((b.textContent || '').trim()))
              || buttons[0];
          }
          if (pick) {
            pick.click();
            pick.scrollIntoView({ behavior: 'auto', block: 'nearest', inline: 'nearest' });
          }
          const row = document.querySelector(
            '#results table tbody tr:last-child, #patients-table table tbody tr:last-child, #captures-table tbody tr:last-child'
          );
          if (row) row.scrollIntoView({ behavior: 'auto', block: 'center' });
          const view = document.querySelector(
            '#queue-view, #json-view, #archive-view, #results pre.viewer, #xml-view'
          );
          if (view) view.scrollIntoView({ behavior: 'auto', block: 'nearest' });
        }"""
    )


def scroll_demo_results(page) -> None:
    """Keep the results panel in frame before and during live inject."""
    for sel in (
        "#results",
        "#queue-list",
        "#patients-table",
        "#json-list",
        "#archive-list",
        "#captures-table",
        "#xml-view",
        "#export",
        "#insert-form",
    ):
        loc = page.locator(sel)
        if loc.count():
            try:
                loc.first.scroll_into_view_if_needed()
                page.wait_for_timeout(250)
            except Exception:
                pass
            return
    inj = page.locator("#inject")
    if inj.count():
        try:
            inj.first.scroll_into_view_if_needed()
        except Exception:
            pass


def click_results_refresh(page) -> None:
    for sel in ("#refresh-btn", "#refresh-xml-btn", "#refresh-sql-btn"):
        refresh = page.locator(sel)
        if refresh.count():
            try:
                refresh.first.click()
                page.wait_for_timeout(400)
            except Exception:
                pass


def run_demo_test_action(page, step: dict) -> None:
    action = str(step.get("action") or "")
    if action == "open_demo":
        clear_theater_overlay(page)
        switch_tab(page, "demo")
        page.wait_for_timeout(400)
        scroll_demo_results(page)
        return

    if action == "inject":
        switch_tab(page, "demo")
        sample = str(step.get("sample") or "").strip()
        select = page.locator("#sample")
        if sample and select.count():
            try:
                select.first.select_option(sample)
                page.wait_for_timeout(300)
            except Exception:
                pass
        scroll_demo_results(page)
        page.wait_for_timeout(200)
        snapshot_demo_results(page)
        form = page.locator("#inject-form")
        if form.count():
            form.locator('button[type="submit"]').first.click()
            return
        insert = page.locator("#insert-form")
        if insert.count():
            payload = page.locator("#CapturePayload")
            if payload.count():
                try:
                    payload.first.fill("Live construction test")
                except Exception:
                    pass
            try:
                insert.first.scroll_into_view_if_needed()
            except Exception:
                pass
            insert.locator('button[type="submit"]').first.click()
            page.wait_for_timeout(600)
        return

    if action == "wait_results":
        return

    if action == "show_results":
        switch_tab(page, "demo")
        scroll_demo_results(page)
        click_results_refresh(page)
        reveal_latest_result(page)
        for sel in ("#xml-view", "#export"):
            loc = page.locator(sel)
            if loc.count():
                try:
                    loc.first.scroll_into_view_if_needed()
                    page.wait_for_timeout(250)
                except Exception:
                    pass
                break
        return


def hold_demo_step(page, step: dict) -> None:
    """Hold for dwell_ms, running wait-poll inside wait_results steps."""
    import time

    dwell = int(step.get("dwell_ms") or 3000)
    action = str(step.get("action") or "")
    if action != "wait_results":
        run_demo_test_action(page, step)
        page.wait_for_timeout(max(0, dwell))
        return

    switch_tab(page, "demo")
    scroll_demo_results(page)
    click_results_refresh(page)
    t0 = time.time()
    deadline = t0 + (dwell / 1000.0)
    extra_refresh = False
    while time.time() < deadline:
        ready = page.evaluate(
            """() => {
              const status = document.getElementById('status');
              const t = (status && status.textContent) || '';
              if (/Loaded\\s+\\d+|wrote|injected|converted|published|Inserted|EIP\\s+\\d+|ok\\b/i.test(t)) return true;
              const meta = document.getElementById('queue-meta');
              if (meta && /message/i.test(meta.textContent || '')) return true;
              if (document.querySelector('#results table tbody tr, #patients-table table tbody tr, #captures-table tbody tr')) return true;
              if (document.querySelector('#json-list button, #archive-list button, #results .file-list button, #queue-list button')) return true;
              const viewers = document.querySelectorAll('#results pre.viewer, #json-view, #archive-view, #queue-view, #xml-view');
              for (const v of viewers) {
                const body = (v.textContent || '').trim();
                if (body.length > 20 && body !== '(none yet)') return true;
              }
              return false;
            }"""
        )
        if ready:
            reveal_latest_result(page)
            break
        if not extra_refresh and (time.time() - t0) > 1.0:
            click_results_refresh(page)
            extra_refresh = True
        page.wait_for_timeout(300)
    remaining = int(max(0, (deadline - time.time()) * 1000))
    if remaining:
        page.wait_for_timeout(remaining)
    reveal_latest_result(page)


def hold_construction_step(page, step: dict, index: int, total: int) -> None:
    import time

    dwell = int(step.get("dwell_ms") or 3000)
    show_construction_step(page, step, index, total)
    try:
        wait_frame_ready(page, 6000, str(step.get("id") or ""))
    except Exception:
        pass
    page.evaluate(
        """() => {
          const frame = document.getElementById('route-viewer-frame');
          if (frame) frame.style.visibility = '';
        }"""
    )
    page.wait_for_timeout(400)
    page.evaluate(
        """() => {
          const frame = document.getElementById('route-viewer-frame');
          if (!frame) return;
          try {
            const doc = frame.contentDocument;
            const node = doc && (
              doc.querySelector('.route-node.is-new') ||
              doc.querySelector('.route-node.selected')
            );
            if (node) node.scrollIntoView({ behavior: 'auto', block: 'center', inline: 'nearest' });
          } catch (e) {}
        }"""
    )
    t0 = time.time()
    if step.get("show_xslt") and step.get("xslt_text"):
        page.wait_for_timeout(700)
        remaining = int(max(4000, dwell - (time.time() - t0) * 1000))
        show_xslt_overlay(page, step, duration_ms=remaining)
    remaining = int(max(0, dwell - (time.time() - t0) * 1000))
    if remaining:
        page.wait_for_timeout(remaining)


def hold_ui_gesture(page, step: dict) -> None:
    import time

    dwell = int(step.get("dwell_ms") or 4000)
    t0 = time.time()
    run_ui_gesture(page, step)
    remaining = int(max(0, dwell - (time.time() - t0) * 1000))
    if remaining:
        page.wait_for_timeout(remaining)


def report_job(plan: list, index: int, step: dict) -> None:
    try:
        tools = Path(__file__).resolve().parent
        if str(tools) not in sys.path:
            sys.path.insert(0, str(tools))
        from construction_video_job import clip_label, update_job
    except Exception:
        return
    total = len(plan) or 1
    remaining_ms = sum(int(s.get("dwell_ms") or 0) for s in plan[index - 1 :])
    kind = str(step.get("kind") or "step")
    phase_name = {
        "outro": "closing",
        "demo_test": "live Demo test",
        "ui_gesture": "setup overlay",
        "intro": "intro",
    }.get(kind, "route diagram")
    label = clip_label(step)
    left = remaining_ms // 1000
    update_job(
        phase="recording",
        status="running",
        step=index,
        step_total=total,
        remaining_sec=left,
        message=f"Recording {index} of {total} — {phase_name}: {label} (~{left}s left)",
        log_line=f"Scene {index}/{total}: {label}",
    )


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: _record_construction_session.py <url> <plan.json> <out.webm>", file=sys.stderr)
        return 2
    url = sys.argv[1]
    plan = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
    out = Path(sys.argv[3])
    out.parent.mkdir(parents=True, exist_ok=True)

    diagram_steps = [
        s
        for s in plan
        if s.get("kind") not in {"intro", "demo_test", "ui_gesture", "outro"}
    ]
    diagram_total = len(diagram_steps) or 1
    demo_tests = [s for s in plan if s.get("kind") == "demo_test"]
    test_total = len(demo_tests) or 1

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1440, "height": 900},
            record_video_dir=str(out.parent),
            record_video_size={"width": 1440, "height": 900},
        )
        page = context.new_page()
        page.add_init_script(
            """() => {
              // Set before any demo JS runs so build-live polling cannot load
              // the finished live route into the iframe during recording.
              window.__pfTheaterRecording = true;
              const paint = () => {
                document.documentElement.style.background = '#0b1220';
                if (document.body) document.body.style.background = '#0b1220';
              };
              paint();
              document.addEventListener('DOMContentLoaded', paint);
            }"""
        )
        page.goto(url, wait_until="domcontentloaded", timeout=60000)
        # Fail fast if CSS did not load (records as an unstyled "jank" page).
        try:
            page.wait_for_function(
                """() => {
                  const hrefs = [...document.styleSheets]
                    .map((s) => s.href || '')
                    .join(' ');
                  if (hrefs.includes('app.css') || hrefs.includes('.css')) {
                    const bg = getComputedStyle(document.body).backgroundColor || '';
                    // Any non-default transparent/white-only is fine; also accept
                    // PilotFish sandbox --bg (#f5f8fb) and plain white panels.
                    if (bg && bg !== 'rgba(0, 0, 0, 0)' && bg !== 'transparent') return true;
                    // Stylesheets present is enough when body bg is inherited/white.
                    return document.styleSheets.length >= 1;
                  }
                  return false;
                }""",
                timeout=20000,
            )
        except Exception:
            print(
                "ERROR: Demo UI CSS not loaded (unstyled page). "
                "Check /static/app.css on the Web UI and restart the webui container.",
                file=sys.stderr,
            )
            context.close()
            browser.close()
            return 1

        ensure_theater_chrome(page)
        welcome = next(
            (
                s
                for s in plan
                if s.get("action") in {"show_brand", "show_product_demo", "show_welcome"}
                or s.get("id") in {"open-brand", "welcome"}
            ),
            None,
        )
        if welcome:
            run_ui_gesture(page, welcome)
        else:
            switch_tab(page, "routes")
        page.wait_for_timeout(200)

        diagram_index = 0
        demo_index = 0
        for index, step in enumerate(plan, start=1):
            report_job(plan, index, step)
            kind = str(step.get("kind") or "step")
            if kind == "ui_gesture":
                update_banner(page, step, 1, 1, phase="Setup")
                hold_ui_gesture(page, step)
            elif kind == "outro":
                update_banner(page, step, 1, 1, phase="Done")
                show_outro(page, step)
                page.wait_for_timeout(int(step.get("dwell_ms") or 5000))
            elif kind == "demo_test":
                demo_index += 1
                update_banner(page, step, demo_index, test_total, phase="Live test")
                hold_demo_step(page, step)
            elif kind == "intro":
                update_banner(page, step, 1, 1, phase="Intro")
                page.wait_for_timeout(int(step.get("dwell_ms") or 2000))
            else:
                diagram_index += 1
                hold_construction_step(page, step, diagram_index, diagram_total)

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
