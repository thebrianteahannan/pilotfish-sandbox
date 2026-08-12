"""Orchestrate Reddit scrape + scoring into SQLite."""

from __future__ import annotations

import json
import os
import traceback
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from db import Store, utc_now
from g2_client import G2Client
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
    for post in posts:
        seen += 1
        if post["id"] in seen_ids:
            continue
        seen_ids.add(post["id"])
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
        scored = score_post(post, caps)
        post = {**post, **scored, "fetched_at": utc_now()}
        if store.upsert_post(post):
            n += 1
    return n


def run_scout(store: Store | None = None, config: dict[str, Any] | None = None) -> dict[str, Any]:
    cfg = config or load_config()
    store = store or Store(db_path())
    client = RedditClient(cfg.get("user_agent") or "PilotFishHealthcareBuzzScout/1.0")
    run_id = store.start_run()
    seen = new = kept = 0
    errors: list[str] = []
    by_query: dict[str, int] = {}
    seen_ids: set[str] = set()

    min_score = int(cfg.get("min_score_to_keep") or 18)
    limit = int(cfg.get("max_posts_per_query") or 25)
    focus_subs = list(cfg.get("subreddits") or [])
    queries = list(cfg.get("queries") or [])
    caps = list(cfg.get("capability_map") or [])
    rate_limited = False

    try:
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
                if (post.get("source") or "reddit") == "g2":
                    continue
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

        # G2 paying-user reviews (Wayback) — the "check G2 ratings" path
        g2_seen = g2_new = g2_kept = 0
        try:
            g2 = G2Client(cfg.get("user_agent") or "PilotFishHealthcareBuzzScout/1.0", request_gap=2.5)
            products = g2.load_products()
            # Rotate through a few products per hour so we don't hammer Wayback
            hour_bucket = datetime.now(timezone.utc).hour
            start = (hour_bucket * 3) % max(1, len(products))
            batch = products[start:] + products[:start]
            for product in batch[:4]:
                key = f"g2::{product['slug']}"
                try:
                    reviews = g2.fetch_product_reviews(product, limit=int(cfg.get("max_g2_reviews_per_product") or 20))
                    by_query[key] = len(reviews)
                    s, n, k = _ingest(store, reviews, caps, min_score, seen_ids)
                    g2_seen += s
                    g2_new += n
                    g2_kept += k
                    seen += s
                    new += n
                    kept += k
                except Exception as exc:  # noqa: BLE001
                    errors.append(f"{key}: {exc}")
        except Exception as exc:  # noqa: BLE001
            errors.append(f"g2: {exc}")

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
                "g2_seen": g2_seen,
                "g2_new": g2_new,
                "g2_kept": g2_kept,
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
