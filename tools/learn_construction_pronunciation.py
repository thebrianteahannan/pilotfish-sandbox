#!/usr/bin/env python3
"""Teach the construction-video robot TTS one spoken term at a time.

Records a few seconds from the Mac mic, transcribes how you said the word,
and writes that into docs/construction-narration-pronunciation.json.
Display/transcript spelling stays unchanged. Only Edge TTS speech is rewritten.

  python3 tools/learn_construction_pronunciation.py --word RabbitMQ
  python3 tools/learn_construction_pronunciation.py --word RabbitMQ --speak "rabbit em queue"
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GUIDE_JSON = ROOT / "docs" / "construction-narration-pronunciation.json"
CLIPS = ROOT / "tools" / "voices" / "clips"
FFMPEG = "/opt/homebrew/bin/ffmpeg"


def _mic_index() -> str:
    proc = subprocess.run(
        [FFMPEG, "-f", "avfoundation", "-list_devices", "true", "-i", ""],
        capture_output=True,
        text=True,
    )
    blob = (proc.stderr or "") + (proc.stdout or "")
    in_audio = False
    for line in blob.splitlines():
        if "AVFoundation audio devices" in line:
            in_audio = True
            continue
        if in_audio and "AVFoundation video devices" in line:
            break
        if not in_audio:
            continue
        m = re.search(r"\[(\d+)\]\s+(.+)$", line)
        if not m:
            continue
        name = m.group(2).strip().lower()
        if "macbook" in name and "mic" in name:
            return m.group(1)
        if "microphone" in name:
            return m.group(1)
    raise SystemExit("No Mac microphone found. Check System Settings → Privacy → Microphone.")


def _record(path: Path, seconds: float, mic: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    beep = Path("/System/Library/Sounds/Tink.aiff")
    if beep.is_file():
        subprocess.run(["afplay", str(beep)], check=False)
    print(f"Speak now ({seconds:.0f}s)…", flush=True)
    proc = subprocess.run(
        [
            FFMPEG, "-hide_banner", "-loglevel", "error", "-y",
            "-f", "avfoundation", "-i", f":{mic}",
            "-t", str(seconds), "-ac", "1", "-ar", "16000",
            str(path),
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0 or not path.is_file() or path.stat().st_size < 400:
        err = (proc.stderr or proc.stdout or "").strip() or f"exit {proc.returncode}"
        raise SystemExit(f"Mic record failed: {err}")


def _transcribe(wav: Path) -> str:
    try:
        import mlx_whisper
    except ImportError as exc:
        raise SystemExit(
            "mlx-whisper is not installed. From repo root:\n"
            "  tools/.venv-video/bin/pip install mlx-whisper"
        ) from exc
    result = mlx_whisper.transcribe(
        str(wav),
        path_or_hf_repo="mlx-community/whisper-tiny-en-mlx",
    )
    return " ".join(str(result.get("text") or "").split()).strip(" .")


def _term_id(word: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9]+", "-", word.strip()).strip("-").lower()
    return slug or "term"


def _upsert(word: str, speak: str, heard: str) -> dict:
    guide = json.loads(GUIDE_JSON.read_text(encoding="utf-8"))
    items = guide.setdefault("replacements", [])
    tid = _term_id(word)
    escaped = re.escape(word.strip())
    match = rf"\b{escaped}\b"
    note = f"Spoken sample; heard “{heard}”." if heard else "Spoken sample."
    existing = next((x for x in items if x.get("id") == tid), None)
    payload = {
        "id": tid,
        "match": match,
        "flags": "i",
        "speak": speak,
        "notes": note,
    }
    if existing is None:
        items.insert(0, payload)
    else:
        existing.update(payload)
    GUIDE_JSON.write_text(json.dumps(guide, indent=2) + "\n", encoding="utf-8")
    return payload


def _preview_robot(word: str, speak: str) -> Path:
    sys.path.insert(0, str(ROOT / "tools"))
    from construction_speech import for_speech

    line = for_speech(f"This is {word}.")
    out = Path(tempfile.gettempdir()) / "pf-pronounce-preview.mp3"
    venv_tts = ROOT / "tools" / ".venv-video" / "bin" / "edge-tts"
    cmd = [str(venv_tts) if venv_tts.is_file() else "edge-tts"]
    cmd += [
        "--voice", "en-US-AvaNeural",
        "--rate", "-5%",
        "--text", line,
        "--write-media", str(out),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit((proc.stderr or proc.stdout or "edge-tts failed").strip())
    print(f"Robot preview: {line}", flush=True)
    subprocess.run(["afplay", str(out)], check=False)
    return out


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--word", required=True, help="Display spelling as it appears in the transcript")
    p.add_argument("--speak", default="", help="Override: how the robot should say it")
    p.add_argument("--from-wav", default="", help="Use this recording instead of the mic")
    p.add_argument("--seconds", type=float, default=3.5)
    p.add_argument("--no-preview", action="store_true")
    args = p.parse_args()
    word = args.word.strip()
    if not word:
        raise SystemExit("--word is empty")

    wav = Path(args.from_wav) if args.from_wav else CLIPS / f"{_term_id(word)}.wav"
    heard = ""
    if args.from_wav:
        if not wav.is_file():
            raise SystemExit(f"Missing wav: {wav}")
    else:
        _record(wav, args.seconds, _mic_index())
    if not args.speak:
        heard = _transcribe(wav)
        if not heard:
            raise SystemExit("Heard silence. Try again a bit louder, or pass --speak.")
        speak = heard
    else:
        speak = args.speak.strip()
        if wav.is_file():
            try:
                heard = _transcribe(wav)
            except SystemExit:
                heard = ""
    payload = _upsert(word, speak, heard or speak)
    print(f"Saved {payload['id']}: {word} → {speak}", flush=True)
    if not args.no_preview:
        _preview_robot(word, speak)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
