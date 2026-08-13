"""Fire-and-forget ntfy.sh alerts for Sandbox client-request milestones."""

from __future__ import annotations

import json
import os
import threading
import urllib.error
import urllib.parse
import urllib.request

import demos

TOPIC = os.environ.get("SANDBOX_NTFY_TOPIC", "pilotfish-sandbox")
NTFY = os.environ.get("SANDBOX_NTFY_URL", "https://ntfy.sh").rstrip("/")


def hub_url(slug: str = "", req_id: str = "") -> str:
    lan = demos.lan_ip()
    port = os.environ.get("SANDBOX_HUB_PORT", "8077")
    query = urllib.parse.urlencode({"tab": "clients", "client": slug, "request": req_id})
    return f"http://{lan}:{port}/?{query}"


def _post(title: str, message: str, url: str, tags: list[str]) -> None:
    payload = json.dumps(
        {
            "topic": TOPIC,
            "title": title,
            "message": message,
            "click": url,
            "tags": tags,
            "actions": [{"action": "view", "label": "Open on LAN", "url": url, "clear": True}],
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        NTFY,
        data=payload,
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )
    try:
        urllib.request.urlopen(req, timeout=5).read()
    except (urllib.error.URLError, TimeoutError, OSError):
        pass


def notify(title: str, detail: str, *, slug: str = "", req_id: str = "", tags: str = "mailbox") -> None:
    url = hub_url(slug, req_id)
    body = "\n".join(p for p in (detail.strip(), url) if p)
    tag_list = [t for t in (tags or "").split(",") if t]
    threading.Thread(target=_post, args=(title, body, url, tag_list), daemon=True).start()
