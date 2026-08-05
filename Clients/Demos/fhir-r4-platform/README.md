# FHIR R4 Expandable Platform (Phase 1)

Multi-resource **FHIR R4 REST** façade on PilotFish eiPlatform with SQL primary store, CapabilityStatement metadata, simple search, plus an **outbound FHIR client** route.

> This is an expandable platform scaffold — **not** the entire FHIR specification. See `DESIGN.md` for the phased roadmap.

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

## What Phase 1 does

1. **Route 1 — FHIR R4 REST Platform** (sync)
   - `POST/GET/PUT/DELETE` for enumerated resource types
   - `GET /metadata` → CapabilityStatement
   - `GET /{type}?_id=` / `?q=` → searchset Bundle (demo filters)
   - Persist to SQL Server + `output/fhir-store/`
2. **Route 2 — FHIR Outbound Client**
   - Drop request envelopes into `input/outbound/`
   - `RESTfulWebServiceTransport` → configurable remote FHIR base
3. **Web UI** — multi-resource client, search, metadata viewer, proxy toggle (Flask → remote when enabled)

## Ports

| Service | Host |
|---------|------|
| SQL Server | 14338 |
| PilotFish EIP | 8110 |
| Web UI | 8111 |

## Smoke

```bash
curl -sS http://127.0.0.1:8110/eip/rest/fhir/metadata | head -c 200

curl -sS -D- -H 'Content-Type: application/fhir+json' \
  --data-binary @samples/Patient_alice.json \
  http://127.0.0.1:8110/eip/rest/fhir/Patient

curl -sS http://127.0.0.1:8110/eip/rest/fhir/Patient/pat-alice-001

curl -sS 'http://127.0.0.1:8110/eip/rest/fhir/Patient?_id=pat-alice-001'
```

## Demo only

Shared `sa` password, heuristic JSON checks, simplified search — see `DESIGN.md` Risks.
