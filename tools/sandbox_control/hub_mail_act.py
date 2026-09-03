"""Turn an Outlook work-email into a client request or a new demo folder."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import client_requests
import clients
import demos
import hub_mail

TOOLS = Path(__file__).resolve().parent.parent
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))


def _message(mail_id: str) -> dict:
    cache = hub_mail._load(hub_mail.CACHE_PATH, {})
    for msg in cache.get("messages") or []:
        if msg.get("id") == mail_id:
            return msg
    raise ValueError("Email not in the last Outlook scan. Refresh first.")


def create_request(mail_id: str, slug: str) -> dict:
    msg = _message(mail_id)
    slug = (slug or msg.get("client_slug") or "").strip()
    if not slug:
        raise ValueError("Pick a client for this request.")
    clients.require_root(slug)
    email_txt = (msg.get("body") or "").strip()
    if not email_txt:
        email_txt = msg.get("subject") or "(no body)"
    meta = client_requests.create_request(
        slug,
        {
            "from": msg.get("from") or "",
            "subject": msg.get("subject") or "",
            "received_at": msg.get("received_at") or "",
            "email": email_txt,
        },
    )
    hub_mail.set_action(
        mail_id,
        {"status": "request", "slug": slug, "req_id": meta.get("id") or ""},
    )
    return {"ok": True, "slug": slug, "request": meta, **hub_mail.inbox()}


def _next_port() -> int:
    used = {int(d.get("webui_port") or 0) for d in demos.list_demos()}
    used.add(8077)
    used.add(8130)
    used.add(8765)
    for port in range(8140, 8199):
        if port not in used:
            return port
    return 8190


def _category(text: str) -> str:
    blob = (text or "").lower()
    if re.search(r"\b(837|835|834|270|271|278|x12|edi)\b", blob):
        return "Insurance/EDI"
    if re.search(r"\bhl7\b|\badt\b|\boru\b|\bmllp\b", blob):
        return "Medical/HL7"
    if re.search(r"\bfhir\b", blob):
        return "Medical/FHIR"
    return "Other"


def create_demo(mail_id: str, slug: str, title: str) -> dict:
    import scaffold_demo_stage

    msg = _message(mail_id)
    title = (title or msg.get("subject") or "New demo").strip()
    title = re.sub(r"^(re|fw|fwd):\s*", "", title, flags=re.I)
    slug = scaffold_demo_stage.slugify(slug or title)
    demo = scaffold_demo_stage.scaffold(
        slug,
        title,
        _next_port(),
        category=_category(f"{msg.get('subject')} {msg.get('body')}"),
    )
    note = (
        f"From Outlook: {msg.get('from')}\n"
        f"Subject: {msg.get('subject')}\n"
        f"Received: {msg.get('received_at')}\n\n"
        f"{msg.get('body') or ''}\n"
    )
    (demo / "documents" / "from-email.txt").write_text(note, encoding="utf-8")
    design = demo / "DESIGN.md"
    if design.is_file():
        extra = f"\n## Source email\n\n{msg.get('subject')}\n\nSee `documents/from-email.txt`.\n"
        design.write_text(design.read_text(encoding="utf-8") + extra, encoding="utf-8")
    hub_mail.set_action(mail_id, {"status": "demo", "slug": slug})
    return {
        "ok": True,
        "slug": slug,
        "path": str(demo.relative_to(demos.ROOT)),
        **hub_mail.inbox(),
    }
