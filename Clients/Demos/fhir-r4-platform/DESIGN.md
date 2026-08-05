# DESIGN.md — FHIR R4 Expandable Platform (Phase 1–6)

## Purpose

Expandable **HL7 FHIR R4** PilotFish platform through **Phase 6 Bulk `$export`**.

## Honest scope

| In Phase 1–6 | Explicitly deferred |
|--------------|---------------------|
| CRUD, soft delete, metadata | Full search grammar / history |
| Token search (core-6) | US Core IG packages |
| Bundle transaction/batch | Group / Patient compartment export |
| HAPI base-R4 validation | CapStatement `$validate` |
| Keycloak Bearer on writes + export | Full SMART EHR launch |
| **Auth via PF Call Route + Keycloak introspection** (no JWT custom JAR) | Local JWKS/Nimbus custom processor |
| **Async system `$export` → NDJSON** | Multi-node Bulk, `_since` tombstones |

## Phase 6 Bulk export

```text
GET|POST /$export?_type=Patient,Observation   (Bearer required)
  → 202 Accepted + Content-Location: /$export-status/{jobId}
GET /$export-status/{jobId}                   (Bearer)
  → 202 while running · 200 manifest with output[]
GET /$export-file/{jobId}?_type=Patient       (Bearer)
  → application/fhir+ndjson
```

Jobs + files: `/opt/pilotfish/output/bulk-export/{jobId}/` (+ `dbo.FhirExportJobs`).

## Auth (Phase 5 → PF route)

Route `0 - Keycloak JWT Auth` is invoked synchronously from route `1` (`CallRouteProcessor`).
Protected verbs (POST/PUT/DELETE) and Bulk ops call Keycloak
`/protocol/openid-connect/token/introspect` with client credentials
(`$$fhir.oauth.*` in `environment-settings.conf`). Sets `fhir.AuthStatus`
PASS/FAIL/SKIP for the Unauthorized router rule.

## Ops

| Service | Port |
|---------|------|
| SQL | 14338 |
| EIP | 8110 |
| Web UI | 8111 |
| Keycloak | 8112 |
