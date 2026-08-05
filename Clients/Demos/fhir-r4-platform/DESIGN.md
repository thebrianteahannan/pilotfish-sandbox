# DESIGN.md — FHIR R4 Expandable Platform (Phase 1)

## Purpose

Expandable **HL7 FHIR R4** PilotFish platform: multi-resource REST server (SQL primary store) plus an outbound FHIR client route. This is **Phase 1 of a staged program toward broader FHIR coverage** — not a claim to implement the entire FHIR specification.

## Honest scope

| In Phase 1 | Explicitly deferred |
|------------|---------------------|
| CRUD for enumerated resource types | Full search grammar / chained / `_include` |
| `GET /metadata` CapabilityStatement | `_history` / versioning / ETags |
| Simple searchset Bundle (`_id`, text contains) | Transaction/batch Bundle atomicity |
| Soft delete | StructureDefinition / terminology validation |
| Outbound client route + UI proxy toggle | SMART / OAuth |
| OperationOutcome errors | Bulk `$export`, `$everything`, `$validate` |

## Phased roadmap

1. **Phase 1 (this demo):** multi-resource CRUD, metadata, simple search, outbound client scaffold  
2. **Phase 2:** resource-specific search parameters + better indexing  
3. **Phase 3:** Bundle transaction/batch  
4. **Phase 4:** profile validation  
5. **Phase 5:** SMART on FHIR  
6. **Phase 6:** Bulk export  

## Actors

| Actor | Role |
|-------|------|
| FHIR HTTP clients / Web UI | Call PilotFish `/eip/rest/fhir/...` |
| PilotFish Route 1 | Sync REST server → SQL + file mirror |
| SQL Server `FhirR4PlatformDemo` | Primary store |
| PilotFish Route 2 | Outbound REST client (file-triggered) |
| Optional remote FHIR | Target of Route 2 / UI proxy mode |

## Architecture

```text
Client / Web UI
    │  CRUD / search / metadata
    ▼
PilotFish Route 1 — FHIR R4 REST Platform (sync)
    │  default
    ▼
SQL FhirResources + output/fhir-store
    │
Web UI proxy toggle ──► remote FHIR base (urllib client demo)
Route 2 file trigger ──► RESTfulWebServiceTransport ──► remote FHIR
```

**Proxy note:** Sync REST + outbound `RESTfulWebServiceTransport` cannot both be the sync reply transport. Phase 1 demonstrates outbound client as **Route 2** (native PF module) and **Web UI proxy** (Flask → remote). Inlining remote calls into Route 1 sync responses is a follow-on (Call Route / Response Listener patterns).

## Supported resources (Phase 1 list)

Patient, Practitioner, PractitionerRole, Organization, Location, Encounter, Observation, Condition, Procedure, AllergyIntolerance, MedicationRequest, Medication, Immunization, DiagnosticReport, DocumentReference, CarePlan, CareTeam, Goal, ServiceRequest, Coverage, Claim, ExplanationOfBenefit, Appointment, Schedule, Slot, RelatedPerson, Person, EpisodeOfCare, Binary, Bundle, Parameters, metadata

## Pipeline (Route 1)

| Stage | Module | FQCN |
|-------|--------|------|
| Listener | RESTful Web Service | `com.pilotfish.eip.modules.http.rest.RESTfulWebServiceListener` |
| Extract | RegEx / Attribute Population | validation = JSON `resourceType` + id rules |
| Router | XPathRoutingModule (OGNL) | metadata / create / read / update / delete / search / error |
| Persist | DatabaseSqlProcessor + FileWrite | MERGE / SELECT / soft delete |
| Map | XSLTProcessor | resource JSON, searchset Bundle, OperationOutcome |
| Reply | SynchronousResponseTransport | `application/fhir+json` |

## Pipeline (Route 2 — outbound)

| Stage | Module | FQCN |
|-------|--------|------|
| Listener | DirectoryListener | `input/outbound/*.json` request envelopes |
| Transport | RESTful Web Service | `com.pilotfish.eip.modules.http.rest.RESTfulWebServiceTransport` |
| Archive | DirectoryTransport | `output/outbound-responses/` |

Request envelope JSON: `{ "method":"GET", "path":"Patient/123", "query":"", "body":null }`

## State & commit

- Upsert on create/update after validation PASS  
- Soft delete sets `DeletedAt`; reads/search ignore deleted rows  
- Dual-write file + SQL accepted demo risk (no outbox)

## Risks

| Severity | Risk | Mitigation |
|----------|------|------------|
| High | Not full FHIR | CapabilityStatement tells truth; DESIGN/README |
| Med | Search is demo-simple | Documented; Phase 2 |
| Med | Sync REST cannot use outbound transport as reply | Route 2 + Web UI proxy |
| Med | 23R1 vs 26R1.11 doc skew | Call out in README |
| Low | Heuristic JSON checks only | Phase 4 validation |

## Ops

- Ports: SQL **14338**, EIP **8110**, Web UI **8111**  
- LAN: `http://192.168.68.52:8111/` · FHIR `http://192.168.68.52:8110/eip/rest/fhir`  
- Demo password: `PilotFish_Demo1!` (demo only)  
