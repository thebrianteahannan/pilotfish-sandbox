"""Process a client email request: plan, sandbox tests, interface diff, TEST zip."""

from __future__ import annotations

import difflib
import hashlib
import json
import threading
import time
import urllib.error
import urllib.request
import zipfile
from datetime import datetime
from html import escape as html_esc
from pathlib import Path

import client_dive
import client_plan_pdf
import client_requests as reqs
import clients
import demos
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
    return f'<div class="diff-file"><p class="diff-name"><button type="button" class="diff-file-open" data-rel="{html_esc(rel)}" title="{html_esc(rel)}">{html_esc(rel)}</button></p>{table}</div>'


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


def wait_url(url: str, timeout: float = 60.0) -> bool:
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
    items = []
    url = "http://127.0.0.1:8080/eip/"
    up = wait_url(url, timeout=90)
    items.append({"name": "EIP http://127.0.0.1:8080/eip/", "ok": up, "detail": "up" if up else "not responding"})
    log = clients.ROOT / "logs" / "eip.log"
    if log.is_file():
        tail = log.read_text(encoding="utf-8", errors="replace")[-4000:]
        bad = "SEVERE" in tail and "Exception" in tail
        items.append({"name": "eip.log present", "ok": True, "detail": "recent SEVERE+Exception" if bad else "ok"})
    else:
        items.append({"name": "eip.log present", "ok": False, "detail": "no log yet"})
    seen: set[str] = set()
    for ed in (dive or {}).get("edits") or []:
        code = str(ed.get("code") or "")
        rel = str(ed.get("path") or "")
        if ed.get("action") != "remove_when" or not code or not rel or code in seen:
            continue
        seen.add(code)
        inner = rel.split("eip-root/", 1)[-1]
        dest = f"/usr/local/tomcat/webapps/eip/eip-root/{inner}"
        rc, _ = demos.run(["docker", "exec", "pilotfish-eip", "grep", "-F", code, dest], timeout=20)
        gone = rc != 0
        items.append({"name": f"EIP stripped {code}", "ok": gone, "detail": "absent" if gone else "still present"})
    result = {"ok": all(i["ok"] for i in items), "items": items}
    (folder / "tests.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    return result


def ensure_sandbox(root: Path, folder: Path) -> None:
    if clients.is_running(root):
        reqs.append_log(folder, "Sandbox already running")
        return
    reqs.append_log(folder, f"Starting {root.name} sandbox…")
    clients.start_client(root)


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
    deploy_txt = write_deploy_txt(root, meta, changes, tests)
    (folder / "DEPLOY.txt").write_text(deploy_txt, encoding="utf-8")
    with zipfile.ZipFile(zpath, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for fname in ("DEPLOY.txt", "email.txt", "changes-needed.md", "changes-needed.pdf", "dive.json", "tests.json", "changes.diff", "request.json"):
            p = folder / fname
            if p.is_file():
                zf.write(p, f"{pack}/{fname}")
        for rec in changes:
            src = root / rec["path"]
            if src.is_file():
                zf.write(src, f"{pack}/{rec['path']}")
        for shot in sorted(folder.glob("screenshot-*")):
            if shot.is_file() and shot.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".gif", ".tif", ".tiff"}:
                zf.write(shot, f"{pack}/{shot.name}")
    return zpath


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
        _set(message="Reading eip-root against the email…")
        dive = client_dive.dive(root, email, str(meta.get("subject") or ""))
        client_dive.write_markdown(folder, meta, dive)
        pdf = client_plan_pdf.write_plan_pdf(folder, meta, dive)
        meta["asks"] = dive.get("codes") or []
        meta["likely_files"] = [f["path"] for f in dive.get("files") or []]
        meta["plan_pdf"] = pdf.name
        meta["edit_count"] = len(dive.get("edits") or [])
        meta["status"] = "planned"
        meta["phase"] = "review"
        meta["message"] = "Change plan PDF ready — review it, then Start work"
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


def _work_paths(root: Path, meta: dict, dive: dict, applied: list[dict]) -> list[str]:
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
    for path in root.joinpath("eip-root").rglob("*.bak-req") if (root / "eip-root").is_dir() else []:
        src = path.with_name(path.name[: -len(".bak-req")])
        if src.is_file():
            rel = src.relative_to(root).as_posix()
            if rel not in rels:
                extra.append(rel)
    return rels + extra


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
        meta["status"] = "processing"
        meta["phase"] = "applying"
        meta["zip"] = ""
        reqs.save_meta(folder, meta)
        hub_ntfy.notify("Work started", f"{root.name}: {meta.get('subject') or req_id}", slug=slug, req_id=req_id, tags="hammer")
        applied = client_dive.apply_edits(root, dive)
        if not applied:
            applied = list(meta.get("applied") or [])
            reqs.append_log(folder, "Edits already on disk" if applied else "No automatic edits — loading sandbox anyway")
        else:
            meta["applied"] = applied
            reqs.append_log(folder, f"Applied {len(applied)} file edit(s)")
        rels = _work_paths(root, meta, dive, applied)
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
        meta["status"] = "tested"
        meta["phase"] = "review"
        meta["tests"] = tests
        if tests.get("ok"):
            meta["message"] = "Tests passed. Review the code diff, then generate the TEST zip."
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


def package_request(slug: str, req_id: str) -> None:
    _set(busy=True, slug=slug, request_id=req_id, message="Building TEST zip…", error="")
    root = clients.require_root(slug)
    folder = reqs.request_path(root, req_id)
    meta = reqs.load_meta(folder)
    if not meta:
        _set(busy=False, error="Unknown request")
        return
    try:
        if meta.get("status") not in {"tested", "ready"}:
            _set(error="Start work and review the results before generating a zip.", message="Zip not ready")
            return
        tests = meta.get("tests") if isinstance(meta.get("tests"), dict) else {}
        changes = meta.get("changes") if isinstance(meta.get("changes"), list) else []
        zpath = package_zip(root, folder, meta, changes, tests)
        meta["zip"] = zpath.name
        meta["zip_kb"] = zpath.stat().st_size // 1024
        meta["status"] = "ready"
        meta["phase"] = "done"
        meta["message"] = f"TEST zip ready ({meta['zip_kb']} KB)"
        reqs.save_meta(folder, meta)
        reqs.append_log(folder, f"Packaged {zpath.name} ({meta['zip_kb']} KB)")
        hub_ntfy.notify("TEST deploy ZIP ready", f"{zpath.name}\n{root.name}: {meta.get('subject') or req_id}", slug=slug, req_id=req_id, tags="package")
        _set(message=meta["message"])
    except Exception as exc:
        reqs.append_log(folder, f"Zip failed: {exc}")
        meta = reqs.load_meta(folder)
        meta["status"] = "error"
        meta["error"] = str(exc)[:800]
        reqs.save_meta(folder, meta)
        _set(error=str(exc)[:800], message="Zip failed")
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


def enqueue_zip(slug: str, req_id: str) -> dict:
    return _enqueue(package_request, slug, req_id)
