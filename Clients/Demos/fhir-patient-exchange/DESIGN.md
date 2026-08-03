# FHIR Patient Exchange — Design

## 1. Purpose

Demo PilotFish ingesting HL7 FHIR R4 Patient (and Patient+Observation Bundle) JSON from provider systems, applying structural/business validation, then dual-writing to SQL Server (BI) and a mock FHIR store directory — inspired by PilotFish FHIR / CMS interoperability messaging.

## 2. Context / actors

- Sources: Hospital / EHR systems submitting FHIR R4 JSON via demo Web UI (directory drop)
- Destinations: SQL Server `FhirResources` table; `output/fhir-store/*.json` mock FHIR repository
- Demo vs production: **Demo only** — heuristic validation, shared `sa` password, no real FHIR REST server or OAuth

## 3. Inbound contract

- Transport: Directory poll (`DirectoryListener`) of XML envelopes produced by the Web UI from FHIR JSON
- Format / envelope: `<FhirMessage>` with metadata + `<RawFhir>` CDATA (FHIR R4 JSON)
- Identity fields: `ResourceId`, `PatientId` (MRN), `SourceSystem`
- Samples path: `samples/*.json`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| SQL Server | SQLXML insert into `dbo.FhirResources` | Row with `ValidationStatus=PASS` |
| FHIR store | Original FHIR JSON (`.json`) | File under `output/fhir-store/` |
| Kickout | Validation snapshot XML | File under `output/kickout/` when FAIL |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.file.DirectoryListener` | Polls `$$FHIR_INBOUND_DIRECTORY`, `xml` |
| Archive Inbound | `com.pilotfish.eip.modules.file.FileWriteProcessor` | Snapshot received envelope |
| Basic Validation | `com.pilotfish.eip.modules.transform.XSLTProcessor` | resourceType / id / RawFhir checks |
| Bundle Flag Snapshot | `com.pilotfish.eip.modules.file.FileWriteProcessor` | Renamed honestly — not a true fork |
| Advanced Validation | `com.pilotfish.eip.modules.transform.XSLTProcessor` | MRN, name, Patient/Bundle rules |
| Validation Snapshot | `com.pilotfish.eip.modules.file.FileWriteProcessor` | `_validated.xml` |
| Router | `com.pilotfish.eip.modules.routing.XPathRoutingModule` | FAIL→kickout; PASS→SQL+store |
| Map To SQL XML | `com.pilotfish.eip.modules.transform.XSLTProcessor` | PilotFish SQLXML insert |
| Insert Resource SQL | `com.pilotfish.eip.modules.db.DatabaseSqlTransport` | JDBC SQL Server |
| Extract FHIR JSON | `com.pilotfish.eip.modules.transform.XSLTProcessor` | Emits RawFhir text |
| Write FHIR Store | `com.pilotfish.eip.modules.file.DirectoryTransport` | `.json` to store dir |
| Write Kickout | `com.pilotfish.eip.modules.file.DirectoryTransport` | Fail path |

**Note:** There is no dedicated FHIR Listener/Transport in `modules.conf`; FHIR I/O is JSON + HTTP/directory. This demo uses Directory + XSLT heuristics (honest labeling). Format Builder FHIR support exists in V2 GUI only.

## 6. State & idempotency

- Status model: `PASS` / `FAIL` on validation; SQL only on PASS
- When state advances: after advanced validation; SQL+file on PASS (demo dual-write, no outbox)
- Dedup keys: none enforced (demo); `ResourceId` + timestamp filenames
- Retry / poison: kickout directory on FAIL; listener Move to archive after poll

## 7. Validation

- What is checked: resourceType Patient|Bundle; resource id; RawFhir JSON markers; Patient name/MRN; Bundle entry presence when Bundle
- What is NOT checked: full FHIR profile/StructureDefinition validation, terminology, OAuth, REST OperationOutcome
- Does failure block outbound? **yes** (router gates SQL + FHIR store)

## 8. Dual-write / side effects

- Order of commits: router fans out SQL and FHIR store in parallel (`retries=1`)
- Compensation: none
- Demo shortcuts: accepted dual-write without outbox (listed in Risks)

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | Dual-write without outbox | SQL may succeed while file fails (or reverse) | Accepted demo risk |
| Med | Validation theater if renamed poorly | Heuristic XSLT ≠ FHIR validator | Documented; gates FAIL path |
| Med | Runtime vs eip-root drift | Two trees | convert_routes_to_v2 syncs both |
| Low | Directory instead of REST listener | Story is FHIR API; demo uses file drop | Honest README labeling |
| Low | Shared sa password / PHI mounts | Local sandbox | Demo only |

## 10. Ops

- Ports: SQL **14337**, EIP **8102**, Web UI **8103**
- Volumes: `input/`, `output/`, `logs/`, `documents/`, routes for viewer
- Heap / special JVM: 512M–2G (no SNIP)
- Dependencies / cold start: ~60–90s for SQL init + EIP

## 11. Observability

- Logs: `logs/eip.log`
- Kickout dir: `output/kickout`
- Transaction / debug tracing: on in route.xml for demo

## 12. Open questions

- Future: swap DirectoryListener for `RESTfulWebServiceListener` when smoke-proven on `pilotfish-eip:23R1`
- Future: add HL7 v2 → FHIR Patient mapping route
