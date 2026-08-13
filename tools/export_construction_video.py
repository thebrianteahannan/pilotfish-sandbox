#!/usr/bin/env python3
"""Record a narrated construction-replay video from the demo Web UI.

Drives each build-replay step in headless Chromium (Playwright), speaks the
step narration with macOS ``say``, then muxes voice onto
``documents/construction-replay.mp4``.

Requires:
  - Web UI reachable (stage or full compose)
  - documents/build-replay/ with steps
  - tools/.venv-video + chromium (see tools/export_construction_video.py --help)
  - macOS ``say`` (TTS) and ``ffmpeg`` / ``ffprobe`` on PATH

Usage:
  python3 tools/export_construction_video.py --root Clients/Demos/csv-sftp-to-sql
  python3 tools/export_construction_video.py --root Clients/Demos/csv-sftp-to-sql \\
      --url http://127.0.0.1:8133/ --voice en-US-AvaNeural
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import wave
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
VENV_PY = ROOT / "tools" / ".venv-video" / "bin" / "python"
RECORDER = ROOT / "tools" / "_record_construction_session.py"

# Keep dwell close to spoken length — avoid long silent holds on empty canvases
DEFAULT_MIN_DWELL_MS = 2200
DEFAULT_FOCUS_MIN_DWELL_MS = 2800
DEFAULT_POST_SPEECH_MS = 400
DEFAULT_EMPTY_POST_SPEECH_MS = 250
DEFAULT_INTRO_MS = 1200
DEFAULT_PACE = 1.0
DEFAULT_EDGE_RATE = "+8%"


def resolve_root(raw: str | None) -> Path:
    from demo_paths import require_demo

    return require_demo(raw)


def bump_webui_status(
    demo: Path,
    message: str,
    *,
    phase: str = "tts",
    log: str | None = None,
    **job_fields,
) -> None:
    """Write Info-tab job progress. Do not reopen the completed-build theater."""
    os.environ["CONSTRUCTION_VIDEO_DEMO"] = str(demo.resolve())
    try:
        from construction_video_job import update_job
    except ImportError:
        sys.path.insert(0, str(ROOT / "tools"))
        from construction_video_job import update_job
    payload = {
        "status": "running",
        "slug": demo.name,
        "message": message,
        "phase": phase,
    }
    payload.update(job_fields)
    if log:
        payload["log_line"] = log
    update_job(demo, **payload)


def detect_webui_url(demo: Path, explicit: str | None) -> str:
    if explicit:
        return explicit.rstrip("/") + "/"
    compose = demo / "docker-compose.yml"
    if compose.is_file():
        text = compose.read_text(encoding="utf-8", errors="replace")
        m = re.search(r'WEBUI_PORT:\s*"?(\d+)"?', text)
        if m:
            return f"http://127.0.0.1:{m.group(1)}/"
        ports = re.findall(r'"(\d+):\1"', text)
        if ports:
            return f"http://127.0.0.1:{max(int(p) for p in ports)}/"
    return "http://127.0.0.1:8120/"


def _oxford(items: list[str]) -> str:
    items = [i for i in items if i]
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    if len(items) == 2:
        return f"{items[0]} and {items[1]}"
    return ", ".join(items[:-1]) + f", and {items[-1]}"


def _ctx():
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    import construction_demo_context as ctx

    return ctx


def detect_demo_test(url: str, demo: Path) -> dict | None:
    return _ctx().detect_demo_test(url, demo)


def find_demo_xslt(demo: Path, step: dict | None = None) -> tuple[str, str] | None:
    return _ctx().find_xslt_for_step(demo, step)


def xslt_highlight_lines(text: str) -> list[int]:
    return _ctx().xslt_highlight_lines(text)


def xslt_overlay_fields(body: str) -> dict:
    meta = _ctx().xslt_overlay_meta(body)
    nbeats = max(1, len(meta.get("beats") or []))
    return {
        "xslt_subtitle": meta.get("subtitle") or "Stock XSLT · mapping",
        "xslt_beats": meta.get("beats") or [],
        "xslt_tour_ms": 3500 + nbeats * 2200,
        "xslt_narration": meta.get("narration") or "",
    }


def load_demo_display_name(demo: Path) -> str:
    return _ctx().load_demo_display_name(demo)


def build_theater_preamble_entries(
    demo_name: str = "PilotFish Demo",
    *,
    demo: Path | None = None,
) -> list[dict]:
    ctx = _ctx()
    name = (demo_name or "PilotFish Demo").strip() or "PilotFish Demo"
    purpose_s = ctx.first_sentence(ctx.load_purpose(demo), 220)
    extra = (
        "This demo adds a small custom module on top of stock PilotFish."
        if ctx.has_custom_modules(demo)
        else "PilotFish supports the whole flow out of the box."
    )
    welcome = f"Welcome to the PilotFish demo: {name}."
    if purpose_s:
        welcome += " " + purpose_s
        if not welcome.endswith("."):
            welcome += "."
        welcome += " " + extra
    entries: list[dict] = [
        {
            "kind": "ui_gesture",
            "action": "show_welcome",
            "id": "welcome",
            "message": "Welcome",
            "demo_name": name,
            "headline": "Welcome to the demo",
            "detail": welcome,
            "logo_url": ctx.logo_data_uri(demo),
            "min_dwell_ms": 5500,
        },
    ]
    stages = ctx.load_pipeline_stages(demo)
    if stages:
        titles = [str(s.get("title") or "") for s in stages]
        detail = "Before we wire anything, here's the flow end to end."
        if purpose_s:
            detail += " " + purpose_s
            if not detail.endswith("."):
                detail += "."
        elif titles:
            detail += f" {_oxford(titles)}."
        entries.append(
            {
                "kind": "ui_gesture",
                "action": "show_pipeline",
                "id": "pipeline-overview",
                "message": "Pipeline overview",
                "detail": detail,
                "lead": purpose_s or "What you're about to watch us build.",
                "pipeline_stages": stages,
                "min_dwell_ms": 8000,
            }
        )
    systems = ctx.load_compose_systems(demo)
    if systems:
        names = [str(s.get("name") or "") for s in systems]
        one = len(systems) == 1
        docker_line = (
            "That's spun up in a docker image for this demo."
            if one
            else "All of those are spun up in docker images for this demo."
        )
        entries.append(
            {
                "kind": "ui_gesture",
                "action": "spotlight_systems",
                "id": "systems-overview",
                "message": "External system" if one else "External systems",
                "detail": (
                    "And here's what sits around the routes. "
                    f"{_oxford(names)}. {docker_line}"
                ),
                "headline": (
                    "External system & Docker service"
                    if one
                    else "External systems & Docker services"
                ),
                "lead": (
                    "The runtime this interface talks to — a local compose service."
                    if one
                    else "Mocks and runtimes this interface talks to — all local compose services."
                ),
                "systems": systems,
                "min_dwell_ms": 10000,
            }
        )
    return entries


def build_outro_entries(*, demo: Path | None = None) -> list[dict]:
    ctx = _ctx()
    purpose_s = ctx.first_sentence(ctx.load_purpose(demo), 160)
    if purpose_s:
        p = purpose_s.rstrip(".")
        if p:
            p = p[0].lower() + p[1:]
        detail = f"That's the demo — {p}. Thanks for choosing PilotFish."
    else:
        name = ctx.load_demo_display_name(demo) if demo else "this interface"
        detail = f"That's the walkthrough of {name}. Thanks for choosing PilotFish."
    return [
        {
            "kind": "outro",
            "action": "thank_you",
            "id": "outro-thanks",
            "message": "Demo complete",
            "detail": detail,
            "logo_url": ctx.logo_data_uri(demo),
        },
    ]


def build_demo_test_plan_entries(cfg: dict) -> list[dict]:
    raw = cfg.get("samples") or [cfg.get("sample") or "the sample"]
    samples = [str(s).strip() for s in raw if str(s).strip()]
    if not samples:
        samples = ["the sample"]
    mode = str(cfg.get("mode") or "")
    if mode != "insert" and len(samples) == 1:
        samples = [samples[0], samples[0]]
    samples = samples[:1] if mode == "insert" else samples[:2]
    has_sql = bool(cfg.get("has_sql"))
    has_ftp = bool(cfg.get("has_ftp"))
    has_queue = bool(cfg.get("has_queue"))
    results_label = str(cfg.get("results_label") or "Results")
    if mode == "insert":
        show_msg = results_label or "XML export"
        wait_first = "The table updates right away. The listener keeps polling and rewriting the XML export."
        wait_again = wait_first
        show_first = "There's the live table, and the pretty-printed XML file from the last poll."
        show_again = show_first
    elif has_sql:
        show_msg = "Rows in SQL"
        wait_first = "Give the routes a moment to pick up the file and write to SQL."
        wait_again = "Same path — it should land in SQL in a moment."
        show_first = f"There they are — rows in the database, under {results_label}."
        show_again = "And there's the second payload in SQL."
    elif has_queue:
        show_msg = results_label
        wait_first = "Give PilotFish a moment to publish that POST onto the queue."
        wait_again = "Same path — it should show up on the queue right away."
        show_first = "There it is — the same body sitting on the queue."
        show_again = "Second payload's on the queue too."
    else:
        show_msg = results_label
        wait_first = "Give the routes a moment to pick up the file and write the output."
        wait_again = "Same path — the second result should show up here."
        show_first = "There it is — output on the results panel."
        show_again = "And there's the second result."
    entries: list[dict] = [
        {
            "kind": "demo_test",
            "action": "open_demo",
            "id": "test-open",
            "message": "Prove it works",
            "detail": "Routes are built. Let's switch to the Demo tab and prove it works.",
        },
    ]
    for i, sample in enumerate(samples, start=1):
        distinct = i > 1 and sample != samples[0]
        repeat = i > 1 and sample == samples[0]
        if mode == "insert":
            inject_msg = "Insert a row"
            inject_detail = "I'll insert a row from the Demo tab so it shows up in Captures."
        elif has_ftp:
            inject_msg = "Drop another sample" if i > 1 else "Drop a sample"
            if distinct:
                inject_detail = "Now I'll drop a second file into the FTP upload folder."
            elif repeat:
                inject_detail = "I'll drop another copy so we can watch it land again."
            else:
                inject_detail = (
                    "I'll drop this sample into the FTP upload folder — same place a trading partner would."
                )
        else:
            inject_msg = "Submit another sample" if i > 1 else "Submit a sample"
            if distinct:
                inject_detail = "Now a second payload from the Demo tab."
            elif repeat:
                inject_detail = "I'll send it one more time so we can watch it land again."
            else:
                inject_detail = "I'll submit this sample from the Demo tab — same as an operator would."
        entries.extend(
            [
                {
                    "kind": "demo_test",
                    "action": "inject",
                    "id": f"test-inject-{i}",
                    "sample": sample,
                    "message": inject_msg,
                    "detail": inject_detail,
                },
                {
                    "kind": "demo_test",
                    "action": "wait_results",
                    "id": f"test-wait-{i}",
                    "timeout_ms": 8000,
                    "message": "Waiting for the routes",
                    "detail": wait_again if i > 1 else wait_first,
                    "min_dwell_ms": 2200,
                },
                {
                    "kind": "demo_test",
                    "action": "show_results",
                    "id": f"test-show-{i}",
                    "message": show_msg,
                    "detail": show_again if i > 1 else show_first,
                },
            ]
        )
    return entries


def synthesize_plan_audio(
    entries: list[dict],
    work: Path,
    *,
    engine: str,
    voice: str,
    rate: int,
    edge_rate: str,
    pace: float,
    post_speech_ms: int,
    empty_post_speech_ms: int,
    min_dwell_ms: int,
    stem_prefix: str,
) -> tuple[list[dict], list[Path]]:
    """Attach dwell_ms + speech wav parts for plan entries that already have detail text."""
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_speech import for_speech

    plans: list[dict] = []
    wav_parts: list[Path] = []
    for i, entry in enumerate(entries, start=1):
        raw = clean_speech(str(entry.get("detail") or entry.get("message") or ""))
        text = for_speech(raw) if raw else f"Step {i}."
        wav = synthesize_voice(
            text,
            work,
            f"{stem_prefix}_{i:04d}",
            engine=engine,
            voice=voice,
            rate=rate,
            edge_rate=edge_rate,
        )
        speech_ms = wav_duration_ms(wav)
        action = str(entry.get("action") or "")
        floor = int(entry.get("min_dwell_ms") or 0)
        if action == "wait_results":
            # Speech plus a short beat — never a 20s+ silent hold after results land
            dwell = max(speech_ms + max(post_speech_ms, 700), 2200)
            if floor:
                dwell = max(dwell, min(floor, 3500))
            dwell = min(dwell, speech_ms + 1500) if speech_ms else min(dwell, 3500)
        elif action == "inject":
            dwell = max(speech_ms + post_speech_ms, 2800)
        elif action == "show_results":
            dwell = max(speech_ms + post_speech_ms, 2800)
        elif action == "spotlight_ognl":
            dwell = max(floor, speech_ms + post_speech_ms + 2000, 10000)
        elif action == "show_welcome":
            dwell = max(floor, speech_ms + post_speech_ms + 800, 5500)
        elif action == "show_pipeline":
            dwell = max(floor, speech_ms + post_speech_ms + 1200, 8000)
        elif action == "spotlight_systems":
            dwell = max(floor, speech_ms + post_speech_ms + 1800, 10000)
        elif action == "create_interface":
            dwell = max(floor, speech_ms + post_speech_ms, 5500)
        elif action == "thank_you" or entry.get("kind") == "outro":
            dwell = max(floor, speech_ms + post_speech_ms, 5500)
        else:
            dwell = max(speech_ms + post_speech_ms, min_dwell_ms, floor)
        pad_ms = max(0, dwell - speech_ms)
        if pad_ms:
            silence = work / f"{stem_prefix}_{i:04d}_pad.wav"
            build_silent_wav(silence, pad_ms)
            full = work / f"{stem_prefix}_{i:04d}_full.wav"
            concat_wavs([wav, silence], full)
            wav_parts.append(full)
        else:
            wav_parts.append(wav)
        out = dict(entry)
        out["dwell_ms"] = dwell
        out["speech_ms"] = speech_ms
        out["text"] = text
        plans.append(out)
        print(f"  narrate {out.get('id')}: {speech_ms}ms speech → {dwell}ms on screen")
        try:
            from construction_video_job import clip_label, update_job

            batch = {"preamble": "setup", "test": "live Demo test", "outro": "closing"}.get(
                stem_prefix, stem_prefix
            )
            label = clip_label(out)
            left = max(0, len(entries) - i)
            update_job(
                phase="tts",
                status="running",
                step=i,
                step_total=len(entries),
                remaining_sec=left * 8,
                message=f"Speaking {batch} {i} of {len(entries)} — {label}",
                log_line=f"TTS {stem_prefix} {i}/{len(entries)}: {label}",
            )
        except Exception:
            pass
    return plans, wav_parts


def wait_url(url: str, timeout: float = 30.0) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urlopen(url, timeout=2) as resp:
                if 200 <= getattr(resp, "status", 200) < 500:
                    return True
        except (URLError, OSError, TimeoutError):
            time.sleep(1.0)
    return False


def wait_webui_styled(base_url: str, timeout: float = 30.0) -> bool:
    """Require HTML + app.css so we never record an unstyled (jank) UI."""
    root = (base_url or "").rstrip("/") + "/"
    css = root + "static/app.css"
    if not wait_url(root, timeout=timeout):
        return False
    return wait_url(css, timeout=min(15.0, timeout))


def load_steps(demo: Path) -> tuple[list[dict], str]:
    manifest = demo / "documents" / "build-replay" / "manifest.json"
    if not manifest.is_file():
        return [], ""
    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return [], ""
    steps = data.get("steps") if isinstance(data, dict) else []
    if not isinstance(steps, list):
        steps = []
    title = load_demo_display_name(demo)
    return steps, title or demo.name


def _items_for_json(plans: list[dict]) -> list[dict]:
    return [
        {
            "id": p.get("id"),
            "action": p.get("action"),
            "message": p.get("message"),
            "detail": p.get("detail"),
            "demo_name": p.get("demo_name"),
            "text": p.get("text") or p.get("detail"),
        }
        for p in plans
    ]


def write_construction_demo_test_json(
    demo: Path,
    *,
    sample: str | None,
    preamble: list[dict],
    steps: list[dict],
    outro: list[dict],
) -> Path:
    docs = demo / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    path = docs / "construction-demo-test.json"
    path.write_text(
        json.dumps(
            {
                "version": 1,
                "sample": sample,
                "preamble": _items_for_json(preamble),
                "steps": _items_for_json(steps),
                "outro": _items_for_json(outro),
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return path


def export_transcript_pdf(demo: Path) -> None:
    transcript_script = Path(__file__).resolve().parent / "export_construction_transcript_pdf.py"
    py_for_pdf = shutil.which("python3") or sys.executable
    proc = subprocess.run(
        [py_for_pdf, str(transcript_script), "--root", str(demo)],
        cwd=str(ROOT),
        capture_output=True,
        text=True,
    )
    if proc.returncode == 0:
        print((proc.stdout or "").strip())
        return
    print(
        f"WARNING: transcript export failed ({proc.returncode}): "
        f"{(proc.stderr or proc.stdout or '').strip()[:400]}",
        file=sys.stderr,
    )


def ensure_build_replay(demo: Path) -> None:
    manifest = demo / "documents" / "build-replay" / "manifest.json"
    if manifest.is_file():
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
            if isinstance(data, dict) and data.get("steps"):
                return
        except json.JSONDecodeError:
            pass
    script = ROOT / "tools" / "record_module_replay.py"
    if not script.is_file():
        return
    print("Recording build-replay steps…")
    subprocess.run([sys.executable, str(script), "--root", str(demo)], cwd=str(ROOT), check=False)


def prepare_construction_assets(demo: Path, *, url: str | None = None) -> int:
    """Replay + naturalized narration + transcript. Does not record mp4."""
    ensure_build_replay(demo)
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_narration_naturalize import naturalize_demo_root

    counts = naturalize_demo_root(demo)
    if counts.get("manifest") or counts.get("demo_test"):
        print(
            f"Naturalized narration: manifest={counts['manifest']}, "
            f"demo-test={counts['demo_test']}"
        )
    steps, title = load_steps(demo)
    title = title or load_demo_display_name(demo) or demo.name
    resolved = detect_webui_url(demo, url)
    demo_cfg = detect_demo_test(resolved, demo)
    preamble = build_theater_preamble_entries(title, demo=demo)
    outro = build_outro_entries(demo=demo)
    test_entries = build_demo_test_plan_entries(demo_cfg) if demo_cfg else []
    path = write_construction_demo_test_json(
        demo,
        sample=(demo_cfg or {}).get("sample") if demo_cfg else None,
        preamble=preamble,
        steps=test_entries,
        outro=outro,
    )
    print(path)
    export_transcript_pdf(demo)
    print("Prepared construction video assets (no mp4)")
    return 0


def ensure_playwright_python() -> Path:
    if VENV_PY.is_file():
        return VENV_PY
    print(
        "Missing tools/.venv-video. Create it with:\n"
        "  python3 -m venv tools/.venv-video\n"
        "  tools/.venv-video/bin/pip install playwright\n"
        "  tools/.venv-video/bin/python -m playwright install chromium",
        file=sys.stderr,
    )
    raise SystemExit(2)


def clean_speech(text: str) -> str:
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_narration_naturalize import naturalize_spoken

    t = naturalize_spoken(text or "")
    t = t.replace("\u201c", '"').replace("\u201d", '"').replace("\u2019", "'")
    t = t.replace("\u2014", " — ").replace("\u2192", " to ")
    t = re.sub(r"`([^`]+)`", r"\1", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def narration_for_step(step: dict, index: int, total: int) -> str:
    """Voiceover text = step transcript, pronunciation-rewritten for TTS."""
    # Lazy import so transcript-only tooling need not load this always
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_speech import for_speech

    detail = clean_speech(str(step.get("detail") or ""))
    message = clean_speech(str(step.get("message") or ""))
    body = detail or message
    if not body:
        return f"Step {index} of {total}."
    return for_speech(body)


def synthesize_edge(text: str, out_mp3: Path, *, voice: str, edge_rate: str = DEFAULT_EDGE_RATE) -> Path:
    """Microsoft Edge neural TTS via edge-tts (much more natural than macOS say)."""
    out_mp3.parent.mkdir(parents=True, exist_ok=True)
    py = ensure_playwright_python()
    rate_arg = edge_rate if edge_rate.startswith(("+", "-")) else f"+{edge_rate}"
    if not rate_arg.endswith("%"):
        rate_arg += "%"
    proc = subprocess.run(
        [
            str(py),
            "-m",
            "edge_tts",
            "--voice",
            voice,
            f"--rate={rate_arg}",
            "--text",
            text,
            "--write-media",
            str(out_mp3),
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0 or not out_mp3.is_file():
        print(proc.stderr or proc.stdout, file=sys.stderr)
        raise SystemExit(f"edge-tts failed ({proc.returncode})")
    return out_mp3


def media_to_wav(src: Path, wav: Path) -> Path:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required to convert TTS audio")
    proc = subprocess.run(
        [ffmpeg, "-y", "-i", str(src), "-acodec", "pcm_s16le", "-ar", "44100", "-ac", "1", str(wav)],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        print(proc.stderr[-1500:], file=sys.stderr)
        raise SystemExit("ffmpeg media→wav failed")
    return wav


def synthesize_say(text: str, out_aiff: Path, *, voice: str, rate: int) -> Path:
    out_aiff.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["say", "-v", voice, "-r", str(rate), "-o", str(out_aiff), text]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(proc.stderr or proc.stdout, file=sys.stderr)
        raise SystemExit(f"say failed ({proc.returncode})")
    return out_aiff


def aiff_to_wav(aiff: Path, wav: Path) -> Path:
    return media_to_wav(aiff, wav)


def wav_duration_ms(path: Path) -> int:
    with wave.open(str(path), "rb") as wf:
        frames = wf.getnframes()
        rate = wf.getframerate() or 1
        return int(round(1000.0 * frames / rate))


def synthesize_voice(
    text: str,
    work: Path,
    stem: str,
    *,
    engine: str,
    voice: str,
    rate: int,
    edge_rate: str = DEFAULT_EDGE_RATE,
) -> Path:
    """Return a wav path for the spoken text."""
    wav = work / f"{stem}.wav"
    if engine == "edge":
        mp3 = work / f"{stem}.mp3"
        synthesize_edge(text, mp3, voice=voice, edge_rate=edge_rate)
        return media_to_wav(mp3, wav)
    aiff = work / f"{stem}.aiff"
    synthesize_say(text, aiff, voice=voice, rate=rate)
    return aiff_to_wav(aiff, wav)


def build_silent_wav(path: Path, duration_ms: int, *, rate: int = 44100) -> Path:
    nframes = max(1, int(rate * duration_ms / 1000.0))
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(b"\x00\x00" * nframes)
    return path


def concat_wavs(parts: list[Path], out: Path) -> Path:
    """Concatenate mono 16-bit WAV files with identical params."""
    if not parts:
        raise SystemExit("no audio parts")
    with wave.open(str(parts[0]), "rb") as first:
        params = first.getparams()
        frames = [first.readframes(first.getnframes())]
    for part in parts[1:]:
        with wave.open(str(part), "rb") as wf:
            if wf.getparams()[:3] != params[:3]:
                raise SystemExit(f"WAV param mismatch: {part}")
            frames.append(wf.readframes(wf.getnframes()))
    with wave.open(str(out), "wb") as out_wf:
        out_wf.setparams(params)
        for chunk in frames:
            out_wf.writeframes(chunk)
    return out


def mux_video_audio(video: Path, audio_wav: Path, dest_mp4: Path) -> None:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required to mux narration")
    dest_mp4.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        ffmpeg,
        "-y",
        "-i",
        str(video),
        "-i",
        str(audio_wav),
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-c:a",
        "aac",
        "-b:a",
        "160k",
        "-shortest",
        "-movflags",
        "+faststart",
        str(dest_mp4),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(proc.stderr[-2000:], file=sys.stderr)
        raise SystemExit(f"ffmpeg mux failed ({proc.returncode})")


def prepare_narration(
    steps: list[dict],
    title: str,
    work: Path,
    *,
    engine: str,
    voice: str,
    rate: int,
    pace: float,
    min_dwell_ms: int,
    focus_min_dwell_ms: int,
    post_speech_ms: int,
    empty_post_speech_ms: int,
    edge_rate: str,
    include_intro: bool,
    demo: Path | None = None,
) -> tuple[list[dict], Path]:
    """Return (step_plans with dwell_ms), full narration wav path."""
    plans: list[dict] = []
    wav_parts: list[Path] = []
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_speech import for_speech

    if include_intro:
        intro_text = for_speech(
            clean_speech(
                f"Construction replay for {title}. "
                f"{len(steps)} steps, module by module."
            )
        )
        intro_wav = synthesize_voice(
            intro_text,
            work,
            "intro",
            engine=engine,
            voice=voice,
            rate=rate,
            edge_rate=edge_rate,
        )
        intro_ms = wav_duration_ms(intro_wav)
        # Intro used to show about:blank — keep it tight if enabled
        intro_dwell = max(DEFAULT_INTRO_MS, intro_ms + empty_post_speech_ms)
        pad_ms = max(0, intro_dwell - intro_ms)
        if pad_ms:
            silence = work / "intro_pad.wav"
            build_silent_wav(silence, pad_ms)
            intro_full = work / "intro_full.wav"
            concat_wavs([intro_wav, silence], intro_full)
            wav_parts.append(intro_full)
        else:
            wav_parts.append(intro_wav)
        # Prefer first diagram step visually instead of a blank frame
        first = steps[0] if steps else {}
        plans.append(
            {
                "kind": "step",
                "dwell_ms": intro_dwell,
                "speech_ms": intro_ms,
                "text": intro_text,
                "id": str(first.get("id") or "0001"),
                "message": f"Construction replay — {title}",
                "detail": intro_text,
                "route_id": str(first.get("route_id") or ""),
                "focus_label": "",
                "focus_node_id": "",
            }
        )

    for i, step in enumerate(steps, start=1):
        text = narration_for_step(step, i, len(steps))
        module_type = str(step.get("module_type") or "")
        is_xslt = "xslt" in module_type.lower()
        xslt_hit = find_demo_xslt(demo, step) if demo and is_xslt else None
        overlay: dict = {}
        if is_xslt and xslt_hit:
            name, body = xslt_hit
            overlay = xslt_overlay_fields(body)
            walk = str(overlay.get("xslt_narration") or "")
            if walk:
                text = (
                    f"Now for the mapping — we're using the stock XSLT processor with {name}. {walk}"
                )
        wav = synthesize_voice(
            text,
            work,
            f"step_{i:04d}",
            engine=engine,
            voice=voice,
            rate=rate,
            edge_rate=edge_rate,
        )
        speech_ms = wav_duration_ms(wav)
        focus = bool(step.get("focus_label") or step.get("focus_node_id"))
        empty = not focus
        floor = focus_min_dwell_ms if focus else min_dwell_ms
        tail = empty_post_speech_ms if empty else post_speech_ms
        # Empty canvas: stay on speech length; modules get a tiny beat after TTS
        dwell = max(floor, speech_ms + tail) if empty else max(floor, int(speech_ms * pace) + tail)
        if overlay:
            dwell = max(dwell, speech_ms + 2000, int(overlay.get("xslt_tour_ms") or 12000), 12000)
        pad_ms = max(0, dwell - speech_ms)
        if pad_ms:
            silence = work / f"step_{i:04d}_pad.wav"
            build_silent_wav(silence, pad_ms)
            full = work / f"step_{i:04d}_full.wav"
            concat_wavs([wav, silence], full)
            wav_parts.append(full)
        else:
            wav_parts.append(wav)

        step_id = step.get("id") or str(step.get("seq") or i).zfill(4)
        plan_step = {
            "kind": "step",
            "dwell_ms": dwell,
            "speech_ms": speech_ms,
            "text": text,
            "id": str(step_id),
            "message": str(step.get("message") or ""),
            "detail": str(step.get("detail") or step.get("message") or ""),
            "route_id": str(step.get("route_id") or ""),
            "focus_label": str(step.get("focus_label") or ""),
            "focus_node_id": str(step.get("focus_node_id") or ""),
            "module_type": module_type,
        }
        if is_xslt and xslt_hit:
            name, body = xslt_hit
            plan_step["show_xslt"] = True
            plan_step["xslt_name"] = name
            plan_step["xslt_text"] = body
            plan_step["xslt_highlight_lines"] = xslt_highlight_lines(body)
            plan_step["xslt_subtitle"] = overlay.get("xslt_subtitle")
            plan_step["xslt_beats"] = overlay.get("xslt_beats") or []
        plans.append(plan_step)
        print(f"  narrate {step_id}: {speech_ms}ms speech → {dwell}ms on screen")
        try:
            from construction_video_job import clip_label, update_job

            n = len(steps)
            label = clip_label(plan_step)
            update_job(
                phase="tts",
                status="running",
                step=i,
                step_total=n,
                remaining_sec=max(0, n - i) * 8,
                message=f"Speaking route step {i} of {n} — {label}",
                log_line=f"TTS route {i}/{n}: {label}",
            )
        except Exception:
            pass

    narration = work / "narration.wav"
    concat_wavs(wav_parts, narration)
    return plans, narration


def record_session(url: str, plans: list[dict], out_webm: Path) -> None:
    if not RECORDER.is_file():
        raise SystemExit(f"Missing recorder helper: {RECORDER}")
    py = ensure_playwright_python()
    plan_path = out_webm.parent / "session_plan.json"
    plan_path.write_text(json.dumps(plans, indent=2) + "\n", encoding="utf-8")
    total_ms = sum(int(p["dwell_ms"]) for p in plans) + 3000
    print(f"Recording video (~{total_ms // 1000}s)…")
    proc = subprocess.run(
        [str(py), str(RECORDER), url, str(plan_path), str(out_webm)],
        cwd=str(ROOT),
    )
    if proc.returncode != 0:
        raise SystemExit(proc.returncode)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="Demo root under Clients/Demos/")
    ap.add_argument("--url", help="Web UI base URL (default: detect from compose)")
    ap.add_argument("--out", help="Output mp4 path (default: documents/construction-replay.mp4)")
    ap.add_argument(
        "--engine",
        choices=("edge", "say"),
        default="edge",
        help="TTS engine: edge (neural, default) or macOS say",
    )
    ap.add_argument(
        "--voice",
        default="en-US-AvaNeural",
        help="Voice id (edge default: en-US-AvaNeural; say e.g. Samantha)",
    )
    ap.add_argument("--rate", type=int, default=175, help="say rate words/min (say engine only)")
    ap.add_argument(
        "--edge-rate",
        default=DEFAULT_EDGE_RATE,
        help=f"edge-tts rate (default: {DEFAULT_EDGE_RATE})",
    )
    ap.add_argument(
        "--pace",
        type=float,
        default=DEFAULT_PACE,
        help=f"Multiply speech duration for module-step dwell (default: {DEFAULT_PACE})",
    )
    ap.add_argument("--min-dwell-ms", type=int, default=DEFAULT_MIN_DWELL_MS)
    ap.add_argument("--focus-min-dwell-ms", type=int, default=DEFAULT_FOCUS_MIN_DWELL_MS)
    ap.add_argument("--post-speech-ms", type=int, default=DEFAULT_POST_SPEECH_MS)
    ap.add_argument(
        "--empty-post-speech-ms",
        type=int,
        default=DEFAULT_EMPTY_POST_SPEECH_MS,
        help="Silence after empty-canvas / non-focus steps (default: tighter)",
    )
    ap.add_argument(
        "--intro",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="Optional short intro (default: off — avoids blank-canvas hold)",
    )
    ap.add_argument(
        "--demo-test",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="After construction, inject a sample on the Demo tab when /api/samples exists (default: on)",
    )
    ap.add_argument(
        "--skip-if-missing-replay",
        action="store_true",
        help="Exit 0 when no build-replay steps exist",
    )
    ap.add_argument("--no-voice", action="store_true", help="Record video without TTS narration")
    ap.add_argument(
        "--prepare-only",
        action="store_true",
        help="Write build-replay / narration / transcript; do not record mp4",
    )
    args = ap.parse_args()

    # If user picks a classic say voice name with default engine, switch to say
    if args.engine == "edge" and args.voice and not args.voice.startswith("en-") and "Neural" not in args.voice:
        # e.g. --voice Samantha implies say
        if args.voice in {"Samantha", "Daniel", "Karen", "Moira", "Tessa", "Alex", "Fred"}:
            args.engine = "say"

    demo = resolve_root(args.root)
    os.environ["CONSTRUCTION_VIDEO_DEMO"] = str(demo.resolve())
    if args.prepare_only:
        return prepare_construction_assets(demo, url=args.url)
    steps, title = load_steps(demo)
    if not steps:
        msg = f"No build-replay steps under {demo / 'documents' / 'build-replay'}"
        if args.skip_if_missing_replay:
            print(msg)
            return 0
        print(msg, file=sys.stderr)
        return 1

    # Always naturalize spoken copy before TTS / plan assembly
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_narration_naturalize import naturalize_demo_root

    counts = naturalize_demo_root(demo)
    if counts.get("manifest") or counts.get("demo_test"):
        print(
            f"Naturalized narration: manifest={counts['manifest']}, "
            f"demo-test={counts['demo_test']}"
        )
    # Reload steps after in-place rewrite
    steps, title = load_steps(demo)

    url = detect_webui_url(demo, args.url)
    print(f"Web UI: {url}")
    print(
        f"Replay steps: {len(steps)} · voice={'off' if args.no_voice else f'{args.engine}/{args.voice}'}"
    )
    bump_webui_status(
        demo,
        f"Preparing {len(steps)} route steps for the construction video",
        phase="starting",
        log="Exporter started",
        step=0,
        step_total=0,
    )
    if not wait_webui_styled(url, timeout=20):
        print(
            f"Web UI not ready (or /static/app.css missing) at {url} — "
            "restart the webui container and retry.",
            file=sys.stderr,
        )
        return 1

    bump_webui_status(
        demo,
        "Writing narration for the construction video",
        log="Started construction-video export",
    )

    out_mp4 = Path(args.out).expanduser().resolve() if args.out else (demo / "documents" / "construction-replay.mp4")

    with tempfile.TemporaryDirectory(prefix="pf-construction-video-") as tmp:
        work = Path(tmp)
        plans: list[dict] = []
        narration: Path | None = None
        preamble_plans: list[dict] = []
        test_plans: list[dict] = []
        outro_plans: list[dict] = []

        preamble_entries = build_theater_preamble_entries(title, demo=demo)
        outro_entries = build_outro_entries(demo=demo)

        if args.no_voice:
            for te in preamble_entries:
                item = dict(te)
                action = item.get("action")
                if action == "show_welcome":
                    item["dwell_ms"] = 5000
                elif action == "spotlight_ognl":
                    item["dwell_ms"] = 7000
                else:
                    item["dwell_ms"] = 4500
                preamble_plans.append(item)
            plans.extend(preamble_plans)
            for i, step in enumerate(steps, start=1):
                focus = bool(step.get("focus_label") or step.get("focus_node_id"))
                dwell = args.focus_min_dwell_ms if focus else args.min_dwell_ms
                step_id = step.get("id") or str(step.get("seq") or i).zfill(4)
                item = {
                    "kind": "step",
                    "dwell_ms": dwell,
                    "id": str(step_id),
                    "message": str(step.get("message") or ""),
                    "detail": str(step.get("detail") or ""),
                    "route_id": str(step.get("route_id") or ""),
                    "focus_label": str(step.get("focus_label") or ""),
                    "focus_node_id": str(step.get("focus_node_id") or ""),
                    "module_type": str(step.get("module_type") or ""),
                }
                if "xslt" in str(step.get("module_type") or "").lower():
                    xslt_hit = find_demo_xslt(demo, step)
                    if xslt_hit:
                        name, body = xslt_hit
                        overlay = xslt_overlay_fields(body)
                        item["show_xslt"] = True
                        item["xslt_name"] = name
                        item["xslt_text"] = body
                        item["xslt_highlight_lines"] = xslt_highlight_lines(body)
                        item["xslt_subtitle"] = overlay.get("xslt_subtitle")
                        item["xslt_beats"] = overlay.get("xslt_beats") or []
                        item["dwell_ms"] = max(int(item["dwell_ms"]), int(overlay.get("xslt_tour_ms") or 14000), 14000)
                plans.append(item)
        else:
            print("Synthesizing narration…")
            bump_webui_status(
                demo,
                "Synthesizing the spoken walkthrough",
                phase="tts",
                log="TTS narration",
            )
            preamble_plans, preamble_wavs = synthesize_plan_audio(
                preamble_entries,
                work,
                engine=args.engine,
                voice=args.voice,
                rate=args.rate,
                edge_rate=args.edge_rate,
                pace=args.pace,
                post_speech_ms=args.post_speech_ms,
                empty_post_speech_ms=args.empty_post_speech_ms,
                min_dwell_ms=args.min_dwell_ms,
                stem_prefix="preamble",
            )
            construction_plans, narration = prepare_narration(
                steps,
                title,
                work,
                engine=args.engine,
                voice=args.voice,
                rate=args.rate,
                pace=args.pace,
                min_dwell_ms=args.min_dwell_ms,
                focus_min_dwell_ms=args.focus_min_dwell_ms,
                post_speech_ms=args.post_speech_ms,
                empty_post_speech_ms=args.empty_post_speech_ms,
                edge_rate=args.edge_rate,
                include_intro=args.intro,
                demo=demo,
            )
            plans = [*preamble_plans, *construction_plans]
            if preamble_wavs and narration and narration.is_file():
                merged = work / "narration_with_preamble.wav"
                concat_wavs([*preamble_wavs, narration], merged)
                narration = merged
            elif preamble_wavs:
                narration = work / "narration.wav"
                concat_wavs(preamble_wavs, narration)

        demo_cfg = detect_demo_test(url, demo) if args.demo_test else None
        if args.demo_test and not demo_cfg:
            print(
                "skip live demo test: Demo tab has no inject or insert form",
                file=sys.stderr,
            )
        if demo_cfg:
            sink = "SQL" if demo_cfg.get("has_sql") else ("queue" if demo_cfg.get("has_queue") else "results")
            print(f"Live demo test: inject {demo_cfg.get('samples') or demo_cfg.get('sample')} → {sink}")
            test_entries = build_demo_test_plan_entries(demo_cfg)
            if args.no_voice:
                for te in test_entries:
                    item = dict(te)
                    action = item.get("action")
                    if action == "wait_results":
                        item["dwell_ms"] = 2800
                    elif action == "inject":
                        item["dwell_ms"] = 2800
                    else:
                        item["dwell_ms"] = 3500
                    plans.append(item)
                    test_plans.append(item)
            else:
                test_plans, test_wavs = synthesize_plan_audio(
                    test_entries,
                    work,
                    engine=args.engine,
                    voice=args.voice,
                    rate=args.rate,
                    edge_rate=args.edge_rate,
                    pace=args.pace,
                    post_speech_ms=args.post_speech_ms,
                    empty_post_speech_ms=args.empty_post_speech_ms,
                    min_dwell_ms=args.min_dwell_ms,
                    stem_prefix="test",
                )
                plans.extend(test_plans)
                if narration and narration.is_file() and test_wavs:
                    merged = work / "narration_with_test.wav"
                    concat_wavs([narration, *test_wavs], merged)
                    narration = merged
                elif test_wavs:
                    narration = work / "narration.wav"
                    concat_wavs(test_wavs, narration)

        if args.no_voice:
            for te in outro_entries:
                item = dict(te)
                item["dwell_ms"] = 5500
                outro_plans.append(item)
                plans.append(item)
        else:
            outro_plans, outro_wavs = synthesize_plan_audio(
                outro_entries,
                work,
                engine=args.engine,
                voice=args.voice,
                rate=args.rate,
                edge_rate=args.edge_rate,
                pace=args.pace,
                post_speech_ms=max(args.post_speech_ms, 800),
                empty_post_speech_ms=args.empty_post_speech_ms,
                min_dwell_ms=max(args.min_dwell_ms, 4500),
                stem_prefix="outro",
            )
            plans.extend(outro_plans)
            if narration and narration.is_file() and outro_wavs:
                merged = work / "narration_with_outro.wav"
                concat_wavs([narration, *outro_wavs], merged)
                narration = merged
            elif outro_wavs:
                narration = work / "narration.wav"
                concat_wavs(outro_wavs, narration)

        write_construction_demo_test_json(
            demo,
            sample=(demo_cfg or {}).get("sample") if demo_cfg else None,
            preamble=preamble_plans,
            steps=test_plans,
            outro=outro_plans,
        )

        webm = work / "construction-replay.webm"
        bump_webui_status(
            demo,
            f"Recording the browser — about {sum(int(p.get('dwell_ms') or 0) for p in plans) // 1000}s of scenes",
            phase="recording",
            log="Playwright capture",
            step=0,
            step_total=len(plans),
            remaining_sec=sum(int(p.get("dwell_ms") or 0) for p in plans) // 1000,
        )
        record_session(url, plans, webm)
        if not webm.is_file():
            found = list(work.glob("*.webm"))
            if not found:
                print("No video file produced", file=sys.stderr)
                return 1
            webm = found[0]

        if narration and narration.is_file():
            print("Muxing narration…")
            bump_webui_status(
                demo,
                "Combining narration with the video (ffmpeg) — often 20–40s",
                phase="mux",
                log="ffmpeg mux",
                remaining_sec=None,
            )
            mux_video_audio(webm, narration, out_mp4)
        else:
            # silent fallback
            ffmpeg = shutil.which("ffmpeg")
            if not ffmpeg:
                shutil.copy2(webm, out_mp4.with_suffix(".webm"))
                print(f"ffmpeg missing — left {out_mp4.with_suffix('.webm')}", file=sys.stderr)
                return 1
            proc = subprocess.run(
                [
                    ffmpeg,
                    "-y",
                    "-i",
                    str(webm),
                    "-c:v",
                    "libx264",
                    "-pix_fmt",
                    "yuv420p",
                    "-an",
                    "-movflags",
                    "+faststart",
                    str(out_mp4),
                ],
                capture_output=True,
                text=True,
            )
            if proc.returncode != 0:
                print(proc.stderr[-1500:], file=sys.stderr)
                return 1

    print(out_mp4)
    print(f"Size: {out_mp4.stat().st_size // 1024} KB")
    bump_webui_status(demo, "Writing the construction transcript", phase="transcript", log="Transcript PDF")
    export_transcript_pdf(demo)
    size_kb = out_mp4.stat().st_size // 1024 if out_mp4.is_file() else None
    bump_webui_status(
        demo,
        "Construction video ready",
        phase="done",
        status="done",
        size_kb=size_kb,
        remaining_sec=0,
        log="Construction video ready",
    )
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "tools" / "update_build_status.py"),
            "--root",
            str(demo),
            "--inactive",
            "--phase",
            "complete",
            "--message",
            "Construction video ready",
            "--log",
            "Construction video and transcript are on the Info tab",
        ],
        cwd=str(ROOT),
        check=False,
        capture_output=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
