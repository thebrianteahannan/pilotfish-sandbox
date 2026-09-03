"""Timestamped notes on the construction-replay video."""

from __future__ import annotations

import json
import os
import time
import uuid
from pathlib import Path

from flask import Flask, jsonify, request


def _paths(documents_dir: Path) -> list[Path]:
    snap = Path(os.environ.get("SNAPSHOT_DIR") or "/output/snapshots")
    output = Path(os.environ.get("OUTPUT_DIR") or snap.parent)
    names = ("construction-video-comments.json",)
    out: list[Path] = []
    for base in (documents_dir, output):
        for name in names:
            path = Path(base) / name
            if path not in out:
                out.append(path)
    return out


def _load(documents_dir: Path) -> tuple[list[dict], Path | None]:
    for path in _paths(documents_dir):
        if not path.is_file():
            continue
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        rows = raw.get("comments") if isinstance(raw, dict) else raw
        if isinstance(rows, list):
            return [r for r in rows if isinstance(r, dict)], path
    return [], None


def _save(documents_dir: Path, comments: list[dict]) -> Path:
    payload = json.dumps({"comments": comments}, indent=2) + "\n"
    last_err: OSError | None = None
    for path in _paths(documents_dir):
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            tmp = path.with_name(path.name + ".tmp")
            tmp.write_text(payload, encoding="utf-8")
            tmp.replace(path)
            return path
        except OSError as exc:
            last_err = exc
    raise last_err or OSError("no writable comments path")


def _clean_text(value: object) -> str:
    return " ".join(str(value or "").split()).strip()[:2000]


def ensure_video_review_api(app: Flask, documents_dir: Path) -> None:
    existing = {rule.rule for rule in app.url_map.iter_rules()}
    if "/api/video-review-comments" in existing:
        return

    @app.get("/api/video-review-comments")
    def _list_video_review_comments():
        comments, path = _load(documents_dir)
        comments.sort(key=lambda row: float(row.get("t_sec") or 0))
        return jsonify({"ok": True, "comments": comments, "path": str(path) if path else ""})

    @app.post("/api/video-review-comments")
    def _add_video_review_comment():
        incoming = request.get_json(silent=True) or {}
        text = _clean_text(incoming.get("text") if isinstance(incoming, dict) else "")
        if not text:
            return jsonify({"ok": False, "error": "Note text is required"}), 400
        try:
            t_sec = max(0.0, float(incoming.get("t_sec") or 0))
        except (TypeError, ValueError):
            t_sec = 0.0
        comments, _path = _load(documents_dir)
        row = {
            "id": f"c{int(time.time())}{uuid.uuid4().hex[:4]}",
            "t_sec": round(t_sec, 2),
            "text": text,
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "status": "open",
        }
        comments.append(row)
        _save(documents_dir, comments)
        return jsonify({"ok": True, "comment": row}), 201

    @app.patch("/api/video-review-comments/<comment_id>")
    def _patch_video_review_comment(comment_id: str):
        incoming = request.get_json(silent=True) or {}
        comments, _path = _load(documents_dir)
        found = None
        for row in comments:
            if str(row.get("id")) == comment_id:
                found = row
                break
        if not found:
            return jsonify({"ok": False, "error": "not found"}), 404
        status = str(incoming.get("status") or "").strip().lower()
        if status in {"open", "done"}:
            found["status"] = status
        text = _clean_text(incoming.get("text")) if incoming.get("text") is not None else ""
        if text:
            found["text"] = text
        _save(documents_dir, comments)
        return jsonify({"ok": True, "comment": found})

    @app.delete("/api/video-review-comments/<comment_id>")
    def _delete_video_review_comment(comment_id: str):
        comments, _path = _load(documents_dir)
        keep = [row for row in comments if str(row.get("id")) != comment_id]
        if len(keep) == len(comments):
            return jsonify({"ok": False, "error": "not found"}), 404
        _save(documents_dir, keep)
        return jsonify({"ok": True})
