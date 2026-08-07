# EDI 278 Prior Auth — Design

## 1. Purpose
Demo of opportunity idea **2.1 Prior authorization that does not die in fax and portal hell**: ingest X12 **278** prior-auth requests, apply **completeness rules** (member, procedure, diagnosis, attachment when required), simulate a payer decision, and emit an **X12 278 response** plus an EHR **HL7 ORU** “auth decided” notice. Demo only — not Da Vinci PAS, not real payer APIs.

## 2. Context / actors
- Sources: Provider PA drop folder (`input/inbound/*.edi`)
- Destinations: decision buckets (`approved` / `denied` / `incomplete` / `pended`), `output/responses/*.edi` (278), `output/ehr-notices/*.hl7` (ORU), SQL `AuthRequest` status
- Demo vs production: **Demo only** — synthetic 278, catalog rules in SQL, no FHIR PAS path in v1, no LLP to a live EHR

## 3. Inbound contract
- Transport: Directory / File (`DirectoryListener`)
- Format / envelope: X12 **278** (5010-shaped Health Care Services Review Request), multi-`ST` / multi-`Transaction`
- Identity fields: `TRN02` → `AuthTraceNumber` (also keyed on demo catalog outcomes)
- Samples path: `samples/`

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Approved / denied / incomplete / pended buckets | XML `AuthDecision` | File under matching `output/<bucket>/` |
| 278 response | X12 278-shaped text | File under `output/responses/{AuthTraceNumber}_278_response.edi` |
| EHR notice | HL7 v2 ORU^R01 | File under `output/ehr-notices/{AuthTraceNumber}_auth_decided.oru.hl7` |
| AuthRequest SQL | Status UPDATE | `APPROVED` / `DENIED` / `INCOMPLETE` / `PENDED` after emit |

## 5. Pipeline
| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `DirectoryListener` | Poll `$$EDI_INBOUND_DIRECTORY` |
| R1 Format | `EDITransformationModule` + `XPathForkingModule` `//Transaction` | Split each ST; `UseInternalData=false` + TableData mount (Sandbox mounts `EDI/TableData/x12` → `eip-root/edi-tabledata` with `USE_ENHANCED_CONTEXT=true` + `TransactionDataWithVersion` (5010); see playbook §3.6 / `EDI/README.md`.) |
| R1 Target processors | XPath extract → `DatabaseSqlProcessor` AuthCatalog lookup → XSLT completeness + disposition | Build `AuthDecision` |
| R1 Transport | `DirectoryTransport` | Stage under `output/staged-decisions/` |
| R2 Listener | `DirectoryListener` | Poll staged decisions |
| R2 Router | `XPathRoutingModule` accumulate=true | Emit 278+ORU+SQL for all; bucket writers by `DecisionBucket` |
| R2 278 emit | `XSLTProcessor` → `EDITransformationProcessor` (`XML to EDI`) | XSLT builds XCSData only; no hardcoded ISA* wire text |
| R2 ORU emit | `XSLTProcessor` → `HL7TransformationProcessor` (`XML to HL7 2.X`) → `EOLProcessor` | XSLT builds ORU_R01 HL7 XML only; no hardcoded MSH| wire text |
| R2 Transports | `DirectoryTransport` + `NullTransport` + SQL UPDATE | Files + AuthRequest status |

**FQCN sources:** Sandbox demos (`edi-835-payment-integrity`, `medical-device-hl7-ehr`) + playbook. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency
- Status model: AuthRequest.Status `OPEN` → `APPROVED` | `DENIED` | `INCOMPLETE` | `PENDED`
- When state advances: after AuthDecision is routed
- Dedup keys: AuthTraceNumber + inbound file stamp (resubmits overwrite decision / response files)
- Retry / poison: bad EDI fails at EDI→XML (fail-closed); incompleteness is business theater (does not hard-fail the route)

## 7. Validation
- What is checked: EDI parses; TRN identity present; completeness (MemberId, PatientName, ProcedureCode, DiagnosisCode; attachment when catalog requires); catalog disposition for complete requests
- What is NOT checked: full 278 SNIP, HCD/UM loop fidelity, real clinical attachment content, Da Vinci PAS, LOINC questionnaires
- Does failure block outbound? yes for unparseable EDI; no for incompleteness (incomplete bucket + 278/ORU still emit)

## 8. Dual-write / side effects
- Order: stage AuthDecision → route fan-out (278 + ORU + bucket + SQL)
- Compensation: none (demo)
- Demo shortcuts: simulated payer is SQL `DefaultDisposition` + completeness gate; attachment is a `PWK` / `REF*EA` flag, not a real 275 payload

## 9. Risks & bottlenecks
| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | No real payer / FHIR PAS | Pitch lists Da Vinci + portals | Accepted — X12 278 first cut |
| Med | 23R1 trial X12 tables expired | Sandbox mounts `EDI/TableData/x12` → `eip-root/edi-tabledata` with `USE_ENHANCED_CONTEXT=true` + `TransactionDataWithVersion` (5010); see playbook §3.6 / `EDI/README.md`. | Named-segment EDI XML via Sandbox TableData |
| Med | Claim-before-complete on multi-file emit | 278, ORU, bucket, SQL not XA | Accepted demo dual-write |
| Med | Synthetic 278 not clearinghouse-certified | Theater segments only | Documented; samples are demo-shaped |
| Low | Multi-service loop per ST | Fork is //Transaction | Sample uses 1 service story per ST |

## 10. Ops
- Ports: SQL **14340**, EIP **8120**, Web UI **8121**
- Volumes: `./input`, `./output`, `./logs`, `./samples`, `./documents`
- Heap: 1–2GB
- Dependencies / cold start: SQL health + seed ~30–60s, EIP ~60–90s
- LAN: Web UI on `0.0.0.0`; `LAN_HINT=http://192.168.68.52:8121/`

## 11. Observability
- Logs: `logs/eip.log`
- Kickout / incomplete dir: `output/incomplete/`
- debuggingTrace: true (demo)

## 12. Open questions
- Add FHIR Da Vinci PAS inbound path in a later pass?
- LLP delivery of ORU instead of file drop?
