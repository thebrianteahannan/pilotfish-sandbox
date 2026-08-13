"""Build a TEST deploy zip from git main."""

from __future__ import annotations

import json
import re
import zipfile
from datetime import datetime
from pathlib import Path

import client_git
import client_requests as reqs
import clients


def write_deploy_txt(root: Path, meta: dict, changes: list[dict], tests: dict) -> str:
    asks = meta.get("asks") or []
    lines = [
        "=" * 72,
        f"{root.name} — TEST deploy package",
        f"Request: {meta.get('id')}",
        f"Prepared: {datetime.now().strftime('%Y-%m-%d')}",
        "=" * 72,
        "",
        "WHAT THIS PACKAGE IS FOR",
        "-" * 24,
        meta.get("subject") or "",
        f"From: {meta.get('from') or ''}",
        "",
    ]
    if asks:
        lines.append("Asks:")
        lines.extend(f"  - {a}" for a in asks)
        lines.append("")
    lines += ["CONTENTS", "-" * 8, "  DEPLOY.txt", "  email.txt", "  changes-needed.md", "  tests.json", "  changes.diff", ""]
    if changes:
        lines.append("  Changed interface files:")
        lines.extend(f"    {c['path']}" for c in changes)
    else:
        lines.append("  (no eip-root diffs vs last deploy — zip still includes the email, plan, and tests)")
    lines += ["", "SANDBOX TESTS", "-" * 13]
    for item in (tests or {}).get("items") or []:
        mark = "PASS" if item.get("ok") else "FAIL"
        lines.append(f"  [{mark}] {item.get('name')} — {item.get('detail')}")
    lines += [
        "",
        "DEPLOY",
        "-" * 6,
        "  1. Backup TEST copies of every eip-root path listed above.",
        "  2. Copy those files onto TEST, preserving relative paths under eip-root/.",
        "  3. Restart eiPlatform / Tomcat on TEST.",
        "  4. Re-run the client’s smoke case.",
        "",
        f"SOURCE  {root.as_posix()}",
        "PACKAGED FROM  git branch main",
        "",
    ]
    return "\n".join(lines)


def package_zip(root: Path, folder: Path, meta: dict, changes: list[dict], tests: dict) -> Path:
    name = reqs.zip_filename(root.name, folder, meta)
    pack = name[:-4] if name.endswith(".zip") else name
    zpath = folder / name
    for old in folder.glob("*.zip"):
        if old != zpath:
            old.unlink()
    missing = [rec["path"] for rec in changes if client_git.show_main(root, rec["path"]) is None]
    if missing:
        raise RuntimeError("Not on main yet: " + ", ".join(missing[:6]))
    deploy_txt = write_deploy_txt(root, meta, changes, tests)
    (folder / "DEPLOY.txt").write_text(deploy_txt, encoding="utf-8")
    with zipfile.ZipFile(zpath, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for fname in ("DEPLOY.txt", "email.txt", "changes-needed.md", "changes-needed.pdf", "dive.json", "tests.json", "changes.diff", "request.json"):
            p = folder / fname
            if p.is_file():
                zf.write(p, f"{pack}/{fname}")
        for rec in changes:
            data = client_git.show_main(root, rec["path"])
            if data is not None:
                zf.writestr(f"{pack}/{rec['path']}", data)
        for shot in sorted(folder.glob("screenshot-*")):
            if shot.is_file() and shot.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".gif", ".tif", ".tiff"}:
                zf.write(shot, f"{pack}/{shot.name}")
    return zpath


def deploy_dir(root: Path) -> Path:
    path = reqs.requests_dir(root) / "_deploy"
    path.mkdir(parents=True, exist_ok=True)
    return path


def snapshot(slug: str) -> dict:
    try:
        root = clients.require_root(slug)
    except ValueError:
        return {"ready": False}
    latest = deploy_dir(root) / "latest.json"
    if not latest.is_file():
        return {"ready": False}
    try:
        data = json.loads(latest.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"ready": False}
    name = str(data.get("name") or "")
    zpath = deploy_dir(root) / name
    if not name or not zpath.is_file():
        return {"ready": False}
    rel = zpath.relative_to(clients.ROOT).as_posix()
    return {
        "ready": True,
        "name": name,
        "path": rel,
        "url": f"/api/clients/{slug}/requests/deploy",
        "ids": data.get("ids") or [],
        "size_kb": zpath.stat().st_size // 1024,
    }


def _merged_rows(slug: str) -> tuple[Path, list[tuple[Path, dict]]]:
    root = clients.require_root(slug)
    rows: list[tuple[Path, dict]] = []
    folder = reqs.requests_dir(root)
    for child in sorted(folder.iterdir(), key=lambda p: p.name, reverse=True):
        if not child.is_dir() or child.name.startswith("_") or not reqs.meta_path(child).is_file():
            continue
        meta = reqs.load_meta(child)
        if meta.get("git_merged"):
            rows.append((child, meta))
    if not rows:
        raise ValueError("Merge a request into main before deploying.")
    return root, rows


def _union_changes(rows: list[tuple[Path, dict]]) -> list[dict]:
    paths: list[str] = []
    for _folder, meta in rows:
        for rec in list(meta.get("changes") or []) + list(meta.get("applied") or []):
            path = str(rec.get("path") or "") if isinstance(rec, dict) else ""
            if path and path not in paths:
                paths.append(path)
    return [{"path": p, "status": "modified"} for p in paths]


def _main_txt(root: Path, rows: list[tuple[Path, dict]], changes: list[dict]) -> str:
    lines = [
        "=" * 72,
        f"{root.name} — TEST deploy package",
        f"Requests: {len(rows)}",
        f"Prepared: {datetime.now().strftime('%Y-%m-%d')}",
        "=" * 72,
        "",
        "REQUESTS IN THIS PACKAGE",
        "-" * 24,
    ]
    for _folder, meta in rows:
        lines.append(f"  - {meta.get('subject') or meta.get('id')}  ({meta.get('id')})")
        if meta.get("from"):
            lines.append(f"    From: {meta.get('from')}")
    lines += ["", "CONTENTS", "-" * 8, "  DEPLOY.txt", "  requests/<id>/  (email, plan, tests)", ""]
    if changes:
        lines.append("  Changed interface files:")
        lines.extend(f"    {c['path']}" for c in changes)
    lines += [
        "",
        "DEPLOY",
        "-" * 6,
        "  1. Backup TEST copies of every eip-root path listed above.",
        "  2. Copy those files onto TEST, preserving relative paths under eip-root/.",
        "  3. Restart eiPlatform / Tomcat on TEST.",
        "  4. Re-run the client’s smoke cases.",
        "",
        f"SOURCE  {root.as_posix()}",
        "PACKAGED FROM  git branch main",
        "",
    ]
    return "\n".join(lines)


def package_main(slug: str, set_job) -> Path:
    root, rows = _merged_rows(slug)
    set_job(message=f"Building TEST zip from main ({len(rows)} request{'' if len(rows) == 1 else 's'})…")
    changes = _union_changes(rows)
    dest_dir = deploy_dir(root)
    base = re.sub(r"[^A-Za-z0-9]+", "", root.name or "Client")
    name = f"{base}_TEST_Deploy_{datetime.now().strftime('%Y%m%d')}.zip"
    dest = dest_dir / name
    for old in dest_dir.glob("*.zip"):
        if old != dest:
            old.unlink()
    pack = name[:-4]
    docs = ("email.txt", "changes-needed.md", "changes-needed.pdf", "tests.json", "changes.diff", "request.json")
    missing = [rec["path"] for rec in changes if client_git.show_main(root, rec["path"]) is None]
    if missing:
        raise RuntimeError("Not on main yet: " + ", ".join(missing[:6]))
    with zipfile.ZipFile(dest, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(f"{pack}/DEPLOY.txt", _main_txt(root, rows, changes))
        for rec in changes:
            data = client_git.show_main(root, rec["path"])
            if data is not None:
                zf.writestr(f"{pack}/{rec['path']}", data)
        for folder, meta in rows:
            rid = str(meta.get("id") or folder.name)
            for fname in docs:
                path = folder / fname
                if path.is_file():
                    zf.write(path, f"{pack}/requests/{rid}/{fname}")
    kb = dest.stat().st_size // 1024
    rel = dest.relative_to(clients.ROOT).as_posix()
    payload = {"name": name, "ids": [m.get("id") for _f, m in rows], "path": rel, "size_kb": kb}
    (dest_dir / "latest.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    for folder, _meta in rows:
        reqs.append_log(folder, f"TEST zip from main ready: {rel} ({kb} KB)")
    set_job(message=f"TEST zip from main ready: {rel} ({kb} KB)")
    return dest
