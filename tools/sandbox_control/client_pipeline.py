"""Process a client email request: plan, sandbox tests, interface diff, TEST zip."""

from __future__ import annotations

import difflib
import hashlib
import json
import threading
import time
import urllib.error
import urllib.request
from html import escape as html_esc
from pathlib import Path

import client_comment_plan
import client_dive
import client_git
import client_package
import client_plan_pdf
import client_proof
import client_requests as reqs
import clients
import hub_ntfy

SKIP_DIR = {".venv", "lib", "icons", "__pycache__", "node_modules", ".git", "requests", "deploy"}
SUFFIXES = {".xml", ".xslt", ".xsl", ".sql", ".conf", ".txt", ".json"}

_lock = threading.Lock()
_job: dict = {"busy": False, "slug": "", "request_id": "", "message": "Idle", "error": ""}


def job_snapshot() -> dict:
    with _lock:
        return dict(_job)


def _set(**fields) -> None:
    with _lock:
        _job.update(fields)


def _hash(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


def iter_source_files(root: Path) -> list[Path]:
    found: list[Path] = []
    for base in (root / "eip-root", root / "deploy" / "sql"):
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in SUFFIXES:
                continue
            if any(p in SKIP_DIR for p in path.parts):
                continue
            found.append(path)
    return found


def bak_for(path: Path) -> Path:
    return path.with_name(path.name + ".bak-req")


def last_deploy(root: Path) -> Path | None:
    deploy = root / "deploy"
    if not deploy.is_dir():
        return None
    dirs = [p for p in deploy.iterdir() if p.is_dir() and not p.name.startswith(".") and p.name != "sql"]
    if not dirs:
        return None
    testish = [p for p in dirs if "test" in p.name.lower()]
    pool = testish or dirs
    return max(pool, key=lambda p: p.stat().st_mtime)


def file_diff(old: str, new: str, rel: str) -> str:
    a = (old or "").splitlines()
    b = (new or "").splitlines()
    lines = list(difflib.unified_diff(a, b, fromfile=f"before/{rel}", tofile=f"sandbox/{rel}", lineterm="", n=3))
    if len(lines) > 400:
        lines = lines[:400] + ["… truncated …"]
    return "\n".join(lines)


def snapshot_hashes(root: Path) -> dict[str, str]:
    return {p.relative_to(root).as_posix(): _hash(p) for p in iter_source_files(root)}


def side_table(old: str, new: str, rel: str) -> str:
    table = difflib.HtmlDiff(wrapcolumn=92, tabsize=2).make_table(
        (old or "").splitlines(), (new or "").splitlines(),
        fromdesc="Before", todesc="After", context=True, numlines=3,
    )
    return (
        f'<details class="diff-file"><summary class="diff-name"><span class="diff-path">{html_esc(rel)}</span>'
        f'<button type="button" class="diff-file-open" data-rel="{html_esc(rel)}" title="{html_esc(rel)}">Open</button></summary>{table}</details>'
    )


def collect_changes(root: Path, folder: Path, likely: list[str]) -> tuple[list[dict], str, str]:
    prior = last_deploy(root)
    baseline: dict[str, str] = {}
    bpath = folder / "baseline.json"
    if bpath.is_file():
        try:
            loaded = json.loads(bpath.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                baseline = {str(k): str(v) for k, v in loaded.items()}
        except (OSError, json.JSONDecodeError):
            baseline = {}
    include: set[str] = set()
    for path in iter_source_files(root):
        rel = path.relative_to(root).as_posix()
        cur = _hash(path)
        if baseline:
            prev = baseline.get(rel)
            if prev == cur:
                continue
            include.add(rel)
        elif bak_for(path).is_file() and _hash(bak_for(path)) != cur:
            include.add(rel)
        elif rel in (likely or []):
            include.add(rel)
    changes: list[dict] = []
    chunks: list[str] = []
    html_parts: list[str] = []
    for rel in sorted(include):
        path = root / rel
        if not path.is_file():
            continue
        bak = bak_for(path)
        old_path = prior / rel if prior and (prior / rel).is_file() else None
        if bak.is_file():
            old_text = bak.read_text(encoding="utf-8", errors="replace")
        elif old_path:
            old_text = old_path.read_text(encoding="utf-8", errors="replace")
        elif rel in baseline:
            continue
        else:
            old_text = ""
        new_text = path.read_text(encoding="utf-8", errors="replace")
        if old_text == new_text:
            continue
        existed = bool(old_text) or rel in baseline
        changes.append({"path": rel, "status": "modified" if existed else "added"})
        chunk = file_diff(old_text, new_text, rel)
        if chunk:
            chunks.append(chunk)
        html_parts.append(side_table(old_text, new_text, rel))
    return changes, "\n\n".join(chunks), "\n".join(html_parts)


def wait_url(url: str, timeout: float = 60) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=4) as resp:
                if getattr(resp, "status", 200) < 500:
                    return True
        except (OSError, urllib.error.URLError, TimeoutError):
            time.sleep(2)
    return False


def _http(url: str, *, data: bytes | None = None, headers: dict | None = None, timeout: int = 20) -> tuple[int, str]:
    req = urllib.request.Request(url, data=data, headers=headers or {}, method="POST" if data is not None else "GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            return resp.status, body
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8", errors="replace")[-400:]
    except (OSError, urllib.error.URLError, TimeoutError) as exc:
        return 0, str(exc)


def test_crl_plus(root: Path, folder: Path) -> dict:
    items = []
    url = "http://127.0.0.1:8094/"
    if not wait_url(url + "api/health", timeout=45):
        return {"ok": False, "items": [{"name": "Web UI up", "ok": False, "detail": "Sandbox did not come up on :8094"}]}
    items.append({"name": "Web UI health", "ok": True, "detail": ":8094"})
    sample = root / "sandbox" / "sample-data" / "ail-121-order.xml"
    if not sample.is_file():
        items.append({"name": "Sample 121 POST", "ok": False, "detail": "sample missing"})
        return {"ok": False, "items": items}
    import base64

    token = base64.b64encode(b"ail:AilSandbox$Test1").decode("ascii")
    code, body = _http(
        "http://127.0.0.1:8094/http-post/ail",
        data=sample.read_bytes(),
        headers={"Authorization": f"Basic {token}", "Content-Type": "text/xml"},
    )
    ok = code == 200 and "TXLife" in body
    items.append({"name": "HTTP POST /http-post/ail sample 121", "ok": ok, "detail": f"HTTP {code}"})
    (folder / "tests.json").write_text(json.dumps({"ok": all(i["ok"] for i in items), "items": items}, indent=2), encoding="utf-8")
    return {"ok": all(i["ok"] for i in items), "items": items}


def test_med_rec(folder: Path, dive: dict | None = None) -> dict:
    dive = dive or {}
    items = client_proof.smoke_eip(wait_url) + client_proof.prove(folder.parents[1], dive, folder)
    result = {"ok": all(i["ok"] for i in items), "items": items, "note": client_proof.note(dive)}
    (folder / "tests.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    return result


def ensure_sandbox(root: Path, folder: Path) -> None:
    if clients.is_running(root):
        reqs.append_log(folder, "Sandbox already running")
        return
    reqs.append_log(folder, f"Starting {root.name} sandbox…")
    clients.start_client(root)


def _run_tests(slug: str, root: Path, folder: Path, meta: dict, dive: dict | None = None) -> dict:
    _set(message="Running sandbox tests…")
    reqs.append_log(folder, "Running sandbox tests")
    if slug == "crl-plus":
        tests = test_crl_plus(root, folder)
    elif slug == "med-rec":
        tests = test_med_rec(folder, dive)
    else:
        tests = {"ok": False, "items": [{"name": "tests", "ok": False, "detail": "no sandbox tests wired"}]}
    meta["tests"] = tests
    reqs.save_meta(folder, meta)
    reqs.append_log(folder, "Sandbox tests passed" if tests.get("ok") else "Sandbox tests failed")
    _set(message="Collecting code diffs…")
    changes, diff_text, diff_html = collect_changes(root, folder, meta.get("likely_files") or [])
    meta["changes"] = changes
    (folder / "changes.diff").write_text(diff_text or "(no file diffs)\n", encoding="utf-8")
    (folder / "changes-side.html").write_text(diff_html, encoding="utf-8")
    reqs.save_meta(folder, meta)
    reqs.append_log(folder, f"{len(changes)} file(s) changed")
    return tests


def process_request(slug: str, req_id: str) -> None:
    _set(busy=True, slug=slug, request_id=req_id, message="Building change plan…", error="")
    root = clients.require_root(slug)
    folder = reqs.request_path(root, req_id)
    meta = reqs.load_meta(folder)
    if not meta:
        _set(busy=False, error="Unknown request")
        return
    try:
        meta["status"] = "processing"
        meta["phase"] = "analyzing"
        reqs.save_meta(folder, meta)
        email = (folder / "email.txt").read_text(encoding="utf-8", errors="replace")
        comments = str(meta.get("comments") or "")
        prev = client_plan_pdf.previous_dive(folder)
        _set(message="Reading eip-root against the email…")
        dive = client_dive.dive(root, email, str(meta.get("subject") or ""), "")
        dive = client_comment_plan.refine(root, dive, comments, prev)
        if comments:
            dive["comments"] = comments
            dive["delta"] = client_comment_plan.human_delta(prev or {}, dive)
        client_dive.write_markdown(folder, meta, dive)
        pdf = client_plan_pdf.write_plan_pdf(folder, meta, dive)
        meta["asks"] = dive.get("codes") or []
        meta["request_summary"] = client_plan_pdf.describe_request(dive, meta)
        meta["likely_files"] = [f["path"] for f in dive.get("files") or []]
        meta["plan_pdf"] = pdf.name
        meta["edit_count"] = len(dive.get("edits") or [])
        meta["status"] = "planned"
        meta["phase"] = "review"
        meta["message"] = "Change plan PDF ready — review it, then Start work"
        if comments and dive.get("delta"):
            meta["message"] = "Change plan rebuilt from comments — review Proposed changes, then Start work"
        reqs.save_meta(folder, meta)
        reqs.append_log(folder, f"Plan PDF: {len(dive.get('codes') or [])} code(s), {meta['edit_count']} edit(s)")
        hub_ntfy.notify("Change plan ready", f"{root.name}: {meta.get('subject') or req_id}", slug=slug, req_id=req_id, tags="clipboard")
        _set(message=meta["message"])
    except Exception as exc:
        reqs.append_log(folder, f"Failed: {exc}")
        meta = reqs.load_meta(folder)
        meta["status"] = "error"
        meta["error"] = str(exc)[:800]
        reqs.save_meta(folder, meta)
        _set(error=str(exc)[:800], message="Plan failed")
    finally:
        _set(busy=False)


def apply_work(slug: str, req_id: str) -> None:
    _set(busy=True, slug=slug, request_id=req_id, message="Applying planned edits…", error="")
    root = clients.require_root(slug)
    folder = reqs.request_path(root, req_id)
    meta = reqs.load_meta(folder)
    if not meta:
        _set(busy=False, error="Unknown request")
        return
    try:
        dive_path = folder / "dive.json"
        if not dive_path.is_file():
            raise ValueError("No change plan yet. Build the change plan first.")
        dive = json.loads(dive_path.read_text(encoding="utf-8"))
        meta["git_branch"] = client_git.ensure_work_branch(slug, req_id, meta)
        meta["status"] = "processing"
        meta["phase"] = "applying"
        meta["zip"] = ""
        reqs.save_meta(folder, meta)
        reqs.append_log(folder, f"Branch {meta['git_branch']}")
        hub_ntfy.notify("Work started", f"{root.name}: {meta.get('subject') or req_id}", slug=slug, req_id=req_id, tags="hammer")
        applied = client_dive.apply_edits(root, dive)
        if not applied:
            applied = list(meta.get("applied") or [])
            reqs.append_log(folder, "Edits already on disk" if applied else "No automatic edits — loading sandbox anyway")
        else:
            meta["applied"] = applied
            reqs.append_log(folder, f"Applied {len(applied)} file edit(s)")
        rels = client_git.work_paths(root, meta, dive, applied)
        meta["phase"] = "loading"
        reqs.save_meta(folder, meta)
        _set(message="Loading edits into the sandbox…")
        ensure_sandbox(root, folder)
        copied = clients.push_eip_files(root, rels)
        reqs.append_log(folder, f"Copied {copied} file(s) into EIP" if copied else "Sandbox using host files")
        meta["phase"] = "testing"
        reqs.save_meta(folder, meta)
        tests = _run_tests(slug, root, folder, meta, dive)
        meta = reqs.load_meta(folder)
        meta["git_branch"] = meta.get("git_branch") or client_git.branch_for(slug, req_id)
        reqs.append_log(folder, client_git.commit_work(root, req_id, meta))
        meta["status"] = "tested"
        meta["phase"] = "review"
        meta["tests"] = tests
        if tests.get("ok"):
            meta["message"] = f"Tests passed on {meta['git_branch']}. Review the diff, then Merge into main."
        else:
            meta["message"] = "Tests failed. Review the diff before generating a zip."
        reqs.save_meta(folder, meta)
        reqs.append_log(folder, meta["message"])
        _set(message=meta["message"])
    except Exception as exc:
        reqs.append_log(folder, f"Failed: {exc}")
        meta = reqs.load_meta(folder)
        meta["status"] = "error"
        meta["error"] = str(exc)[:800]
        reqs.save_meta(folder, meta)
        _set(error=str(exc)[:800], message="Start work failed")
    finally:
        _set(busy=False)


def package_client(slug: str, req_id: str = "") -> None:
    try:
        client_package.package_main(slug, _set)
        hub_ntfy.notify("TEST deploy ZIP ready", f"{slug}: zip from main", slug=slug, tags="package")
    except Exception as exc:
        _set(error=str(exc)[:800], message="Deploy failed")
    finally:
        _set(busy=False)


def _enqueue(fn, slug: str, req_id: str) -> dict:
    with _lock:
        if _job.get("busy"):
            return {"ok": False, "error": "Already processing a client request."}
        _job.update({"busy": True, "slug": slug, "request_id": req_id, "message": "Queued", "error": ""})
    threading.Thread(target=fn, args=(slug, req_id), daemon=True).start()
    return {"ok": True, "slug": slug, "request_id": req_id}


def enqueue_process(slug: str, req_id: str) -> dict:
    return _enqueue(process_request, slug, req_id)


def enqueue_work(slug: str, req_id: str) -> dict:
    return _enqueue(apply_work, slug, req_id)


def merge_request(slug: str, req_id: str) -> None:
    _set(busy=True, slug=slug, request_id=req_id, message="Merging into main…", error="")
    root = clients.require_root(slug)
    folder = reqs.request_path(root, req_id)
    meta = reqs.load_meta(folder)
    if not meta:
        _set(busy=False, error="Unknown request")
        return
    try:
        tests = meta.get("tests") if isinstance(meta.get("tests"), dict) else {}
        if not tests.get("ok"):
            _set(error="Tests must pass before merging into main.", message="Merge not ready")
            return
        if meta.get("git_merged"):
            _set(message="Already merged into main")
            return
        if not meta.get("git_branch"):
            meta["git_branch"] = client_git.ensure_work_branch(slug, req_id, meta)
        reqs.append_log(folder, client_git.commit_work(root, req_id, meta))
        git_msg = client_git.push_and_merge(slug, req_id, meta)
        meta = reqs.load_meta(folder)
        meta["git_merged"] = True
        meta["status"] = "ready"
        meta["phase"] = "merged"
        meta["error"] = ""
        meta["message"] = f"{git_msg} Ready to deploy."
        reqs.save_meta(folder, meta)
        reqs.append_log(folder, git_msg)
        _set(message=git_msg)
    except Exception as exc:
        reqs.append_log(folder, f"Merge failed: {exc}")
        meta = reqs.load_meta(folder)
        meta["status"] = "error"
        meta["error"] = str(exc)[:800]
        reqs.save_meta(folder, meta)
        _set(error=str(exc)[:800], message="Merge failed")
    finally:
        _set(busy=False)


def enqueue_deploy(slug: str) -> dict:
    return _enqueue(package_client, slug, "")


def enqueue_merge(slug: str, req_id: str) -> dict:
    return _enqueue(merge_request, slug, req_id)


def record_video(slug: str, req_id: str) -> None:
    try:
        import client_request_video

        client_request_video.run(slug, req_id, _set)
    except Exception as exc:
        _set(error=str(exc)[:800], message="Video failed")
    finally:
        _set(busy=False)


def enqueue_video(slug: str, req_id: str) -> dict:
    return _enqueue(record_video, slug, req_id)
