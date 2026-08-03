# FHIR Patient Exchange — Design

> **Status (2026-08-03):** The directory-listener demo was a temporary scaffold and is **not** the intended FHIR architecture.  
> See research PDF: [`documents/FHIR_REST_Interface_Research.pdf`](documents/FHIR_REST_Interface_Research.pdf).  
> Rebuild target: **synchronous RESTful FHIR** via `RESTfulWebServiceListener` + `SynchronousResponseTransport`.

## 1. Purpose

Provide a PilotFish Sandbox demo of **HL7 FHIR R4 REST** resource exchange (initially Patient create/read), with real HTTP request/response semantics — not file-drop integration.

## 2. Context / actors

- Sources: EHR / app FHIR **clients** calling HTTP endpoints
- Destinations: PilotFish FHIR façade (persist + sync HTTP response); optional later outbound call to an external FHIR server
- Demo vs production: **Demo only** — heuristic validation, basic auth optional, no SMART/OAuth unless explicitly added later

## 3. Inbound contract (target)

- Transport: **HTTP REST** on eiPlatform  
  ` /eip/rest/fhir/{Resource}[/{id}] `
- Format: `application/fhir+json` (FHIR R4)
- Interactions (v1): `POST Patient` (create), `GET Patient/{id}` (read)
- Identity: FHIR logical `id`; business MRN via `Patient.identifier`
- Samples: raw FHIR JSON used by Web UI / curl as a **client**

## 4. Outbound contract(s) (target)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| HTTP client (sync) | Patient or OperationOutcome JSON | Correct status (201/200/404/400) + body |
| Persistence store | FHIR JSON | Resource readable by subsequent GET |
| Optional SQL audit | Row | Written **after** successful persist |

## 5. Pipeline (target modules)

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.http.rest.RESTfulWebServiceListener` | `SERVICE_NAME=fhir`, `Synchronous=true`, GET+POST |
| Branch | Router / XPath on `com.pilotfish.HttpMethodName` | create vs read |
| JSON handling | `JSONTransformationProcessor` and/or keep JSON | Mapping aid; not IG validation |
| Validate | XSLT / heuristic → OperationOutcome on fail | Fail-closed HTTP 4xx |
| Persist / load | SQL and/or directory store as **backend**, not the public API | Source of truth for GET |
| Status / headers | `HttpResponseCodeProcessor`, `AddHttpResponseHeadersProcessor` | 201 + Location, Content-Type |
| Reply | `com.pilotfish.eip.modules.internal.SynchronousResponseTransport` | Sync body to caller |

**Not the public FHIR API:** `DirectoryListener` (retired as the FHIR story).

## 6. State & idempotency

- Status model: HTTP semantics + stored resource versions (simple v1: last-write)
- When state advances: persist then respond (no claim-before-complete)
- Dedup keys: FHIR `id`; conditional create later (`If-None-Exist`) optional
- Retry / poison: OperationOutcome to client; optional audit of failures

## 7. Validation

- What is checked (v1): resourceType, required Patient fields, JSON parse
- What is NOT checked: full StructureDefinition/IG, terminology, SMART scopes
- Does failure block outbound? **yes** — HTTP error, no silent success

## 8. Dual-write / side effects

- Order: persist resource → sync HTTP response → optional SQL audit
- Compensation: none in demo; document if SQL audit added as best-effort
- Demo shortcuts: in-memory/SQL store rather than full FHIR repository history

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | REST listener untested on 23R1 image | Could fail at smoke | Phase 1 spike before UI polish |
| High | Pretending directory demo is FHIR | Wrong partner contract | Research PDF + rebuild |
| Med | Partial FHIR surface | Clients expect search/transaction | Scope v1 explicitly |
| Med | Validation theater | Heuristic ≠ validator | Label in README |
| Low | Auth | Basic only | Demo only |

## 10. Ops

- Ports: SQL **14337**, EIP **8102**, Web UI **8103** (adjust if rebound)
- LAN: `LAN_HINT=http://192.168.68.52:8103/` (re-detect 192.*); EIP REST also on LAN `:8102`
- Heap: 512M–2G unless expanded
- Cold start: 60–90s

## 11. Observability

- Logs: `logs/eip.log`
- Client-visible: HTTP status + OperationOutcome
- Route design PDF after REST rebuild

## 12. Open questions

- Persist backend choice (SQL JSON vs files vs both)
- Include Bundle transaction in v1 or phase 3?
- Deprecate directory-route artifacts immediately on rebuild?
- Auth header expectations for demo clients

## References

- `documents/FHIR_REST_Interface_Research.pdf`
- https://www.hl7.org/fhir/R4/http.html
- https://healthcare.pilotfishtechnology.com/restful-listener-configuration/
