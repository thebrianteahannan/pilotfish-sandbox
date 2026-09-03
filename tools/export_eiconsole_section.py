"""Re-record named eiConsole walkthrough sections and splice them into the existing mp4."""

from __future__ import annotations

import json
import shutil
import tempfile
import time
from pathlib import Path


def export_section(
    demo: Path,
    eic,
    ev,
    *,
    section: str | None = None,
    from_id: str | None = None,
    to_id: str | None = None,
) -> int:
    from construction_official_open import open_intro_line, prepend_official_open
    from construction_speech import for_speech
    from construction_video_job import detect_eiconsole_version, utc_now
    from construction_video_sections import (
        infer_body_layout,
        load_yaml,
        merge_timeline,
        resolve_ranges,
        splice_body,
        write_play_yaml,
        write_sections_json,
    )
    from eiconsole_video_sync import load_timeline, wait_capture_frames
    from export_construction_transcript_pdf import export as export_transcript

    script = eic.find_script(demo)
    raw = load_yaml(script)
    ranges = resolve_ranges(raw, section=section, from_id=from_id, to_id=to_id)
    write_sections_json(script)
    docs = demo / "documents"
    out_mp4 = docs / "construction-replay.mp4"
    old_tl_path = docs / "eiconsole-timeline.json"
    if not out_mp4.is_file() or not old_tl_path.is_file():
        raise SystemExit(
            "Section remake needs an existing construction-replay.mp4 and eiconsole-timeline.json"
        )
    old_tl = load_timeline(old_tl_path)
    if not old_tl:
        raise SystemExit(f"Cannot read {old_tl_path}")
    layout = infer_body_layout(out_mp4, old_tl)
    label = section or f"{from_id}…{to_id}"
    eic_ver = detect_eiconsole_version()
    ev.bump_webui_status(demo, f"Re-recording {label}", phase="starting")
    prev = docs / "construction-replay.prev.mp4"
    shutil.copy2(out_mp4, prev)
    work = Path(tempfile.mkdtemp(prefix="eiconsole-section-"))
    try:
        from construction_video_sections import extract_span

        body = extract_span(
            out_mp4,
            layout["open_ms"],
            layout["mp4_ms"] - layout["close_ms"],
            work / "existing-body.mp4",
            audio=True,
        )
        play_yaml = write_play_yaml(raw, ranges, work / "section-play.yaml")
        plans, _narration, timed = eic.synthesize_from_yaml(play_yaml, work, ev)
        ev.bump_webui_status(demo, f"Recording {label} in eiConsole", phase="recording")
        print(
            f"Re-recording section {label} — unmute to hear those lines. Ctrl+C stops the take.",
            flush=True,
        )
        eic.ensure_agent()
        eic.set_eiconsole_working_directory(demo)
        eic.quit_eiconsole()
        eic.launch_eiconsole()
        eic.wait_eiconsole_visible()
        capture = docs / "eiconsole-section-raw.mov"
        ffmpeg_log = docs / "eiconsole-section-ffmpeg.log"
        rec = eic.start_capture(capture, ffmpeg_log)
        wait_capture_frames(ffmpeg_log, rec)
        if rec.poll() is not None:
            raise SystemExit(
                f"ffmpeg exited {rec.returncode}: "
                f"{ffmpeg_log.read_text(encoding='utf-8', errors='replace')[-2000:]}"
            )
        capture_ready = int(time.time() * 1000)
        timeline = work / "timeline.json"
        play_err = None
        try:
            eic.play_script(demo, timed, timeline)
        except SystemExit as exc:
            play_err = exc
        finally:
            rec.terminate()
            try:
                rec.wait(timeout=12)
            except Exception:
                rec.kill()
            log_fh = getattr(rec, "_ffmpeg_log", None)
            if log_fh:
                try:
                    log_fh.close()
                except Exception:
                    pass
        if not capture.is_file() or capture.stat().st_size < 1000:
            raise SystemExit("Section capture produced no video")
        if timeline.is_file():
            shutil.copy2(timeline, docs / "eiconsole-section-timeline.json")
        new_tl = load_timeline(timeline)
        if not new_tl:
            raise SystemExit("Section walkthrough wrote no timeline")
        session_start = int(new_tl.get("session_start_epoch_ms") or 0)
        new_preroll = session_start - capture_ready if session_start > capture_ready else 800
        print(f"section preroll_ms={new_preroll} splice {label}", flush=True)
        ev.bump_webui_status(demo, f"Splicing {label} into the existing video", phase="mux")
        spliced = splice_body(
            body,
            capture,
            old_tl,
            new_tl,
            ranges,
            old_preroll=layout["preroll_ms"],
            new_preroll=new_preroll,
            work=work,
            ev=ev,
            section_plans=plans,
        )
        intro_mp3 = work / "open-intro.mp3"
        intro_wav = work / "open-intro.wav"
        ev.synthesize_edge(
            for_speech(open_intro_line(demo)),
            intro_mp3,
            voice="en-US-AvaNeural",
            edge_rate=ev.DEFAULT_EDGE_RATE,
        )
        ev.media_to_wav(intro_mp3, intro_wav)
        prepend_official_open(demo, spliced, out_mp4, work, intro_wav=intro_wav)
        shutil.copy2(spliced, docs / "eiconsole-body.mp4")
        merged = merge_timeline(old_tl, new_tl, ranges, preroll_ms=layout["preroll_ms"])
        old_tl_path.write_text(json.dumps(merged, indent=2) + "\n", encoding="utf-8")
        if timed.is_file():
            shutil.copy2(timed, docs / "eiconsole-section-timed.yaml")
        try:
            export_transcript(demo)
        except Exception as exc:
            print(f"WARNING: transcript export failed: {exc}", flush=True)
        ev.bump_webui_status(
            demo,
            f"Updated {label} in the construction video",
            phase="done",
            eiconsole_version=eic_ver,
            video_generated_at=utc_now(),
        )
        print(out_mp4)
        if play_err:
            print(f"Section walkthrough stopped early (splice kept): {play_err}", flush=True)
        return 0
    except Exception:
        if prev.is_file():
            shutil.copy2(prev, out_mp4)
        raise
    finally:
        shutil.rmtree(work, ignore_errors=True)
