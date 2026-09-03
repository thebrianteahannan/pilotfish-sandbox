---
name: regenerate-construction-video
description: Regenerates a PilotFish Sandbox demo construction-replay.mp4 and transcript on demand. Use when the user asks to regenerate, rebuild, remake, export, or re-record the construction video, construction-replay.mp4, narrated demo video, or construction transcript for any Clients/Demos project.
---

# Regenerate construction video

When the user asks to regenerate a construction video, **do it** — do not only give commands.

Do **not** run this at the end of an interface build unless they asked for the video. Completing a demo should `--prepare-only` (replay + transcript). The Info tab **Create construction video** button records the mp4.

## Resolve the demo

1. Slug they name (`csv-sftp-to-sql`) or `@`-mention / open file under `Clients/Demos/` (including category folders)
2. Else unique substring match against demo slugs (`python3 tools/regenerate_construction_video.py <slug>`)
3. If several are plausible, ask which one
4. Do **not** batch every demo unless they explicitly say all / every demo

## Run (repo root)

```bash
python3 tools/regenerate_construction_video.py <slug>
```

- Re-records `documents/build-replay/` then exports MP4 + transcript
- Stops other `Clients/` demo stacks first (`docker compose -p … down`, never `-v`)
- Leaves **this** demo Web UI up
- `--keep-replay` only if they ask to reuse the existing module narration

Needs `tools/.venv-video`. Export can take 2–4 minutes; wait for it.

If they ask to redo **one part** of an existing eiConsole construction video (Data Mapper, Testing Mode, …), do **not** remake the whole take:

```bash
tools/.venv-video/bin/python tools/export_construction_video.py --root Clients/Demos/<path> --list-sections
tools/.venv-video/bin/python tools/export_construction_video.py --root Clients/Demos/<path> --section data-mappers
```

That splices the new stretch into the current `construction-replay.mp4`. `--from-id` / `--to-id` work when there is no named section.

## After

Confirm:

- `Clients/Demos/<Category>/…/<slug>/documents/construction-replay.mp4` (tools resolve by slug)
- `…/construction-replay-transcript.{pdf,txt}`
- Web UI URL from that demo's `WEBUI_PORT` (reload the player if it still shows the old file)

## Shared generator rules (every demo)

Same exporters for every slug — no csv-sftp special cases:

- Facts from **that** demo's DESIGN / compose / routes
- Human processor narration (type + why), not diagram card labels
- No “Create New PilotFish Interface” / “Interface created” overlay
- No OGNL lecture overlay
- Singular vs plural Docker copy from compose service count
- Spoken **FTP** not SFTP
