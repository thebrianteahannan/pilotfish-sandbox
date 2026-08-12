"""Flask UI + hourly scheduler for healthcare Reddit buzz scout."""

from __future__ import annotations

import os
import threading
from pathlib import Path

from apscheduler.schedulers.background import BackgroundScheduler
from flask import Flask, jsonify, redirect, render_template, request, url_for

from curate import enrich_post
from db import Store
from scout import db_path, load_config, run_scout

_HERE = Path(__file__).resolve().parent
ROOT = _HERE if (_HERE / "templates").is_dir() else _HERE.parent
app = Flask(__name__, template_folder=str(ROOT / "templates"), static_folder=str(ROOT / "static"))
store = Store(db_path())
scheduler = BackgroundScheduler(daemon=True)
_run_lock = threading.Lock()


def _safe_run() -> dict:
    with _run_lock:
        return run_scout(store=store)


@app.get("/")
def index():
    status = request.args.get("status") or "new"
    capability = request.args.get("capability") or ""
    source = request.args.get("source") or "all"
    q = request.args.get("q") or ""
    posts = store.list_posts(
        status=status,
        capability=capability or None,
        source=source or None,
        q=q or None,
    )
    stats = store.stats()
    cfg = load_config()
    caps = [{"id": c["id"], "label": c["label"]} for c in cfg.get("capability_map") or []]
    return render_template(
        "index.html",
        posts=posts,
        stats=stats,
        status=status,
        capability=capability,
        source=source,
        q=q,
        capabilities=caps,
        oauth=bool(os.environ.get("REDDIT_CLIENT_ID")),
    )


@app.get("/post/<post_id>")
def post_detail(post_id: str):
    post = store.get_post(post_id)
    if not post:
        return "Not found", 404
    cfg = load_config()
    force = request.args.get("refresh") in {"1", "true", "yes"}
    bundle = enrich_post(
        store,
        post,
        list(cfg.get("capability_map") or []),
        force=force,
        user_agent=cfg.get("user_agent") or "PilotFishSandboxHealthcareBuzzScout/1.0",
    )
    return render_template(
        "post.html",
        post=bundle["post"],
        signal_comments=bundle["signal_comments"],
        other_comments=bundle["other_comments"],
        demo_suggestions=bundle["demo_suggestions"],
        reply_draft=bundle["reply_draft"],
        themes=bundle["themes"],
        signal_count=bundle["signal_count"],
        error=bundle["error"],
    )


@app.post("/post/<post_id>/status")
def post_status(post_id: str):
    status = (request.form.get("status") or "watching").strip()
    notes = request.form.get("notes")
    if status not in {"new", "watching", "idea", "dismissed"}:
        return "Bad status", 400
    store.set_status(post_id, status, notes=notes)
    if request.headers.get("X-Requested-With") == "fetch":
        return jsonify({"ok": True, "status": status})
    return redirect(request.referrer or url_for("index"))


@app.post("/api/run")
@app.get("/api/run")
def api_run():
    try:
        result = _safe_run()
        return jsonify({"ok": True, **result})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 500


@app.get("/api/stats")
def api_stats():
    return jsonify(store.stats())


@app.get("/api/posts")
def api_posts():
    return jsonify(
        {
            "posts": store.list_posts(
                status=request.args.get("status") or "all",
                capability=request.args.get("capability") or None,
                source=request.args.get("source") or None,
                q=request.args.get("q") or None,
            )
        }
    )


def start_scheduler() -> None:
    cfg = load_config()
    seconds = int(os.environ.get("POLL_INTERVAL_SECONDS") or cfg.get("poll_interval_seconds") or 3600)

    def job():
        try:
            _safe_run()
        except Exception as exc:  # noqa: BLE001
            print(f"[scout] scheduled run failed: {exc}", flush=True)

    scheduler.add_job(job, "interval", seconds=seconds, id="hourly_scout", max_instances=1, coalesce=True)
    scheduler.start()
    # Kick once shortly after boot so the UI is not empty
    scheduler.add_job(job, "date", id="startup_scout")


def main() -> None:
    start_scheduler()
    port = int(os.environ.get("WEBUI_PORT", "8130"))
    app.run(host="0.0.0.0", port=port, debug=False, use_reloader=False)


if __name__ == "__main__":
    main()
