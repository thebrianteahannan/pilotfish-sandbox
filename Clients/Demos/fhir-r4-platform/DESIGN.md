# DESIGN.md — FHIR R4 Expandable Platform (Phase 1–3)

## Purpose

Expandable **HL7 FHIR R4** PilotFish platform: multi-resource REST server (SQL primary store) plus an outbound FHIR client route. **Phase 3 adds Bundle `transaction` and `batch` execution** via `dbo.FhirExecuteBundle`.

## Honest scope

| In Phase 1–3 | Explicitly deferred |
|--------------|---------------------|
| CRUD for enumerated resource types | Full search grammar / modifiers / chained / `_include` |
| `GET /metadata` CapabilityStatement | `_history` / versioning / ETags |
| Soft delete | Profile / terminology validation |
| Outbound client + UI proxy | SMART / OAuth |
| Phase 2 token search (core-6) | Bulk `$export` |
| **Phase 3:** `POST /Bundle` type=`transaction`\|`batch` | Search-inside-Bundle; conditional create; full FHIR URL rules |

## Phased roadmap

1. **Phase 1:** multi-resource CRUD, metadata, simple search, outbound scaffold — done  
2. **Phase 2:** resource-specific search + EAV indexing — done  
3. **Phase 3 (this cut):** Bundle transaction (atomic) + batch (per-entry) — done when green  
4. **Phase 4:** profile validation  
5. **Phase 5:** SMART on FHIR  
6. **Phase 6:** Bulk export  

## Phase 3 Bundle execution

```text
POST /Bundle  (body.type = transaction | batch)
    → Route target BundleExecute
    → EXEC dbo.FhirExecuteBundle(@json)
    → 200 Bundle *-response   OR   400 OperationOutcome (failed transaction)
```

| Mode | Atomicity | Per-entry failure |
|------|-----------|-------------------|
| `transaction` | SQL BEGIN/COMMIT; ROLLBACK on failure | Whole Bundle fails → HTTP 400 OperationOutcome |
| `batch` | No outer transaction | Entry 4xx Outcome; others proceed; HTTP 200 batch-response |

Supported entry methods (demo): `POST`/`PUT` (require `resource.id`), `DELETE Type/id`, `GET Type/id`. No in-Bundle search. Max 25 entries.

## Phase 2 search

Core-6 indexed params via `FhirSearchTokens`; other types `_id` + legacy `q`.

| Type | Params |
|------|--------|
| Patient | `_id`, `identifier`, `family`, `given`, `name`, `gender`, `birthdate` |
| Practitioner | `_id`, `identifier`, `family`, `given`, `name` |
| Organization | `_id`, `identifier`, `name`, `active` |
| Observation | `_id`, `patient`, `code`, `date`, `status`, `category` |
| Encounter | `_id`, `patient`, `date`, `status`, `class` |
| Condition | `_id`, `patient`, `code`, `clinical-status`, `onset-date` |

## Ops

- Ports: SQL **14338**, EIP **8110**, Web UI **8111**  
- SQL init: `01` → `02_phase2_search` → `03_phase3_bundle`  
- Demo password: `PilotFish_Demo1!` (demo only)  
