"""Feature-branch git for client-request Implement and Merge to main."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def run(*args: str, timeout: int = 180) -> tuple[int, str]:
    proc = subprocess.run(
        ["git", "-C", str(REPO), *args],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    return proc.returncode, ((proc.stdout or "") + (proc.stderr or "")).strip()


def branch_for(slug: str, req_id: str) -> str:
    raw = f"req/{slug}-{req_id}"
    return (re.sub(r"[^A-Za-z0-9._/-]+", "-", raw).strip("-._") or f"req/{slug}")[:100]


def work_paths(root: Path, meta: dict, dive: dict, applied: list[dict]) -> list[str]:
    rels: list[str] = []
    for rec in applied or meta.get("applied") or []:
        if rec.get("path") and rec["path"] not in rels:
            rels.append(rec["path"])
    for rec in dive.get("files") or []:
        if rec.get("path") and rec["path"] not in rels:
            rels.append(rec["path"])
    for rec in meta.get("likely_files") or []:
        if rec and rec not in rels:
            rels.append(rec)
    extra: list[str] = []
    eip = root / "eip-root"
    for path in eip.rglob("*.bak-req") if eip.is_dir() else []:
        src = path.with_name(path.name[: -len(".bak-req")])
        if src.is_file():
            rel = src.relative_to(root).as_posix()
            if rel not in rels:
                extra.append(rel)
    return rels + extra


def ensure_work_branch(slug: str, req_id: str, meta: dict) -> str:
    branch = str(meta.get("git_branch") or "") or branch_for(slug, req_id)
    rc, cur = run("rev-parse", "--abbrev-ref", "HEAD")
    if rc != 0:
        raise RuntimeError(cur or "not a git repo")
    if cur == branch:
        return branch
    rc, _ = run("show-ref", "--verify", "--quiet", f"refs/heads/{branch}")
    cmd = ("checkout", branch) if rc == 0 else ("checkout", "-b", branch)
    rc, out = run(*cmd)
    if rc != 0:
        raise RuntimeError(out or f"could not use branch {branch}")
    return branch


def _repo_files(root: Path, rels: list[str]) -> list[str]:
    out: list[str] = []
    repo = REPO.resolve()
    for rel in rels:
        path = (root / rel).resolve()
        if not path.is_file():
            continue
        try:
            out.append(path.relative_to(repo).as_posix())
        except ValueError:
            continue
    return out


def _dirty_under(folder: Path) -> list[str]:
    if not folder.is_dir():
        return []
    proc = subprocess.run(
        ["git", "-C", str(REPO), "status", "--porcelain", "-z", "--", str(folder)],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if proc.returncode != 0 or not proc.stdout:
        return []
    found: list[str] = []
    for rec in proc.stdout.split("\0"):
        path = rec[3:] if len(rec) > 3 else ""
        if path:
            found.append(path)
    return found


def commit_work(root: Path, req_id: str, meta: dict) -> str:
    rels = [c.get("path") for c in (meta.get("changes") or []) if isinstance(c, dict) and c.get("path")]
    rels += [c.get("path") for c in (meta.get("applied") or []) if isinstance(c, dict) and c.get("path")]
    files = _repo_files(root, [r for r in rels if r])
    for path in _dirty_under(root / "eip-root"):
        if path not in files:
            files.append(path)
    if not files:
        return "No interface files to commit"
    rc, out = run("add", "--", *files)
    if rc != 0:
        raise RuntimeError(out)
    rc, staged = run("diff", "--cached", "--name-only")
    if rc != 0 or not staged:
        return "Nothing new to commit"
    subject = str(meta.get("subject") or req_id).strip()
    client = str(meta.get("client") or meta.get("slug") or "Client")
    rc, out = run("commit", "-m", f"{client}: {subject}\n\nRequest {req_id}")
    if rc != 0:
        if "nothing to commit" in (out or "").lower():
            return "Nothing new to commit"
        raise RuntimeError(out)
    return f"Committed on {meta.get('git_branch') or 'branch'}"


def show_main(root: Path, rel: str) -> bytes | None:
    path = (root / rel).resolve()
    try:
        repo_rel = path.relative_to(REPO.resolve()).as_posix()
    except ValueError:
        return None
    proc = subprocess.run(
        ["git", "-C", str(REPO), "show", f"main:{repo_rel}"],
        capture_output=True,
        timeout=60,
    )
    if proc.returncode != 0:
        return None
    return proc.stdout


def _stash_worktree() -> bool:
    rc, out = run("status", "--porcelain")
    if rc != 0 or not (out or "").strip():
        return False
    rc, out = run("stash", "push", "-u", "-m", "hub-deploy-temp")
    if rc != 0:
        if "no local changes" in (out or "").lower():
            return False
        raise RuntimeError(out)
    return True


def _unstash() -> None:
    rc, out = run("stash", "list")
    if rc != 0 or "hub-deploy-temp" not in (out or ""):
        return
    run("stash", "pop")


def push_and_merge(slug: str, req_id: str, meta: dict) -> str:
    branch = str(meta.get("git_branch") or "") or ensure_work_branch(slug, req_id, meta)
    rc, cur = run("rev-parse", "--abbrev-ref", "HEAD")
    if rc == 0 and cur != branch:
        rc, out = run("checkout", branch)
        if rc != 0:
            raise RuntimeError(out)
    rc, out = run("push", "-u", "origin", branch)
    if rc != 0:
        raise RuntimeError(f"git push failed: {out}")
    stashed = False
    try:
        stashed = _stash_worktree()
        rc, out = run("checkout", "main")
        if rc != 0:
            raise RuntimeError(f"checkout main failed: {out}")
        rc, out = run("pull", "--ff-only", "origin", "main")
        if rc != 0:
            raise RuntimeError(f"update main failed: {out}")
        rc, out = run("merge", "--no-ff", branch, "-m", f"Merge branch '{branch}'")
        if rc != 0:
            raise RuntimeError(f"merge main failed: {out}")
        rc, pushed = run("push", "origin", "main")
        if rc != 0:
            raise RuntimeError(f"push main failed: {pushed}")
        rc, out = run("checkout", branch)
        if rc != 0:
            raise RuntimeError(f"return to {branch} failed: {out}")
    finally:
        if stashed:
            _unstash()
    return f"Merged {branch} into main"
