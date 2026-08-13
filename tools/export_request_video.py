#!/usr/bin/env python3
"""Record a request-demo.mp4 (theater + Edge AvaNeural) from a client request folder.

  python3 tools/export_request_video.py --folder "Clients/Med Rec/requests/<id>"
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from export_construction_video import (  # noqa: E402
    DEFAULT_EDGE_RATE,
    DEFAULT_MIN_DWELL_MS,
    DEFAULT_POST_SPEECH_MS,
    build_silent_wav,
    concat_wavs,
    ensure_playwright_python,
    mux_video_audio,
    synthesize_voice,
    wav_duration_ms,
)
from request_video_scenes import build_scenes  # noqa: E402

RECORDER = TOOLS / "_record_request_session.py"
THEATER = """<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8" /><title>Request demo</title>
<style>html,body{margin:0;background:#0b1220}</style></head>
<body></body></html>
"""


def write_job(folder: Path, **fields) -> None:
    path = folder / "request-video-job.json"
    data = {}
    if path.is_file():
        try:
            loaded = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                data = loaded
        except (OSError, json.JSONDecodeError):
            data = {}
    log_line = fields.pop("log_line", None)
    if log_line:
        log = list(data.get("log") or [])
        text = str(log_line).strip()
        if text:
            log.append({"at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "text": text})
        fields["log"] = log[-12:]
    data.update(fields)
    data["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    tmp.replace(path)


def prepare_audio(scenes: list[dict], work: Path, folder: Path) -> tuple[list[dict], Path]:
    plans: list[dict] = []
    parts: list[Path] = []
    total = len(scenes) or 1
    for i, scene in enumerate(scenes, start=1):
        label = str(scene.get("message") or scene.get("id") or f"Scene {i}")
        write_job(
            folder,
            status="running",
            phase="tts",
            step=i,
            step_total=total,
            message=f"Writing narration {i} of {total} — {label}",
            log_line=f"Narration {i}/{total}: {label}",
        )
        text = str(scene.get("speak") or scene.get("message") or f"Scene {i}.")
        wav = synthesize_voice(
            text,
            work,
            f"{i:02d}",
            engine="edge",
            voice="en-US-AvaNeural",
            rate=175,
            edge_rate=DEFAULT_EDGE_RATE,
        )
        speech_ms = wav_duration_ms(wav)
        dwell = max(DEFAULT_MIN_DWELL_MS, speech_ms + DEFAULT_POST_SPEECH_MS)
        silence = work / f"{i:02d}-gap.wav"
        build_silent_wav(silence, max(0, dwell - speech_ms))
        full = work / f"{i:02d}-full.wav"
        concat_wavs([wav, silence], full)
        parts.append(full)
        plans.append(
            {
                "id": scene.get("id") or f"{i:02d}",
                "message": scene.get("message") or "",
                "html": scene.get("html") or "",
                "dwell_ms": dwell,
            }
        )
    narration = work / "narration.wav"
    concat_wavs(parts, narration)
    return plans, narration


def record(html: Path, plans: list[dict], webm: Path, folder: Path) -> None:
    py = ensure_playwright_python()
    plan_path = webm.parent / "session_plan.json"
    plan_path.write_text(json.dumps(plans, indent=2) + "\n", encoding="utf-8")
    env = os.environ.copy()
    env["REQUEST_VIDEO_FOLDER"] = str(folder)
    write_job(
        folder,
        status="running",
        phase="recording",
        step=0,
        step_total=len(plans) or 1,
        message="Recording request demo video…",
        log_line="Starting browser recording",
    )
    proc = subprocess.run(
        [str(py), str(RECORDER), str(html), str(plan_path), str(webm)],
        cwd=str(ROOT),
        env=env,
    )
    if proc.returncode != 0:
        raise SystemExit(proc.returncode)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--folder", required=True, help="Client request folder")
    args = ap.parse_args()
    folder = Path(args.folder).expanduser().resolve()
    if not folder.is_dir() or not (folder / "request.json").is_file():
        raise SystemExit(f"Not a request folder: {folder}")
    work = folder / "_video_work"
    work.mkdir(parents=True, exist_ok=True)
    write_job(folder, status="running", phase="tts", message="Writing narration…", error="", log_line="Building scenes")
    scenes = build_scenes(folder)
    if not scenes:
        raise SystemExit("No request video scenes")
    plans, narration = prepare_audio(scenes, work, folder)
    html = work / "theater.html"
    html.write_text(THEATER, encoding="utf-8")
    webm = work / "session.webm"
    record(html, plans, webm, folder)
    dest = folder / "request-demo.mp4"
    write_job(
        folder,
        status="running",
        phase="mux",
        message="Combining audio and video…",
        log_line="Combining audio and video",
    )
    mux_video_audio(webm, narration, dest)
    write_job(
        folder,
        status="done",
        phase="done",
        message="Request demo video ready",
        size_kb=dest.stat().st_size // 1024,
        log_line="Request demo video ready",
    )
    print(dest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
