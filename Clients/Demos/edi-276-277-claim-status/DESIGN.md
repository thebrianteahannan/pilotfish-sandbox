# EDI 276/277 Claim Status — Design

## 1. Purpose
Demo of pitch **§3 / 3.1 quick-win** **276/277 claim status inquiry**: ingest X12 **276** claim status requests, apply a lightweight identity + demo catalog lookup (no SQL), stage a `ClaimStatusDecision`, then emit an X12 **277** response and file buckets (`found` / `not-found` / `error`). Closes the loop after 837/835 demos. Demo only — not a clearinghouse, not real payer claim master.

## 2. Context / actors
- Sources: Provider claim-status drop folder (`input/inbound/*.edi`)
- Destinations: decision buckets (`found` / `not-found` / `error`), `output/responses/*.edi` (277), debug XML
- Demo vs production: **Demo only** — synthetic 276, in-XSLT catalog by `TraceNumber`, no SQL, no FHIR Claim/$status

## 3. Inbound contract
- Transport: Directory / File (`DirectoryListener`)
- Format / envelope: X12 **276** (5010-shaped Health Care Claim Status Request), multi-`ST` / multi-`Transaction`
- Identity fields: `TRN02` / `BHT03` → `TraceNumber`; `NM1*IL*NM109` → `MemberId`; `REF*EJ` → `ClaimId`; `AMT*T3` → `Amount`
- Samples path: `samples/`

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Found / not-found / error buckets | XML `ClaimStatusDecision` | File under matching `output/<bucket>/` |
| 277 response | X12 277-shaped text | File under `output/responses/{TraceNumber}_277_response.edi` |

## 5. Pipeline
| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `DirectoryListener` | Poll `$$EDI_INBOUND_DIRECTORY`; extensions `edi,276,txt` |
| R1 Format | `EDITransformationModule` + `XPathForkingModule` `//Transaction` | Split each ST; TableData `edi-tabledata/276-A1` @ 5010 |
| R1 Target processors | XPath extract → FileWrite debug → XSLT catalog decision → FileWrite decision | **No** `DatabaseSqlProcessor` |
| R1 Transport | `DirectoryTransport` | Stage under `output/staged-decisions/` (filename from `TraceNumber`) |
| R2 Listener | `DirectoryListener` | Poll staged decisions |
| R2 Router | `XPathRoutingModule` accumulate=true | Always emit 277 when `DecisionBucket` present; bucket writers by `found` / `not-found` / `error` |
| R2 277 emit | `XSLTProcessor` → `EDITransformationProcessor` (`XML to EDI`) | XSLT builds XCSData only; TableData `edi-tabledata/277-A1` @ 5010 |
| R2 Transports | `DirectoryTransport` | Response + three buckets — **no** ORU/HL7, **no** SQL UPDATE |

**Demo catalog (by TraceNumber):** `ABCXYZ1` → found/F1 finalized paid; `ABCXYZ2` → found/P1 pending; `ABCXYZ3` → not-found/E1; empty / incomplete identity → error/`MISSING_IDENTITY`; else → not-found.

**FQCN sources:** Sandbox demos (`edi-278-prior-auth` skeleton) + playbook. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency
- Status model: file theater only — `DecisionBucket` on staged XML
- Dedup keys: TraceNumber + ST control (resubmits overwrite decision / response files)
- Retry / poison: bad EDI fails at EDI→XML (fail-closed); missing identity is business theater (error bucket + 277 still emit)

## 7. Validation
- What is checked: EDI parses; TraceNumber + MemberId present for completeness; demo catalog disposition
- What is NOT checked: full 276/277 SNIP, multi-TRN-per-ST claim loops, real claim master / 837 seed join
- Does failure block outbound? yes for unparseable EDI; no for not-found / incomplete (bucket + 277 still emit)

## 8. Dual-write / side effects
- Order: stage `ClaimStatusDecision` → route fan-out (277 + bucket)
- Compensation: none (demo)
- Demo shortcuts: catalog is XSLT `choose` on TraceNumber — no SQL, no 837 reuse yet

## 9. Risks & bottlenecks
| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | No real claim master | Pitch says reuse 837 seed | Accepted — TraceNumber catalog first cut |
| Med | 23R1 trial X12 tables | Needs Sandbox TableData mount | `276-A1` / `277-A1` @ 5010 |
| Med | Multi-TRN / multi-claim per ST | XPath `[1]` takes first TRN/member | Documented; sample has multiple TRNs |
| Med | Synthetic 277 not clearinghouse-certified | Theater segments only | Documented |
| Low | Web UI still scaffold | Progressive build | Do not block runtime smoke |

## 10. Ops
- Ports: EIP **8126**, Web UI **8127** (no SQL)
- Volumes: `./input`, `./output`, `./logs`, `./samples`, `./documents`
- Heap: 1–2GB
- Dependencies / cold start: EIP ~60–90s (no SQL seed)
- LAN: Web UI on `0.0.0.0`; `LAN_HINT=http://192.168.68.62:8127/`

## 11. Observability
- Logs: `logs/eip.log`
- Kickout / error dir: `output/error/`
- debuggingTrace: true (demo)

## 12. Open questions
- Join TraceNumber / ClaimId to an 837 seed store for “reuse 837 data” pitch storytelling?
- Status inquiry UI beyond current Web UI scaffold?
