"""Read failed Implement tests and apply the next on-disk fix."""

from __future__ import annotations

import re
from pathlib import Path

import client_dive
import clients

MAX_TRIES = 8


def failed(tests: dict) -> list[dict]:
    return [i for i in (tests.get("items") or []) if not i.get("ok")]


def _place(path: Path, old: str, new: str, replace_all: bool) -> bool:
    if not path.is_file() or not new:
        return False
    text = path.read_text(encoding="utf-8", errors="replace")
    if new in text:
        return False
    client_dive._bak_req(path)
    if old and old in text:
        path.write_text(text.replace(old, new) if replace_all else text.replace(old, new, 1), encoding="utf-8")
        return True
    add = ""
    if old and new.startswith(old):
        add = new[len(old) :]
    elif "+ (if" in new:
        add = new[new.find("+ (if") :]
        if add.endswith('"'):
            add = add[:-1]
    head = (old or new).split("+ (if")[0]
    if add and add not in text and head and head in text:
        nxt = head.rstrip('"') + add + ('"' if head.endswith('"') else "")
        path.write_text(text.replace(head, nxt) if replace_all else text.replace(head, nxt, 1), encoding="utf-8")
        return True
    for n in (160, 100, 60):
        if old and len(old) > n and text.count(old[:n]) == 1:
            end = text.find(old[:n]) + n
            q = text.find('"', end)
            span = text[text.find(old[:n]) : q + 1] if q > end else old[:n]
            path.write_text(text.replace(span, new if new.endswith('"') or '"' not in span else new, 1), encoding="utf-8")
            return True
    return False


def _fix_edit(root: Path, ed: dict) -> str:
    if ed.get("action") != "replace_block":
        return ""
    path = root / str(ed.get("path") or "")
    if _place(path, str(ed.get("old") or ""), str(ed.get("new") or ""), bool(ed.get("replace_all"))):
        return f"Re-applied {ed.get('title') or path.name}"
    return ""


def repair(root: Path, dive: dict, tests: dict) -> tuple[bool, list[str]]:
    notes: list[str] = []
    for item in failed(tests):
        detail = str(item.get("detail") or "")
        name = str(item.get("name") or "")
        if "not responding" in detail or name.startswith("EIP "):
            try:
                clients.start_client(root)
                notes.append("Restarted the sandbox and will wait for EIP")
            except Exception as exc:
                notes.append(f"Could not restart sandbox: {exc}")
            continue
        if "not on disk" in detail or "not flagged" in detail or "not in strip_data" in detail:
            for ed in dive.get("edits") or []:
                note = _fix_edit(root, ed)
                if note:
                    notes.append(note)
            continue
        if re.search(r"got .* expected", detail):
            for ed in dive.get("edits") or []:
                if "IN1" in (ed.get("title") or "") or "GT1" in (ed.get("title") or ""):
                    note = _fix_edit(root, ed)
                    if note:
                        notes.append(note)
    if not notes:
        applied = client_dive.apply_edits(root, dive)
        if applied:
            notes.append(f"Re-applied {len(applied)} planned edit(s)")
    return bool(notes), notes
