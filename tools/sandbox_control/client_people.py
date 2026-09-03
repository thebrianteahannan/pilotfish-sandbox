"""People on a client: name + email, harvested from request From lines."""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

import clients
import client_requests

FILE = "people.json"
ADDR = re.compile(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}")
ANGLE = re.compile(r"^(.+?)\s*<([^>]+@[^>]+)>\s*$")
LEADING_INITIALS = re.compile(r"^([A-Z]{2,3})\s+(.+)$")


def _path(root: Path) -> Path:
    return root / FILE


def _load(root: Path) -> list[dict]:
    path = _path(root)
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    rows = data.get("people") if isinstance(data, dict) else data
    out = []
    for row in rows or []:
        if not isinstance(row, dict):
            continue
        name = _name_from_from(str(row.get("name") or "").strip())
        email = str(row.get("email") or "").strip()
        if not name and not email:
            continue
        out.append(
            {
                "id": str(row.get("id") or _id(email, name)),
                "name": name,
                "email": email,
                "source": str(row.get("source") or "manual"),
            }
        )
    return out


def _save(root: Path, people: list[dict]) -> None:
    _path(root).write_text(json.dumps({"people": people}, indent=2) + "\n", encoding="utf-8")


def _id(email: str, name: str) -> str:
    key = (email or name or "p").strip().lower()
    return re.sub(r"[^a-z0-9]+", "-", key).strip("-")[:40] or f"p-{int(time.time())}"


def _name_from_from(name: str) -> str:
    name = name.strip().strip("\"'")
    m = LEADING_INITIALS.match(name)
    if not m:
        return name
    tag, rest = m.group(1), m.group(2)
    words = [w for w in rest.split() if w[:1].isalpha()]
    if len(words) < 2:
        return name
    initials = "".join(w[0] for w in words).upper()
    first_last = (words[0][0] + words[-1][0]).upper()
    if tag in (initials, initials[: len(tag)], first_last):
        return rest
    return name


def parse_from(raw: str) -> tuple[str, str]:
    raw = " ".join(str(raw or "").split())
    if not raw:
        return "", ""
    m = ANGLE.match(raw)
    if m:
        return _name_from_from(m.group(1)), m.group(2).strip()
    found = ADDR.search(raw)
    if found:
        email = found.group(0)
        name = _name_from_from(raw.replace(email, "").strip(" <>\",'"))
        return name, email
    return _name_from_from(raw), ""


def _merge(people: list[dict], name: str, email: str, source: str) -> bool:
    name, email = name.strip(), email.strip()
    if not name and not email:
        return False
    el = email.lower()
    nl = name.lower()
    for row in people:
        if el and (row.get("email") or "").lower() == el:
            if name and not row.get("name"):
                row["name"] = name
            return False
        if not el and nl and (row.get("name") or "").lower() == nl and not row.get("email"):
            return False
    people.append({"id": _id(email, name), "name": name, "email": email, "source": source})
    return True


def harvest(slug: str) -> list[dict]:
    root = clients.require_root(slug)
    people = _load(root)
    added = 0
    for req in client_requests.list_requests(slug):
        name, email = parse_from(req.get("from") or "")
        if _merge(people, name, email, "email"):
            added += 1
        try:
            folder = client_requests.request_path(root, req.get("id") or "")
        except ValueError:
            continue
        mail = folder / "email.txt"
        if mail.is_file():
            for line in mail.read_text(encoding="utf-8", errors="replace").splitlines()[:40]:
                if re.match(r"(?i)^from\s*[:\-]", line):
                    n, e = parse_from(re.sub(r"(?i)^from\s*[:\-]\s*", "", line))
                    if _merge(people, n, e, "email"):
                        added += 1
    if added:
        _save(root, people)
    return people


def snapshot(slug: str) -> dict:
    import eip_runtime

    root = clients.require_root(slug)
    return {
        "ok": True,
        "eip_version": clients.eip_version(root),
        "eip_wars": eip_runtime.list_wars(),
        "people": _load(root),
        "title": clients.client_title(root),
        "path": root.relative_to(clients.ROOT).as_posix(),
    }


def add(slug: str, name: str, email: str) -> dict:
    root = clients.require_root(slug)
    people = _load(root)
    name, email = str(name or "").strip(), str(email or "").strip()
    if email and not ADDR.search(email):
        raise ValueError("That does not look like an email address")
    if not name and not email:
        raise ValueError("Enter a name or email")
    _merge(people, name, email, "manual")
    _save(root, people)
    return snapshot(slug)


def remove(slug: str, pid: str) -> dict:
    root = clients.require_root(slug)
    people = [p for p in _load(root) if p.get("id") != pid]
    _save(root, people)
    return snapshot(slug)
