"""SQLite persistence for healthcare Reddit buzz scout."""

from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

SCHEMA = """
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  subreddit TEXT NOT NULL,
  title TEXT NOT NULL,
  selftext TEXT,
  url TEXT NOT NULL,
  permalink TEXT NOT NULL,
  author TEXT,
  created_utc REAL NOT NULL,
  score INTEGER DEFAULT 0,
  num_comments INTEGER DEFAULT 0,
  flair TEXT,
  fetched_at TEXT NOT NULL,
  relevance INTEGER DEFAULT 0,
  topics_json TEXT DEFAULT '[]',
  capabilities_json TEXT DEFAULT '[]',
  demo_hints_json TEXT DEFAULT '[]',
  pitch_refs_json TEXT DEFAULT '[]',
  why TEXT,
  status TEXT DEFAULT 'new',
  notes TEXT DEFAULT '',
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  started_at TEXT NOT NULL,
  finished_at TEXT,
  posts_seen INTEGER DEFAULT 0,
  posts_new INTEGER DEFAULT 0,
  posts_kept INTEGER DEFAULT 0,
  error TEXT,
  detail_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_relevance ON posts(relevance DESC);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_utc DESC);

CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL,
  author TEXT,
  body TEXT NOT NULL,
  permalink TEXT,
  created_utc REAL DEFAULT 0,
  score INTEGER DEFAULT 0,
  relevance INTEGER DEFAULT 0,
  is_signal INTEGER DEFAULT 0,
  why TEXT,
  matched_caps_json TEXT DEFAULT '[]',
  fetched_at TEXT NOT NULL,
  FOREIGN KEY(post_id) REFERENCES posts(id)
);

CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_signal ON comments(post_id, is_signal DESC, relevance DESC);
"""

POST_EXTRA_COLUMNS = {
    "comments_fetched_at": "TEXT",
    "reply_draft": "TEXT",
    "demo_suggestions_json": "TEXT DEFAULT '[]'",
    "comment_themes_json": "TEXT DEFAULT '[]'",
    "signal_comment_count": "INTEGER DEFAULT 0",
    "source": "TEXT DEFAULT 'reddit'",
    "product_name": "TEXT DEFAULT ''",
    "like_text": "TEXT DEFAULT ''",
    "dislike_text": "TEXT DEFAULT ''",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class Store:
    def __init__(self, path: Path):
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as conn:
            conn.executescript(SCHEMA)
            self._migrate(conn)

    @staticmethod
    def _migrate(conn: sqlite3.Connection) -> None:
        existing = {r[1] for r in conn.execute("PRAGMA table_info(posts)").fetchall()}
        for col, decl in POST_EXTRA_COLUMNS.items():
            if col not in existing:
                conn.execute(f"ALTER TABLE posts ADD COLUMN {col} {decl}")

    @contextmanager
    def connect(self) -> Iterator[sqlite3.Connection]:
        conn = sqlite3.connect(self.path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    def upsert_post(self, post: dict[str, Any], *, overwrite_review: bool = False) -> bool:
        """Insert or refresh scrape fields. Returns True if newly inserted."""
        with self.connect() as conn:
            existing = conn.execute("SELECT status, notes FROM posts WHERE id=?", (post["id"],)).fetchone()
            is_new = existing is None
            status = "new" if is_new else existing["status"]
            notes = "" if is_new else (existing["notes"] or "")
            if overwrite_review:
                status = post.get("status", status)
                notes = post.get("notes", notes)
            conn.execute(
                """
                INSERT INTO posts (
                  id, subreddit, title, selftext, url, permalink, author, created_utc,
                  score, num_comments, flair, fetched_at, relevance, topics_json,
                  capabilities_json, demo_hints_json, pitch_refs_json, why, status, notes, updated_at,
                  source, product_name, like_text, dislike_text
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                ON CONFLICT(id) DO UPDATE SET
                  subreddit=excluded.subreddit,
                  title=excluded.title,
                  selftext=excluded.selftext,
                  url=excluded.url,
                  permalink=excluded.permalink,
                  author=excluded.author,
                  created_utc=excluded.created_utc,
                  score=excluded.score,
                  num_comments=excluded.num_comments,
                  flair=excluded.flair,
                  fetched_at=excluded.fetched_at,
                  relevance=excluded.relevance,
                  topics_json=excluded.topics_json,
                  capabilities_json=excluded.capabilities_json,
                  demo_hints_json=excluded.demo_hints_json,
                  pitch_refs_json=excluded.pitch_refs_json,
                  why=excluded.why,
                  source=excluded.source,
                  product_name=excluded.product_name,
                  like_text=excluded.like_text,
                  dislike_text=excluded.dislike_text,
                  updated_at=excluded.updated_at
                """,
                (
                    post["id"],
                    post["subreddit"],
                    post["title"],
                    post.get("selftext") or "",
                    post["url"],
                    post["permalink"],
                    post.get("author") or "",
                    post["created_utc"],
                    int(post.get("score") or 0),
                    int(post.get("num_comments") or 0),
                    post.get("flair") or "",
                    post.get("fetched_at") or utc_now(),
                    int(post.get("relevance") or 0),
                    json.dumps(post.get("topics") or []),
                    json.dumps(post.get("capabilities") or []),
                    json.dumps(post.get("demo_hints") or []),
                    json.dumps(post.get("pitch_refs") or []),
                    post.get("why") or "",
                    status,
                    notes,
                    utc_now(),
                    post.get("source") or "reddit",
                    post.get("product_name") or "",
                    post.get("like_text") or "",
                    post.get("dislike_text") or "",
                ),
            )
            return is_new

    def set_status(self, post_id: str, status: str, notes: str | None = None) -> None:
        with self.connect() as conn:
            if notes is None:
                conn.execute(
                    "UPDATE posts SET status=?, updated_at=? WHERE id=?",
                    (status, utc_now(), post_id),
                )
            else:
                conn.execute(
                    "UPDATE posts SET status=?, notes=?, updated_at=? WHERE id=?",
                    (status, notes, utc_now(), post_id),
                )

    def list_posts(
        self,
        *,
        status: str | None = None,
        capability: str | None = None,
        q: str | None = None,
        source: str | None = None,
        limit: int = 200,
    ) -> list[dict[str, Any]]:
        clauses = ["1=1"]
        args: list[Any] = []
        if status and status != "all":
            clauses.append("status=?")
            args.append(status)
        if source and source != "all":
            clauses.append("COALESCE(source,'reddit')=?")
            args.append(source)
        if capability:
            clauses.append("capabilities_json LIKE ?")
            args.append(f"%{capability}%")
        if q:
            clauses.append(
                "(title LIKE ? OR selftext LIKE ? OR why LIKE ? OR notes LIKE ? OR product_name LIKE ? OR like_text LIKE ? OR dislike_text LIKE ?)"
            )
            like = f"%{q}%"
            args.extend([like, like, like, like, like, like, like])
        args.append(limit)
        sql = f"""
          SELECT * FROM posts
          WHERE {' AND '.join(clauses)}
          ORDER BY
            CASE status
              WHEN 'new' THEN 0
              WHEN 'watching' THEN 1
              WHEN 'idea' THEN 2
              ELSE 3
            END,
            relevance DESC,
            created_utc DESC
          LIMIT ?
        """
        with self.connect() as conn:
            rows = conn.execute(sql, args).fetchall()
        return [self._row(r) for r in rows]

    def get_post(self, post_id: str) -> dict[str, Any] | None:
        with self.connect() as conn:
            row = conn.execute("SELECT * FROM posts WHERE id=?", (post_id,)).fetchone()
        return self._row(row) if row else None

    def replace_comments(self, post_id: str, comments: list[dict[str, Any]]) -> None:
        with self.connect() as conn:
            conn.execute("DELETE FROM comments WHERE post_id=?", (post_id,))
            now = utc_now()
            for c in comments:
                conn.execute(
                    """
                    INSERT INTO comments (
                      id, post_id, author, body, permalink, created_utc, score,
                      relevance, is_signal, why, matched_caps_json, fetched_at
                    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
                    """,
                    (
                        c["id"],
                        post_id,
                        c.get("author") or "",
                        c.get("body") or "",
                        c.get("permalink") or "",
                        float(c.get("created_utc") or 0),
                        int(c.get("score") or 0),
                        int(c.get("relevance") or 0),
                        1 if c.get("is_signal") else 0,
                        c.get("why") or "",
                        json.dumps(c.get("matched_caps") or []),
                        now,
                    ),
                )

    def list_comments(self, post_id: str, *, signals_only: bool = False) -> list[dict[str, Any]]:
        sql = "SELECT * FROM comments WHERE post_id=?"
        args: list[Any] = [post_id]
        if signals_only:
            sql += " AND is_signal=1"
        sql += " ORDER BY is_signal DESC, relevance DESC, created_utc ASC"
        with self.connect() as conn:
            rows = conn.execute(sql, args).fetchall()
        return [self._comment_row(r) for r in rows]

    def save_curation(
        self,
        post_id: str,
        *,
        reply_draft: str,
        demo_suggestions: list[dict[str, Any]],
        themes: list[str],
        signal_count: int,
    ) -> None:
        with self.connect() as conn:
            conn.execute(
                """
                UPDATE posts SET
                  comments_fetched_at=?,
                  reply_draft=?,
                  demo_suggestions_json=?,
                  comment_themes_json=?,
                  signal_comment_count=?,
                  updated_at=?
                WHERE id=?
                """,
                (
                    utc_now(),
                    reply_draft,
                    json.dumps(demo_suggestions),
                    json.dumps(themes),
                    int(signal_count),
                    utc_now(),
                    post_id,
                ),
            )

    def list_posts_needing_comments(self, *, limit: int = 5) -> list[dict[str, Any]]:
        with self.connect() as conn:
            rows = conn.execute(
                """
                SELECT * FROM posts
                WHERE (comments_fetched_at IS NULL OR comments_fetched_at='')
                  AND status != 'dismissed'
                  AND COALESCE(source,'reddit') = 'reddit'
                ORDER BY relevance DESC, created_utc DESC
                LIMIT ?
                """,
                (limit,),
            ).fetchall()
        return [self._row(r) for r in rows]

    def stats(self) -> dict[str, Any]:
        with self.connect() as conn:
            by_status = {
                r["status"]: r["n"]
                for r in conn.execute(
                    "SELECT status, COUNT(*) AS n FROM posts GROUP BY status"
                ).fetchall()
            }
            last = conn.execute(
                "SELECT * FROM runs ORDER BY id DESC LIMIT 1"
            ).fetchone()
            total = conn.execute("SELECT COUNT(*) AS n FROM posts").fetchone()["n"]
        return {
            "total": total,
            "by_status": by_status,
            "last_run": dict(last) if last else None,
        }

    def start_run(self) -> int:
        with self.connect() as conn:
            cur = conn.execute(
                "INSERT INTO runs (started_at) VALUES (?)",
                (utc_now(),),
            )
            return int(cur.lastrowid)

    def finish_run(
        self,
        run_id: int,
        *,
        posts_seen: int,
        posts_new: int,
        posts_kept: int,
        error: str | None = None,
        detail: dict | None = None,
    ) -> None:
        with self.connect() as conn:
            conn.execute(
                """
                UPDATE runs SET finished_at=?, posts_seen=?, posts_new=?, posts_kept=?,
                  error=?, detail_json=?
                WHERE id=?
                """,
                (
                    utc_now(),
                    posts_seen,
                    posts_new,
                    posts_kept,
                    error,
                    json.dumps(detail or {}),
                    run_id,
                ),
            )

    @staticmethod
    def _row(row: sqlite3.Row) -> dict[str, Any]:
        d = dict(row)
        for key in (
            "topics_json",
            "capabilities_json",
            "demo_hints_json",
            "pitch_refs_json",
            "demo_suggestions_json",
            "comment_themes_json",
        ):
            if key not in d:
                continue
            raw = d.pop(key)
            name = key.replace("_json", "")
            try:
                d[name] = json.loads(raw or "[]")
            except json.JSONDecodeError:
                d[name] = []
        return d

    @staticmethod
    def _comment_row(row: sqlite3.Row) -> dict[str, Any]:
        d = dict(row)
        d["is_signal"] = bool(d.get("is_signal"))
        try:
            d["matched_caps"] = json.loads(d.pop("matched_caps_json") or "[]")
        except json.JSONDecodeError:
            d["matched_caps"] = []
            d.pop("matched_caps_json", None)
        return d
