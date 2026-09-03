#!/usr/bin/env python3
"""Record a narrated eiConsole walkthrough using the copied Swing driver.

Leaves the sibling PilotFish Swing Demo Auto project untouched.
Uses tools/swing-demo-auto + documents/eiconsole-walkthrough.yaml.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SWING = ROOT / "tools" / "swing-demo-auto"
AGENT_JAR = SWING / "target" / "swing-demo-auto-0.1.0-SNAPSHOT-agent.jar"


def _export():
    sys.path.insert(0, str(ROOT / "tools"))
    import export_construction_video as ev

    return ev


def find_script(demo: Path) -> Path:
    """Use the demo's walkthrough as-is. Do not regenerate — that wipes verbatim speech."""
    existing = demo / "documents" / "eiconsole-walkthrough.yaml"
    if existing.is_file():
        return existing
    sibling = SWING / "demos" / f"eiconsole-{demo.name}.yaml"
    if sibling.is_file():
        return sibling
    sys.path.insert(0, str(ROOT / "tools"))
    try:
        from generate_eiconsole_walkthrough import generate

        generate(demo)
    except Exception as exc:
        print(f"walkthrough generate skipped: {exc}")
    if existing.is_file():
        return existing
    raise SystemExit(f"No eiconsole-walkthrough.yaml under {demo / 'documents'}")


def ensure_agent() -> Path:
    src = SWING / "src"
    jar_mtime = AGENT_JAR.stat().st_mtime if AGENT_JAR.is_file() else 0.0
    stale = not AGENT_JAR.is_file() or any(
        p.stat().st_mtime > jar_mtime for p in src.rglob("*.java")
    )
    if stale:
        mvnw = SWING / "mvnw"
        proc = subprocess.run([str(mvnw), "-q", "package"], cwd=str(SWING))
        if proc.returncode != 0 or not AGENT_JAR.is_file():
            raise SystemExit("Failed to package tools/swing-demo-auto")
    return AGENT_JAR


def screen_device() -> str:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required to record eiConsole")
    proc = subprocess.run(
        [ffmpeg, "-f", "avfoundation", "-list_devices", "true", "-i", ""],
        capture_output=True,
        text=True,
    )
    text = (proc.stderr or "") + (proc.stdout or "")
    first = None
    for line in text.splitlines():
        lower = line.lower()
        if "capture screen" not in lower and "display" not in lower:
            continue
        indexes = re.findall(r"\[(\d+)\]", line)
        if not indexes:
            continue
        idx = indexes[-1]
        if first is None:
            first = idx
        if "capture screen 0" in lower:
            return idx
    return first or "4"


def start_capture(out_mov: Path, log_path: Path) -> subprocess.Popen:
    ffmpeg = shutil.which("ffmpeg")
    device = screen_device()
    out_mov.parent.mkdir(parents=True, exist_ok=True)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_fh = open(log_path, "w", encoding="utf-8")
    log_fh.write(f"device={device}\n")
    log_fh.flush()
    proc = subprocess.Popen(
        [
            ffmpeg,
            "-y",
            "-f",
            "avfoundation",
            "-capture_cursor",
            "1",
            "-framerate",
            "15",
            "-i",
            f"{device}:none",
            "-pix_fmt",
            "yuv420p",
            "-movflags",
            "+faststart",
            str(out_mov),
        ],
        stdout=log_fh,
        stderr=log_fh,
    )
    proc._ffmpeg_log = log_fh  # type: ignore[attr-defined]
    return proc


def _mvn_exec(args: list[str]) -> None:
    cmd = [
        str(SWING / "mvnw"),
        "-q",
        "exec:java",
        "-Dexec.arguments=" + ",".join(args),
    ]
    proc = subprocess.run(cmd, cwd=str(SWING))
    if proc.returncode != 0:
        raise SystemExit("eiConsole Swing walkthrough failed")


def show_about_dialog() -> None:
    """Open eiConsole → About so it's obvious the construction video finished."""
    script = """
tell application "System Events"
    if not (exists process "eiConsole") then return
    tell process "eiConsole"
        set frontmost to true
        delay 0.35
        click menu item "About eiConsole" of menu 1 of menu bar item "eiConsole" of menu bar 1
    end tell
end tell
"""
    proc = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "").strip()
        print(f"About dialog did not open: {err}", file=sys.stderr)
    else:
        print("Opened eiConsole About — construction video is done")


def quit_eiconsole() -> None:
    """Quit a leftover eiConsole so the next launch shows the splash on camera."""
    home = Path(os.environ.get("EICONSOLE_HOME") or "/Applications/eiConsole")
    app = home / "eiConsole.app"
    subprocess.run(
        ["osascript", "-e", f'tell application "{app}" to quit'],
        capture_output=True,
        text=True,
    )
    subprocess.run(
        ["osascript", "-e", 'tell application "eiConsole" to quit'],
        capture_output=True,
        text=True,
    )
    time.sleep(0.8)
    subprocess.run(["killall", "eiConsole"], capture_output=True, text=True)
    time.sleep(0.5)


def eip_container_name(demo: Path) -> str:
    """Compose often shortens the slug (hl7-interface-engine-demo → pf-hl7-interface-engine-pilotfish)."""
    compose = demo / "docker-compose.yml"
    if compose.is_file():
        for line in compose.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped.startswith("container_name:"):
                name = stripped.split(":", 1)[1].strip().strip("'\"")
                if name.endswith("-pilotfish") and "webui" not in name:
                    return name
    return f"pf-{demo.name}-pilotfish"


def pause_demo_eip(demo: Path) -> str | None:
    """Free the host LLP port so eiConsole Testing Mode can bind."""
    name = eip_container_name(demo)
    proc = subprocess.run(
        ["docker", "inspect", "-f", "{{.State.Running}}", name],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return None
    if proc.stdout.strip() == "true":
        subprocess.run(["docker", "stop", name], check=False)
        print(f"Stopped {name} so the host listener can bind", flush=True)
    return name


def resume_demo_eip(name: str | None) -> None:
    if not name:
        return
    subprocess.run(["docker", "start", name], check=False)
    print(f"Started {name}", flush=True)


def set_eiconsole_working_directory(demo: Path) -> None:
    eip_root = (demo / "eip-root").resolve()
    try:
        if str(ROOT / "tools") not in sys.path:
            sys.path.insert(0, str(ROOT / "tools"))
        from sandbox_control.hub_eiconsole import set_working_directory

        set_working_directory(eip_root)
    except Exception as exc:
        print(f"Working-directory prefs via hub failed ({exc})", flush=True)
    print("eiConsole working directory ->", eip_root, flush=True)


def launch_eiconsole() -> None:
    """Open eiConsole now so the splash is on camera before Maven attaches."""
    home = Path(os.environ.get("EICONSOLE_HOME") or "/Applications/eiConsole")
    app = home / "eiConsole.app"
    proc = subprocess.run(["open", "-a", str(app)], capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit(f"Could not open eiConsole: {(proc.stderr or proc.stdout or '').strip()}")
    print("Launched eiConsole for splash ->", app, flush=True)


def wait_eiconsole_visible(timeout_s: float = 8.0) -> None:
    """Wait until the splash window is up so capture does not start on the desktop."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        seen = subprocess.run(["pgrep", "-if", "eiConsole"], capture_output=True)
        if seen.returncode == 0:
            time.sleep(0.45)
            return
        time.sleep(0.12)
    print("eiConsole process not seen yet; recording anyway", flush=True)


def play_script(demo: Path, script: Path, timeline: Path) -> None:
    ensure_agent()
    _mvn_exec(
        [
            "--app",
            "eiconsole",
            "--eip-root",
            str(demo / "eip-root"),
            "--script",
            str(script),
            "--timeline",
            str(timeline),
            "--no-relaunch",
        ]
    )


def _yaml_steps(script: Path) -> list[dict]:
    try:
        import yaml  # type: ignore

        raw = yaml.safe_load(script.read_text(encoding="utf-8"))
        return list(raw.get("steps") or [])
    except Exception:
        steps: list[dict] = []
        current: dict | None = None
        for line in script.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped.startswith("- id:"):
                if current:
                    steps.append(current)
                current = {"id": stripped.split(":", 1)[1].strip()}
            elif current is not None and stripped.startswith("detail:"):
                current["detail"] = stripped.split(":", 1)[1].strip().strip('"')
            elif current is not None and stripped.startswith("dwell_ms:"):
                current["dwell_ms"] = int(stripped.split(":", 1)[1].strip())
        if current:
            steps.append(current)
        return steps


def synthesize_from_yaml(script: Path, work: Path, ev) -> tuple[list[dict], Path | None, Path]:
    try:
        import yaml  # type: ignore

        raw = yaml.safe_load(script.read_text(encoding="utf-8")) or {}
        steps = list(raw.get("steps") or [])
    except Exception:
        steps = _yaml_steps(script)
        raw = {"name": "timed", "steps": steps}

    wavs = []
    plans = []
    for i, step in enumerate(steps, start=1):
        raw_detail = str(step.get("detail") or "").strip()
        # Official YouTube / website-verbatim scripts: pronunciation only, no naturalizer.
        if raw_detail:
            from construction_speech import for_speech

            text = for_speech(raw_detail)
        else:
            text = ""
        floor = int(step.get("dwell_ms") or 0)
        wav = work / f"step_{i:02d}.wav"
        if text.strip():
            mp3 = work / f"step_{i:02d}.mp3"
            ev.synthesize_edge(text, mp3, voice="en-US-AvaNeural", edge_rate=ev.DEFAULT_EDGE_RATE)
            ev.media_to_wav(mp3, wav)
            speech_ms = ev.wav_duration_ms(wav)
            dwell = max(speech_ms + 180, floor, 500)
            full = work / f"step_{i:02d}_full.wav"
            extra = max(0, dwell - speech_ms)
            if extra:
                pad = work / f"step_{i:02d}_pad.wav"
                ev.build_silent_wav(pad, extra)
                ev.concat_wavs([wav, pad], full)
            else:
                full = wav
            wavs.append(full)
            plans.append({
                "id": step.get("id") or str(i),
                "detail": text,
                "dwell_ms": dwell,
                "speech_ms": speech_ms,
                "wav": str(wav),
                "full_wav": str(full),
            })
            step["speak"] = str(wav)
        else:
            dwell = max(floor, 200)
            silence = work / f"step_{i:02d}_silence.wav"
            ev.build_silent_wav(silence, dwell)
            wavs.append(silence)
            plans.append({
                "id": step.get("id") or str(i),
                "detail": "",
                "dwell_ms": dwell,
                "speech_ms": 0,
                "wav": None,
                "full_wav": str(silence),
            })
        step["dwell_ms"] = dwell
    from eiconsole_video_sync import write_timed_script

    timed = write_timed_script(script, steps, work / "timed-walkthrough.yaml")
    if not wavs:
        return plans, None, timed
    narration = work / "narration-concat.wav"
    ev.concat_wavs(wavs, narration)
    return plans, narration, timed


def prefer_26r1_home() -> None:
    """Record against 26R1 when it is installed alongside 24R1."""
    if os.environ.get("EICONSOLE_HOME"):
        return
    home_26 = Path("/Applications/eiConsole-26R1")
    if (home_26 / "eiConsole.app").is_dir():
        os.environ["EICONSOLE_HOME"] = str(home_26)
        print("EICONSOLE_HOME ->", home_26, flush=True)


def export_eiconsole(
    demo: Path,
    *,
    prepare_only: bool = False,
    section: str | None = None,
    from_id: str | None = None,
    to_id: str | None = None,
) -> int:
    ev = _export()
    prefer_26r1_home()
    if section or (from_id and to_id):
        from export_eiconsole_section import export_section

        return export_section(
            demo, sys.modules[__name__], ev, section=section, from_id=from_id, to_id=to_id
        )
    from construction_video_job import detect_eiconsole_version, utc_now

    eic_ver = detect_eiconsole_version()
    script = find_script(demo)
    out_mp4 = demo / "documents" / "construction-replay.mp4"
    os.environ["CONSTRUCTION_VIDEO_DEMO"] = str(demo.resolve())
    os.environ["SEND_MLLP"] = str(ROOT / "tools" / "send_mllp.py")
    ev.bump_webui_status(demo, "Preparing eiConsole walkthrough", phase="starting")
    work = Path(tempfile.mkdtemp(prefix="eiconsole-video-"))
    timeline = work / "timeline.json"
    try:
        plans, narration, timed = synthesize_from_yaml(script, work, ev)
        if prepare_only:
            (demo / "documents").mkdir(parents=True, exist_ok=True)
            (demo / "documents" / "eiconsole-timeline.json").write_text(
                json.dumps({"steps": plans}, indent=2) + "\n", encoding="utf-8"
            )
            print("Prepared eiConsole narration (no mp4)")
            return 0
        ev.bump_webui_status(demo, "Opening eiConsole on this interface", phase="recording")
        ensure_agent()
        set_eiconsole_working_directory(demo)
        quit_eiconsole()
        ev.bump_webui_status(demo, "Recording eiConsole splash and walkthrough", phase="recording")
        print(
            "Live speech is on — unmute to hear each line as the mouse moves. Ctrl+C stops the take.",
            flush=True,
        )
        launch_eiconsole()
        wait_eiconsole_visible()
        capture = demo / "documents" / "eiconsole-raw.mov"
        ffmpeg_log = demo / "documents" / "eiconsole-ffmpeg.log"
        rec = start_capture(capture, ffmpeg_log)
        from eiconsole_video_sync import (
            align_narration,
            content_end_ms,
            load_timeline,
            video_duration_ms,
            wait_capture_frames,
        )

        wait_capture_frames(ffmpeg_log, rec)
        if rec.poll() is not None:
            raise SystemExit(f"ffmpeg exited {rec.returncode}: {ffmpeg_log.read_text(encoding='utf-8', errors='replace')[-2000:]}")
        capture_ready_epoch_ms = int(time.time() * 1000)
        play_err = None
        paused_eip = pause_demo_eip(demo)
        try:
            play_script(demo, timed, timeline)
        except SystemExit as exc:
            play_err = exc
        finally:
            resume_demo_eip(paused_eip or eip_container_name(demo))
            rec.terminate()
            try:
                rec.wait(timeout=12)
            except subprocess.TimeoutExpired:
                rec.kill()
            log_fh = getattr(rec, "_ffmpeg_log", None)
            if log_fh:
                try:
                    log_fh.close()
                except Exception:
                    pass
        if not capture.is_file() or capture.stat().st_size < 1000:
            tail = ffmpeg_log.read_text(encoding="utf-8", errors="replace")[-2000:] if ffmpeg_log.is_file() else ""
            raise SystemExit(f"Screen capture of eiConsole produced no video\n{tail}")
        ev.bump_webui_status(demo, "Muxing narration onto eiConsole footage", phase="mux")
        docs = demo / "documents"
        docs.mkdir(parents=True, exist_ok=True)
        if timeline.is_file():
            shutil.copy2(timeline, docs / "eiconsole-timeline.json")
        if timed.is_file() and timed != script:
            shutil.copy2(timed, docs / "eiconsole-timed.yaml")
        tl_data = load_timeline(timeline)
        session_start = int((tl_data or {}).get("session_start_epoch_ms") or 0)
        if session_start > capture_ready_epoch_ms:
            preroll_ms = session_start - capture_ready_epoch_ms
        else:
            preroll_ms = 800
        print(f"splash/open preroll_ms={preroll_ms}", flush=True)
        if isinstance(tl_data, dict):
            tl_data["preroll_ms"] = preroll_ms
            (docs / "eiconsole-timeline.json").write_text(
                json.dumps(tl_data, indent=2) + "\n", encoding="utf-8"
            )
        video_ms = video_duration_ms(capture)
        aligned = align_narration(
            plans,
            tl_data,
            preroll_ms,
            video_ms,
            work,
            ev,
        )
        cut_ms = content_end_ms(tl_data, preroll_ms, plans)
        muxed = work / "muxed.mp4"
        if aligned and aligned.is_file():
            ev.mux_video_audio(capture, aligned, muxed, duration_ms=cut_ms)
        elif narration and narration.is_file():
            ev.mux_video_audio(capture, narration, muxed, duration_ms=cut_ms)
        else:
            shutil.copy2(capture, muxed)
        if str(ROOT / "tools") not in sys.path:
            sys.path.insert(0, str(ROOT / "tools"))
        from construction_official_open import open_intro_line, prepend_official_open
        from construction_speech import for_speech

        intro_mp3 = work / "open-intro.mp3"
        intro_wav = work / "open-intro.wav"
        ev.synthesize_edge(
            for_speech(open_intro_line(demo)),
            intro_mp3,
            voice="en-US-AvaNeural",
            edge_rate=ev.DEFAULT_EDGE_RATE,
        )
        ev.media_to_wav(intro_mp3, intro_wav)
        prepend_official_open(demo, muxed, out_mp4, work, intro_wav=intro_wav)
        try:
            sys.path.insert(0, str(ROOT / "tools"))
            from export_construction_transcript_pdf import export as export_transcript

            export_transcript(demo)
        except Exception as exc:
            print(f"WARNING: transcript export failed: {exc}", file=sys.stderr)
        print(out_mp4)
        ev.bump_webui_status(
            demo,
            "Construction video ready",
            phase="done",
            eiconsole_version=eic_ver,
            video_generated_at=utc_now(),
        )
        show_about_dialog()
        if play_err:
            print(f"Walkthrough stopped early (video kept): {play_err}", file=sys.stderr)
        return 0
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage: export_eiconsole_construction_video.py --root <demo> "
            "[--section name | --from-id ID --to-id ID] [--list-sections]"
        )
        return 2
    sys.path.insert(0, str(ROOT / "tools"))
    from demo_paths import require_demo

    root = None
    prepare = False
    section = None
    from_id = None
    to_id = None
    list_sections = False
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--root":
            root = args[i + 1]
            i += 2
        elif args[i] == "--prepare-only":
            prepare = True
            i += 1
        elif args[i] == "--section":
            section = args[i + 1]
            i += 2
        elif args[i] == "--from-id":
            from_id = args[i + 1]
            i += 2
        elif args[i] == "--to-id":
            to_id = args[i + 1]
            i += 2
        elif args[i] == "--list-sections":
            list_sections = True
            i += 1
        else:
            i += 1
    demo = require_demo(root)
    os.environ["CONSTRUCTION_VIDEO_DEMO"] = str(demo.resolve())
    if list_sections:
        from construction_video_sections import catalog, load_yaml, write_sections_json

        script = find_script(demo)
        write_sections_json(script)
        for item in catalog(load_yaml(script)):
            spans = ", ".join(f"{r['from']}…{r['to']}" for r in item["ranges"])
            print(f"{item['id']}\t{item['title']}\t{spans}")
        return 0
    return export_eiconsole(
        demo, prepare_only=prepare, section=section, from_id=from_id, to_id=to_id
    )


if __name__ == "__main__":
    raise SystemExit(main())
