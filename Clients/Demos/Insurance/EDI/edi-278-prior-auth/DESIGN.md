# EDI 278 Prior Auth — Design

Status: **WORKING**

## 1. Purpose

Ingest X12 **278** prior-auth requests, apply completeness rules (member, procedure, diagnosis, attachment when required), simulate a payer decision, and emit an **X12 278 response** plus an EHR **HL7 ORU** “auth decided” notice. Demo only — not Da Vinci PAS, not real payer APIs.

## 2. Context / actors

- Sources: Provider PA drop folder (`input/inbound/*.edi`)
- Destinations: decision buckets (`approved` / `denied` / `incomplete` / `pended`), `output/responses/*.edi` (278), `output/ehr-notices/*.hl7` (ORU), SQL `AuthRequest` status
- Demo vs production: **Demo only** — synthetic 278, catalog rules in SQL, no FHIR PAS, no LLP to a live EHR

## 3. Inbound contract

- Transport: Directory / File (`DirectoryListener`)
- Format: X12 **278** (5010-shaped), multi-`ST` / multi-`Transaction`
- Identity: `TRN02` → `AuthTraceNumber`
- Samples: `samples/sample_278_prior_auths.edi`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Approved / denied / incomplete / pended | XML `AuthDecision` | File under matching `output/<bucket>/` |
| 278 response | X12 278-shaped text | `output/responses/{AuthTraceNumber}_278_response.edi` |
| EHR notice | HL7 v2 ORU^R01 | `output/ehr-notices/{AuthTraceNumber}_auth_decided.oru.hl7` |
| AuthRequest SQL | Status UPDATE | `APPROVED` / `DENIED` / `INCOMPLETE` / `PENDED` |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `DirectoryListener` | Poll `$$EDI_INBOUND_DIRECTORY` |
| R1 Format | `EDITransformationProcessor` EDI→XML + `XPathForkingModule` `//Transaction` | TableData `278-A1` (5010). XML Formatting before XML file writes. |
| R1 Target | XPath extract → `DatabaseSqlProcessor` AuthCatalog lookup → XSLT completeness | Build `AuthDecision`. SQLXML tags are UPPERCASE. |
| R1 Transport | `DirectoryTransport` | Stage under `output/staged-decisions/` |
| R2 Listener | `DirectoryListener` | Poll staged decisions |
| R2 Router | `XPathRoutingModule` accumulate=true | Emit 278+ORU+SQL for all; bucket writers by DecisionBucket |
| R2 278 emit | XSLT → `EDITransformationProcessor` XML→EDI | XSLT builds XCSData only; no hardcoded ISA* |
| R2 ORU emit | XSLT → `HL7TransformationProcessor` XML→HL7 2.X | XSLT builds ORU XML only; no hardcoded MSH\| |
| R2 Transports | Directory + Null + SQL UPDATE | Unique processor names per route |

**FQCN sources:** `edi-835-payment-integrity` (directory, EDI fork, JDBC, XPath router), `medical-device-hl7-ehr` (HL7 XML→ER7). Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- Status: AuthRequest `OPEN` → `APPROVED` \| `DENIED` \| `INCOMPLETE` \| `PENDED`
- Dedup: AuthTraceNumber
- Unparseable EDI fails closed; incompleteness is business theater (still emits 278/ORU)

## 7. Validation

- Checked: EDI parses; TRN identity; completeness; catalog disposition
- Not checked: full 278 SNIP, Da Vinci PAS, real attachments, LLP
- Sample outcomes: PACOMPLETE01 approved, PAINCOMPLETE01 incomplete, PADENY01 denied, PAPEND01 pended

## 8. Dual-write / side effects

- Order: stage AuthDecision → fan-out (278 + ORU + bucket + SQL)
- Compensation: none (demo)

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation |
|----------|------|------------|
| High | No real payer / FHIR PAS | Accepted theater |
| Med | 23R1 trial tables | TableData mount (5 `../`) |
| Med | Duplicate processor names | Unique names per route |
| Med | SQLXML uppercase tags | XPath matches both cases |

## 10. Ops

- Ports: SQL **14340**, EIP **8120**, Web UI **8121**
- DB: `Edi278PriorAuth`, `sa` / `PilotFish_Demo1!`
- TableData: `../../../../../EDI/TableData/x12`
- Compose project: `edi-278-prior-auth`

## 11. Observability

- Logs: `logs/eip.log`
- debuggingTrace: true (demo)

## 12. Open questions

- FHIR Da Vinci PAS inbound later? LLP for ORU later?

## 13. Tests

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-278-prior-auth --wait
```
