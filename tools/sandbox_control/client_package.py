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


def request_extras(folder: Path) -> list[tuple[Path, str]]:
    extras: list[tuple[Path, str]] = []
    for sub in ("88a", "sql"):
        dest = folder / sub
        if not dest.is_dir():
            continue
        for path in sorted(dest.iterdir()):
            if path.is_file() and not path.name.startswith("."):
                extras.append((path, f"{sub}/{path.name}"))
    return extras


def write_deploy_txt(
    root: Path,
    meta: dict,
    changes: list[dict],
    tests: dict,
    *,
    from_disk: bool = False,
    extras: list[tuple[Path, str]] | None = None,
) -> str:
    asks = meta.get("asks") or []
    extras = extras or []
    extra_names = [rel for _p, rel in extras]
    has_xlsx = any(rel.startswith("88a/") and rel.lower().endswith(".xlsx") for rel in extra_names)
    has_sql = any(rel.startswith("sql/") and rel.lower().endswith(".sql") for rel in extra_names)
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
    if extra_names:
        lines.append("  Database / 88a:")
        lines.extend(f"    {rel}" for rel in extra_names)
        lines.append("")
    if changes:
        lines.append("  Changed interface files:")
        lines.extend(f"    {c['path']}" for c in changes)
    else:
        lines.append("  (no eip-root diffs vs last deploy — zip still includes the email, plan, and tests)")
    lines += ["", "SANDBOX TESTS", "-" * 13]
    for item in (tests or {}).get("items") or []:
        mark = "PASS" if item.get("ok") else "FAIL"
        lines.append(f"  [{mark}] {item.get('name')} — {item.get('detail')}")
    lines += ["", "DEPLOY", "-" * 6]
    if has_xlsx or has_sql:
        lines += [
            "  Backup TEST H2 and every eip-root path listed above first.",
            "  Load the database with ONE of these — do not do both:",
        ]
        if has_xlsx:
            lines += [
                "    A) Preferred — 88a Excel drop (also writes Route 1 listeners):",
                "       Drop the 88a/*.xlsx files into FLAT_FILE_INPUT_DIRECTORY on TEST.",
                "       Filenames already match MedReceivables_NewFacilityInfo. CEX SOFTWAREID is 528",
                "       (do not load the original 524 — that ID is NHL CAT).",
                "       Then copy this zip's Route 1 over TEST. 88a listeners use irl<client>.* and",
                "       will not pick up PTH5.COCCN / COCOS / COCPMA / COCOMC; this Route 1 has the",
                "       GAN-cloned PTH5.COC* listeners plus Set Partition processors.",
            ]
        if has_sql:
            lines += [
                "    B) Bypass — SQL (use this if you skip the 88a drop):",
                "       Run sql/*.sql against TEST medreceivables. Route 1 in this zip already",
                "       has the four listeners.",
            ]
        lines += [
            "  Copy the eip-root files, preserving relative paths.",
            "  Restart eiPlatform / Tomcat on TEST.",
            "  Re-run the client’s smoke case.",
        ]
    else:
        lines += [
            "  1. Backup TEST copies of every eip-root path listed above.",
            "  2. Copy those files onto TEST, preserving relative paths under eip-root/.",
            "  3. Restart eiPlatform / Tomcat on TEST.",
            "  4. Re-run the client’s smoke case.",
        ]
    lines += [
        "",
        f"SOURCE  {root.as_posix()}",
        "PACKAGED FROM  sandbox eip-root (this request’s files on disk)" if from_disk else "PACKAGED FROM  git branch main",
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


def _change_paths(meta: dict) -> list[dict]:
    paths: list[str] = []
    for rec in list(meta.get("changes") or []) + list(meta.get("applied") or []):
        path = rec.get("path") if isinstance(rec, dict) else ""
        if path and path not in paths:
            paths.append(path)
    return [{"path": p, "status": "modified"} for p in paths]


def package_request(slug: str, req_id: str) -> Path:
    """Zip this request’s eip-root files from disk (chat Implement has no main merge)."""
    root = clients.require_root(slug)
    folder = reqs.request_path(root, req_id)
    meta = reqs.load_meta(folder)
    if not meta:
        raise ValueError("Unknown request")
    changes = _change_paths(meta)
    extras = request_extras(folder)
    missing = [rec["path"] for rec in changes if not (root / rec["path"]).is_file()]
    if missing:
        raise RuntimeError("Missing files: " + ", ".join(missing[:6]))
    tests = meta.get("tests") if isinstance(meta.get("tests"), dict) else {}
    dest_dir = deploy_dir(root)
    name = reqs.zip_filename(root.name, folder, meta)
    dest = dest_dir / name
    pack = name[:-4]
    deploy_txt = write_deploy_txt(root, meta, changes, tests, from_disk=True, extras=extras)
    (folder / "DEPLOY.txt").write_text(deploy_txt, encoding="utf-8")
    with zipfile.ZipFile(dest, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(f"{pack}/DEPLOY.txt", deploy_txt)
        for fname in ("email.txt", "changes-needed.md", "changes-needed.pdf", "dive.json", "tests.json", "changes.diff", "request.json"):
            path = folder / fname
            if path.is_file():
                zf.write(path, f"{pack}/{fname}")
        for rec in changes:
            zf.write(root / rec["path"], f"{pack}/{rec['path']}")
        for path, rel in extras:
            zf.write(path, f"{pack}/{rel}")
        for shot in sorted(folder.glob("screenshot-*")):
            if shot.is_file() and shot.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".gif", ".tif", ".tiff"}:
                zf.write(shot, f"{pack}/{shot.name}")
    kb = dest.stat().st_size // 1024
    rel = dest.relative_to(clients.ROOT).as_posix()
    payload = {"name": name, "ids": [meta.get("id") or folder.name], "path": rel, "size_kb": kb}
    (dest_dir / "latest.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    (dest_dir / (Path(name).stem + ".json")).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    meta["deployed"] = True
    meta["status"] = "applied"
    meta["deploy_zip"] = name
    meta["deploy_path"] = rel
    reqs.save_meta(folder, meta)
    reqs.append_log(folder, f"TEST zip ready: {rel} ({kb} KB)")
    return dest


def deploy_dir(root: Path) -> Path:
    path = reqs.requests_dir(root) / "_deploy"
    path.mkdir(parents=True, exist_ok=True)
    return path


def zip_file(root: Path, name: str = "") -> Path | None:
    folder = deploy_dir(root)
    want = Path(name or "").name
    if want.endswith(".zip") and not want.startswith("."):
        path = folder / want
        if path.is_file():
            return path
    latest = snapshot_name(root)
    if latest:
        path = folder / latest
        if path.is_file():
            return path
    return None


def snapshot_name(root: Path) -> str:
    latest = deploy_dir(root) / "latest.json"
    if not latest.is_file():
        return ""
    try:
        data = json.loads(latest.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ""
    return str(data.get("name") or "")


def packs(slug: str) -> list[dict]:
    try:
        root = clients.require_root(slug)
    except ValueError:
        return []
    folder = deploy_dir(root)
    rows = []
    for zpath in sorted(folder.glob("*.zip"), key=lambda p: p.stat().st_mtime, reverse=True):
        side = folder / (zpath.stem + ".json")
        ids: list[str] = []
        if side.is_file():
            try:
                ids = [str(i) for i in (json.loads(side.read_text(encoding="utf-8")).get("ids") or []) if i]
            except (OSError, json.JSONDecodeError):
                ids = []
        if not ids:
            latest = folder / "latest.json"
            if latest.is_file():
                try:
                    lat = json.loads(latest.read_text(encoding="utf-8"))
                    if str(lat.get("name") or "") == zpath.name:
                        ids = [str(i) for i in (lat.get("ids") or []) if i]
                except (OSError, json.JSONDecodeError):
                    pass
        rel = zpath.relative_to(clients.ROOT).as_posix()
        rows.append(
            {
                "name": zpath.name,
                "path": rel,
                "url": f"/api/clients/{slug}/requests/deploy?name={zpath.name}",
                "ids": ids,
                "size_kb": zpath.stat().st_size // 1024,
            }
        )
    return rows


def snapshot(slug: str) -> dict:
    try:
        root = clients.require_root(slug)
    except ValueError:
        return {"ready": False, "packs": []}
    listed = packs(slug)
    if not listed:
        return {"ready": False, "packs": []}
    latest = listed[0]
    return {
        "ready": True,
        "name": latest["name"],
        "path": latest["path"],
        "url": latest["url"],
        "ids": latest["ids"],
        "size_kb": latest["size_kb"],
        "packs": listed,
    }


def _merged_rows(slug: str) -> tuple[Path, list[tuple[Path, dict]]]:
    root = clients.require_root(slug)
    rows: list[tuple[Path, dict]] = []
    folder = reqs.requests_dir(root)
    for child in sorted(folder.iterdir(), key=lambda p: p.name, reverse=True):
        if not child.is_dir() or child.name.startswith("_") or not reqs.meta_path(child).is_file():
            continue
        meta = reqs.load_meta(child)
        already = bool(meta.get("deployed") or meta.get("status") == "applied")
        if meta.get("git_merged") and not already:
            rows.append((child, meta))
    if not rows:
        raise ValueError("Nothing new to deploy. Merge a request into main first, or every merged request is already in a TEST zip.")
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
    dest_dir.mkdir(parents=True, exist_ok=True)
    (dest_dir / "latest.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    (dest_dir / (Path(name).stem + ".json")).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    for folder, meta in rows:
        meta["deployed"] = True
        meta["status"] = "applied"
        meta["deploy_zip"] = name
        meta["deploy_path"] = rel
        reqs.save_meta(folder, meta)
        reqs.append_log(folder, f"TEST zip from main ready: {rel} ({kb} KB)")
    set_job(message=f"TEST zip from main ready: {rel} ({kb} KB)")
    return dest
