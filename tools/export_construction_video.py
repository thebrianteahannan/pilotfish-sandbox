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
    if raw:
        return Path(raw).expanduser().resolve()
    return Path.cwd().resolve()


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


def detect_demo_test(url: str, demo: Path) -> dict | None:
    """Return live-test config when Demo inject + SQL are available."""
    base = url.rstrip("/") + "/"
    try:
        with urlopen(base + "api/health", timeout=4) as resp:
            health = json.loads(resp.read().decode("utf-8", errors="replace"))
    except Exception:
        return None
    if not isinstance(health, dict) or not health.get("db_ok"):
        return None
    try:
        with urlopen(base + "api/samples", timeout=4) as resp:
            samples = json.loads(resp.read().decode("utf-8", errors="replace"))
    except Exception:
        return None
    files = samples.get("files") if isinstance(samples, dict) else None
    if not isinstance(files, list) or not files:
        return None
    # Prefer patients.csv when present
    names = [str(f.get("name") or "") for f in files if isinstance(f, dict)]
    sample = "patients.csv" if "patients.csv" in names else names[0]
    # Only enable when this Web UI looks like the inject demo
    if not (demo / "webui" / "static" / "app.js").is_file() and not (
        demo / "webui" / "templates" / "index.html"
    ).is_file():
        # Still OK if APIs work
        pass
    return {"sample": sample, "sftp_hint": str(health.get("sftp_hint") or "SFTP")}


def find_demo_xslt(demo: Path) -> tuple[str, str] | None:
    """Return (filename, text) for the primary route stylesheet if present."""
    preferred = [
        demo / "pilotfish" / "demo-eip-root" / "routes" / "2 - CSV To SQL" / "csv-to-sqlxml.xslt",
        demo / "eip-root" / "interfaces" / "CSV SFTP To SQL" / "routes" / "2 - CSV To SQL" / "csv-to-sqlxml.xslt",
    ]
    for p in preferred:
        if p.is_file():
            return p.name, p.read_text(encoding="utf-8", errors="replace")
    hits = sorted(demo.rglob("*.xslt"))
    if hits:
        p = hits[0]
        return p.name, p.read_text(encoding="utf-8", errors="replace")
    return None


def xslt_highlight_lines(text: str) -> list[int]:
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


OGNL_EXAMPLE = (
    "{ognl:(getAttribute('com.pilotfish.FileName') != null "
    "? getAttribute('com.pilotfish.FileName') : 'csv') + '_' "
    "+ @java.lang.System@currentTimeMillis() + '.csv'}"
)

# Default sandbox stack for csv-sftp-to-sql (ports match DESIGN.md / compose).
DEFAULT_EXTERNAL_SYSTEMS = [
    {
        "name": "FTP drop",
        "kind": "Docker",
        "image": "atmoz/sftp:alpine",
        "detail": "localhost:2224 · demo/demo · upload/",
        "role": "Trading-partner file drop (secure FTP)",
    },
    {
        "name": "SQL Server 2022",
        "kind": "Docker",
        "image": "mssql/server:2022-latest",
        "detail": "localhost:14341 · database CsvSftpDemo",
        "role": "Target — dbo.CsvPatients",
    },
    {
        "name": "PilotFish eiPlatform",
        "kind": "Docker",
        "image": "pilotfish-csv-sftp-to-sql:23R1",
        "detail": "localhost:8132/eip/",
        "role": "Runs the two routes",
    },
    {
        "name": "Demo Web UI",
        "kind": "Docker",
        "image": "pilotfish-csv-sftp-to-sql-webui",
        "detail": "localhost:8133",
        "role": "Inject sample CSV + review SQL rows",
    },
]

DEFAULT_PIPELINE_STAGES = [
    {"title": "FTP drop", "subtitle": "upload/ · CSV"},
    {"title": "Stage", "subtitle": "Archive + local copy"},
    {"title": "CSV → XML", "subtitle": "Dialect A rows"},
    {"title": "SQL Server", "subtitle": "dbo.CsvPatients"},
]


def load_demo_display_name(demo: Path) -> str:
    """Human-facing demo / interface name (DESIGN.md H1 preferred)."""
    design = demo / "DESIGN.md"
    if design.is_file():
        for line in design.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("# "):
                name = line[2:].strip()
                if name:
                    return name
    interfaces = demo / "eip-root" / "interfaces"
    if interfaces.is_dir():
        kids = sorted(p.name for p in interfaces.iterdir() if p.is_dir() and not p.name.startswith("."))
        if kids:
            return kids[0]
    return demo.name.replace("-", " ").strip() or "PilotFish Demo"


def build_theater_preamble_entries(demo_name: str = "PilotFish Demo") -> list[dict]:
    name = (demo_name or "PilotFish Demo").strip() or "PilotFish Demo"
    return [
        {
            "kind": "ui_gesture",
            "action": "show_welcome",
            "id": "welcome",
            "message": "Welcome",
            "demo_name": name,
            "headline": "Welcome to the demo",
            "detail": (
                f"Welcome to the PilotFish demo: {name}. "
                "This one didn't need any custom code — "
                "PilotFish supports the whole flow out of the box."
            ),
            "logo_url": "/static/pilotfish-logo.jpg",
            "min_dwell_ms": 5500,
        },
        {
            "kind": "ui_gesture",
            "action": "show_pipeline",
            "id": "pipeline-overview",
            "message": "Pipeline overview",
            "detail": (
                "Before we wire anything, here's the flow end to end. "
                "A CSV lands on FTP, we stage it, turn the rows into XML, "
                "and load them into SQL Server. Two routes — pickup, then load."
            ),
            "pipeline_stages": DEFAULT_PIPELINE_STAGES,
            "min_dwell_ms": 8000,
        },
        {
            "kind": "ui_gesture",
            "action": "spotlight_systems",
            "id": "systems-overview",
            "message": "External systems",
            "detail": (
                "And here's what sits around the routes. "
                "FTP holds the drop folder, SQL Server holds the patients table, "
                "eiPlatform runs the interfaces, and this Web UI is where we inject and review. "
                "All of that is Docker for the demo."
            ),
            "systems": DEFAULT_EXTERNAL_SYSTEMS,
            "min_dwell_ms": 10000,
        },
        {
            "kind": "ui_gesture",
            "action": "create_interface",
            "id": "create-iface",
            "message": "Blank canvas",
            "detail": (
                "Here is a blank canvas, so let's get started creating the new PilotFish interface."
            ),
        },
        {
            "kind": "ui_gesture",
            "action": "spotlight_ognl",
            "id": "ognl-intro",
            "message": "What OGNL is",
            "detail": (
                "One thing you'll see in a few configs: OGNL. "
                "Think of it as a tiny expression language — instead of hard-coding a file name, "
                "we build it from the transaction. "
                "On archive and stage we use the original name, an underscore, a timestamp, then .csv. "
                "That keeps every copy unique without losing where it came from."
            ),
            "ognl_summary": "{sourceFileName}_<timestamp>.csv",
            "ognl_example": OGNL_EXAMPLE,
            "ognl_why": (
                "OGNL lets config values stay dynamic — tied to the file or transaction — "
                "instead of a static string."
            ),
            "min_dwell_ms": 10000,
        },
    ]


def build_outro_entries() -> list[dict]:
    return [
        {
            "kind": "outro",
            "action": "thank_you",
            "id": "outro-thanks",
            "message": "Demo complete",
            "detail": (
                "That's the demo — file in on FTP, patients in SQL. "
                "Thanks for choosing PilotFish."
            ),
        },
    ]


def build_demo_test_plan_entries(cfg: dict) -> list[dict]:
    sample = cfg.get("sample") or "patients.csv"
    return [
        {
            "kind": "demo_test",
            "action": "open_demo",
            "id": "test-open",
            "message": "Prove it works",
            "detail": (
                "Routes are built. Let's switch to the Demo tab and prove it works."
            ),
        },
        {
            "kind": "demo_test",
            "action": "inject",
            "id": "test-inject",
            "sample": sample,
            "message": f"Drop {sample} on FTP",
            "detail": (
                f"I'll drop {sample} into the FTP upload folder — same place a trading partner would."
            ),
        },
        {
            "kind": "demo_test",
            "action": "wait_results",
            "id": "test-wait",
            "timeout_ms": 90000,
            "message": "Waiting for the routes",
            "detail": (
                "Give the routes a moment. Route one picks up the file and stages it; "
                "route two parses the CSV and inserts into SQL."
            ),
            "min_dwell_ms": 32000,
        },
        {
            "kind": "demo_test",
            "action": "show_results",
            "id": "test-show",
            "message": "Rows in SQL",
            "detail": (
                "There they are — patient rows in the database. File in on FTP, data out in SQL."
            ),
        },
    ]


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
            # Speech + silence pad so A/V stay aligned while EIP polls
            dwell = max(floor, speech_ms + empty_post_speech_ms, 28000)
        elif action == "inject":
            dwell = max(speech_ms + post_speech_ms, 2800)
        elif action == "show_results":
            dwell = max(speech_ms + post_speech_ms, 5000)
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

    xslt_hit = find_demo_xslt(demo) if demo else None

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
        # XSLT beat needs extra on-screen time for scroll/highlight
        module_type = str(step.get("module_type") or "")
        is_xslt = "xslt" in module_type.lower()
        if is_xslt and xslt_hit:
            dwell = max(dwell, speech_ms + 6500, 14000)
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
        plans.append(plan_step)
        print(f"  narrate {step_id}: {speech_ms}ms speech → {dwell}ms on screen")

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
        help="After construction, inject sample CSV on Demo tab and show SQL rows (default: on when health/db OK)",
    )
    ap.add_argument(
        "--skip-if-missing-replay",
        action="store_true",
        help="Exit 0 when no build-replay steps exist",
    )
    ap.add_argument("--no-voice", action="store_true", help="Record video without TTS narration")
    args = ap.parse_args()

    # If user picks a classic say voice name with default engine, switch to say
    if args.engine == "edge" and args.voice and not args.voice.startswith("en-") and "Neural" not in args.voice:
        # e.g. --voice Samantha implies say
        if args.voice in {"Samantha", "Daniel", "Karen", "Moira", "Tessa", "Alex", "Fred"}:
            args.engine = "say"

    demo = resolve_root(args.root)
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
    if not wait_webui_styled(url, timeout=20):
        print(
            f"Web UI not ready (or /static/app.css missing) at {url} — "
            "restart the webui container and retry.",
            file=sys.stderr,
        )
        return 1

    out_mp4 = Path(args.out).expanduser().resolve() if args.out else (demo / "documents" / "construction-replay.mp4")

    with tempfile.TemporaryDirectory(prefix="pf-construction-video-") as tmp:
        work = Path(tmp)
        plans: list[dict] = []
        narration: Path | None = None
        preamble_plans: list[dict] = []
        test_plans: list[dict] = []
        outro_plans: list[dict] = []

        preamble_entries = build_theater_preamble_entries(title)
        outro_entries = build_outro_entries()

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
                    xslt_hit = find_demo_xslt(demo)
                    if xslt_hit:
                        name, body = xslt_hit
                        item["show_xslt"] = True
                        item["xslt_name"] = name
                        item["xslt_text"] = body
                        item["xslt_highlight_lines"] = xslt_highlight_lines(body)
                        item["dwell_ms"] = max(int(item["dwell_ms"]), 14000)
                plans.append(item)
        else:
            print("Synthesizing narration…")
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
                "skip live demo test: /api/health db_ok or /api/samples not available",
                file=sys.stderr,
            )
        if demo_cfg:
            print(f"Live demo test: inject {demo_cfg.get('sample')} → SQL")
            test_entries = build_demo_test_plan_entries(demo_cfg)
            if args.no_voice:
                for te in test_entries:
                    item = dict(te)
                    item["dwell_ms"] = 6000 if item.get("action") != "wait_results" else 32000
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

        # Persist spoken extras for transcript PDF
        (demo / "documents").mkdir(parents=True, exist_ok=True)
        extras_payload = {
            "version": 1,
            "sample": (demo_cfg or {}).get("sample") if demo_cfg else None,
            "preamble": [
                {
                    "id": p.get("id"),
                    "action": p.get("action"),
                    "message": p.get("message"),
                    "detail": p.get("detail"),
                    "demo_name": p.get("demo_name"),
                    "text": p.get("text") or p.get("detail"),
                }
                for p in preamble_plans
            ],
            "steps": [
                {
                    "id": p.get("id"),
                    "action": p.get("action"),
                    "message": p.get("message"),
                    "detail": p.get("detail"),
                    "text": p.get("text") or p.get("detail"),
                }
                for p in test_plans
            ],
            "outro": [
                {
                    "id": p.get("id"),
                    "action": p.get("action"),
                    "message": p.get("message"),
                    "detail": p.get("detail"),
                    "text": p.get("text") or p.get("detail"),
                }
                for p in outro_plans
            ],
        }
        (demo / "documents" / "construction-demo-test.json").write_text(
            json.dumps(extras_payload, indent=2) + "\n",
            encoding="utf-8",
        )

        webm = work / "construction-replay.webm"
        record_session(url, plans, webm)
        if not webm.is_file():
            found = list(work.glob("*.webm"))
            if not found:
                print("No video file produced", file=sys.stderr)
                return 1
            webm = found[0]

        if narration and narration.is_file():
            print("Muxing narration…")
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
    else:
        print(
            f"WARNING: transcript export failed ({proc.returncode}): "
            f"{(proc.stderr or proc.stdout or '').strip()[:400]}",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
