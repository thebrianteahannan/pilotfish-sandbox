"""Flask UI + hourly scheduler for healthcare Reddit buzz scout."""

from __future__ import annotations

import os
import threading
from pathlib import Path

from apscheduler.schedulers.background import BackgroundScheduler
from flask import Flask, jsonify, redirect, render_template, request, url_for

from briefing import build_briefing
from companies import COMPANY_STATUSES, company_stats, list_companies, normalize_company_status, refresh_companies, set_company
from market import build_market
from marketing import build_marketing
from searchcomp import ingest_ai_paste, load_search, run_probe
from curate import enrich_post
from db import Store
from feeds import SOURCE_LABELS, format_when, source_label, when_stale
from scout import db_path, load_config, run_scout

_HERE = Path(__file__).resolve().parent
ROOT = _HERE if (_HERE / "templates").is_dir() else _HERE.parent
app = Flask(__name__, template_folder=str(ROOT / "templates"), static_folder=str(ROOT / "static"))
app.jinja_env.globals["source_label"] = source_label
app.jinja_env.globals["format_when"] = format_when
app.jinja_env.globals["when_stale"] = when_stale
app.jinja_env.globals["SOURCE_CHOICES"] = ["all", *SOURCE_LABELS.keys()]
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
        source=source,
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


@app.get("/briefing")
def briefing():
    cfg = load_config()
    pack = build_briefing(store, cfg)
    return render_template("briefing.html", **pack)


@app.get("/api/briefing")
def api_briefing():
    return jsonify(build_briefing(store, load_config()))


@app.get("/market")
def market():
    return render_template("market.html", **build_market(store, load_config()))


@app.get("/api/market")
def api_market():
    return jsonify(build_market(store, load_config()))


@app.get("/search")
def search():
    return render_template("search.html", **load_search(store))


@app.post("/api/search/probe")
@app.get("/api/search/probe")
def api_search_probe():
    try:
        return jsonify({"ok": True, **run_probe(store)})
    except Exception as exc:  # noqa: BLE001
        return jsonify({"ok": False, "error": str(exc)}), 500


@app.post("/api/search/ai-paste")
def api_search_ai_paste():
    data = request.get_json(silent=True) or request.form
    source = (data.get("source") or "chatgpt").strip()
    text = data.get("text") or ""
    n = ingest_ai_paste(store, source=source, text=text)
    if request.headers.get("X-Requested-With") == "fetch" or request.is_json:
        return jsonify({"ok": True, "named": n})
    return redirect(url_for("search"))


@app.get("/marketing")
def marketing():
    return render_template("marketing.html", **build_marketing(store, load_config()))


@app.get("/api/marketing")
def api_marketing():
    return jsonify(build_marketing(store, load_config()))


@app.get("/companies")
def companies():
    status = request.args.get("status") or "all"
    market = request.args.get("market") or ""
    q = request.args.get("q") or ""
    normalize_company_status(store)
    rows = list_companies(store, status="all")
    if not rows:
        refresh_companies(store)
        rows = list_companies(store, status="all")
    return render_template(
        "companies.html",
        companies=rows,
        names=sorted({c["name"] for c in rows}),
        stats=company_stats(store),
        status=status,
        market=market,
        q=q,
    )


@app.post("/companies/<company_id>/status")
def company_status(company_id: str):
    status = (request.form.get("status") or "watching").strip()
    notes = request.form.get("notes")
    if status not in COMPANY_STATUSES:
        return "Bad status", 400
    set_company(store, company_id, status=status, notes=notes)
    return redirect(request.referrer or url_for("companies"))


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
