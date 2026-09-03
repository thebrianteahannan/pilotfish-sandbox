"""Orchestrate Reddit scrape + scoring into SQLite."""

from __future__ import annotations

import json
import os
import traceback
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from db import Store, utc_now
from feeds import fetch_all, signal_too_old
from jobs import fetch_jobs
from reddit_client import RedditClient
from score import score_post

_HERE = Path(__file__).resolve().parent
ROOT = _HERE if (_HERE / "config").is_dir() else _HERE.parent
CONFIG_PATH = ROOT / "config" / "topics.json"
SEED_PATH = ROOT / "config" / "seed_posts.json"


def load_config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def db_path() -> Path:
    return Path(os.environ.get("SCOUT_DB", str(ROOT / "data" / "buzz.sqlite3")))


def _ingest(store: Store, posts: list[dict[str, Any]], caps: list[dict[str, Any]], min_score: int, seen_ids: set[str]) -> tuple[int, int, int]:
    seen = new = kept = 0
    now_ts = datetime.now(timezone.utc).timestamp()
    for post in posts:
        seen += 1
        if post["id"] in seen_ids:
            continue
        seen_ids.add(post["id"])
        created = float(post.get("created_utc") or 0)
        if created < 1_000_000_000:
            post["created_utc"] = now_ts
        if signal_too_old(post.get("created_utc")):
            continue
        scored = score_post(post, caps)
        if scored["relevance"] < min_score:
            continue
        kept += 1
        if store.upsert_post({**post, **scored, "fetched_at": utc_now()}):
            new += 1
    return seen, new, kept


def _load_seed(store: Store, caps: list[dict[str, Any]]) -> int:
    if not SEED_PATH.is_file():
        return 0
    items = json.loads(SEED_PATH.read_text(encoding="utf-8"))
    n = 0
    for post in items:
        if signal_too_old(post.get("created_utc")):
            continue
        scored = score_post(post, caps)
        post = {**post, **scored, "fetched_at": utc_now()}
        if store.upsert_post(post):
            n += 1
    return n


def run_scout(store: Store | None = None, config: dict[str, Any] | None = None) -> dict[str, Any]:
    cfg = config or load_config()
    store = store or Store(db_path())
    client = RedditClient(cfg.get("user_agent") or "PilotFishHealthcareBuzzScout/1.0")
    store.purge_g2()
    run_id = store.start_run()
    seen = new = kept = 0
    errors: list[str] = []
    by_query: dict[str, int] = {}
    seen_ids: set[str] = set()

    min_score = int(cfg.get("min_score_to_keep") or 18)
    feed_min = int(cfg.get("min_score_feeds") or 14)
    regs_min = int(cfg.get("min_score_regs") or 10)
    jobs_min = int(cfg.get("min_score_jobs") or 10)
    limit = int(cfg.get("max_posts_per_query") or 25)
    focus_subs = list(cfg.get("subreddits") or [])
    queries = list(cfg.get("queries") or [])
    caps = list(cfg.get("capability_map") or [])
    rate_limited = False

    try:
        extra, extra_by, extra_err = fetch_all(
            cfg.get("user_agent") or "PilotFishHealthcareBuzzScout/1.0",
            limit=int(cfg.get("max_feed_items") or 15),
        )
        errors.extend(extra_err)
        by_query.update(extra_by)
        for src, floor in (("news", feed_min), ("regs", regs_min), ("stack", feed_min), ("hn", feed_min)):
            batch = [p for p in extra if p.get("source") == src]
            s, n, k = _ingest(store, batch, caps, floor, seen_ids)
            seen += s
            new += n
            kept += k

        job_posts, job_by, job_err = fetch_jobs(
            cfg.get("user_agent") or "PilotFishHealthcareBuzzScout/1.0",
            limit=int(cfg.get("max_feed_items") or 15),
        )
        errors.extend(job_err)
        by_query.update(job_by)
        s, n, k = _ingest(store, job_posts, caps, jobs_min, seen_ids)
        seen += s
        new += n
        kept += k
        from jobs import backfill_job_companies

        by_query["job_companies"] = backfill_job_companies(store)

        for sub in focus_subs:
            if rate_limited:
                errors.append(f"{sub}::rss/new: skipped (rate limited earlier)")
                continue
            key = f"{sub}::rss/new"
            try:
                posts = client.list_subreddit(sub, sort="new", limit=max(limit, 40))
                by_query[key] = len(posts)
                s, n, k = _ingest(store, posts, caps, min_score, seen_ids)
                seen += s
                new += n
                kept += k
            except Exception as exc:  # noqa: BLE001
                msg = str(exc)
                errors.append(f"{key}: {exc}")
                if "HTTP 429" in msg:
                    rate_limited = True

        # Site-wide RSS searches only if we have headroom
        for q in queries:
            if rate_limited:
                errors.append(f"all::{q[:40]}: skipped (rate limited earlier)")
                continue
            key = f"all::{q[:48]}"
            try:
                posts = client.search(query=q, sort="new", time_filter="week", limit=limit)
                by_query[key] = len(posts)
                s, n, k = _ingest(store, posts, caps, min_score, seen_ids)
                seen += s
                new += n
                kept += k
            except Exception as exc:  # noqa: BLE001
                msg = str(exc)
                errors.append(f"{key}: {exc}")
                if "HTTP 429" in msg:
                    rate_limited = True

        seeded = 0
        if kept == 0:
            seeded = _load_seed(store, caps)
            if seeded:
                kept = seeded
                new += seeded

        comments_enriched = 0
        if not rate_limited:
            from curate import curate_thread

            for post in store.list_posts_needing_comments(limit=3):
                try:
                    raw = client.fetch_comments(post)
                    curated = curate_thread(post, raw, caps)
                    store.replace_comments(post["id"], curated["comments"])
                    store.save_curation(
                        post["id"],
                        reply_draft=curated["reply_draft"],
                        demo_suggestions=curated["demo_suggestions"],
                        themes=curated["themes"],
                        signal_count=curated["signal_count"],
                    )
                    comments_enriched += 1
                except Exception as exc:  # noqa: BLE001
                    errors.append(f"comments::{post['id']}: {exc}")
                    if "HTTP 429" in str(exc):
                        rate_limited = True
                        break

        from companies import refresh_companies

        companies_n = refresh_companies(store)
        store.finish_run(
            run_id,
            posts_seen=seen,
            posts_new=new,
            posts_kept=kept,
            detail={
                "by_query": by_query,
                "oauth": client.oauth_ready,
                "errors": errors[:40],
                "seeded": seeded,
                "comments_enriched": comments_enriched,
                "companies": companies_n,
            },
        )
    except Exception as exc:  # noqa: BLE001
        store.finish_run(
            run_id,
            posts_seen=seen,
            posts_new=new,
            posts_kept=kept,
            error=f"{exc}\n{traceback.format_exc()}",
            detail={"by_query": by_query, "errors": errors},
        )
        raise

    return {
        "run_id": run_id,
        "seen": seen,
        "new": new,
        "kept": kept,
        "errors": errors,
        "finished_at": datetime.now(timezone.utc).isoformat(),
    }


if __name__ == "__main__":
    print(json.dumps(run_scout(), indent=2))
