# DESIGN.md — FHIR R4 Expandable Platform (Phase 1–2)

## Purpose

Expandable **HL7 FHIR R4** PilotFish platform: multi-resource REST server (SQL primary store) plus an outbound FHIR client route. **Phase 2 adds resource-specific search parameters** via an EAV token index — still not a claim to implement the entire FHIR specification.

## Honest scope

| In Phase 1–2 | Explicitly deferred |
|--------------|---------------------|
| CRUD for enumerated resource types | Full search grammar / modifiers / chained / `_include` |
| `GET /metadata` CapabilityStatement | `_history` / versioning / ETags |
| Soft delete | Transaction/batch Bundle atomicity |
| Outbound client route + UI proxy toggle | StructureDefinition / terminology validation |
| OperationOutcome errors | SMART / OAuth |
| **Phase 2:** token search for core-6 types | Bulk `$export`, `$everything`, `$validate` |
| **Phase 2:** legacy `q` / `_id` for other types | FHIR date prefix operators (`eq`/`ge`/…) |

## Phased roadmap

1. **Phase 1:** multi-resource CRUD, metadata, simple search, outbound client scaffold — done  
2. **Phase 2 (this cut):** resource-specific search parameters + EAV indexing — in progress / done when green  
3. **Phase 3:** Bundle transaction/batch  
4. **Phase 4:** profile validation  
5. **Phase 5:** SMART on FHIR  
6. **Phase 6:** Bulk export  

## Phase 2 search architecture

```text
POST/PUT  → MERGE FhirResources → EXEC FhirReindexResource → FhirSearchTokens
GET search → EXEC FhirSearchResources (AND of provided params) → searchset Bundle
DELETE    → soft-delete FhirResources + DELETE FhirSearchTokens
```

### Core-6 indexed parameters

| Type | Params |
|------|--------|
| Patient | `_id`, `identifier`, `family`, `given`, `name`, `gender`, `birthdate` |
| Practitioner | `_id`, `identifier`, `family`, `given`, `name` |
| Organization | `_id`, `identifier`, `name`, `active` |
| Observation | `_id`, `patient`, `code`, `date`, `status`, `category` |
| Encounter | `_id`, `patient`, `date`, `status`, `class` |
| Condition | `_id`, `patient`, `code`, `clinical-status`, `onset-date` |

Matching: string prefix/contains (case-insensitive), token exact on lowered value or `system|value`, patient accepts `Patient/{id}` or bare id, dates are ISO prefix matches.

## Actors

| Actor | Role |
|-------|------|
| FHIR HTTP clients / Web UI | Call PilotFish `/eip/rest/fhir/...` |
| PilotFish Route 1 | Sync REST server → SQL + file mirror + reindex |
| SQL Server `FhirR4PlatformDemo` | `FhirResources` + `FhirSearchTokens` |
| PilotFish Route 2 | Outbound REST client (file-triggered) |
| Optional remote FHIR | Target of Route 2 / UI proxy mode |

## Pipeline (Route 1)

| Stage | Module | Notes |
|-------|--------|-------|
| Listener | RESTfulWebServiceListener | sync |
| Extract | RegEx / Attribute Population | ids + `fhir.Search*` HTTP params |
| Router | OGNL rules | metadata / CRUD / search / errors |
| Persist | DatabaseSqlProcessor | MERGE; then `FhirReindexResource` |
| Search | DatabaseSqlProcessor | `FhirSearchResources` |
| Map | XSLTProcessor | resource JSON / searchset / outcome |
| Reply | SynchronousResponseTransport | `application/fhir+json` |

## State & commit

- Upsert on create/update after validation PASS  
- Reindex replaces all tokens for `(ResourceType, ResourceId)`  
- Soft delete sets `DeletedAt` and removes tokens  

## Risks

| Severity | Risk | Mitigation |
|----------|------|------------|
| High | Not full FHIR | CapabilityStatement + DESIGN |
| Med | OPENJSON paths incomplete vs all FHIR shapes | Core samples covered; extend proc |
| Med | Sync REST cannot use outbound transport as reply | Route 2 + Web UI proxy |
| Low | Heuristic JSON checks only | Phase 4 validation |

## Ops

- Ports: SQL **14338**, EIP **8110**, Web UI **8111**  
- LAN: `http://192.168.68.52:8111/` · FHIR `http://192.168.68.52:8110/eip/rest/fhir`  
- SQL init: `sql/01_init.sql` then `sql/02_phase2_search.sql`  
- Demo password: `PilotFish_Demo1!` (demo only)  
