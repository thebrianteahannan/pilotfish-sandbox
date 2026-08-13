# EDI 270/271 Eligibility — Design

Status: **WORKING**

## 1. Purpose

Clinic front desk verifies member eligibility over real X12 **270/271** (005010X279A1): build a 270, call a mock payer, parse the 271, and show **AAA rejection theater** then a **successful EB benefits** response. Demo only — not a real payer.

## 2. Context / actors

- Sources: Clinic Web UI posts `EligibilityRequest` XML
- Destinations: sync X12 270, mock-payer 271, clinic JSON summary; audit files under `output/`
- Demo vs production: **Demo only** — canned AAA/EB, no SNIP, no clearinghouse

## 3. Inbound contract

- Transport: RESTful Web Service (`SERVICE_NAME=eligibility`, resources `build` / `parse`, Synchronous=true)
- Format / envelope: XML request → PilotFish EDI XML → X12 270; raw 271 wrapped as `<EdiPayload>` for parse
- Identity fields: MemberId (NM1*IL*…*MI*), TraceNumber (TRN02 / BHT03)
- Samples path: TableData examples in `samples/`; live story uses UI presets FAIL001 / OK001 / UNKNOWN

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Sync 270 | X12 text | `ISA*` + `ST*270` returned from `/build` |
| Mock payer 271 | X12 text | `ST*271` with AAA or EB |
| Clinic summary | JSON | `status=rejected` (AAA) or `status=active` (EB) |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.http.rest.RESTfulWebServiceListener` | Skeleton: CRL Plus Status.91 REST listener (POST, no auth). `Synchronous=true` because this is request/response, not a queue. |
| Router | `XPathRoutingModule` OGNL on HttpMethodName + ResourceName | build / parse / 405 |
| Build processors | XSLT → XML Formatting → `EDITransformationProcessor` XML→EDI | TableData `edi-tabledata/270-A1` (5010). XML Formatting on the **270 EDI XML audit write**, not the listener. |
| Parse processors | File snapshot → XSLT structural 271→JSON | 23R1 EDI→XML for 271 has failed without licensed tables; parse uses wrapped raw 271. TableData `271-A1` is still mounted. |
| Transports | `SynchronousResponseTransport` | Returns 270 text or JSON |
| Mock payer | Flask `:8210/x12/270` | FAIL001→AAA 72, UNKNOWN→AAA 75, else success EB |

**FQCN sources:** CRL Plus REST listener, `edi-835-payment-integrity` EDI transform + XML Formatting, PilotFish Documentation 26R1.11. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- Status model: none (sync request/response)
- Dedup keys: TraceNumber on the wire
- Retry / poison: bad XML fails at XSLT; unknown methods 405

## 7. Validation

- What is checked: 270 has ISA/ST; 271 has AAA or EB; clinic banner from parse JSON
- What is NOT checked: SNIP 270/271, real payer connectivity, HIPAA code-set licensing
- Does failure block outbound? yes for unparseable request XML

## 8. Dual-write / side effects

- Order: sync response is the contract; file snapshots are audit only
- Compensation: none
- Demo shortcuts: UI may insert `ST*270` if XML→EDI omitted it; UI wraps 271 in `EdiPayload` for parse

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | Mock payer is not a real 271 engine | Pitch is eligibility theater | Accepted |
| Med | 23R1 trial X12 tables expired | Sandbox mounts `EDI/TableData/x12` → `eip-root/edi-tabledata` | Named-segment XML→EDI 270; structural parse for 271 |
| Med | Duplicate processor names | EIP will not load the route | Unique names per processor |
| Low | Clinic UI orchestrates three HTTP hops | Sync REST + HttpPost mismatch | Intentional demo shape |

## 10. Ops

- Ports: Mock payer **8210**, EIP **8106**, Web UI **8107**
- Volumes: `./output`, `./logs`, `./samples`, `./documents`, TableData mount (5 `../` from `Insurance/EDI/`)
- Heap: 512M–2GB
- Dependencies / cold start: EIP ~60–90s
- Compose project: `edi-270-271-eligibility`

## 11. Observability

- Logs: `logs/eip.log`
- Audit: `output/requests/`, `output/270/`, `output/271/`, `output/responses/`
- debuggingTrace: true (demo)

## 12. Open questions

- Switch parse to `EDITransformationProcessor` EDI→XML once 271 TableData is proven on 23R1?

## 13. Tests

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-270-271-eligibility --wait
```
