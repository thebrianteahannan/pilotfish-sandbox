# CSV to JSON Demo

Simple PilotFish eiPlatform demo: poll a folder for CSV files, convert to JSON, write to an output folder.

## What it does

1. Drop a `.csv` into `input/inbound` (or use the Web UI)
2. **Route 1 — Convert CSV To JSON**
   - `DirectoryListener` polls every 10s (`.csv` only), Moves file to `output/archive`
   - Source: `CSVTransformationProcessor` → Dialect A XML (`XCSData` / `XCSRecord`)
   - Target: XSLT `csv-xml-to-json.xslt` → `{"records":[…]}` JSON
   - `DirectoryTransport` writes `output/json/<basename>.json`
3. Web UI submits samples and shows JSON + archive

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` built from the Sandbox root

## Run

```bash
cd "Clients/Demos/csv-to-json"
docker compose up -d --build
```

Wait ~60–90s for EIP, then open the Web UI.

## Ports / URLs

| Service | Host port |
|---------|-----------|
| PilotFish EIP | 8108 |
| Demo Web UI | 8109 |

- Web UI local: http://localhost:8109/
- Web UI LAN: http://192.168.68.52:8109/
- Route design PDF: http://192.168.68.52:8109/documents/route-diagrams.pdf
- Local PDF: http://localhost:8109/documents/route-diagrams.pdf

## Smoke test

```bash
cp samples/SAMPLE-01_patients.csv input/inbound/
# wait ~15s
ls output/json/
cat output/json/SAMPLE-01_patients.json
```

Or use **Convert to JSON** in the Web UI.

## Demo only

- No schema validation / kickout path
- Listener archives CSV before JSON write (accepted demo risk)
- JSON is a simple `records` array from Dialect A column tags (not full CSV schema validation)

See `DESIGN.md`.
