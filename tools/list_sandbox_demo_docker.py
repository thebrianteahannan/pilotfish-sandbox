#!/usr/bin/env python3
"""List Compose projects / running containers for Sandbox demos under Clients/.

Helps manage idle demos: which stacks are up, how many containers, project dirs.
Does not stop or remove anything — report only unless --check-unused.

Usage (from repo root or any cwd):
  python3 tools/list_sandbox_demo_docker.py
  python3 tools/list_sandbox_demo_docker.py --json
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLIENTS = ROOT / "Clients"


def run(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def compose_ls() -> list[dict]:
    raw = run(["docker", "compose", "ls", "--format", "json"])
    if not raw.strip():
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


def under_clients(config_files: str | None) -> bool:
    if not config_files:
        return False
    for part in config_files.split(","):
        p = Path(part.strip()).resolve()
        try:
            p.relative_to(CLIENTS.resolve())
            return True
        except ValueError:
            continue
    return False


def demo_containers() -> list[dict]:
    raw = run(
        [
            "docker",
            "ps",
            "--format",
            "{{json .}}",
        ]
    )
    out = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        name = row.get("Names") or ""
        image = row.get("Image") or ""
        # Sandbox demos use pf-* container names and/or compose under Clients/
        if name.startswith("pf-") or "pilotfish" in image.lower():
            out.append(
                {
                    "name": name,
                    "image": image,
                    "status": row.get("Status") or "",
                    "ports": row.get("Ports") or "",
                }
            )
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", action="store_true", help="Machine-readable JSON")
    args = ap.parse_args()

    projects = [p for p in compose_ls() if under_clients(p.get("ConfigFiles"))]
    containers = demo_containers()

    # Also list known demo dirs that have compose but are not running
    known = sorted(
        {
            p.parent.relative_to(ROOT).as_posix()
            for p in CLIENTS.rglob("docker-compose.yml")
            if "node_modules" not in p.parts
        }
    )
    running_configs = set()
    for p in projects:
        for part in (p.get("ConfigFiles") or "").split(","):
            part = part.strip()
            if part:
                try:
                    running_configs.add(
                        Path(part).resolve().parent.relative_to(ROOT).as_posix()
                    )
                except ValueError:
                    pass
    idle = [d for d in known if d not in running_configs]

    payload = {
        "sandbox_root": str(ROOT),
        "running_compose_projects": len(projects),
        "running_demo_containers": len(containers),
        "projects": [
            {
                "name": p.get("Name"),
                "status": p.get("Status"),
                "config": p.get("ConfigFiles"),
            }
            for p in projects
        ],
        "containers": containers,
        "idle_demo_dirs_with_compose": idle,
    }

    if args.json:
        print(json.dumps(payload, indent=2))
        return 0

    print(f"Sandbox demo Compose projects running: {payload['running_compose_projects']}")
    print(f"Sandbox-ish containers (pf-*/pilotfish*): {payload['running_demo_containers']}")
    print()
    if projects:
        print("Running projects:")
        for p in projects:
            print(f"  - {p.get('Name')}: {p.get('Status')}")
            print(f"      {p.get('ConfigFiles')}")
    else:
        print("Running projects: (none under Clients/)")
    print()
    if containers:
        print("Containers:")
        for c in containers:
            print(f"  - {c['name']:40} {c['status']:28} {c['image']}")
    print()
    print(f"Idle demo dirs with compose (not in docker compose ls): {len(idle)}")
    for d in idle[:30]:
        print(f"  - {d}")
    if len(idle) > 30:
        print(f"  … +{len(idle) - 30} more")
    print()
    print("To stop a stack (from that demo dir): docker compose down")
    print("Do not run down -v unless the user accepts wiping DB volumes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
