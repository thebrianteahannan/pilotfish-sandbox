"""Side-by-side Code changes for a hub request (scoped files vs git HEAD)."""

from __future__ import annotations

import difflib
import subprocess
from html import escape as html_esc
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def paths(meta: dict, dive: dict | None = None) -> list[str]:
    out: list[str] = []
    rows: list = list(meta.get("applied") or []) + list(meta.get("changes") or [])
    if dive:
        rows += list(dive.get("files") or [])
    for rec in rows:
        path = rec.get("path") if isinstance(rec, dict) else None
        if path and path not in out:
            out.append(path)
    for path in meta.get("likely_files") or []:
        if path and path not in out:
            out.append(str(path))
    return out


def _git_head(root: Path, rel: str) -> str:
    path = (root / rel).resolve()
    try:
        repo_rel = path.relative_to(REPO.resolve()).as_posix()
    except ValueError:
        return ""
    proc = subprocess.run(
        ["git", "-C", str(REPO), "show", f"HEAD:{repo_rel}"],
        capture_output=True,
        text=True,
        timeout=60,
    )
    return proc.stdout if proc.returncode == 0 else ""


def _file_diff(old: str, new: str, rel: str) -> str:
    lines = list(
        difflib.unified_diff(
            (old or "").splitlines(),
            (new or "").splitlines(),
            fromfile=f"before/{rel}",
            tofile=f"sandbox/{rel}",
            lineterm="",
            n=3,
        )
    )
    if len(lines) > 400:
        lines = lines[:400] + ["… truncated …"]
    return "\n".join(lines)


def _side_table(old: str, new: str, rel: str) -> str:
    table = difflib.HtmlDiff(wrapcolumn=92, tabsize=2).make_table(
        (old or "").splitlines(),
        (new or "").splitlines(),
        fromdesc="Before",
        todesc="After",
        context=True,
        numlines=3,
    )
    return (
        f'<details class="diff-file"><summary class="diff-name"><span class="diff-path">{html_esc(rel)}</span>'
        f'<button type="button" class="diff-file-open" data-rel="{html_esc(rel)}" title="{html_esc(rel)}">Open</button></summary>{table}</details>'
    )


def stale(root: Path, folder: Path, rels: list[str]) -> bool:
    side = folder / "changes-side.html"
    if not rels:
        return False
    if not side.is_file() or side.stat().st_size == 0:
        return True
    side_m = side.stat().st_mtime
    for rel in rels:
        path = root / rel
        if path.is_file() and path.stat().st_mtime > side_m + 0.5:
            return True
    return False


def write(root: Path, folder: Path, meta: dict, dive: dict | None = None) -> list[dict]:
    rels = paths(meta, dive)
    changes: list[dict] = []
    chunks: list[str] = []
    html_parts: list[str] = []
    for rel in rels:
        path = root / rel
        if not path.is_file():
            continue
        old = _git_head(root, rel)
        bak = path.with_name(path.name + ".bak-req")
        if not old and bak.is_file():
            old = bak.read_text(encoding="utf-8", errors="replace")
        new = path.read_text(encoding="utf-8", errors="replace")
        if old == new:
            continue
        changes.append({"path": rel, "status": "modified" if old else "added"})
        chunk = _file_diff(old, new, rel)
        if chunk:
            chunks.append(chunk)
        html_parts.append(_side_table(old, new, rel))
    side = folder / "changes-side.html"
    if not changes and side.is_file() and side.stat().st_size > 0:
        return list(meta.get("changes") or [])
    (folder / "changes.diff").write_text(("\n\n".join(chunks) or "(no file diffs)") + "\n", encoding="utf-8")
    side.write_text("\n".join(html_parts), encoding="utf-8")
    meta["changes"] = changes
    if not meta.get("change_summary") and dive and dive.get("summary"):
        meta["change_summary"] = str(dive["summary"])
    return changes


def refresh(root: Path, folder: Path, meta: dict, dive: dict | None = None) -> bool:
    rels = paths(meta, dive)
    if not rels or not stale(root, folder, rels):
        return False
    write(root, folder, meta, dive=dive)
    import client_requests as reqs

    reqs.save_meta(folder, meta)
    return True
