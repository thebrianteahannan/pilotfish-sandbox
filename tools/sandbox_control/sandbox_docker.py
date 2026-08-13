"""Running Docker containers and images that belong to this Sandbox (Clients/)."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

import demos

CLIENTS = demos.CLIENTS
KNOWN = {
    "pilotfish-eip": ("client", "Med Rec"),
    "pf-crlplus-ail-sandbox": ("client", "CRL Plus"),
}

_demo_slugs: list[str] | None = None


def _run(cmd: list[str], timeout: int = 30) -> tuple[int, str]:
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError) as exc:
        return 1, str(exc)
    return proc.returncode, (proc.stdout or "").strip()


def _under_clients(path: Path | str | None) -> Path | None:
    if not path:
        return None
    try:
        p = Path(str(path)).resolve()
        p.relative_to(CLIENTS.resolve())
        return p
    except (ValueError, OSError):
        return None


def _kind_project(path: Path) -> tuple[str, str]:
    rel = path.resolve().relative_to(CLIENTS.resolve())
    parts = rel.parts
    if not parts:
        return "other", path.name
    if parts[0] == "Demos":
        for ancestor in (path, *path.parents):
            if _under_clients(ancestor) is None:
                break
            if (ancestor / "docker-compose.yml").is_file() or (ancestor / "DESIGN.md").is_file():
                return "demo", ancestor.name
        return "demo", parts[-1]
    return "client", parts[0]


def _slugs() -> list[str]:
    global _demo_slugs
    if _demo_slugs is None:
        from demo_paths import iter_demo_roots

        _demo_slugs = sorted({p.name for p in iter_demo_roots()}, key=len, reverse=True)
    return _demo_slugs


def _from_name(name: str) -> tuple[str, str] | None:
    if name in KNOWN:
        return KNOWN[name]
    if not name.startswith("pf-"):
        return None
    rest = name[3:]
    for slug in _slugs():
        if rest == slug or rest.startswith(slug + "-"):
            return "demo", slug
    return "demo", rest


def _candidate_paths(info: dict) -> list[Path]:
    labels = (info.get("Config") or {}).get("Labels") or {}
    out: list[Path] = []
    wd = labels.get("com.docker.compose.project.working_dir")
    if wd:
        out.append(Path(wd))
    for part in (labels.get("com.docker.compose.project.config_files") or "").split(","):
        part = part.strip()
        if part:
            out.append(Path(part).parent)
    for mount in info.get("Mounts") or []:
        src = (mount.get("Source") or "").strip()
        if src.startswith("/"):
            out.append(Path(src))
    return out


def _classify(name: str, info: dict) -> tuple[str, str] | None:
    for cand in _candidate_paths(info):
        hit = _under_clients(cand)
        if hit is not None:
            return _kind_project(hit)
    return _from_name(name)


def _inspect_by_id(ids: list[str]) -> dict[str, dict]:
    if not ids:
        return {}
    code, out = _run(["docker", "inspect", *ids], timeout=45)
    if code != 0 or not out:
        return {}
    try:
        items = json.loads(out)
    except json.JSONDecodeError:
        return {}
    by_id: dict[str, dict] = {}
    for item in items:
        full = item.get("Id") or ""
        if full:
            by_id[full] = item
            by_id[full[:12]] = item
    return by_id


def _image_index() -> dict[str, dict]:
    code, out = _run(["docker", "images", "--format", "{{json .}}"])
    idx: dict[str, dict] = {}
    if code != 0:
        return idx
    for line in out.splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        repo = row.get("Repository") or ""
        tag = row.get("Tag") or ""
        ident = row.get("ID") or ""
        rec = {"id": ident, "size": row.get("Size") or ""}
        if repo:
            idx[repo] = rec
            if tag and tag != "<none>":
                idx[f"{repo}:{tag}"] = rec
        if ident:
            idx[ident] = rec
    return idx


def _lookup_image(image: str, idx: dict[str, dict]) -> dict:
    if image in idx:
        return idx[image]
    hexish = image[:12].lower()
    if len(hexish) >= 8 and all(ch in "0123456789abcdef" for ch in hexish):
        for rec in idx.values():
            ident = rec.get("id") or ""
            if ident and (image.startswith(ident) or ident.startswith(hexish)):
                return rec
    return {}


def snapshot() -> dict:
    code, out = _run(["docker", "ps", "--format", "{{json .}}"])
    if code != 0:
        return {
            "ok": False,
            "error": out or "Docker is not available",
            "containers": [],
            "images": [],
            "count": 0,
        }
    rows = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    inspected = _inspect_by_id([r.get("ID") or "" for r in rows if r.get("ID")])
    containers = []
    for row in rows:
        name = (row.get("Names") or "").split(",")[0].strip()
        info = inspected.get(row.get("ID") or "") or {}
        kind = _classify(name, info)
        if kind is None:
            continue
        k, project = kind
        labels = (info.get("Config") or {}).get("Labels") or {}
        containers.append(
            {
                "name": name,
                "image": row.get("Image") or "",
                "status": row.get("Status") or "",
                "ports": row.get("Ports") or "",
                "running": True,
                "kind": k,
                "project": project,
                "compose": labels.get("com.docker.compose.project") or "",
            }
        )
    containers.sort(key=lambda c: (0 if c["kind"] == "client" else 1, c["project"].lower(), c["name"].lower()))
    idx = _image_index()
    images = []
    seen: set[str] = set()
    for rec in containers:
        img = rec["image"]
        if not img or img in seen:
            continue
        seen.add(img)
        meta = _lookup_image(img, idx)
        images.append({"name": img, "size": meta.get("size") or "", "id": meta.get("id") or ""})
    return {"ok": True, "containers": containers, "images": images, "count": len(containers)}
