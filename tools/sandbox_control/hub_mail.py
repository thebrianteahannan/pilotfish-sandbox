"""Outlook inbox for the hub: link account, find client-work mail, act on it."""

from __future__ import annotations

import email
import imaplib
import json
import re
import threading
from datetime import datetime, timedelta, timezone
from email.header import decode_header, make_header
from email.utils import parsedate_to_datetime
from pathlib import Path
from typing import Any

from flask import jsonify, request

import clients
import hub_graph

HERE = Path(__file__).resolve().parent
DATA = HERE / "data"
SETTINGS_PATH = DATA / "outlook.json"
ACTIONS_PATH = DATA / "outlook-actions.json"
CACHE_PATH = DATA / "outlook-cache.json"

OUTLOOK_HOSTS = ("outlook.office365.com", "imap-mail.outlook.com")
DEFAULT_HOST = OUTLOOK_HOSTS[0]
DEFAULT_PORT = 993

SKIP_FROM = re.compile(
    r"no-?reply|noreply|mailer-daemon|notifications@|newsletter|donotreply|do-not-reply",
    re.I,
)
SKIP_SUBJ = re.compile(
    r"unsubscribe|% off|password reset|verify your (?:email|account)|delivery status",
    re.I,
)
ASK = re.compile(
    r"\b(?:can you|could you|would you|is it possible|do you(?:r team)? support|"
    r"are you able|please (?:add|update|change|fix|build)|need(?:s|ed)?|"
    r"request|question|how (?:do|can|would)|what(?:'s| is) the (?:best|way))\b",
    re.I,
)
NEW_WORK = re.compile(r"\b(?:new (?:interface|work|project|demo)|build|implement|stand up|create)\b", re.I)
UPDATE = re.compile(r"\b(?:update|change|add|strip|remove|fix|modify|tweak)\b", re.I)
CAPABILITY = re.compile(
    r"\b(?:can you|capable|support|possible|do you (?:handle|do|map)|have you done)\b", re.I,
)
DOMAIN = re.compile(r"\b(hl7|fhir|edi|x12|837|835|834|270|271|278|interface|ehr|emr|acord)\b", re.I)

_lock = threading.Lock()
_sync = {"busy": False, "message": "", "error": ""}


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _load(path: Path, default):
    if not path.is_file():
        return default
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default
    return data if isinstance(data, type(default)) else default


def _save(path: Path, data) -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    tmp.replace(path)


def settings() -> dict:
    data = _load(SETTINGS_PATH, {})
    return data if isinstance(data, dict) else {}


def linked() -> bool:
    s = settings()
    return bool(s.get("user") and s.get("password") and s.get("verified")) or hub_graph.signed_in()


def public_status() -> dict:
    s = settings()
    graph = hub_graph.device_status()
    imap_on = bool(s.get("user") and s.get("password") and s.get("verified"))
    user = s.get("user") or graph.get("user") or ""
    if hub_graph.signed_in() and not user:
        try:
            info = hub_graph.me()
            user = info.get("mail") or info.get("userPrincipalName") or ""
        except Exception:
            user = ""
    mode = "imap" if imap_on else ("graph" if hub_graph.signed_in() else "none")
    return {
        "ok": True,
        "linked": linked(),
        "mode": mode,
        "user": user,
        "host": s.get("host") or DEFAULT_HOST,
        "port": int(s.get("port") or DEFAULT_PORT),
        "sync": dict(_sync),
        "device": graph,
        "cached_at": (_load(CACHE_PATH, {}) or {}).get("fetched_at") or "",
    }


def save_link(body: dict) -> dict:
    user = str(body.get("user") or body.get("email") or "").strip()
    password = str(body.get("password") or "").strip()
    if not user or not password:
        raise ValueError("Outlook email and password are required.")
    host = str(body.get("host") or DEFAULT_HOST).strip() or DEFAULT_HOST
    port = int(body.get("port") or DEFAULT_PORT)
    probe = {
        "user": user,
        "password": password,
        "host": host,
        "port": port,
        "mailbox": str(body.get("mailbox") or "INBOX"),
        "verified": False,
        "updated_at": _now(),
    }
    box = _imap_login(probe)
    try:
        box.logout()
    except Exception:
        pass
    probe["verified"] = True
    _save(SETTINGS_PATH, probe)
    return public_status()


def unlink() -> dict:
    hub_graph.clear()
    for path in (SETTINGS_PATH, CACHE_PATH):
        if path.is_file():
            path.unlink()
    return public_status()


def _hdr(raw) -> str:
    if not raw:
        return ""
    try:
        return str(make_header(decode_header(raw))).replace("\n", " ").strip()
    except Exception:
        return str(raw).replace("\n", " ").strip()


def _body(msg: email.message.Message) -> str:
    if msg.is_multipart():
        plain = html = ""
        for part in msg.walk():
            ctype = (part.get_content_type() or "").lower()
            disp = str(part.get("Content-Disposition") or "")
            if "attachment" in disp.lower():
                continue
            try:
                payload = part.get_payload(decode=True) or b""
                text = payload.decode(part.get_content_charset() or "utf-8", errors="replace")
            except Exception:
                continue
            if ctype == "text/plain" and not plain:
                plain = text
            elif ctype == "text/html" and not html:
                html = text
        raw = plain or html
    else:
        try:
            raw = (msg.get_payload(decode=True) or b"").decode(msg.get_content_charset() or "utf-8", errors="replace")
        except Exception:
            raw = str(msg.get_payload() or "")
    text = re.sub(r"(?is)<(script|style)[^>]*>.*?</\1>", " ", raw)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:12000]


def _when(msg: email.message.Message) -> str:
    raw = msg.get("Date") or ""
    try:
        dt = parsedate_to_datetime(raw)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return _now()


def classify(from_addr: str, subject: str, body: str, client_rows: list[dict]) -> dict | None:
    blob = f"{from_addr}\n{subject}\n{body}"
    if SKIP_FROM.search(from_addr or "") or SKIP_SUBJ.search(subject or ""):
        return None
    if re.search(r"list-unsubscribe", blob, re.I) and not ASK.search(blob):
        return None
    match = None
    low = blob.lower()
    for row in client_rows:
        name = (row.get("name") or "").lower()
        title = (row.get("title") or "").lower()
        slug = (row.get("slug") or "").lower()
        if name and len(name) >= 3 and name in low:
            match = row
            break
        if title and len(title) >= 4 and title.lower() in low:
            match = row
            break
        if slug and slug.replace("-", " ") in low:
            match = row
            break
    score = 0
    if ASK.search(blob):
        score += 8
    if NEW_WORK.search(blob):
        score += 6
    if UPDATE.search(blob):
        score += 5
    if CAPABILITY.search(blob):
        score += 6
    if DOMAIN.search(blob):
        score += 5
    if match:
        score += 10
    if "?" in (subject or "") or "?" in (body or "")[:400]:
        score += 3
    if score < 8:
        return None
    kind = "question"
    if NEW_WORK.search(blob):
        kind = "new_work"
    elif UPDATE.search(blob) and match:
        kind = "update"
    elif CAPABILITY.search(blob):
        kind = "capability"
    return {
        "kind": kind,
        "score": min(100, score),
        "client_slug": (match or {}).get("slug") or "",
        "client_name": (match or {}).get("name") or "",
    }


def _imap_login(s: dict) -> imaplib.IMAP4_SSL:
    last = None
    hosts = [s.get("host") or DEFAULT_HOST]
    for extra in OUTLOOK_HOSTS:
        if extra not in hosts:
            hosts.append(extra)
    port = int(s.get("port") or DEFAULT_PORT)
    for host in hosts:
        try:
            box = imaplib.IMAP4_SSL(host, port, timeout=45)
            box.login(s["user"], s["password"])
            s["host"] = host
            return box
        except Exception as exc:
            last = exc
    raise RuntimeError(
        f"Could not sign in to Outlook IMAP ({last}). "
        "Microsoft 365 often blocks this until an admin enables IMAP for the mailbox "
        "(Exchange admin center → Mailbox → Manage email apps → IMAP). "
        "Use the full email address and the mailbox password."
    )


def fetch_messages(*, limit: int = 80) -> list[dict]:
    if settings().get("verified") and settings().get("password"):
        return _fetch_imap(limit=limit)
    if hub_graph.signed_in():
        return _fetch_graph(limit=limit)
    raise ValueError("Link Outlook over IMAP first.")


def _fetch_imap(*, limit: int = 80) -> list[dict]:
    s = settings()
    since = (datetime.now(timezone.utc) - timedelta(days=45)).strftime("%d-%b-%Y")
    box = _imap_login(s)
    try:
        box.select(s.get("mailbox") or "INBOX", readonly=True)
        typ, data = box.search(None, "SINCE", since)
        if typ != "OK":
            raise RuntimeError("Outlook IMAP search failed.")
        ids = (data[0] or b"").split()[-limit:]
        rows: list[dict] = []
        for uid in reversed(ids):
            typ, fetched = box.fetch(uid, "(RFC822)")
            if typ != "OK" or not fetched or not fetched[0]:
                continue
            raw = fetched[0][1]
            msg = email.message_from_bytes(raw)
            mid = _hdr(msg.get("Message-ID")) or f"imap-{uid.decode()}"
            rows.append(
                {
                    "id": re.sub(r"[^a-zA-Z0-9._@+-]+", "_", mid)[:180],
                    "from": _hdr(msg.get("From")),
                    "to": _hdr(msg.get("To")),
                    "subject": _hdr(msg.get("Subject")),
                    "received_at": _when(msg),
                    "body": _body(msg),
                }
            )
        return rows
    finally:
        try:
            box.logout()
        except Exception:
            pass


def _fetch_graph(*, limit: int = 80) -> list[dict]:
    data = hub_graph.graph_get(
        "/me/mailFolders/inbox/messages",
        {
            "$top": str(min(limit, 80)),
            "$select": "id,subject,from,toRecipients,receivedDateTime,bodyPreview,body",
            "$orderby": "receivedDateTime desc",
        },
    )
    rows = []
    for item in data.get("value") or []:
        frm = ((item.get("from") or {}).get("emailAddress") or {})
        from_s = f"{frm.get('name') or ''} <{frm.get('address') or ''}>".strip()
        tos = []
        for rec in item.get("toRecipients") or []:
            addr = (rec.get("emailAddress") or {}).get("address") or ""
            if addr:
                tos.append(addr)
        body = (item.get("body") or {}).get("content") or item.get("bodyPreview") or ""
        if (item.get("body") or {}).get("contentType") == "html":
            body = re.sub(r"(?is)<(script|style)[^>]*>.*?</\1>", " ", body)
            body = re.sub(r"(?s)<[^>]+>", " ", body)
            body = re.sub(r"\s+", " ", body).strip()
        mid = str(item.get("id") or "")
        rows.append(
            {
                "id": re.sub(r"[^a-zA-Z0-9._@+-]+", "_", mid)[:180],
                "from": from_s,
                "to": ", ".join(tos),
                "subject": item.get("subject") or "",
                "received_at": item.get("receivedDateTime") or "",
                "body": (body or item.get("bodyPreview") or "")[:12000],
            }
        )
    return rows


def sync() -> dict:
    with _lock:
        if _sync.get("busy"):
            return {"ok": False, "error": "Already scanning Outlook."}
        _sync.update({"busy": True, "message": "Scanning Outlook…", "error": ""})
    try:
        client_rows = clients.list_clients()
        raw = fetch_messages()
        actions = _load(ACTIONS_PATH, {})
        kept = []
        for msg in raw:
            hit = classify(msg["from"], msg["subject"], msg["body"], client_rows)
            if not hit:
                continue
            act = actions.get(msg["id"]) or {}
            kept.append({**msg, **hit, "action": act})
        payload = {"fetched_at": _now(), "messages": kept}
        _save(CACHE_PATH, payload)
        _sync.update({"message": f"Found {len(kept)} work emails", "error": ""})
        return {"ok": True, **payload, **public_status()}
    except Exception as exc:
        _sync.update({"error": str(exc)[:500], "message": "Scan failed"})
        return {"ok": False, "error": str(exc)[:500], **public_status()}
    finally:
        _sync["busy"] = False


def inbox() -> dict:
    cache = _load(CACHE_PATH, {})
    actions = _load(ACTIONS_PATH, {})
    messages = []
    for msg in cache.get("messages") or []:
        act = actions.get(msg.get("id") or "") or msg.get("action") or {}
        if act.get("status") == "dismissed":
            continue
        messages.append({**msg, "action": act})
    return {"ok": True, "messages": messages, **public_status()}


def set_action(mail_id: str, action: dict) -> dict:
    actions = _load(ACTIONS_PATH, {})
    actions[mail_id] = {**action, "at": _now()}
    _save(ACTIONS_PATH, actions)
    return inbox()


def register(app) -> None:
    @app.get("/api/mail")
    def api_mail():
        return jsonify(inbox())

    @app.post("/api/mail/link")
    def api_mail_link():
        try:
            st = save_link(request.get_json(silent=True) or {})
        except Exception as exc:
            return jsonify({"ok": False, "error": str(exc)[:500]}), 400
        return jsonify({"ok": True, **st})

    @app.post("/api/mail/ms")
    def api_mail_ms():
        try:
            st = hub_graph.start_device_login()
        except Exception as exc:
            return jsonify({"ok": False, "error": str(exc)[:400]}), 400
        return jsonify({"ok": True, **public_status(), "device": st})

    @app.get("/api/mail/device")
    def api_mail_device():
        return jsonify({"ok": True, **public_status()})

    @app.post("/api/mail/unlink")
    def api_mail_unlink():
        return jsonify({"ok": True, **unlink()})

    @app.post("/api/mail/sync")
    def api_mail_sync():
        result = sync()
        return jsonify(result), (200 if result.get("ok") else 400)

    @app.post("/api/mail/<mail_id>/dismiss")
    def api_mail_dismiss(mail_id: str):
        return jsonify(set_action(mail_id, {"status": "dismissed"}))

    @app.post("/api/mail/<mail_id>/request")
    def api_mail_request(mail_id: str):
        import hub_mail_act

        body = request.get_json(silent=True) or {}
        try:
            result = hub_mail_act.create_request(mail_id, body.get("slug") or "")
        except (ValueError, FileNotFoundError) as exc:
            return jsonify({"ok": False, "error": str(exc)}), 400
        return jsonify(result), 201

    @app.post("/api/mail/<mail_id>/demo")
    def api_mail_demo(mail_id: str):
        import hub_mail_act

        body = request.get_json(silent=True) or {}
        try:
            result = hub_mail_act.create_demo(mail_id, body.get("slug") or "", body.get("title") or "")
        except ValueError as exc:
            return jsonify({"ok": False, "error": str(exc)}), 400
        return jsonify(result), 201
