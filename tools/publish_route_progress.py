#!/usr/bin/env python3
"""Publish progressive route snapshots so the Web UI diagram grows while building.

After each meaningful module addition (not only when a route is finished):

  python3 tools/publish_route_progress.py \\
    --root Clients/Demos/edi-276-277-claim-status \\
    --route "2 - Emit 277 And Bucket" \\
    --message "Route 2: added Conditional Node Router"

Replay construction theater (truncate processors, convert, pause):

  python3 tools/publish_route_progress.py \\
    --root Clients/Demos/edi-276-277-claim-status \\
    --route "1 - Intake And Lookup" \\
    --replay-stages --pause 3
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import shutil
import sys
import time
from datetime import datetime, timezone
from demo_paths import require_demo
from pathlib import Path
from xml.etree import ElementTree as ET


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def clear_replay(root: Path) -> None:
    replay = root / "documents" / "build-replay"
    if replay.exists():
        shutil.rmtree(replay)
    replay.mkdir(parents=True, exist_ok=True)
    (replay / "steps").mkdir(parents=True, exist_ok=True)
    manifest = {"version": 1, "title": "Interface construction replay", "steps": [], "updated_at": utc_now()}
    (replay / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Cleared {replay}")


def snapshot_route_dir(root: Path, route_dir: Path) -> Path:
    twin = root / "pilotfish" / "demo-eip-root" / "routes" / route_dir.name
    if (twin / "route.v2.xml").is_file():
        return twin
    return route_dir


def record_replay_step(
    root: Path,
    route_dir: Path,
    *,
    route_id: str,
    message: str,
    modules: int | None = None,
) -> int:
    """Persist a diagram snapshot under documents/build-replay/ for UI Replay."""
    docs = root / "documents"
    replay = docs / "build-replay"
    steps_dir = replay / "steps"
    steps_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = replay / "manifest.json"
    manifest: dict = {"version": 1, "title": "Interface construction replay", "steps": []}
    if manifest_path.is_file():
        try:
            loaded = json.loads(manifest_path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                manifest.update(loaded)
        except json.JSONDecodeError:
            pass
    steps = list(manifest.get("steps") or [])
    seq = len(steps) + 1
    step_id = f"{seq:04d}"
    dest = steps_dir / step_id
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)

    src = snapshot_route_dir(root, route_dir)
    v2 = src / "route.v2.xml"
    if not v2.is_file():
        print(f"WARNING: no route.v2.xml to record at {src}", file=sys.stderr)
        return seq
    shutil.copy2(v2, dest / "route.v2.xml")
    groups = src / "diagram-groups.json"
    if groups.is_file():
        shutil.copy2(groups, dest / "diagram-groups.json")
    modules_src = src / "modules"
    if modules_src.is_dir():
        shutil.copytree(modules_src, dest / "modules")

    entry = {
        "id": step_id,
        "seq": seq,
        "route_id": route_id,
        "route_name": route_dir.name,
        "message": message,
        "modules_visible": modules,
        "recorded_at": utc_now(),
    }
    steps.append(entry)
    manifest["steps"] = steps
    manifest["updated_at"] = utc_now()
    manifest["version"] = 1
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Recorded replay step {step_id}: {message}")
    # Also narrate for Experience tab (best-effort)
    try:
        import subprocess

        subprocess.run(
            [
                "python3",
                str(Path(__file__).resolve().parent / "log_build_experience.py"),
                "--root",
                str(root),
                "--kind",
                "route",
                "--title",
                message,
                "--summary",
                f"Published diagram snapshot for {route_dir.name}",
                "--route-id",
                route_id,
                "--replay-step",
                step_id,
            ],
            check=False,
            capture_output=True,
        )
    except Exception as exc:
        print(f"WARNING: experience log skipped ({exc})", file=sys.stderr)
    return seq


def local(tag: str) -> str:
    return tag.split("}")[-1] if "}" in tag else tag


def find_child(el: ET.Element | None, name: str) -> ET.Element | None:
    if el is None:
        return None
    for child in el:
        if local(child.tag) == name:
            return child
    return None


def find_all(el: ET.Element | None, name: str) -> list[ET.Element]:
    if el is None:
        return []
    return [c for c in el if local(c.tag) == name]


def slug_route(name: str) -> str:
    return (
        name.strip()
        .lower()
        .replace(" - ", "-")
        .replace(" ", "-")
        .replace("_", "-")
    )


def resolve_route_dirs(root: Path, route_name: str) -> list[Path]:
    """Prefer eip-root interface routes; also include demo-eip-root twin when present."""
    found: list[Path] = []
    for routes_dir in root.glob("eip-root/interfaces/*/routes"):
        cand = routes_dir / route_name
        if (cand / "route.xml").is_file():
            found.append(cand)
    demo = root / "pilotfish" / "demo-eip-root" / "routes" / route_name
    if (demo / "route.xml").is_file() and demo not in found:
        found.append(demo)
    if not found:
        # allow passing a folder name under demo-eip-root only
        for routes_dir in root.glob("**/routes"):
            if "node_modules" in routes_dir.parts:
                continue
            cand = routes_dir / route_name
            if (cand / "route.xml").is_file():
                found.append(cand)
                break
    return found


def load_converter(root: Path):
    path = root / "tools" / "convert_routes_to_v2.py"
    if not path.is_file():
        # fall back to nearest demo convert script
        for alt in sorted(
            Path(__file__).resolve().parents[1].glob("Clients/Demos/**/tools/convert_routes_to_v2.py")
        ):
            path = alt
            break
    if not path.is_file():
        raise SystemExit("No convert_routes_to_v2.py found")
    spec = importlib.util.spec_from_file_location("convert_routes_to_v2", path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"Cannot load {path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def formats_dir_for(route_dir: Path, root: Path) -> Path:
    # eip-root/interfaces/<iface>/routes/<route> → formats sibling
    if route_dir.parent.name == "routes" and (route_dir.parent.parent / "formats").is_dir():
        return route_dir.parent.parent / "formats"
    iface = root / "eip-root" / "interfaces"
    for d in iface.glob("*/formats"):
        return d
    return root / "pilotfish" / "demo-eip-root" / "formats"


def convert_route(root: Path, route_dir: Path) -> int:
    mod = load_converter(root)
    fmt = formats_dir_for(route_dir, root)
    mod.Converter(route_dir, fmt).convert()
    # sync twin under demo-eip-root when converting eip-root
    demo_twin = root / "pilotfish" / "demo-eip-root" / "routes" / route_dir.name
    if route_dir.resolve() != demo_twin.resolve() and demo_twin.parent.is_dir():
        demo_twin.mkdir(parents=True, exist_ok=True)
        for name in ("route.xml", "route.v2.xml", "diagram-groups.json"):
            src = route_dir / name
            if src.is_file():
                shutil.copy2(src, demo_twin / name)
        # copy xslt and other siblings except modules (rebuilt below)
        for src in route_dir.iterdir():
            if src.name in ("modules", "route.xml", "route.v2.xml", "diagram-groups.json"):
                continue
            if src.is_file():
                shutil.copy2(src, demo_twin / src.name)
        # convert again into demo tree so modules/ ids match v2
        if (demo_twin / "route.xml").is_file():
            demo_fmt = formats_dir_for(demo_twin, root)
            if not demo_fmt.is_dir():
                demo_fmt = fmt
            mod.Converter(demo_twin, demo_fmt).convert()
    return len(list((route_dir / "modules").glob("*.xml"))) if (route_dir / "modules").is_dir() else 0


def update_status(root: Path, *, route_id: str, message: str, modules: int | None = None) -> None:
    docs = root / "documents"
    docs.mkdir(parents=True, exist_ok=True)
    path = docs / "build-status.json"
    data: dict = {"version": 1, "active": True, "phase": "routes", "routes_ready": []}
    if path.is_file():
        try:
            loaded = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                data.update(loaded)
        except json.JSONDecodeError:
            pass
    data["active"] = True
    data["phase"] = "routes"
    data["current_route"] = route_id
    data["message"] = message
    ready = list(data.get("routes_ready") or [])
    if route_id and route_id not in ready:
        ready.append(route_id)
    data["routes_ready"] = ready
    if modules is not None:
        data["modules_visible"] = modules
    data["updated_at"] = utc_now()
    data["version"] = 1
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(path)
    print(json.dumps(data, indent=2))


def processor_count(route_xml: Path) -> int:
    root = ET.parse(route_xml).getroot()
    n = 0
    for wrap in root.iter():
        if local(wrap.tag) == "Processors":
            n += len(find_all(wrap, "Processor"))
    return n


def truncate_processors(full_xml: str, keep: int) -> str:
    """Keep the first `keep` Processor elements (document order) under Processors wrappers."""
    root = ET.fromstring(full_xml)
    seen = 0
    for wrap in list(root.iter()):
        if local(wrap.tag) != "Processors":
            continue
        for proc in list(find_all(wrap, "Processor")):
            if seen < keep:
                seen += 1
            else:
                wrap.remove(proc)
    # If keep==0, still leave listener+transport(+router) so the diagram is non-empty
    return ET.tostring(root, encoding="unicode")


def stage_messages(route_name: str, keep: int, total: int, last_name: str | None) -> str:
    if keep <= 0:
        return f"{route_name}: listener + transports scaffold"
    if keep >= total:
        return f"{route_name}: complete ({total} processors)"
    label = last_name or f"processor {keep}"
    return f"{route_name}: adding “{label}” ({keep}/{total})"


def last_kept_processor_name(full_xml: str, keep: int) -> str | None:
    if keep <= 0:
        return None
    root = ET.fromstring(full_xml)
    seen = 0
    for wrap in root.iter():
        if local(wrap.tag) != "Processors":
            continue
        for proc in find_all(wrap, "Processor"):
            seen += 1
            if seen == keep:
                return proc.attrib.get("name") or "Processor"
    return None


def replay_stages(root: Path, route_dir: Path, pause: float) -> None:
    route_xml = route_dir / "route.xml"
    full = route_xml.read_text(encoding="utf-8")
    backup = route_dir / "route.xml.full.bak"
    backup.write_text(full, encoding="utf-8")
    total = processor_count(route_xml)
    route_id = slug_route(route_dir.name)
    try:
        # Stage 0: no processors
        stages = list(range(0, total + 1))
        for keep in stages:
            staged = truncate_processors(full, keep)
            route_xml.write_text(staged, encoding="utf-8")
            # Keep twin route.xml in sync before convert
            twin = root / "pilotfish" / "demo-eip-root" / "routes" / route_dir.name / "route.xml"
            if twin.parent.is_dir() and twin.resolve() != route_xml.resolve():
                twin.write_text(staged, encoding="utf-8")
            modules = convert_route(root, route_dir)
            label = last_kept_processor_name(full, keep)
            msg = stage_messages(route_dir.name, keep, total, label)
            update_status(root, route_id=route_id, message=msg, modules=modules)
            record_replay_step(root, route_dir, route_id=route_id, message=msg, modules=modules)
            print(f"=== stage {keep}/{total}: {msg}")
            if keep < total:
                time.sleep(max(0.0, pause))
    finally:
        route_xml.write_text(backup.read_text(encoding="utf-8"), encoding="utf-8")
        modules = convert_route(root, route_dir)
        final_msg = f"{route_dir.name}: complete — diagram live"
        update_status(
            root,
            route_id=route_id,
            message=final_msg,
            modules=modules,
        )
        record_replay_step(root, route_dir, route_id=route_id, message=final_msg, modules=modules)
        backup.unlink(missing_ok=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="Demo root")
    ap.add_argument("--route", help='Route folder name, e.g. "1 - Intake And Lookup"')
    ap.add_argument("--message", help="Banner message (single publish)")
    ap.add_argument("--replay-stages", action="store_true", help="Publish truncated stages for theater")
    ap.add_argument("--pause", type=float, default=3.0, help="Seconds between replay stages")
    ap.add_argument(
        "--clear-replay",
        action="store_true",
        help="Clear documents/build-replay/ before recording (or alone to wipe)",
    )
    ap.add_argument(
        "--no-record",
        action="store_true",
        help="Do not append to documents/build-replay/",
    )
    args = ap.parse_args()

    root = require_demo(args.root)
    if args.clear_replay:
        clear_replay(root)
        if not args.route:
            return 0

    if not args.route:
        print("--route is required unless using --clear-replay alone", file=sys.stderr)
        return 1

    dirs = resolve_route_dirs(root, args.route)
    if not dirs:
        print(f"No route.xml found for {args.route!r} under {root}", file=sys.stderr)
        return 1

    # Prefer eip-root copy as source of truth when both exist
    route_dir = dirs[0]
    for d in dirs:
        if "eip-root" in d.parts and "demo-eip-root" not in d.parts:
            route_dir = d
            break

    if args.replay_stages:
        replay_stages(root, route_dir, args.pause)
        return 0

    modules = convert_route(root, route_dir)
    route_id = slug_route(route_dir.name)
    msg = args.message or f"{route_dir.name}: published ({modules} modules)"
    update_status(root, route_id=route_id, message=msg, modules=modules)
    if not args.no_record:
        record_replay_step(root, route_dir, route_id=route_id, message=msg, modules=modules)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
