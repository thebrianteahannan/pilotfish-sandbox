#!/usr/bin/env python3
"""Apply docs/construction-narration-pronunciation.json to TTS speech text.

Display/transcript text stays unchanged. Only voiceover strings should pass
through ``for_speech``.
"""

from __future__ import annotations

import json
import re
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GUIDE_JSON = ROOT / "docs" / "construction-narration-pronunciation.json"


@lru_cache(maxsize=1)
def load_guide() -> dict:
    if not GUIDE_JSON.is_file():
        return {"replacements": [], "friendly_paths": [], "path_rules": {}}
    return json.loads(GUIDE_JSON.read_text(encoding="utf-8"))


def _speak_path_segments(path: str) -> str:
    text = path.strip().rstrip("/\\")
    text = re.sub(r"^file://", "", text, flags=re.I)
    windows = "\\" in text and "/" not in text
    sep = "\\" if windows else "/"
    parts = [p for p in text.split(sep) if p and p != "."]
    if not parts:
        return "the project folder"
    spoken: list[str] = []
    for p in parts:
        if re.fullmatch(r"[A-Za-z]:", p):
            spoken.append(p[0])
            continue
        spoken.append(p.replace("-", " ").replace("_", " "))
    return ", ".join(spoken)


def _rewrite_paths(text: str, guide: dict) -> str:
    out = text
    friends = sorted(
        guide.get("friendly_paths") or [],
        key=lambda x: len(str(x.get("match") or "")),
        reverse=True,
    )
    for item in friends:
        match = str(item.get("match") or "")
        speak = str(item.get("speak") or "")
        if match and speak:
            out = re.sub(re.escape(match), speak, out, flags=re.IGNORECASE)

    # Absolute unix paths (do not touch leftover lone slashes in prose)
    out = re.sub(
        r"(?<![A-Za-z0-9])/?(?:[A-Za-z0-9._-]+/){1,}[A-Za-z0-9._-]+/?",
        lambda m: _speak_path_segments(m.group(0)),
        out,
    )
    out = re.sub(
        r"(?:[A-Za-z]:\\)(?:[A-Za-z0-9._-]+\\)+[A-Za-z0-9._-]+",
        lambda m: _speak_path_segments(m.group(0)),
        out,
    )
    return out


def _rewrite_filename_tokens(text: str) -> str:
    out = text
    out = out.replace("{sourceFileName}", "source file name")
    out = out.replace("<timestamp>", "timestamp")
    # Pattern like: source file name_timestamp.dot… already partially expanded
    out = re.sub(
        r"(source file name)_(timestamp)",
        r"\1, underscore, \2",
        out,
        flags=re.I,
    )
    return out


def _apply_replacements(text: str, guide: dict) -> str:
    out = text
    for item in guide.get("replacements") or []:
        pattern = item.get("match") or ""
        if not pattern:
            continue
        flags = 0
        if "i" in str(item.get("flags") or ""):
            flags |= re.IGNORECASE
        speak_map = item.get("speak_map")
        if isinstance(speak_map, dict) and speak_map:

            def repl_map(m: re.Match[str], mapping=speak_map) -> str:
                raw = m.group(0)
                return str(
                    mapping.get(raw)
                    or mapping.get(raw.upper())
                    or mapping.get(raw.lower())
                    or raw
                )

            out = re.sub(pattern, repl_map, out, flags=flags)
            continue
        speak = item.get("speak")
        if speak is None:
            continue
        out = re.sub(pattern, str(speak), out, flags=flags)
    return out


def _rewrite_extensions(text: str) -> str:
    def repl(m: re.Match[str]) -> str:
        return " dot " + " ".join(m.group(1).upper())

    # Avoid rewriting domain-like tokens; only short file extensions
    return re.sub(r"\.([A-Za-z]{2,5})\b", repl, text)


def _split_demo_names(text: str) -> str:
    """Split CamelCase demo identifiers (CsvSftpDemo) for clearer TTS."""

    def split_camel(m: re.Match[str]) -> str:
        word = m.group(0)
        if len(word) < 6:
            return word
        if word.upper() == word or word.lower() == word:
            return word
        return re.sub(r"(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", " ", word)

    return re.sub(r"\b[A-Z][A-Za-z0-9]{5,}\b", split_camel, text)


def for_speech(text: str) -> str:
    """Rewrite display narration into TTS-friendly speech."""
    guide = load_guide()
    t = (text or "").strip()
    if not t:
        return t
    t = t.replace("\u201c", '"').replace("\u201d", '"').replace("\u2019", "'")
    t = t.replace("\u2014", " — ").replace("\u2192", " to ")
    t = re.sub(r"`([^`]+)`", r"\1", t)

    t = _rewrite_paths(t, guide)
    t = _rewrite_filename_tokens(t)
    t = _apply_replacements(t, guide)
    t = _rewrite_extensions(t)
    t = _split_demo_names(t)
    t = re.sub(r"\s+", " ", t).strip()
    t = t.replace("dot dot ", "dot ")
    return t
