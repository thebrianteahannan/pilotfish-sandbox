"""Align eiConsole construction-video narration to the Swing click timeline."""

from __future__ import annotations

import array
import json
import re
import subprocess
import time
import wave
from pathlib import Path


def wait_capture_frames(log_path: Path, proc: subprocess.Popen, timeout_s: float = 25.0) -> None:
    """Block until ffmpeg has encoded at least one real frame."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        if proc.poll() is not None:
            tail = ""
            if log_path.is_file():
                tail = log_path.read_text(encoding="utf-8", errors="replace")[-2000:]
            raise SystemExit(f"ffmpeg exited {proc.returncode} before any frames\n{tail}")
        if log_path.is_file():
            text = log_path.read_text(encoding="utf-8", errors="replace")
            if re.search(r"frame=\s*[1-9]\d*", text):
                return
        time.sleep(0.15)
    raise SystemExit("ffmpeg never produced a video frame")


def video_duration_ms(path: Path) -> int:
    proc = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "csv=p=0",
            str(path),
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise SystemExit(f"ffprobe failed for {path}: {proc.stderr[-400:]}")
    try:
        return int(round(float((proc.stdout or "0").strip()) * 1000))
    except ValueError:
        return 0


def write_timed_script(source: Path, steps: list[dict], dest: Path) -> Path:
    """Copy the walkthrough YAML and stamp speech-length dwells. Do not silently keep the short floors."""
    by_id = {str(s.get("id") or ""): s for s in steps if s.get("id")}
    current = None
    out: list[str] = []
    patched = 0
    for line in source.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("- id:"):
            current = stripped.split(":", 1)[1].strip()
        if stripped.startswith("speak:"):
            continue
        if current and stripped.startswith("dwell_ms:") and current in by_id:
            step = by_id[current]
            indent = line[: len(line) - len(line.lstrip())]
            out.append(f"{indent}dwell_ms: {int(step.get('dwell_ms') or 0)}")
            speak = str(step.get("speak") or "").strip()
            if speak:
                out.append(f"{indent}speak: {speak}")
            patched += 1
            current = None
            continue
        out.append(line)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text("\n".join(out) + "\n", encoding="utf-8")
    if patched == 0:
        raise SystemExit(f"Failed to write timed dwells into {dest}")
    print(f"timed walkthrough: patched {patched} dwell_ms values → {dest}")
    return dest


def content_end_ms(timeline: dict | None, preroll_ms: int, plans: list[dict]) -> int | None:
    spoken = {str(p.get("id") or "") for p in plans if int(p.get("speech_ms") or 0) > 0}
    last = None
    for event in (timeline or {}).get("steps") or []:
        if event.get("skipped") or str(event.get("id") or "") not in spoken:
            continue
        last = event
    if last is None:
        return None
    return preroll_ms + int(last.get("ended_at_ms") or 0) + 800


def load_timeline(path: Path) -> dict | None:
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def mix_wavs_at(clips: list[tuple[int, Path]], total_ms: int, out: Path, *, rate: int = 44100) -> Path:
    """Mix mono 16-bit clips onto a silent canvas. Each clip is (start_ms, wav)."""
    n = max(1, int(rate * max(total_ms, 1) / 1000.0))
    samples = array.array("h", [0] * n)
    for start_ms, wav in clips:
        with wave.open(str(wav), "rb") as wf:
            if wf.getnchannels() != 1 or wf.getsampwidth() != 2:
                raise SystemExit(f"expected mono 16-bit WAV: {wav}")
            src_rate = wf.getframerate() or rate
            data = array.array("h")
            data.frombytes(wf.readframes(wf.getnframes()))
        if src_rate != rate:
            raise SystemExit(f"WAV rate {src_rate} != {rate}: {wav}")
        start = int(rate * max(0, start_ms) / 1000.0)
        for i, value in enumerate(data):
            j = start + i
            if 0 <= j < n:
                mixed = samples[j] + value
                samples[j] = -32768 if mixed < -32768 else 32767 if mixed > 32767 else mixed
    out.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(out), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(samples.tobytes())
    return out


def align_narration(
    plans: list[dict],
    timeline: dict | None,
    preroll_ms: int,
    video_ms: int,
    work: Path,
    ev,
) -> Path:
    """Place each spoken line when that click actually landed. Skip failed clicks."""
    spoken = {
        str(p.get("id") or ""): p
        for p in plans
        if p.get("wav") and int(p.get("speech_ms") or 0) > 0
    }
    clips: list[tuple[int, Path]] = []
    for event in (timeline or {}).get("steps") or []:
        if event.get("skipped"):
            continue
        plan = spoken.get(str(event.get("id") or ""))
        if not plan:
            continue
        landed = int(event.get("ended_at_ms") or 0) - int(event.get("dwell_ms") or 0)
        clips.append((max(0, preroll_ms + landed), Path(plan["wav"])))
    if clips:
        clips.sort(key=lambda item: item[0])
        placed: list[tuple[int, Path]] = []
        cursor = 0
        for start, wav in clips:
            start = max(start, cursor)
            placed.append((start, wav))
            cursor = start + ev.wav_duration_ms(wav) + 40
        return mix_wavs_at(placed, max(video_ms, cursor + 250), work / "narration.wav")

    parts: list[Path] = []
    if preroll_ms > 0:
        pad = work / "preroll.wav"
        ev.build_silent_wav(pad, preroll_ms)
        parts.append(pad)
    for plan in plans:
        wav = plan.get("full_wav") or plan.get("wav")
        if wav:
            parts.append(Path(wav))
    if not parts:
        ev.build_silent_wav(work / "narration.wav", max(video_ms, 1000))
        return work / "narration.wav"
    concat = work / "narration-concat.wav"
    ev.concat_wavs(parts, concat)
    extra = max(0, video_ms - ev.wav_duration_ms(concat))
    if extra:
        tail = work / "tail.wav"
        ev.build_silent_wav(tail, extra)
        ev.concat_wavs([concat, tail], work / "narration.wav")
        return work / "narration.wav"
    return concat
