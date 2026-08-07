# Hindsight AI (Cursor memory)

This project uses [Hindsight](https://hindsight.vectorize.io) for long-term agent memory across Cursor sessions.

## What you get

- **Session recall** — at chat start, relevant memories from bank `PilotFish-Sandbox` are injected (via `.cursor/rules/hindsight-session.mdc`)
- **Auto-retain** — when a task finishes, the transcript is stored in Hindsight Cloud
- **MCP tools** — on-demand `recall`, `retain`, and `reflect`
- **Skills** — `hindsight-docs` (API/architecture docs) and `hindsight-recall` (when to search memory)
- **Rule** — `.cursor/rules/hindsight-memory.mdc` (always on)

Bank ID is case-sensitive and must match the Cloud UI exactly: `PilotFish-Sandbox`.

## Setup (Mac)

1. Install the CLI (once per machine):

```bash
brew install pipx && pipx ensurepath
pipx install hindsight-cursor
```

2. Create an API key at [Hindsight Cloud](https://ui.hindsight.vectorize.io) → Settings → API Keys.

3. From the repo root:

```bash
hindsight-cursor init \
  --api-url https://api.hindsight.vectorize.io \
  --api-token YOUR_HINDSIGHT_API_TOKEN \
  --bank-id PilotFish-Sandbox \
  --force
```

If `~/.hindsight/cursor.json` already exists, `init` will not overwrite `bankId` — edit that file (or delete it and re-init) so `"bankId": "PilotFish-Sandbox"`.

4. **Fully quit and reopen Cursor** (window reload is not enough).

This repo also has `.cursor/hooks.json`, which is what Cursor actually loads for session recall / auto-retain (the `.cursor-plugin` package alone is not enough on current Cursor builds). Auto-retain runs when an agent task **stops** — mid-task demos will not show new bank activity until the turn finishes.

Credentials live in `~/.hindsight/cursor.json`. Project MCP auth is in `.cursor/mcp.json` (gitignored). Copy from `.cursor/mcp.json.example` if needed.

## Verify

```bash
cat ~/.hindsight/cursor-state/state/last_recall.json
cat ~/.hindsight/cursor-state/state/last_retain.json
```

Or: complete a task that records a decision, start a new chat, and ask about that decision.

## Docs

- [Cursor memory guide](https://hindsight.vectorize.io/guides/2026/07/17/guide-cursor-memory-with-hindsight)
- [Cursor integration](https://hindsight.vectorize.io/sdks/integrations/cursor)
- In-agent: use the `hindsight-docs` skill
