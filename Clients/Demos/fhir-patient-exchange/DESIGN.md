# FHIR Patient Exchange — Design

> Implemented as synchronous **FHIR REST** (see `documents/FHIR_REST_Interface_Research.pdf`). DirectoryListener is retired.

## 1. Purpose

Demo PilotFish accepting HL7 FHIR R4 Patient create/read over HTTP REST with synchronous responses.

## 2. Context / actors

- Sources: FHIR HTTP clients (Web UI, curl, LAN devices)
- Destinations: Sync HTTP response; SQL `FhirResources`; file mirror under `output/fhir-store`
- Demo vs production: **Demo only**

## 3. Inbound contract

- Transport: `RESTfulWebServiceListener` — `/eip/rest/fhir/{Resource}[/{id}]`
- Format: `application/fhir+json`
- Interactions: `POST Patient`, `GET Patient/{id}`
- Identity: FHIR `id`; MRN via `identifier.value` (demo expects `MRN-*`)
- Samples: `samples/*.json`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| HTTP client | Patient / OperationOutcome JSON | 201 / 200 / 404 / 400 / 405 |
| SQL `FhirResources` | Row keyed by ResourceType+ResourceId | Readable by subsequent GET |
| fhir-store file | `{id}.json` | Mirror of created Patient |

## 5. Pipeline

| Stage | Module | Notes |
|-------|--------|-------|
| Listener | `com.pilotfish.eip.modules.http.rest.RESTfulWebServiceListener` | `SERVICE_NAME=fhir`, `Synchronous=true` |
| Extract / validate | RegEx + Attribute Population | Heuristic PASS/FAIL for create |
| Router | `XPathRoutingModule` OGNL on method/resource/validation | Create / Read / 400 / 405 |
| Persist | `FileWriteProcessor` + `DatabaseSqlProcessor` MERGE | After validation on create |
| Read | `DatabaseSqlProcessor` SELECT + XSLT | Empty → OperationOutcome |
| Status / headers | `HttpResponseCodeProcessor`, `AddHttpResponseHeadersProcessor` | fhir+json, Location |
| Reply | `com.pilotfish.eip.modules.internal.SynchronousResponseTransport` | Sync body |

## 6. State & idempotency

- MERGE upsert on create (same id updates RawFhir)
- Respond after persist
- Dedup: unique (ResourceType, ResourceId)

## 7. Validation

- Checked: resourceType Patient, id, MRN-ish identifier value, family name
- Not checked: full FHIR profiles, terminology, OAuth/SMART
- Failure blocks create with HTTP 400 OperationOutcome

## 8. Dual-write / side effects

- Order: file write → SQL MERGE → sync response body restored from attribute
- Accepted demo risk: file/SQL dual-write without outbox

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation / accepted? |
|----------|------|------------------------|
| High | REST listener quirks on 23R1 | Smoke-tested with curl |
| Med | Heuristic validation | Labeled demo-only |
| Med | Dual-write file+SQL | Accepted demo risk |
| Low | No search/transaction yet | Scoped in README |

## 10. Ops

- Ports: SQL 14337, EIP 8102, Web UI 8103
- LAN: `LAN_HINT=http://192.168.68.52:8103/`; FHIR public base on `:8102`
- Cold start ~60–90s

## 11. Observability

- `logs/eip.log`
- HTTP status + OperationOutcome to client
- Routes PDF under `documents/`

## 12. Open questions

- Add Bundle transaction / search in a later phase
- Basic auth on REST listener for demos?
