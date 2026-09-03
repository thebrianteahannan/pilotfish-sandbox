"""Match eiPlatform WARs in the Documentation project for Docker builds."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

import docs_portal

WAR_RE = re.compile(r"^eip\.war\.hs\.(.+)$", re.I)


def wars_dir() -> Path:
    return docs_portal.docs_root() / "PilotFish WARs"


def _parse(name: str) -> str:
    m = WAR_RE.match(name)
    return (m.group(1) if m else "").strip()


def list_wars() -> list[dict]:
    folder = wars_dir()
    rows = []
    if folder.is_dir():
        for path in sorted(folder.iterdir()):
            build = _parse(path.name)
            if not build or not path.is_file():
                continue
            family = re.split(r"\.(?=\d+$)", build)[0]
            rows.append({"build": build, "family": family, "name": path.name, "path": str(path), "size_mb": round(path.stat().st_size / (1024 * 1024))})
    return rows


def resolve(version: str) -> dict | None:
    want = (version or "").strip()
    if not want:
        want = "23R1"
    want = re.sub(r"^eip\.war\.hs\.", "", want, flags=re.I)
    hits = []
    for row in list_wars():
        build, family = row["build"], row["family"]
        if build == want or family == want or build.startswith(want + ".") or family.startswith(want):
            hits.append(row)
    if not hits:
        return None
    hits.sort(key=lambda r: r["build"])
    return hits[-1]


def stage_war(version: str, dest: Path) -> dict:
    row = resolve(version)
    if not row:
        have = ", ".join(r["family"] for r in list_wars()) or "none"
        raise FileNotFoundError(f"No eiPlatform WAR for {version or '23R1'}. Have: {have}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(row["path"], dest)
    return row
