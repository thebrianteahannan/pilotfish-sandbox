# fhir-bulk-export-processor (reference only — NOT baked into the image)

Phase 6 Bulk `$export` is implemented as PilotFish callout routes:

- `routes/3 - FHIR Bulk Export` — sync kickoff / status / NDJSON file serve
- `routes/3b - FHIR Bulk Export Worker` — async NDJSON + manifest writer
- Parent route `1` uses **Call Route** (synchronous) → Bulk Ops listener

SQL helpers: `sql/05_phase6_bulk_pf.sql` (`FhirBulkSelectNdjsonByJob`, `FhirBulkUpdateJobStatus`).

Sources remain here for historical comparison only. Do not re-add the JAR to
`pilotfish/Dockerfile` unless a concrete gap forces a custom module (see playbook §3.4).

HAPI profile validation remains a justified custom module.
