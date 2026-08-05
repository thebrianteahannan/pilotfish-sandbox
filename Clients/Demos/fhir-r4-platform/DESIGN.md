# DESIGN.md — FHIR R4 Expandable Platform (Phase 1–6)

## Purpose

Expandable **HL7 FHIR R4** PilotFish platform through **Phase 6 Bulk `$export`**.

## Honest scope

| In Phase 1–6 | Explicitly deferred |
|--------------|---------------------|
| CRUD, soft delete, metadata | Full search grammar / history |
| Token search (core-6) | US Core IG packages |
| Bundle transaction/batch | Group / Patient compartment export |
| HAPI base-R4 validation (**custom module** — HAPI cannot be expressed as stock PF alone) | CapStatement `$validate` |
| Keycloak Bearer on writes + export (**PF Call Route + introspection**) | Full SMART EHR launch |
| **Async system `$export` → NDJSON** (**PF Call Routes 3 / 3b + SQL**) | Multi-node Bulk, `_since` tombstones |

## Auth (Phase 5 → PF route)

Route `0 - Keycloak JWT Auth` is invoked synchronously from route `1` (`CallRouteProcessor`).
Protected verbs (POST/PUT/DELETE) and Bulk ops call Keycloak
`/protocol/openid-connect/token/introspect` with client credentials
(`$$fhir.oauth.*` in `environment-settings.conf`). Sets `fhir.AuthStatus`
PASS/FAIL/SKIP for the Unauthorized router rule.

## Phase 6 Bulk export (PF routes)

```text
GET|POST /$export?_type=Patient,Observation   (Bearer required)
  → Route 1 CallRoute sync → Route 3 kickoff
  → INSERT FhirExportJobs + status.json + async CallRoute → Route 3b worker
  → 202 Accepted + Content-Location: /$export-status/{jobId}
GET /$export-status/{jobId}                   (Bearer)
  → SQL job row → 202 while running · 200 manifest with output[]
GET /$export-file/{jobId}?_type=Patient       (Bearer)
  → application/fhir+ndjson from /opt/pilotfish/output/bulk-export/{jobId}/
```

Worker: `EXEC dbo.FhirBulkSelectNdjsonByJob` (`STRING_AGG` NDJSON) → FileWrite per
demo type → manifest.json + SQL `completed`.

Jobs + files: `/opt/pilotfish/output/bulk-export/{jobId}/` (+ `dbo.FhirExportJobs`).

## Custom modules

| Module | Status |
|--------|--------|
| HAPI Profile Validation | **Kept** — in-process HAPI Instance Validator |
| JWT Auth | Removed from image — PF Route 0 |
| Bulk Export | Removed from image — PF Routes 3 / 3b |

## Ops

| Service | Port |
|---------|------|
| SQL | 14338 |
| EIP | 8110 |
| Web UI | 8111 |
| Keycloak | 8112 |
