# FHIR R4 Expandable Platform (Phase 4)

Multi-resource **FHIR R4 REST** façade on PilotFish with SQL primary store, token search (core-6), Bundle transaction/batch, and **HAPI FHIR base-R4 profile validation**.

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

## Phase 4 validation

CREATE/UPDATE (and Bundle transaction/batch bodies) run through a custom `FhirProfileValidationProcessor` (HAPI instance validator). Failures return **HTTP 400** with a dynamic **OperationOutcome**.

```bash
# Expect 400 OperationOutcome (invalid Patient.gender)
curl -sS -D- -H 'Content-Type: application/fhir+json' \
  --data-binary @samples/Patient_invalid_gender.json \
  http://127.0.0.1:8110/eip/rest/fhir/Patient
```

Rebuilds compile the shaded validator module inside `pilotfish/Dockerfile` (not committed as a fat JAR).

## Phase 3 Bundles

```bash
curl -sS -H 'Content-Type: application/fhir+json' \
  --data-binary @samples/Bundle_transaction_patient_obs.json \
  http://127.0.0.1:8110/eip/rest/fhir/Bundle
```

## Ports

| Service | Host |
|---------|------|
| SQL Server | 14338 |
| PilotFish EIP | 8110 |
| Web UI | 8111 |
