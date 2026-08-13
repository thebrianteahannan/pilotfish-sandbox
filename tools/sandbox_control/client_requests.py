"""Persist client email change-requests under Clients/<Name>/requests/."""

from __future__ import annotations

import json
import re
import shutil
import threading
from datetime import datetime, timezone
from pathlib import Path

import clients
import difflib

_lock = threading.Lock()


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def requests_dir(root: Path) -> Path:
    path = root / "requests"
    path.mkdir(parents=True, exist_ok=True)
    keep = path / ".gitkeep"
    if not keep.is_file():
        keep.write_text("", encoding="utf-8")
    return path


_ZIP_SKIP = {"summarize", "this", "email", "fwd", "re", "fw"}


def _slug_bit(text: str) -> str:
    bit = re.sub(r"[^a-z0-9]+", "-", (text or "").strip().lower()).strip("-")
    return (bit[:40] or "request").strip("-")


def zip_filename(client: str, folder: Path, meta: dict) -> str:
    subject = str(meta.get("subject") or "")
    dive_path = folder / "dive.json"
    if dive_path.is_file():
        try:
            dive = json.loads(dive_path.read_text(encoding="utf-8"))
            subject = str(dive.get("subject") or subject)
        except (OSError, json.JSONDecodeError):
            pass
    cleaned = re.sub(r"[\u20ac€©]?\s*summarize this email", "", subject or "", flags=re.I)
    parts = [p for p in _slug_bit(cleaned).split("-") if p and not p.isdigit() and p not in _ZIP_SKIP]
    short = "-".join(parts[:3]) or "request"
    base = re.sub(r"[^A-Za-z0-9]+", "", client or "Client")
    stamp = datetime.now().strftime("%Y%m%d")
    return f"{base}_TEST_Deploy_{stamp}_{short}.zip"


def new_id(subject: str) -> str:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return f"{stamp}-{_slug_bit(subject)}"


def request_path(root: Path, req_id: str) -> Path:
    req_id = Path(req_id).name
    if not req_id or req_id.startswith("."):
        raise ValueError("invalid request id")
    return requests_dir(root) / req_id


def meta_path(folder: Path) -> Path:
    return folder / "request.json"


def load_meta(folder: Path) -> dict:
    path = meta_path(folder)
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def save_meta(folder: Path, data: dict) -> dict:
    folder.mkdir(parents=True, exist_ok=True)
    payload = dict(data)
    payload["updated_at"] = utc_now()
    tmp = folder / "request.json.tmp"
    tmp.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    tmp.replace(meta_path(folder))
    return payload


def append_log(folder: Path, text: str) -> None:
    line = {"at": utc_now(), "text": str(text).strip()}
    if not line["text"]:
        return
    path = folder / "log.jsonl"
    with _lock:
        with path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(line) + "\n")
        meta = load_meta(folder)
        log = list(meta.get("log") or [])
        log.append(line)
        meta["log"] = log[-24:]
        meta["message"] = line["text"]
        save_meta(folder, meta)


def _summary(meta: dict, folder: Path | None = None) -> dict:
    import client_hours

    hours = client_hours.for_request(meta, folder)
    return {
        "id": meta.get("id"),
        "from": meta.get("from") or "",
        "subject": meta.get("subject") or "",
        "received_at": meta.get("received_at") or meta.get("created_at") or "",
        "status": "ready" if meta.get("git_merged") else (meta.get("status") or "received"),
        "phase": meta.get("phase") or "",
        "message": meta.get("message") or "",
        "plan_pdf": bool(meta.get("plan_pdf")),
        "zip": meta.get("zip") or "",
        "tests_ok": (meta.get("tests") or {}).get("ok") if isinstance(meta.get("tests"), dict) else None,
        "change_count": len(meta.get("changes") or []),
        "git_merged": bool(meta.get("git_merged")),
        "git_branch": meta.get("git_branch") or "",
        "billable_hours": hours["hours"],
        "billable_label": hours["label"],
    }


def list_requests(slug: str) -> list[dict]:
    try:
        root = clients.require_root(slug)
    except ValueError:
        return []
    folder = root / "requests"
    if not folder.is_dir():
        return []
    rows = []
    for child in folder.iterdir():
        if not child.is_dir() or child.name.startswith("_") or not meta_path(child).is_file():
            continue
        rows.append(_summary(load_meta(child), child))
    rows.sort(key=lambda r: r.get("id") or "", reverse=True)
    return rows


def set_comments(slug: str, req_id: str, text: str) -> dict:
    folder = request_path(clients.require_root(slug), req_id)
    meta = load_meta(folder)
    if not meta:
        raise FileNotFoundError(req_id)
    meta["comments"] = str(text or "").strip()
    save_meta(folder, meta)
    return meta


def _comment_log(meta: dict) -> list:
    log = list(meta.get("comment_log") or [])
    if not log and str(meta.get("comments") or "").strip():
        log.append({"at": str(meta.get("updated_at") or ""), "text": str(meta["comments"]).strip()})
    return log


def _store_comments(folder: Path, meta: dict, log: list) -> dict:
    meta["comment_log"] = log
    meta["comments"] = "\n\n".join(str(c.get("text") or "") for c in log if c.get("text"))
    save_meta(folder, meta)
    return meta


def _load_comment_meta(slug: str, req_id: str) -> tuple[Path, dict]:
    folder = request_path(clients.require_root(slug), req_id)
    meta = load_meta(folder)
    if not meta:
        raise FileNotFoundError(req_id)
    return folder, meta


def _take_inbox_shot(root: Path, folder: Path, rel: str) -> str:
    inbox = (root / "requests" / "_inbox").resolve()
    rel = str(rel or "").strip()
    if not rel:
        return ""
    src = (clients.ROOT / rel).resolve() if not Path(rel).is_absolute() else Path(rel).resolve()
    try:
        src.relative_to(inbox)
    except ValueError:
        return ""
    if not src.is_file():
        return ""
    ext = src.suffix.lower() or ".png"
    n = 1
    while (folder / f"comment-shot-{n}{ext}").exists():
        n += 1
    dest = folder / f"comment-shot-{n}{ext}"
    shutil.copy2(src, dest)
    sidecar = Path(str(src) + ".ocr.json")
    if sidecar.is_file():
        shutil.copy2(sidecar, folder / f"{dest.stem}.ocr.json")
    return dest.name


def add_comment(slug: str, req_id: str, text: str, screenshot: str = "") -> dict:
    text = str(text or "").strip()
    if not text:
        raise ValueError("Comment is empty")
    folder, meta = _load_comment_meta(slug, req_id)
    rec: dict = {"at": utc_now(), "text": text}
    if screenshot:
        name = _take_inbox_shot(clients.require_root(slug), folder, screenshot)
        if name:
            rec["screenshot"] = name
    log = _comment_log(meta)
    log.append(rec)
    return _store_comments(folder, meta, log)


def edit_comment(slug: str, req_id: str, index: int, text: str) -> dict:
    text = str(text or "").strip()
    if not text:
        raise ValueError("Comment is empty")
    folder, meta = _load_comment_meta(slug, req_id)
    log = _comment_log(meta)
    if index < 0 or index >= len(log):
        raise ValueError("Unknown comment")
    log[index]["text"] = text
    log[index]["edited_at"] = utc_now()
    return _store_comments(folder, meta, log)


def delete_comment(slug: str, req_id: str, index: int) -> dict:
    folder, meta = _load_comment_meta(slug, req_id)
    log = _comment_log(meta)
    if index < 0 or index >= len(log):
        raise ValueError("Unknown comment")
    rec = log.pop(index)
    name = str(rec.get("screenshot") or "")
    if name.startswith("comment-shot-"):
        for path in (folder / name, folder / f"{Path(name).stem}.ocr.json"):
            if path.is_file():
                path.unlink()
    return _store_comments(folder, meta, log)


def get_request(slug: str, req_id: str) -> dict:
    root = clients.require_root(slug)
    folder = request_path(root, req_id)
    meta = load_meta(folder)
    if not meta:
        raise FileNotFoundError(req_id)
    email = ""
    email_path = folder / "email.txt"
    if email_path.is_file():
        email = email_path.read_text(encoding="utf-8", errors="replace")
    plan = ""
    plan_path = folder / "changes-needed.md"
    if plan_path.is_file():
        plan = plan_path.read_text(encoding="utf-8", errors="replace")
    diff = ""
    diff_path = folder / "changes.diff"
    if diff_path.is_file():
        diff = diff_path.read_text(encoding="utf-8", errors="replace")
    meta["email"] = email
    meta["plan"] = plan
    meta["diff"] = diff[-20000:]
    tests_path = folder / "tests.json"
    if tests_path.is_file():
        try:
            loaded_tests = json.loads(tests_path.read_text(encoding="utf-8"))
            if isinstance(loaded_tests, dict) and loaded_tests.get("items"):
                try:
                    import client_proof

                    loaded_tests["items"] = client_proof.hydrate(folder, loaded_tests["items"])
                except Exception:
                    pass
                meta["tests"] = loaded_tests
        except (OSError, json.JSONDecodeError):
            pass
    side_path = folder / "changes-side.html"
    meta["diff_html"] = side_path.read_text(encoding="utf-8", errors="replace") if side_path.is_file() else ""
    meta["folder"] = folder.relative_to(clients.ROOT).as_posix()
    pdf = folder / "changes-needed.pdf"
    meta["plan_pdf"] = bool(pdf.is_file())
    meta["plan_pdf_url"] = f"/api/clients/{meta.get('slug')}/requests/{folder.name}/plan.pdf" if pdf.is_file() else ""
    dive_path = folder / "dive.json"
    dive = {}
    if dive_path.is_file():
        try:
            loaded = json.loads(dive_path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                dive = {
                    "summary": loaded.get("summary") or "",
                    "ask": loaded.get("ask") or "",
                    "codes": loaded.get("codes") or [],
                    "risks": loaded.get("risks") or [],
                    "edit_count": len(loaded.get("edits") or []),
                    "comments": loaded.get("comments") or "",
                    "delta": loaded.get("delta") or [],
                    "files": [{"path": f.get("path"), "hits": f.get("hits") or []} for f in (loaded.get("files") or [])],
                }
        except (OSError, json.JSONDecodeError):
            dive = {}
    meta["dive"] = dive
    import client_hours

    hours = client_hours.for_request(meta, folder, dive)
    meta["billable_hours"] = hours["hours"]
    meta["billable_label"] = hours["label"]
    shots = []
    base = f"/api/clients/{meta.get('slug')}/requests/{folder.name}/screenshot/"
    for name in meta.get("screenshots") or []:
        p = folder / str(name)
        if p.is_file():
            shots.append(base + p.name)
    meta["screenshot_urls"] = shots
    for rec in meta.get("comment_log") or []:
        name = str(rec.get("screenshot") or "")
        if name and (folder / name).is_file():
            rec["screenshot_url"] = base + name
    import client_request_video

    meta["video"] = client_request_video.snapshot(folder, meta.get("slug") or slug, folder.name)
    if meta.get("git_merged"):
        meta["status"] = "ready"
    return meta


def create_request(slug: str, body: dict) -> dict:
    root = clients.require_root(slug)
    sender = str(body.get("from") or "").strip()
    subject = re.sub(r"[\u20ac€©]?\s*summarize this email", "", str(body.get("subject") or ""), flags=re.I)
    subject = subject.strip(" \t-–—|") or "Client request"
    received = str(body.get("received_at") or "").strip() or utc_now()
    email = str(body.get("email") or "").strip()
    if not email:
        raise ValueError("Paste the client email or drop a screenshot.")
    req_id = new_id(subject)
    folder = request_path(root, req_id)
    folder.mkdir(parents=True, exist_ok=False)
    (folder / "email.txt").write_text(email + ("\n" if not email.endswith("\n") else ""), encoding="utf-8")
    shots = _copy_screenshots(root, folder, body.get("screenshots"))
    meta = {
        "id": req_id,
        "slug": slug,
        "client": root.name,
        "from": sender,
        "subject": subject,
        "received_at": received,
        "created_at": utc_now(),
        "status": "received",
        "phase": "",
        "message": "Saved",
        "comments": "",
        "asks": [],
        "likely_files": [],
        "changes": [],
        "tests": None,
        "zip": "",
        "screenshots": shots,
        "source": "screenshot" if shots else "paste",
        "log": [],
    }
    save_meta(folder, meta)
    append_log(folder, f"Saved email request ({len(email)} chars)")
    try:
        import hub_ntfy

        hub_ntfy.notify("New email request", f"{root.name}: {subject}", slug=slug, req_id=req_id, tags="incoming_envelope")
    except Exception:
        pass
    try:
        from client_pipeline import snapshot_hashes

        (folder / "baseline.json").write_text(json.dumps(snapshot_hashes(root), indent=2) + "\n", encoding="utf-8")
    except Exception:
        pass
    return load_meta(folder)


def _copy_screenshots(root: Path, folder: Path, shots) -> list[str]:
    inbox = (root / "requests" / "_inbox").resolve()
    names: list[str] = []
    if isinstance(shots, str):
        try:
            shots = json.loads(shots)
        except json.JSONDecodeError:
            shots = [shots] if shots.strip() else []
    if not isinstance(shots, list):
        return names
    for i, raw in enumerate(shots, start=1):
        rel = str(raw or "").strip()
        if not rel:
            continue
        src = (clients.ROOT / rel).resolve() if not Path(rel).is_absolute() else Path(rel).resolve()
        try:
            src.relative_to(inbox)
        except ValueError:
            continue
        if not src.is_file():
            continue
        dest = folder / f"screenshot-{i}{src.suffix.lower() or '.png'}"
        shutil.copy2(src, dest)
        names.append(dest.name)
        sidecar = Path(str(src) + ".ocr.json")
        if sidecar.is_file():
            shutil.copy2(sidecar, folder / f"screenshot-{i}.ocr.json")
    return names


VIEW_OK = {".xml", ".xslt", ".xsl", ".xsd", ".html", ".json", ".sql", ".txt", ".conf"}
XML_OK = {".xml", ".xslt", ".xsl", ".xsd", ".html"}


def pretty_xml(text: str) -> str:
    from xml.dom import minidom

    parsed = minidom.parseString(text.encode("utf-8"))
    body = parsed.documentElement.toprettyxml(indent="  ")
    lines = [ln.rstrip() for ln in body.splitlines() if ln.strip()]
    decl = ""
    stripped = text.lstrip()
    if stripped.startswith("<?xml"):
        decl = stripped.split("?>", 1)[0] + "?>\n"
    return decl + "\n".join(lines) + "\n"


def format_view_text(path: Path, text: str) -> tuple[str, str]:
    lang = "xml" if path.suffix.lower() in XML_OK else ("json" if path.suffix.lower() == ".json" else "text")
    if lang == "xml":
        try:
            text = pretty_xml(text)
        except Exception:
            pass
    elif lang == "json":
        try:
            text = json.dumps(json.loads(text), indent=2) + "\n"
        except Exception:
            pass
    return text, lang


def changed_line_nums(old: str, new: str, side: str) -> list[int]:
    a = (old or "").splitlines()
    b = (new or "").splitlines()
    out: list[int] = []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(a=a, b=b).get_opcodes():
        if tag == "equal":
            continue
        if side == "before" and tag in {"replace", "delete"}:
            out.extend(range(i1 + 1, i2 + 1))
        if side != "before" and tag in {"replace", "insert"}:
            out.extend(range(j1 + 1, j2 + 1))
        if side != "before" and tag == "delete":
            if j1 > 0:
                out.append(j1)
            if j1 < len(b):
                out.append(j1 + 1)
    return sorted(set(out))


def view_file(slug: str, rel: str, side: str = "after") -> dict:
    root = clients.require_root(slug)
    rel = (rel or "").replace("\\", "/").strip().lstrip("/")
    if not rel or ".." in Path(rel).parts:
        raise ValueError("invalid path")
    path = (root / rel).resolve()
    path.relative_to(root.resolve())
    rel_ok = path.relative_to(root.resolve()).as_posix()
    if not (rel_ok.startswith("eip-root/") or rel_ok.startswith("deploy/")):
        raise ValueError("invalid path")
    if path.suffix.lower() not in VIEW_OK:
        raise ValueError("unsupported file type")
    bak = path.with_name(path.name + ".bak-req")
    after = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    before = bak.read_text(encoding="utf-8", errors="replace") if bak.is_file() else ""
    if not after and not before:
        raise FileNotFoundError(rel)
    after, lang = format_view_text(path, after)
    before, _ = format_view_text(path, before) if before else ("", lang)
    use_before = side == "before" and bool(before)
    text = before if use_before else after
    shown = "before" if use_before else "after"
    return {
        "name": path.name,
        "path": rel_ok,
        "side": shown,
        "has_before": bool(before),
        "language": lang,
        "text": text,
        "changed": changed_line_nums(before, after, shown) if before else [],
    }
