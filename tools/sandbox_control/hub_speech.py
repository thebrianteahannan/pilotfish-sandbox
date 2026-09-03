"""Hub UI: teach construction-video pronunciation from a browser recording."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

from flask import jsonify, request, send_file

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"
GUIDE_JSON = ROOT / "docs" / "construction-narration-pronunciation.json"
VIDEO_PY = TOOLS / ".venv-video" / "bin" / "python"
EDGE_TTS = TOOLS / ".venv-video" / "bin" / "edge-tts"
FFMPEG = shutil.which("ffmpeg") or "/opt/homebrew/bin/ffmpeg"
WORK = Path(tempfile.gettempdir()) / "pf-hub-speech"
VOICE = "en-US-AvaNeural"
EDGE_RATE = "-10%"

if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))


def _term_id(word: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9]+", "-", word.strip()).strip("-").lower()
    return slug or "term"


def _display_word(item: dict) -> str:
    if item.get("word"):
        return str(item["word"])
    raw = str(item.get("match") or "")
    raw = raw.replace(r"\b", "")
    raw = re.sub(r"\\s\*", " ", raw)
    return re.sub(r"\\(.)", r"\1", raw)


def list_terms() -> list[dict]:
    if not GUIDE_JSON.is_file():
        return []
    guide = json.loads(GUIDE_JSON.read_text(encoding="utf-8"))
    rows = []
    seen = set()
    for item in guide.get("replacements") or []:
        if not isinstance(item, dict) or not item.get("speak"):
            continue
        word = _display_word(item)
        key = (word.strip().lower(), str(item.get("match") or "").lower())
        if key in seen:
            continue
        seen.add(key)
        rows.append(
            {
                "id": item.get("id") or "",
                "word": word,
                "speak": str(item.get("speak") or ""),
                "notes": str(item.get("notes") or ""),
            }
        )
    return rows


def _ffmpeg() -> str:
    if not FFMPEG or not Path(FFMPEG).is_file():
        raise RuntimeError("ffmpeg is not on PATH")
    return FFMPEG


def _to_wav(src: Path) -> Path:
    WORK.mkdir(parents=True, exist_ok=True)
    wav = WORK / f"{uuid.uuid4().hex}.wav"
    proc = subprocess.run(
        [
            _ffmpeg(),
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-i",
            str(src),
            "-ac",
            "1",
            "-ar",
            "16000",
            str(wav),
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0 or not wav.is_file() or wav.stat().st_size < 200:
        err = (proc.stderr or proc.stdout or "ffmpeg failed").strip()
        raise RuntimeError(err[:400])
    return wav


def _transcribe(wav: Path) -> str:
    if not VIDEO_PY.is_file():
        raise RuntimeError("tools/.venv-video is missing. Install the video venv first.")
    code = (
        "import sys; import mlx_whisper; "
        "r = mlx_whisper.transcribe(sys.argv[1], path_or_hf_repo='mlx-community/whisper-tiny-en-mlx'); "
        "print(' '.join(str(r.get('text') or '').split()).strip(' .'))"
    )
    proc = subprocess.run(
        [str(VIDEO_PY), "-c", code, str(wav)],
        capture_output=True,
        text=True,
        timeout=180,
    )
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "whisper failed").strip()
        raise RuntimeError(err[-400:])
    return (proc.stdout or "").strip()


def synthesize(speak: str) -> dict:
    text = (speak or "").strip()
    if not text:
        return {"ok": False, "error": "Nothing to say yet."}
    if not EDGE_TTS.is_file():
        return {"ok": False, "error": "edge-tts is missing in tools/.venv-video."}
    WORK.mkdir(parents=True, exist_ok=True)
    token = uuid.uuid4().hex
    mp3 = WORK / f"{token}.mp3"
    proc = subprocess.run(
        [
            str(EDGE_TTS),
            "--voice",
            VOICE,
            f"--rate={EDGE_RATE}",
            "--text",
            text,
            "--write-media",
            str(mp3),
        ],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if proc.returncode != 0 or not mp3.is_file():
        err = (proc.stderr or proc.stdout or "edge-tts failed").strip()
        return {"ok": False, "error": err[-400:]}
    return {"ok": True, "token": token, "preview": f"/api/speech/preview/{token}"}


def hear(word: str, upload) -> dict:
    word = (word or "").strip()
    if not word:
        return {"ok": False, "error": "Type a word first."}
    WORK.mkdir(parents=True, exist_ok=True)
    suffix = Path(getattr(upload, "filename", "") or "clip.webm").suffix or ".webm"
    raw = WORK / f"{uuid.uuid4().hex}{suffix}"
    upload.save(raw)
    try:
        wav = _to_wav(raw)
        heard = _transcribe(wav)
    except Exception as exc:
        return {"ok": False, "error": str(exc)}
    if not heard:
        return {"ok": False, "error": "Heard silence. Say the word again a bit louder."}
    existing = next((t for t in list_terms() if t["id"] == _term_id(word)), None)
    speak = heard
    preview = synthesize(speak)
    if not preview.get("ok"):
        return preview
    return {
        "ok": True,
        "word": word,
        "heard": heard,
        "speak": speak,
        "current": (existing or {}).get("speak") or "",
        "token": preview["token"],
        "preview": preview["preview"],
    }


def save_term(word: str, speak: str, heard: str = "") -> dict:
    word = (word or "").strip()
    speak = (speak or "").strip()
    if not word:
        return {"ok": False, "error": "Type a word first."}
    if not speak:
        return {"ok": False, "error": "How should the robot say it?"}
    from learn_construction_pronunciation import _upsert

    payload = _upsert(word, speak, heard)
    payload["word"] = word
    try:
        import construction_speech

        construction_speech.load_guide.cache_clear()
    except Exception:
        pass
    return {"ok": True, "term": {"id": payload["id"], "word": word, "speak": speak}}


def preview_file(token: str) -> Path | None:
    if not re.fullmatch(r"[0-9a-f]{32}", token or ""):
        return None
    path = WORK / f"{token}.mp3"
    return path if path.is_file() else None


def register(app) -> None:
    @app.get("/api/speech")
    def api_speech_list():
        return jsonify({"ok": True, "terms": list_terms()})

    @app.post("/api/speech/hear")
    def api_speech_hear():
        word = (request.form.get("word") or "").strip()
        upload = request.files.get("audio")
        if not upload:
            return jsonify({"ok": False, "error": "No recording."}), 400
        result = hear(word, upload)
        return jsonify(result), (200 if result.get("ok") else 400)

    @app.post("/api/speech/preview")
    def api_speech_preview():
        data = request.get_json(silent=True) or {}
        result = synthesize(str(data.get("speak") or ""))
        return jsonify(result), (200 if result.get("ok") else 400)

    @app.post("/api/speech/save")
    def api_speech_save():
        data = request.get_json(silent=True) or {}
        result = save_term(
            str(data.get("word") or ""),
            str(data.get("speak") or ""),
            str(data.get("heard") or ""),
        )
        return jsonify(result), (200 if result.get("ok") else 400)

    @app.get("/api/speech/preview/<token>")
    def api_speech_preview_file(token: str):
        path = preview_file(token)
        if not path:
            return jsonify({"ok": False, "error": "Preview expired."}), 404
        resp = send_file(path, mimetype="audio/mpeg", as_attachment=False, download_name="preview.mp3")
        resp.headers["Cache-Control"] = "no-store"
        return resp
