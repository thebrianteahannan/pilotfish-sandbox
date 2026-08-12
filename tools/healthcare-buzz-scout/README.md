# Healthcare Buzz Scout

Hourly monitor for healthcare / insurance **data integration** chatter PilotFish could address:

1. **Reddit** — EDI / HL7 / FHIR / EHR / ACORD threads + curated comments
2. **G2** — paying-user reviews of medical billing / RCM / clearinghouse / interface-engine products (via Wayback Machine archives, because live G2 blocks bots)

Scores against Sandbox capability themes and nearby demos.

## Run

```bash
cd tools/healthcare-buzz-scout
docker compose up -d --build
```

UI: http://localhost:8130/

Without credentials it uses Reddit **Atom RSS** feeds (JSON is often blocked from cloud/datacenter IPs) with a polite gap between requests (~3.5s). If a run finds nothing (rate-limit / outage), it loads `config/seed_posts.json` so the UI still has representative industry asks to mull over.

Optional Reddit app credentials (script app) for higher limits:

```bash
export REDDIT_CLIENT_ID=...
export REDDIT_CLIENT_SECRET=...
docker compose up -d --build
```

## What it does

1. Every hour (and once at startup), searches Reddit for integration-shaped posts.
2. Scores against PilotFish capability map (`config/topics.json`).
3. Stores hits in SQLite (`data/buzz.sqlite3`).
4. Web UI: filter by status / capability, mark **Watch** / **Idea** / **Dismiss**, add notes.

## Local (no Docker)

```bash
cd tools/healthcare-buzz-scout
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
SCOUT_DB=./data/buzz.sqlite3 python app/main.py
# or one-shot scrape:
PYTHONPATH=app SCOUT_DB=./data/buzz.sqlite3 python app/scout.py
```

## Files

| Path | Role |
|------|------|
| `config/topics.json` | Subreddits, queries, capability → demo / pitch mapping |
| `config/seed_posts.json` | Fallback sample asks when Reddit is empty/blocked |
| `config/g2_products.json` | Medical billing / RCM / engine products to pull from G2 |
| `app/g2_client.py` | Wayback → G2 review parser |
| `app/reddit_client.py` | Reddit RSS / optional OAuth / PullPush |
| `app/score.py` | Relevance scoring |
| `app/scout.py` | Orchestration |
| `app/curate.py` | Comment curation, demo ideas, reply draft |
| `app/main.py` | Flask UI + APScheduler |
| `data/` | SQLite volume (gitignored) |
