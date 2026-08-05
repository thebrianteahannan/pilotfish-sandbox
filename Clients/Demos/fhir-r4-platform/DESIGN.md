# DESIGN.md — FHIR R4 Expandable Platform (Phase 1–4)

## Purpose

Expandable **HL7 FHIR R4** PilotFish platform: multi-resource REST server (SQL primary store) plus an outbound FHIR client route. **Phase 4 adds HAPI FHIR base-R4 profile validation** on create/update (and Bundle bodies) via a custom `FhirProfileValidationProcessor` JAR.

## Honest scope

| In Phase 1–4 | Explicitly deferred |
|--------------|---------------------|
| CRUD for enumerated resource types | Full search grammar / modifiers / chained / `_include` |
| `GET /metadata` CapabilityStatement | `_history` / versioning / ETags |
| Soft delete | US Core / other IG packages |
| Outbound client + UI proxy | SMART / OAuth |
| Phase 2 token search (core-6) | Bulk `$export` |
| Phase 3: Bundle `transaction` \| `batch` | CapStatement `$validate` operation |
| **Phase 4:** HAPI instance validation (base R4); HTTP 400 OperationOutcome | Strict terminology / ValueSet expansion |

## Phased roadmap

1. **Phase 1:** multi-resource CRUD, metadata, simple search, outbound scaffold — done  
2. **Phase 2:** resource-specific search + EAV indexing — done  
3. **Phase 3:** Bundle transaction (atomic) + batch (per-entry) — done  
4. **Phase 4 (this cut):** profile validation (HAPI) — done when green  
5. **Phase 5:** SMART on FHIR  
6. **Phase 6:** Bulk export  

## Phase 4 validation

```text
POST|PUT resource (or POST /Bundle transaction|batch)
  → structural type/id checks
  → FhirProfileValidationProcessor (HAPI FhirInstanceValidator)
  → PASS → Create / Update / BundleExecute
  → FAIL → HTTP 400 dynamic OperationOutcome
```

- Built as shaded custom module (`custom-modules/fhir-profile-validation-processor`), baked into the PilotFish image.
- Uses **base R4** StructureDefinitions (`hapi-fhir-validation-resources-r4`).
- `noTerminologyChecks=true` for demo stability; **error/fatal** severities fail the request; warnings do not.
- Bundle path requires `fhir.ProfileValidationStatus == PASS` before `FhirExecuteBundle`.

## Phase 3 Bundle execution

| Mode | Atomicity | Per-entry failure |
|------|-----------|-------------------|
| `transaction` | SQL BEGIN/COMMIT; ROLLBACK on failure | Whole Bundle fails → HTTP 400 OperationOutcome |
| `batch` | No outer transaction | Entry 4xx Outcome; others proceed; HTTP 200 batch-response |

## Ops

- Ports: SQL **14338**, EIP **8110**, Web UI **8111**  
- SQL init: `01` → `02_phase2_search` → `03_phase3_bundle`  
- Demo password: `PilotFish_Demo1!` (demo only)  
- First request after startup may be slow while HAPI warms (module also warms on `systemStartup`)
