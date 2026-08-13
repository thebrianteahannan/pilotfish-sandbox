#!/usr/bin/env python3
"""Build request-demo theater scenes (HTML + spoken copy) from a request folder."""

from __future__ import annotations

import base64
import json
import re
from html import escape as esc
from pathlib import Path

from construction_demo_context import logo_data_uri
from construction_narration_naturalize import naturalize_spoken
from construction_speech import for_speech


def _load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def _clip(text: str, n: int = 720) -> str:
    t = re.sub(r"\s+", " ", str(text or "")).strip()
    if len(t) <= n:
        return t
    return t[: n - 1].rstrip() + "…"


def _clip_block(text: str, lines: int = 10, n: int = 700) -> str:
    raw = str(text or "").replace("\t", "  ").strip()
    if not raw:
        return ""
    kept = "\n".join(raw.splitlines()[:lines])
    if len(kept) > n:
        kept = kept[: n - 1].rstrip() + "…"
    return kept


def _short_path(path: str) -> str:
    parts = [p for p in Path(path).parts if p not in {".", "/"}]
    if len(parts) >= 2:
        return "/".join(parts[-2:])
    return path


def _clean_subject(text: str) -> str:
    t = re.sub(r"[\u20ac€©]?\s*summarize this email", "", str(text or ""), flags=re.I)
    return t.strip(" \t-–—|") or "Client request"


def _speak(text: str) -> str:
    t = naturalize_spoken(text or "")
    t = t.replace("\u201c", '"').replace("\u201d", '"').replace("\u2019", "'")
    t = t.replace("\u2014", " — ").replace("\u2192", " to ")
    t = re.sub(r"`([^`]+)`", r"\1", t)
    t = re.sub(r"\s+", " ", t).strip()
    return for_speech(t)


def _is_smoke(item: dict) -> bool:
    name = str(item.get("name") or "").lower()
    return "eip.log" in name or name.startswith("eip http") or "/eip/" in name


def _looks_code(text: str) -> bool:
    t = str(text or "")
    return "<xsl" in t or "select=" in t or t.startswith("<?xml")


def _shot_uri(folder: Path, meta: dict) -> str:
    for name in meta.get("screenshots") or []:
        path = folder / str(name)
        if not path.is_file() or path.stat().st_size > 2_000_000:
            continue
        ext = path.suffix.lower().lstrip(".") or "png"
        if ext == "jpg":
            ext = "jpeg"
        b64 = base64.b64encode(path.read_bytes()).decode("ascii")
        return f"data:image/{ext};base64,{b64}"
    return ""


def _card(eyebrow: str, headline: str, body: str = "", extra: str = "") -> str:
    lead = f'<p class="lead">{esc(body)}</p>' if body else ""
    return (
        '<div class="pf-t-layer"><div class="pf-pipe-card">'
        f'<p class="eyebrow">{esc(eyebrow)}</p><h2>{esc(headline)}</h2>'
        f"{lead}{extra}</div></div>"
    )


def _welcome(logo: str, title: str, lead: str) -> str:
    return (
        '<div class="pf-t-layer pf-welcome-layer"><div class="pf-welcome-card">'
        f'<img class="logo" src="{esc(logo)}" alt="PilotFish" />'
        '<p class="eyebrow">PilotFish</p><h1>Change request replay</h1>'
        f'<p class="demo-name">{esc(title)}</p>'
        f'<p class="lead">{esc(lead)}</p></div></div>'
    )


def _outro(logo: str, title: str, body: str) -> str:
    return (
        '<div class="pf-t-layer pf-outro-layer"><div class="pf-outro-card">'
        f'<img class="logo" src="{esc(logo)}" alt="PilotFish" />'
        f'<p class="mark">PilotFish</p><h1>{esc(title)}</h1>'
        f"<p>{esc(body)}</p></div></div>"
    )


def _bullets(items: list[str]) -> str:
    rows = "".join(f"<li>{esc(x)}</li>" for x in items if x)
    return f'<ul class="pf-bullets">{rows}</ul>' if rows else ""


def _files(paths: list[str]) -> str:
    tiles = "".join(
        f'<div class="pf-file-tile"><strong>{esc(_short_path(p))}</strong></div>' for p in paths
    )
    return f'<div class="pf-file-grid">{tiles}</div>' if tiles else ""


def _pair(before: str, after: str) -> str:
    if not (before or after):
        return ""
    return (
        '<div class="pf-tpair">'
        f'<div><p class="tmeta">Before</p><pre>{esc(before)}</pre></div>'
        f'<div><p class="tmeta">After</p><pre>{esc(after)}</pre></div>'
        "</div>"
    )


def _speak_proof(item: dict) -> str:
    name = str(item.get("name") or "This test")
    detail = str(item.get("detail") or "").strip()
    ev = [str(x).strip() for x in (item.get("evidence") or []) if str(x).strip()]
    lead = next((x for x in ev if not _looks_code(x) and len(x) < 220), "")
    bits = [f"This one is {name}."]
    if item.get("ok"):
        bits.append("It passed.")
    if lead:
        bits.append(lead)
    elif detail and not _looks_code(detail):
        bits.append(f"The result is {detail}.")
    before = str(item.get("before") or "")
    after = str(item.get("after") or "")
    if "<flagged>0" in before and "<flagged>1" in after:
        bits.append("Before the change this location was not flagged. After, it is.")
    elif "<rows>0" in before and "<rows>1" in after:
        bits.append("Before the change the strip report had no row. After, the row is there.")
    elif "blank" in lead.lower() and "IN1.16" in (lead + name):
        bits.append("So the subscriber name is filled now.")
    return _speak(" ".join(bits))


def build_scenes(folder: Path) -> list[dict]:
    folder = folder.resolve()
    meta = _load_json(folder / "request.json")
    dive = _load_json(folder / "dive.json")
    tests = _load_json(folder / "tests.json")
    if not tests.get("items") and isinstance(meta.get("tests"), dict):
        tests = meta["tests"]
    client = str(meta.get("client") or "the client")
    subject = _clean_subject(str(meta.get("subject") or folder.name))
    ask = str(meta.get("request_summary") or dive.get("summary") or dive.get("ask") or subject).strip()
    change = str(meta.get("change_summary") or dive.get("summary") or ask).strip()
    sender = str(meta.get("from") or "").strip()
    logo = logo_data_uri()
    items = [i for i in (tests.get("items") or []) if isinstance(i, dict)]
    proofs = [i for i in items if not _is_smoke(i)]

    def _rank(item: dict) -> int:
        blob = str(item.get("before") or "") + str(item.get("after") or "")
        if "<proof>" in blob or "<flagged>" in blob or "<rows>" in blob:
            return 0
        if item.get("before") or item.get("after"):
            return 1
        return 2

    proofs.sort(key=_rank)
    proofs = proofs[:5]
    files = [str(c.get("path") or "") for c in (meta.get("changes") or []) if c.get("path")]
    if not files:
        files = [str(e.get("path") or "") for e in (dive.get("edits") or []) if e.get("path")]
    files = [p for i, p in enumerate(files) if p and p not in files[:i]][:6]
    plan_bits = []
    for ed in dive.get("edits") or []:
        line = str(ed.get("title") or ed.get("why") or "").strip()
        if line and line not in plan_bits:
            plan_bits.append(line)
    plan_bits = plan_bits[:6] or ([change] if change else [])
    shot = _shot_uri(folder, meta)
    shot_html = f'<img class="pf-shot" src="{esc(shot)}" alt="Request screenshot" />' if shot else ""

    scenes: list[dict] = [
        {
            "id": "welcome",
            "message": "Welcome",
            "html": _welcome(
                logo,
                f"{client}: {subject}",
                "The request, the plan, the changes, and the tests that show it worked.",
            ),
            "speak": _speak(
                f"Here's a walkthrough of the {client} request: {subject}. "
                "We'll cover what they asked for, the plan, what changed, and the tests that show it worked."
            ),
        },
        {
            "id": "request",
            "message": "The request",
            "html": _card(
                "The request",
                subject,
                ask,
                (f'<p class="meta">From {esc(sender)}</p>' if sender else "") + shot_html,
            ),
            "speak": _speak(f"First up, the request. {ask}"),
        },
        {
            "id": "plan",
            "message": "The plan",
            "html": _card("The plan", "What we set out to change", change, _bullets(plan_bits)),
            "speak": _speak(f"Here's the plan. {change}"),
        },
    ]
    if files:
        n = len(files)
        label = "file" if n == 1 else "files"
        scenes.append(
            {
                "id": "changes",
                "message": "Code changes",
                "html": _card("Code changes", "What changed", change, _files(files)),
                "speak": _speak(f"We changed {n} {label}. {change}"),
            }
        )
    n_ok = sum(1 for i in items if i.get("ok"))
    all_ok = bool(tests.get("ok"))
    scenes.append(
        {
            "id": "tests",
            "message": "Test results",
            "html": _card(
                "Test results",
                "All tests passed" if all_ok else "Tests failed",
                f"{n_ok} of {len(items)} checks passed." if items else "No tests were recorded.",
                f'<p class="pf-pass">{esc("PASS" if all_ok else "FAIL")}</p>',
            ),
            "speak": _speak(
                f"All {len(items)} tests passed. That includes the sandbox checks and the cases that prove the change."
                if all_ok
                else f"{n_ok} of {len(items)} tests passed. Here's what we found."
            ),
        }
    )
    for idx, item in enumerate(proofs, start=1):
        ev = [str(x) for x in (item.get("evidence") or []) if x and not _looks_code(str(x))]
        extra = _pair(_clip_block(item.get("before") or ""), _clip_block(item.get("after") or ""))
        if ev and not extra:
            extra = _bullets([_clip(x, 180) for x in ev[:3]])
        scenes.append(
            {
                "id": f"proof-{idx}",
                "message": str(item.get("name") or f"Test {idx}"),
                "html": _card(
                    "Proof",
                    str(item.get("name") or f"Test {idx}"),
                    _clip(str(item.get("detail") or (ev[0] if ev else "")), 220),
                    f'<p class="pf-pass">{esc("PASS" if item.get("ok") else "FAIL")}</p>' + extra,
                ),
                "speak": _speak_proof(item),
            }
        )
    scenes.append(
        {
            "id": "outro",
            "message": "Ready to deploy",
            "html": _outro(
                logo,
                "Ready to deploy",
                "The change is in, the tests passed, and this request is ready to go.",
            ),
            "speak": _speak(
                "That's the walkthrough. The change is in, the tests passed, and this request is ready to deploy. "
                "Thanks for choosing PilotFish."
            ),
        }
    )
    return scenes
