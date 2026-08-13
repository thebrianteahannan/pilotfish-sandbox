# EDI 270/271 Realtime Eligibility — Design

Status: **WORKING**

## 1. Purpose

Clinic (or EHR) posts **once**. PilotFish owns the full synchronous **270 → payer → 271** round-trip and returns clinic-ready JSON on the same HTTP request.

Sibling of `edi-270-271-eligibility` (UI orchestrates three hops). Built for Gary Beatty’s real-time eligibility demo.

## 2. Context / actors

- Sources: Clinic Web UI posts `EligibilityRequest` XML to PilotFish `/eip/rest/eligibility/check`
- Destinations: mock payer X12 271; clinic JSON summary; audit files under `output/`
- Demo vs production: **Demo only** — canned AAA/EB, no SNIP, no clearinghouse

## 3. Inbound contract

- Transport: RESTful Web Service (`SERVICE_NAME=eligibility`, resource `check`, Synchronous=true)
- Format: XML request → PilotFish EDI XML → X12 270 → HttpPost → wrap 271 in `<EdiPayload>` → JSON
- Identity fields: MemberId (NM1*IL*…*MI*), TraceNumber (TRN02 / BHT03)
- Samples: TableData examples in `samples/`; live story uses FAIL001 / OK001 / UNKNOWN

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Mock payer | X12 270 POST | 271 with AAA or EB |
| Clinic | JSON | `status=rejected` (AAA) or `status=active` (EB) on the same HTTP request |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `RESTfulWebServiceListener` | Skeleton: CRL Plus Status.91 REST listener. `Synchronous=true` because this is request/response. |
| Router | `XPathRoutingModule` OGNL on HttpMethodName + ResourceName | `check` vs 405 |
| Build | XSLT → XML Formatting → `EDITransformationProcessor` XML→EDI | TableData `270-A1` / `271-A1`. XML Formatting on the **270 EDI XML audit write**. |
| Payer | `HttpPostTransport` | Skeleton: FHIR Route `0 - Keycloak JWT Auth`. Target `$$PAYER_X12_URL`. |
| Parse | Save body → wrap `<EdiPayload>` → structural Saxon XSLT | Same 23R1 honesty as orig: no EDI→XML 271. |
| Sync reply | `SynchronousResponseProcessor` in **PostProcessors** | Continues after HttpPost (Keycloak pattern). |

**FQCN sources:** CRL Plus REST, `edi-270-271-eligibility` EDI/XSLT, FHIR Keycloak HttpPost + PostProcessors + `SynchronousResponseProcessor`. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- Status model: none (sync request/response)
- Dedup keys: TraceNumber on the wire
- Retry / poison: bad XML fails at XSLT; unknown methods 405

## 7. Validation

- What is checked: 271 has AAA or EB; clinic banner from parse JSON; UI `mode=realtime`
- What is NOT checked: SNIP 270/271, real payer connectivity, HIPAA code-set licensing
- Does failure block outbound? yes for unparseable request XML

## 8. Dual-write / side effects

- Order: sync JSON is the contract; file snapshots are audit only
- Compensation: none
- Demo shortcuts: mock payer matches on `NM1*IL` and does not require `ST*270`; wrap 271 in `EdiPayload` for the parse XSLT

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | Mock payer is not a real 271 engine | Pitch is eligibility theater | Accepted |
| Med | 23R1 trial X12 tables | XML→EDI may omit ST; EDI→XML 271 unused | Named-segment XML→EDI 270; structural parse |
| Med | Duplicate processor names | EIP will not load the route | Unique names per processor |
| Low | Clinic UI still builds EligibilityRequest XML | Production could POST the same XML from any clinic system | Intentional |

## 10. Ops

- Ports: Mock payer **8211**, EIP **8120**, Web UI **8121**
- Volumes: `./output`, `./logs`, `./samples`, `./documents`, TableData mount (5 `../` from `Insurance/EDI/`)
- Heap: 512M–2GB
- Dependencies / cold start: EIP ~60–90s
- Compose project: `edi-270-271-realtime`

## 11. Observability

- Logs: `logs/eip.log`
- Audit: `output/requests/`, `output/270/`, `output/271/`, `output/responses/`
- debuggingTrace: true (demo)

## 12. Open questions

- Switch parse to `EDITransformationProcessor` EDI→XML once 271 TableData is proven on 23R1?

## 13. Tests

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-270-271-realtime --wait
```
