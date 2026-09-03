# Healthcare Buzz Scout

Hourly monitor for healthcare / insurance **data integration** chatter PilotFish could address. It watches **Reddit**, industry news, Federal Register, Stack Overflow, Hacker News, and **integration job posts** (companies hiring HL7 / EDI / FHIR / interface people) for gaps, curates comments, and scores them against Sandbox capability themes and nearby demos.

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

1. Every hour (and once at startup), pulls Reddit plus industry news, Federal Register, Stack Overflow, Hacker News, and integration job posts.
2. Scores against PilotFish capability map (`config/topics.json`).
3. Stores hits in SQLite (`data/buzz.sqlite3`).
4. Web UI: filter by status / capability, mark **Watch** / **Idea** / **Dismiss**, add notes.
5. **Find work** (`/briefing`): demand by capability, what we can ship, prospect-shaped signals, and BD plays.
6. **Companies** (`/companies`): running list of shops that may need PilotFish (hiring, news, public asks). Status and notes persist.
7. **Market** (`/market`): share of this week’s conversation plus where PilotFish sits vs engines, EHRs, RCM, and insurance cores.
8. **Search** (`/search`): who ranks when buyers search our hops (Bing + comparison articles AIs cite). Paste ChatGPT/Claude/Perplexity answers.
9. **Marketing** (`/marketing`): curated search / LinkedIn / trade ads from this week’s buzz.

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
| `config/feeds.json` | Industry news RSS, Google News, Federal Register, Stack Overflow, HN |
| `config/seed_posts.json` | Fallback sample asks when Reddit is empty/blocked |
| `app/reddit_client.py` | Reddit RSS / optional OAuth / PullPush |
| `app/feeds.py` | News RSS, Google News, Federal Register, Stack Overflow, HN |
| `app/jobs.py` | Integration job posts → companies to call |
| `app/marketing.py` | Curated ads from this week’s buzz |
| `app/companies.py` | Running prospect list (healthcare / insurance) |
| `app/systems.py` | Named engines / EHRs / missing-hop cues |
| `app/score.py` | Relevance scoring |
| `app/scout.py` | Orchestration |
| `app/curate.py` | Comment curation, demo ideas, reply draft |
| `app/main.py` | Flask UI + APScheduler |
| `data/` | SQLite volume (gitignored) |
