# FHIR R4 Expandable Platform (Phase 3)

Multi-resource **FHIR R4 REST** façade on PilotFish with SQL primary store, token search (core-6), and **Bundle transaction/batch** execution.

> Not the entire FHIR specification — see `DESIGN.md`.

## Quick start

```bash
cd "Clients/Demos/fhir-r4-platform"
docker compose up -d --build
./tools/smoke.sh
```

| Where | URL |
|-------|-----|
| Web UI | http://127.0.0.1:8111/ |
| FHIR base | http://127.0.0.1:8110/eip/rest/fhir |
| Metadata | http://127.0.0.1:8110/eip/rest/fhir/metadata |

## Phase 3 Bundles

```bash
# Atomic transaction (Patient + Observation)
curl -sS -D- -H 'Content-Type: application/fhir+json' \
  --data-binary @samples/Bundle_transaction_patient_obs.json \
  http://127.0.0.1:8110/eip/rest/fhir/Bundle

# Batch (success + 404 entry)
curl -sS -H 'Content-Type: application/fhir+json' \
  --data-binary @samples/Bundle_batch_mixed.json \
  http://127.0.0.1:8110/eip/rest/fhir/Bundle
```

Entry methods supported in demo: `POST`/`PUT` (with `resource.id`), `GET Type/id`, `DELETE Type/id`.

## Ports

| Service | Host |
|---------|------|
| SQL Server | 14338 |
| PilotFish EIP | 8110 |
| Web UI | 8111 |
