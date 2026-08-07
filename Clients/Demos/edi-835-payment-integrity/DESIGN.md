# EDI 835 Payment Integrity — Design

## 1. Purpose
Demo of opportunity idea **2.5 Payment integrity / 835 that finance can trust**: ingest ERA 835s, enrich each claim payment with open-AR lineage from SQL Server, bucket **matched vs exception**, and emit an **underpay alert CSV** for shortfalls finance can act on. Demo only — not a full posting engine.

## 2. Context / actors
- Sources: Remit drop folder (`input/inbound/*.edi`)
- Destinations: `output/matched/`, `output/exceptions/`, `output/underpay/underpay_alerts.csv`, OpenAR status updates
- Demo vs production: **Demo only** — synthetic 835 + AR, no PM/EHR posting, no SNIP Types 1–7 for 835

## 3. Inbound contract
- Transport: Directory / File (`DirectoryListener`)
- Format / envelope: X12 **835** (5010-shaped), multi-`ST` / multi-`Transaction`
- Identity fields: `CLP02` patient control # → `OpenAR.ClaimControlNumber`
- Samples path: `samples/`

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Matched bucket | XML `RemitDecision` | File under `output/matched/` when AR found and paid within $0.01 of expected |
| Exception bucket | XML `RemitDecision` | File under `output/exceptions/` for underpay or no-AR |
| Underpay alerts | CSV (append) | Row in `output/underpay/underpay_alerts.csv` when underpay |
| OpenAR SQL | Status UPDATE | `MATCHED` / `EXCEPTION` / `UNDERPAY` after decision |

## 5. Pipeline
| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `DirectoryListener` | Poll `$$EDI_INBOUND_DIRECTORY` |
| R1 Format | `EDITransformationModule` + `XPathForkingModule` `//Transaction` | Split each ST |
| R1 Target processors | XPath → `DatabaseSqlProcessor` OpenAR lookup → XSLT score | Build `RemitDecision` |
| R1 Transport | `DirectoryTransport` | Stage under `output/staged-decisions/` |
| R2 Listener | `DirectoryListener` | Poll staged decisions |
| R2 Router | `XPathRoutingModule` accumulate=true | matched / exception / underpay CSV |
| R2 Transports | `DirectoryTransport` + `NullTransport` + SQL UPDATE | File buckets + AR status |

**FQCN sources:** Sandbox demos (`edi-835-oci-bucket`, `fhir-patient-exchange`, `hl7-healthcare-automation`) + playbook. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency
- Status model: OpenAR.Status `OPEN` → `MATCHED` | `UNDERPAY` | `EXCEPTION`
- When state advances: after RemitDecision is built, on each routing target
- Dedup keys: ClaimControlNumber + inbound file stamp (resubmits re-append CSV / overwrite decision files)
- Retry / poison: bad EDI fails at EDI→XML (fail-closed); unmatched AR stays EXCEPTION

## 7. Validation
- What is checked: EDI parses; CLP identity present; AR presence; paid vs expected within $0.01
- What is NOT checked: SNIP 835, PLB full accounting, CAS semantics beyond string capture, dual-write posting to PM
- Does failure block outbound? yes for unparseable EDI; no (exception theater) for business exceptions

## 8. Dual-write / side effects
- Order: decision XML → route fan-out (files + SQL update)
- Compensation: none (demo)
- Demo shortcuts: underpay threshold fixed at $0.01; CSV append without unique transaction id enforced

## 9. Risks & bottlenecks
| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | No PM/EHR post | Story stops at buckets + CSV | Accepted for sketch depth |
| Med | 23R1 trial X12 tables expired | Sandbox mounts `EDI/TableData/x12` → `eip-root/edi-tabledata` with `USE_ENHANCED_CONTEXT=true` + `TransactionDataWithVersion` (5010); see playbook §3.6 / `EDI/README.md`. | Named-segment EDI XML via Sandbox TableData |
| Med | Claim-before-complete on AR UPDATE | File write and SQL update not XA | Accepted demo dual-write |
| Med | Multi-CLP per ST not forked per CLP | Fork is //Transaction | Sample uses 1 CLP per ST |
| Low | CSV append races | Concurrent ST | Demo poll SerializedTransactions=1 |

## 10. Ops
- Ports: SQL **14339**, EIP **8110**, Web UI **8111**
- Volumes: `./input`, `./output`, `./logs`, `./samples`, `./documents`
- Heap: 1–2GB
- Dependencies / cold start: SQL health + seed ~30–60s, EIP ~60–90s

## 11. Observability
- Logs: `logs/eip.log`
- Kickout / exception dir: `output/exceptions/`
- debuggingTrace: true (demo)

## 12. Open questions
- Add selective mock PM post in a later pass?
- Fork `//CLP` (+ sibling CAS context) for true multi-claim ST files?
