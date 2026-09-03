#!/usr/bin/env python3
"""Named walkthrough sections and splice helpers for eiConsole construction videos.

Re-record one stretch (for example the Data Mapper) and drop it into the
existing construction-replay.mp4 without replaying the rest of the demo.
"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

LEAD_DWELL = {
    "double_click": 700,
    "wait_for": 350,
    "click": 180,
    "escape": 150,
    "drag": 280,
    "pause": 200,
}


def load_yaml(path: Path) -> dict:
    import yaml  # type: ignore

    raw = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(raw, dict):
        raise SystemExit(f"Walkthrough is not a mapping: {path}")
    return raw


def step_ids(script: dict) -> list[str]:
    return [str(s.get("id") or "") for s in (script.get("steps") or []) if s.get("id")]


def catalog(script: dict) -> list[dict]:
    """Return [{id, title, ranges:[{from,to}]}] from the walkthrough `sections` map."""
    raw = script.get("sections") or {}
    if not isinstance(raw, dict):
        return []
    out: list[dict] = []
    for key, spec in raw.items():
        if not isinstance(spec, dict):
            continue
        ranges = []
        if spec.get("parts"):
            for part in spec["parts"]:
                child = raw.get(part) or {}
                if child.get("from") and child.get("to"):
                    ranges.append({"from": str(child["from"]), "to": str(child["to"])})
        elif spec.get("from") and spec.get("to"):
            ranges.append({"from": str(spec["from"]), "to": str(spec["to"])})
        if ranges:
            out.append({
                "id": str(key),
                "title": str(spec.get("title") or key.replace("-", " ")).strip(),
                "ranges": ranges,
            })
    return out


def write_sections_json(script_path: Path, dest: Path | None = None) -> Path:
    dest = dest or (script_path.parent / "video-sections.json")
    items = [{"id": s["id"], "title": s["title"]} for s in catalog(load_yaml(script_path))]
    dest.write_text(json.dumps(items, indent=2) + "\n", encoding="utf-8")
    return dest


def resolve_ranges(
    script: dict,
    *,
    section: str | None = None,
    from_id: str | None = None,
    to_id: str | None = None,
) -> list[dict]:
    if from_id and to_id:
        return [{"from": from_id, "to": to_id}]
    if not section:
        raise SystemExit("Need --section or both --from-id and --to-id")
    for item in catalog(script):
        if item["id"] == section:
            return list(item["ranges"])
    known = ", ".join(s["id"] for s in catalog(script)) or "(none)"
    raise SystemExit(f"Unknown section {section!r}. Known: {known}")


def _index(ids: list[str], step_id: str) -> int:
    try:
        return ids.index(step_id)
    except ValueError as exc:
        raise SystemExit(f"Walkthrough has no step {step_id!r}") from exc


def in_ranges(step_id: str, ids: list[str], ranges: list[dict]) -> bool:
    idx = ids.index(step_id) if step_id in ids else -1
    if idx < 0:
        return False
    for rng in ranges:
        if _index(ids, rng["from"]) <= idx <= _index(ids, rng["to"]):
            return True
    return False


def last_needed_index(ids: list[str], ranges: list[dict]) -> int:
    return max(_index(ids, rng["to"]) for rng in ranges)


def write_play_yaml(script: dict, ranges: list[dict], dest: Path) -> Path:
    """Lead-in (silent, short) + the named ranges. Drop everything after the last range."""
    import yaml  # type: ignore

    ids = step_ids(script)
    cutoff = last_needed_index(ids, ranges)
    play_steps: list[dict] = []
    for i, step in enumerate(script.get("steps") or []):
        if i > cutoff:
            break
        row = {k: v for k, v in dict(step).items() if v is not None}
        sid = str(row.get("id") or "")
        if not in_ranges(sid, ids, ranges):
            action = str(row.get("action") or "click")
            row["detail"] = ""
            row.pop("speak", None)
            row["dwell_ms"] = int(LEAD_DWELL.get(action, 200))
        play_steps.append(row)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(
        yaml.safe_dump(
            {"name": script.get("name") or "section-play", "steps": play_steps},
            sort_keys=False,
            allow_unicode=True,
        ),
        encoding="utf-8",
    )
    return dest


def events_by_id(timeline: dict | None) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for event in (timeline or {}).get("steps") or []:
        sid = str(event.get("id") or "")
        if sid:
            out[sid] = event
    return out


def range_session_window(timeline: dict | None, rng: dict) -> tuple[int, int]:
    by_id = events_by_id(timeline)
    start_ev = by_id.get(rng["from"])
    if not start_ev:
        raise SystemExit(f"Timeline is missing section start {rng['from']!r}")
    start = int(start_ev.get("started_at_ms") or 0)
    end = start
    ids = [str(e.get("id") or "") for e in (timeline or {}).get("steps") or []]
    lo = _index(ids, rng["from"]) if rng["from"] in ids else 0
    hi = _index(ids, rng["to"]) if rng["to"] in ids else lo
    for event in (timeline or {}).get("steps") or []:
        sid = str(event.get("id") or "")
        if sid not in ids:
            continue
        idx = ids.index(sid)
        if lo <= idx <= hi:
            end = max(end, int(event.get("ended_at_ms") or 0))
    if end <= start:
        raise SystemExit(f"Empty timeline window for {rng['from']}…{rng['to']}")
    return start, end


def infer_body_layout(mp4: Path, timeline: dict) -> dict:
    """Find official-card padding and preroll on an existing wrapped construction-replay.mp4."""
    from construction_official_open import CLOSE_MS
    from eiconsole_video_sync import video_duration_ms

    mp4_ms = video_duration_ms(mp4)
    spoken_end = 0
    for event in timeline.get("steps") or []:
        if event.get("skipped"):
            continue
        spoken_end = max(spoken_end, int(event.get("ended_at_ms") or 0))
    stored = int(timeline.get("preroll_ms") or 0)
    candidates = [p for p in (stored, 5400, 800) if p > 0]
    for preroll in candidates:
        body = preroll + spoken_end + 800
        open_ms = mp4_ms - CLOSE_MS - body
        if 3500 <= open_ms <= 22000:
            return {
                "open_ms": int(open_ms),
                "close_ms": CLOSE_MS,
                "preroll_ms": int(preroll),
                "body_ms": int(body),
                "mp4_ms": mp4_ms,
            }
    from construction_official_open import PRODUCT_MS

    open_ms = PRODUCT_MS
    preroll = mp4_ms - CLOSE_MS - open_ms - spoken_end - 800
    if preroll < 0:
        raise SystemExit(
            f"Cannot locate the walkthrough body in {mp4} "
            f"(duration {mp4_ms}ms, last step {spoken_end}ms)"
        )
    return {
        "open_ms": int(open_ms),
        "close_ms": CLOSE_MS,
        "preroll_ms": int(preroll),
        "body_ms": int(mp4_ms - open_ms - CLOSE_MS),
        "mp4_ms": mp4_ms,
    }


def extract_span(src: Path, start_ms: int, end_ms: int, dest: Path, *, audio: bool) -> Path:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required to splice a construction-video section")
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        ffmpeg,
        "-y",
        "-i",
        str(src),
        "-ss",
        f"{max(0, start_ms) / 1000.0:.3f}",
        "-to",
        f"{max(start_ms + 40, end_ms) / 1000.0:.3f}",
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
    ]
    if audio:
        cmd.extend(["-c:a", "aac", "-b:a", "160k", "-ar", "44100", "-ac", "2"])
    else:
        cmd.append("-an")
    cmd.extend(["-movflags", "+faststart", str(dest)])
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0 or not dest.is_file() or dest.stat().st_size < 500:
        raise SystemExit((proc.stderr or "ffmpeg extract failed")[-1600:])
    return dest


def video_wh(path: Path) -> tuple[int, int]:
    proc = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=width,height",
            "-of",
            "csv=p=0",
            str(path),
        ],
        capture_output=True,
        text=True,
    )
    line = (proc.stdout or "").strip().split(",")
    if proc.returncode != 0 or len(line) < 2:
        raise SystemExit(f"ffprobe size failed for {path}")
    return int(line[0]), int(line[1])


def concat_mp4s(parts: list[Path], dest: Path) -> Path:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required to splice a construction-video section")
    if not parts:
        raise SystemExit("Nothing to concat")
    dest.parent.mkdir(parents=True, exist_ok=True)
    width, height = video_wh(parts[0])
    cmd = [ffmpeg, "-y"]
    for part in parts:
        cmd.extend(["-i", str(part)])
    n = len(parts)
    filters = []
    for i in range(n):
        filters.append(
            f"[{i}:v:0]scale={width}:{height}:force_original_aspect_ratio=decrease,"
            f"pad={width}:{height}:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=15[v{i}]"
        )
        filters.append(f"[{i}:a:0]aformat=sample_rates=44100:channel_layouts=stereo[a{i}]")
    links = "".join(f"[v{i}][a{i}]" for i in range(n))
    cmd.extend(
        [
            "-filter_complex",
            ";".join(filters) + f";{links}concat=n={n}:v=1:a=1[v][a]",
            "-map",
            "[v]",
            "-map",
            "[a]",
            "-c:v",
            "libx264",
            "-pix_fmt",
            "yuv420p",
            "-c:a",
            "aac",
            "-b:a",
            "160k",
            "-ar",
            "44100",
            "-ac",
            "2",
            "-movflags",
            "+faststart",
            str(dest),
        ]
    )
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0 or not dest.is_file():
        raise SystemExit((proc.stderr or "ffmpeg concat failed")[-1600:])
    return dest


def remap_section_timeline(new_timeline: dict, rng: dict) -> dict:
    """Shift section events so the first click is t=0 inside the replacement clip."""
    start, _end = range_session_window(new_timeline, rng)
    steps = []
    ids = [str(e.get("id") or "") for e in (new_timeline.get("steps") or [])]
    lo = _index(ids, rng["from"])
    hi = _index(ids, rng["to"])
    for event in new_timeline.get("steps") or []:
        sid = str(event.get("id") or "")
        if sid not in ids:
            continue
        idx = ids.index(sid)
        if not (lo <= idx <= hi):
            continue
        row = dict(event)
        row["started_at_ms"] = max(0, int(event.get("started_at_ms") or 0) - start)
        row["ended_at_ms"] = max(row["started_at_ms"], int(event.get("ended_at_ms") or 0) - start)
        steps.append(row)
    return {"name": new_timeline.get("name") or "section", "steps": steps}


def merge_timeline(
    old: dict,
    new: dict,
    ranges: list[dict],
    *,
    preroll_ms: int,
) -> dict:
    """Replace section events; shift later events by the duration delta of each range."""
    old_steps = list(old.get("steps") or [])
    ids = [str(e.get("id") or "") for e in old_steps]
    new_by = events_by_id(new)
    deltas: list[tuple[int, int]] = []
    for rng in ranges:
        old_start, old_end = range_session_window(old, rng)
        new_start, new_end = range_session_window(new, rng)
        deltas.append((old_end, (new_end - new_start) - (old_end - old_start)))

    def shift_after(t: int) -> int:
        return sum(delta for end, delta in deltas if t >= end)

    merged: list[dict] = []
    for event in old_steps:
        sid = str(event.get("id") or "")
        idx = ids.index(sid) if sid in ids else -1
        replaced = False
        for rng in ranges:
            lo = _index(ids, rng["from"])
            hi = _index(ids, rng["to"])
            if lo <= idx <= hi:
                fresh = new_by.get(sid)
                if not fresh:
                    break
                old_start, _old_end = range_session_window(old, rng)
                new_start, _new_end = range_session_window(new, rng)
                row = dict(fresh)
                row["started_at_ms"] = old_start + (
                    int(fresh.get("started_at_ms") or 0) - new_start
                )
                row["ended_at_ms"] = old_start + (
                    int(fresh.get("ended_at_ms") or 0) - new_start
                )
                merged.append(row)
                replaced = True
                break
        if replaced:
            continue
        row = dict(event)
        adj = shift_after(int(event.get("started_at_ms") or 0))
        row["started_at_ms"] = int(event.get("started_at_ms") or 0) + adj
        row["ended_at_ms"] = int(event.get("ended_at_ms") or 0) + adj
        merged.append(row)
    out = dict(old)
    out["steps"] = merged
    out["preroll_ms"] = int(preroll_ms)
    return out


def splice_body(
    body: Path,
    new_raw: Path,
    old_timeline: dict,
    new_timeline: dict,
    ranges: list[dict],
    *,
    old_preroll: int,
    new_preroll: int,
    work: Path,
    ev,
    section_plans: list[dict],
) -> Path:
    """Keep the existing body audio/video except the named ranges."""
    from eiconsole_video_sync import align_narration, video_duration_ms

    body_ms = video_duration_ms(body)
    cursor = 0
    parts: list[Path] = []
    for i, rng in enumerate(ranges):
        old_start, old_end = range_session_window(old_timeline, rng)
        new_start, new_end = range_session_window(new_timeline, rng)
        keep_to = old_preroll + old_start
        if keep_to > cursor + 40:
            parts.append(extract_span(body, cursor, keep_to, work / f"keep-{i}.mp4", audio=True))
        clip_v = extract_span(
            new_raw,
            new_preroll + new_start,
            new_preroll + new_end,
            work / f"sec-{i}.mov",
            audio=False,
        )
        clip_tl = remap_section_timeline(new_timeline, rng)
        audio_dir = work / f"sec-{i}-audio"
        audio_dir.mkdir(parents=True, exist_ok=True)
        wav = align_narration(
            section_plans,
            clip_tl,
            0,
            video_duration_ms(clip_v),
            audio_dir,
            ev,
        )
        muxed = work / f"sec-{i}.mp4"
        ev.mux_video_audio(clip_v, wav, muxed)
        parts.append(muxed)
        cursor = old_preroll + old_end
    if cursor < body_ms - 40:
        parts.append(extract_span(body, cursor, body_ms, work / "keep-tail.mp4", audio=True))
    dest = work / "spliced-body.mp4"
    return concat_mp4s(parts, dest)
