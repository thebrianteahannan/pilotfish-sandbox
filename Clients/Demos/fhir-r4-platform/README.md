# FHIR R4 Expandable Platform (Phase 2)

Multi-resource **FHIR R4 REST** façade on PilotFish eiPlatform with SQL primary store, CapabilityStatement metadata, **token-indexed search for six core types**, plus an **outbound FHIR client** route.

> Expandable platform scaffold — **not** the entire FHIR specification. See `DESIGN.md`.

## Quick start

```bash
cd "Clients/Demos/fhir-r4-platform"
docker compose up -d --build
```

Wait ~60–90s, then open:

| Where | URL |
|-------|-----|
| Web UI (localhost) | http://127.0.0.1:8111/ |
| Web UI (LAN) | http://192.168.68.52:8111/ |
| FHIR base (LAN) | http://192.168.68.52:8110/eip/rest/fhir |
| Metadata | http://192.168.68.52:8110/eip/rest/fhir/metadata |
| Route PDF | http://192.168.68.52:8111/documents/route-diagrams.pdf |

## What it does

1. **Route 1 — FHIR R4 REST Platform** (sync)
   - `POST/GET/PUT/DELETE` for enumerated resource types
   - `GET /metadata` → CapabilityStatement (v0.2.0)
   - Persist to SQL + `output/fhir-store/`; reindex `FhirSearchTokens` on write
   - **Phase 2 search** (core-6): e.g. `Patient?family=Smith`, `Observation?patient=Patient/pat-alice-001&code=8867-4`
   - Other types: `_id` + legacy `q` substring on `RawFhir`
2. **Route 2 — FHIR Outbound Client** — file envelopes → remote FHIR
3. **Web UI** — multi-resource client, typed search helpers, proxy toggle

## Ports

| Service | Host |
|---------|------|
| SQL Server | 14338 |
| PilotFish EIP | 8110 |
| Web UI | 8111 |

## Smoke

```bash
./tools/smoke.sh

curl -sS 'http://127.0.0.1:8110/eip/rest/fhir/Patient?family=Smith'
curl -sS 'http://127.0.0.1:8110/eip/rest/fhir/Observation?patient=Patient/pat-alice-001&code=8867-4'
```

## Demo only

Shared `sa` password, heuristic JSON checks, simplified search matching — see `DESIGN.md` Risks.
